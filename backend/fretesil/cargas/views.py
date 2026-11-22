from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from usuario.models import Caminhoneiro
from .models import Carga, Candidatura
from .serializers import CargaSerializer, CandidaturaSerializer


def _erro(mensagem, codigo=status.HTTP_400_BAD_REQUEST):
    return Response({'erro': mensagem}, status=codigo)


def _travar_carga(carga_id):
    """Bloqueia a carga até o fim da transação, evitando decisões simultâneas.

    Ordem dos bloqueios em todo o fluxo: carga → candidatura → motorista.
    """
    return Carga.objects.select_for_update().get(pk=carga_id)


def _viagem_ativa(motorista, exceto_carga_id=None):
    cargas = Carga.objects.filter(motorista_alocado=motorista, status__in=Carga.ETAPAS_ATIVAS)
    if exceto_carga_id is not None:
        cargas = cargas.exclude(pk=exceto_carga_id)
    return cargas.exists()


class CargaViewSet(viewsets.ModelViewSet):
    serializer_class = CargaSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]
    # Sem PUT/PATCH/DELETE: cargas não podem ser editadas/apagadas via API
    # (evita que um motorista altere cargas disponíveis). Restam list/retrieve,
    # o create (empresa) e as ações customizadas (candidatar, finalizar, etc.).
    http_method_names = ['get', 'post', 'head', 'options']

    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'perfil_empresa'):
            cargas = Carga.objects.filter(empresa=user.perfil_empresa)
        elif hasattr(user, 'perfil_motorista'):
            # O motorista vê as cargas abertas e também as que são dele
            # (para aceitar, acoplar, cancelar e consultar depois).
            cargas = Carga.objects.filter(
                Q(status='disponivel') | Q(motorista_alocado=user.perfil_motorista)
            )
        else:
            return Carga.objects.none()

        filtro_status = self.request.query_params.get('status')
        if self.action == 'list' and filtro_status:
            cargas = cargas.filter(status=filtro_status)
        return cargas

    def _minha_carga(self, request):
        """Carga do motorista logado, bloqueada e garantidamente dele."""
        if not hasattr(request.user, 'perfil_motorista'):
            raise PermissionDenied('Apenas motoristas.')
        carga = _travar_carga(self.get_object().pk)
        if carga.motorista_alocado_id != request.user.perfil_motorista.pk:
            raise PermissionDenied('Esta carga não é sua.')
        return carga

    def perform_create(self, serializer):
        if not hasattr(self.request.user, 'perfil_empresa'):
            raise PermissionDenied('Somente empresas podem criar cargas.')
        serializer.save(empresa=self.request.user.perfil_empresa)

    @action(detail=False, methods=['get'], url_path='ativa')
    def ativa(self, request):
        """Viagem em andamento do motorista, em qualquer etapa antes da entrega."""
        if not hasattr(request.user, 'perfil_motorista'):
            return Response({'erro': 'Apenas motoristas.'}, status=403)
        carga = Carga.objects.filter(
            motorista_alocado=request.user.perfil_motorista,
            status__in=Carga.ETAPAS_ATIVAS,
        ).first()
        if not carga:
            return Response(None, status=200)
        return Response(CargaSerializer(carga, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='aceitar')
    @transaction.atomic
    def aceitar(self, request, pk=None):
        """Motorista confirma a carga que a empresa aprovou para ele."""
        carga = self._minha_carga(request)
        if carga.status != 'aguardando_aceite':
            return _erro('Esta carga não está aguardando o seu aceite.')
        carga.status = 'acoplar_carreta'
        # Usa o consumo mais recente, caso o motorista tenha atualizado o perfil.
        carga.consumo_veiculo_alocado = request.user.perfil_motorista.consumo_medio_km_l
        carga.save()
        return Response({
            'mensagem': 'Carga aceita! Vá buscar a carreta.',
            'carga': CargaSerializer(carga, context={'request': request}).data,
        })

    @action(detail=True, methods=['post'], url_path='iniciar-viagem')
    @transaction.atomic
    def iniciar_viagem(self, request, pk=None):
        """Motorista acoplou a carreta e saiu para a estrada."""
        carga = self._minha_carga(request)
        if carga.status != 'acoplar_carreta':
            return _erro('A carreta precisa estar na etapa de acoplagem.')
        carga.status = 'em_transito'
        carga.save()
        return Response({
            'mensagem': 'Boa viagem! Carga em trânsito.',
            'carga': CargaSerializer(carga, context={'request': request}).data,
        })

    @action(detail=True, methods=['post'], url_path='cancelar')
    @transaction.atomic
    def cancelar(self, request, pk=None):
        """Motorista desiste da viagem; a carga volta a ficar disponível."""
        carga = self._minha_carga(request)
        if carga.status not in Carga.ETAPAS_ATIVAS:
            return _erro('Esta viagem não pode mais ser cancelada.')

        motorista = request.user.perfil_motorista
        carga.candidaturas.filter(caminhoneiro=motorista).update(status='cancelada')
        # Quem só perdeu a vaga para este motorista volta a concorrer.
        carga.candidaturas.filter(status='recusada', recusa_automatica=True).update(
            status='pendente', recusa_automatica=False)
        carga.motorista_alocado = None
        carga.consumo_veiculo_alocado = None
        carga.status = 'disponivel'
        carga.save()
        return Response({'mensagem': 'Viagem cancelada. A carga voltou para a lista.'})

    @action(detail=False, methods=['get'], url_path='minhas-entregas')
    def minhas_entregas(self, request):
        """Entregas finalizadas do motorista (para avaliar a empresa)."""
        if not hasattr(request.user, 'perfil_motorista'):
            return Response({'erro': 'Apenas motoristas.'}, status=403)
        cargas = Carga.objects.filter(
            motorista_alocado=request.user.perfil_motorista,
            status='finalizado',
        ).order_by('-data_entrega')
        return Response(CargaSerializer(cargas, many=True, context={'request': request}).data)

    @action(detail=False, methods=['get'], url_path='minhas-candidaturas')
    def minhas_candidaturas(self, request):
        """Cargas às quais o motorista se candidatou (com o status do pedido)."""
        if not hasattr(request.user, 'perfil_motorista'):
            return Response({'erro': 'Apenas motoristas.'}, status=403)
        candidaturas = Candidatura.objects.filter(
            caminhoneiro=request.user.perfil_motorista
        ).select_related('carga')
        return Response(CandidaturaSerializer(candidaturas, many=True, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='candidatar')
    @transaction.atomic
    def candidatar(self, request, pk=None):
        """Motorista pede para pegar a carga. A empresa decide depois."""
        user = request.user
        carga = self.get_object()

        if not hasattr(user, 'perfil_motorista'):
            return _erro('Somente motoristas podem se candidatar.', status.HTTP_403_FORBIDDEN)

        carga = _travar_carga(carga.pk)
        motorista = user.perfil_motorista

        if carga.status != 'disponivel':
            return _erro('Carga indisponível.')

        if _viagem_ativa(motorista):
            return _erro('Conclua ou cancele sua viagem atual antes de se candidatar.')

        if motorista.media_notas < carga.nota_minima_motorista:
            return _erro(
                f'Sua nota ({motorista.media_notas:.1f}) é menor que a mínima exigida '
                f'({carga.nota_minima_motorista:.1f}).',
                status.HTTP_403_FORBIDDEN)

        mensagem = request.data.get('mensagem', '')
        candidatura, criada = Candidatura.objects.get_or_create(
            carga=carga,
            caminhoneiro=motorista,
            defaults={'mensagem': mensagem},
        )
        if not criada:
            # Quem desistiu pode tentar de novo; recusa da empresa continua valendo.
            if candidatura.status != 'cancelada':
                return _erro('Você já se candidatou a esta carga.')
            candidatura.status = 'pendente'
            candidatura.mensagem = mensagem
            candidatura.save()

        return Response(
            {'mensagem': 'Candidatura enviada! Aguarde a empresa avaliar seu perfil.',
             'candidatura': CandidaturaSerializer(candidatura, context={'request': request}).data},
            status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'], url_path='candidaturas')
    def candidaturas(self, request, pk=None):
        """Empresa lista os motoristas candidatos a esta carga."""
        carga = self.get_object()
        if not hasattr(request.user, 'perfil_empresa') or carga.empresa != request.user.perfil_empresa:
            return _erro('Apenas a empresa dona da carga.', status.HTTP_403_FORBIDDEN)
        cands = carga.candidaturas.filter(status='pendente').select_related('caminhoneiro')
        return Response(CandidaturaSerializer(cands, many=True, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='finalizar')
    @transaction.atomic
    def finalizar(self, request, pk=None):
        """Empresa marca a carga como entregue/finalizada."""
        carga = self.get_object()
        if not hasattr(request.user, 'perfil_empresa') or carga.empresa != request.user.perfil_empresa:
            return _erro('Apenas a empresa dona da carga.', status.HTTP_403_FORBIDDEN)
        carga = _travar_carga(carga.pk)
        if carga.status != 'em_transito':
            return _erro('Só é possível finalizar uma carga em trânsito.')
        carga.status = 'finalizado'
        carga.data_entrega = timezone.now()
        carga.save()
        return Response({'mensagem': 'Carga finalizada! Agora você pode avaliar o motorista.'})


class CandidaturaViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = CandidaturaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'perfil_empresa'):
            qs = Candidatura.objects.filter(carga__empresa=user.perfil_empresa)
        elif hasattr(user, 'perfil_motorista'):
            qs = Candidatura.objects.filter(caminhoneiro=user.perfil_motorista)
        else:
            return Candidatura.objects.none()
        carga_id = self.request.query_params.get('carga')
        if carga_id:
            qs = qs.filter(carga_id=carga_id)
        return qs.select_related('carga', 'caminhoneiro')

    def _get_empresa_candidatura(self, request):
        """Candidatura da empresa logada, com carga e candidatura bloqueadas."""
        candidatura = self.get_object()
        if not hasattr(request.user, 'perfil_empresa') or \
                candidatura.carga.empresa != request.user.perfil_empresa:
            raise PermissionDenied('Apenas a empresa dona da carga.')
        carga = _travar_carga(candidatura.carga_id)
        return Candidatura.objects.select_for_update().get(pk=candidatura.pk), carga

    @action(detail=True, methods=['post'], url_path='aceitar')
    @transaction.atomic
    def aceitar(self, request, pk=None):
        """Empresa aceita este motorista para a carga, com base no perfil dele."""
        candidatura, carga = self._get_empresa_candidatura(request)

        if carga.status != 'disponivel':
            return _erro('Esta carga já não está disponível.')
        if candidatura.status != 'pendente':
            return _erro('Só é possível aceitar uma candidatura pendente.')

        motorista = Caminhoneiro.objects.select_for_update().get(pk=candidatura.caminhoneiro_id)
        if _viagem_ativa(motorista, exceto_carga_id=carga.pk):
            return _erro('Este motorista já está em outra viagem.')
        if motorista.media_notas < carga.nota_minima_motorista:
            return _erro('Este motorista não atinge a nota mínima da carga.')

        # Aloca o motorista escolhido; ele ainda precisa confirmar a carga.
        carga.motorista_alocado = motorista
        carga.consumo_veiculo_alocado = motorista.consumo_medio_km_l
        carga.status = 'aguardando_aceite'
        carga.save()

        candidatura.status = 'aceita'
        candidatura.save()

        # Recusa automaticamente as demais candidaturas pendentes
        carga.candidaturas.filter(status='pendente').exclude(pk=candidatura.pk).update(
            status='recusada', recusa_automatica=True)

        return Response({'mensagem': f'{motorista.nome_completo} foi aceito! '
                                     f'Aguardando a confirmação do motorista.'})

    @action(detail=True, methods=['post'], url_path='recusar')
    @transaction.atomic
    def recusar(self, request, pk=None):
        candidatura, _carga = self._get_empresa_candidatura(request)
        if candidatura.status != 'pendente':
            return _erro('Só é possível recusar uma candidatura pendente.')
        candidatura.status = 'recusada'
        candidatura.recusa_automatica = False
        candidatura.save()
        return Response({'mensagem': 'Candidatura recusada.'})
