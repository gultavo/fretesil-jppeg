from django.db.models import Q
from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from .models import Carga, Candidatura
from .serializers import CargaSerializer, CandidaturaSerializer


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
            return Carga.objects.filter(empresa=user.perfil_empresa)
        if hasattr(user, 'perfil_motorista'):
            # O motorista vê as cargas abertas e também as que são dele
            # (para aceitar, acoplar, cancelar e consultar depois).
            return Carga.objects.filter(
                Q(status='disponivel') | Q(motorista_alocado=user.perfil_motorista)
            )
        return Carga.objects.none()

    def _minha_carga(self, request):
        """Carga do motorista logado, garantindo que ela é mesmo dele."""
        if not hasattr(request.user, 'perfil_motorista'):
            raise PermissionDenied('Apenas motoristas.')
        carga = self.get_object()
        if carga.motorista_alocado != request.user.perfil_motorista:
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
            status__in=['aguardando_aceite', 'acoplar_carreta', 'em_transito'],
        ).first()
        if not carga:
            return Response(None, status=200)
        return Response(CargaSerializer(carga, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='aceitar')
    def aceitar(self, request, pk=None):
        """Motorista confirma a carga que a empresa aprovou para ele."""
        carga = self._minha_carga(request)
        if carga.status != 'aguardando_aceite':
            return Response({'erro': 'Esta carga não está aguardando o seu aceite.'},
                            status=status.HTTP_400_BAD_REQUEST)
        carga.status = 'acoplar_carreta'
        carga.save()
        return Response({
            'mensagem': 'Carga aceita! Vá buscar a carreta.',
            'carga': CargaSerializer(carga, context={'request': request}).data,
        })

    @action(detail=True, methods=['post'], url_path='iniciar-viagem')
    def iniciar_viagem(self, request, pk=None):
        """Motorista acoplou a carreta e saiu para a estrada."""
        carga = self._minha_carga(request)
        if carga.status != 'acoplar_carreta':
            return Response({'erro': 'A carreta precisa estar na etapa de acoplagem.'},
                            status=status.HTTP_400_BAD_REQUEST)
        carga.status = 'em_transito'
        carga.save()
        return Response({
            'mensagem': 'Boa viagem! Carga em trânsito.',
            'carga': CargaSerializer(carga, context={'request': request}).data,
        })

    @action(detail=True, methods=['post'], url_path='cancelar')
    def cancelar(self, request, pk=None):
        """Motorista desiste da viagem; a carga volta a ficar disponível."""
        carga = self._minha_carga(request)
        if carga.status not in ['aguardando_aceite', 'acoplar_carreta', 'em_transito']:
            return Response({'erro': 'Esta viagem não pode mais ser cancelada.'},
                            status=status.HTTP_400_BAD_REQUEST)

        motorista = request.user.perfil_motorista
        carga.candidaturas.filter(caminhoneiro=motorista).update(status='cancelada')
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
    def candidatar(self, request, pk=None):
        """Motorista pede para pegar a carga. A empresa decide depois."""
        user = request.user
        carga = self.get_object()

        if not hasattr(user, 'perfil_motorista'):
            return Response({'erro': 'Somente motoristas podem se candidatar.'},
                            status=status.HTTP_403_FORBIDDEN)

        motorista = user.perfil_motorista

        if carga.status != 'disponivel':
            return Response({'erro': 'Carga indisponível.'}, status=status.HTTP_400_BAD_REQUEST)

        if motorista.media_notas < carga.nota_minima_motorista:
            return Response(
                {'erro': f'Sua nota ({motorista.media_notas:.1f}) é menor que a mínima exigida '
                         f'({carga.nota_minima_motorista:.1f}).'},
                status=status.HTTP_403_FORBIDDEN)

        candidatura, criada = Candidatura.objects.get_or_create(
            carga=carga,
            caminhoneiro=motorista,
            defaults={'mensagem': request.data.get('mensagem', '')},
        )
        if not criada:
            return Response({'erro': 'Você já se candidatou a esta carga.'},
                            status=status.HTTP_400_BAD_REQUEST)

        return Response(
            {'mensagem': 'Candidatura enviada! Aguarde a empresa avaliar seu perfil.',
             'candidatura': CandidaturaSerializer(candidatura, context={'request': request}).data},
            status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'], url_path='candidaturas')
    def candidaturas(self, request, pk=None):
        """Empresa lista os motoristas candidatos a esta carga."""
        carga = self.get_object()
        if not hasattr(request.user, 'perfil_empresa') or carga.empresa != request.user.perfil_empresa:
            return Response({'erro': 'Apenas a empresa dona da carga.'},
                            status=status.HTTP_403_FORBIDDEN)
        cands = carga.candidaturas.filter(status='pendente').select_related('caminhoneiro')
        return Response(CandidaturaSerializer(cands, many=True, context={'request': request}).data)

    @action(detail=True, methods=['post'], url_path='finalizar')
    def finalizar(self, request, pk=None):
        """Empresa marca a carga como entregue/finalizada."""
        carga = self.get_object()
        if not hasattr(request.user, 'perfil_empresa') or carga.empresa != request.user.perfil_empresa:
            return Response({'erro': 'Apenas a empresa dona da carga.'},
                            status=status.HTTP_403_FORBIDDEN)
        if carga.status != 'em_transito':
            return Response({'erro': 'Só é possível finalizar uma carga em trânsito.'},
                            status=status.HTTP_400_BAD_REQUEST)
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

    def _get_empresa_candidatura(self, request, pk):
        candidatura = self.get_object()
        if not hasattr(request.user, 'perfil_empresa') or \
                candidatura.carga.empresa != request.user.perfil_empresa:
            raise PermissionDenied('Apenas a empresa dona da carga.')
        return candidatura

    @action(detail=True, methods=['post'], url_path='aceitar')
    def aceitar(self, request, pk=None):
        """Empresa aceita este motorista para a carga, com base no perfil dele."""
        candidatura = self._get_empresa_candidatura(request, pk)
        carga = candidatura.carga

        if carga.status != 'disponivel':
            return Response({'erro': 'Esta carga já não está disponível.'},
                            status=status.HTTP_400_BAD_REQUEST)

        # Aloca o motorista escolhido; ele ainda precisa confirmar a carga.
        carga.motorista_alocado = candidatura.caminhoneiro
        carga.status = 'aguardando_aceite'
        carga.save()

        candidatura.status = 'aceita'
        candidatura.save()

        # Recusa automaticamente as demais candidaturas pendentes
        carga.candidaturas.filter(status='pendente').exclude(pk=candidatura.pk).update(status='recusada')

        return Response({'mensagem': f'{candidatura.caminhoneiro.nome_completo} foi aceito! '
                                     f'Aguardando a confirmação do motorista.'})

    @action(detail=True, methods=['post'], url_path='recusar')
    def recusar(self, request, pk=None):
        candidatura = self._get_empresa_candidatura(request, pk)
        candidatura.status = 'recusada'
        candidatura.save()
        return Response({'mensagem': 'Candidatura recusada.'})
