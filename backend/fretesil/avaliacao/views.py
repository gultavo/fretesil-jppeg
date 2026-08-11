from rest_framework import viewsets, permissions, serializers
from rest_framework.exceptions import PermissionDenied, ValidationError
from .models import Avaliacao, AvaliacaoCaminhoneiro
from .serializers import AvaliacaoSerializer, AvaliacaoCaminhoneiroSerializer
from cargas.models import Carga


class AvaliacaoViewSet(viewsets.ModelViewSet):
    queryset = Avaliacao.objects.all()
    serializer_class = AvaliacaoSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = Avaliacao.objects.all()
        empresa_id = self.request.query_params.get('empresa')
        if empresa_id:
            qs = qs.filter(empresa_id=empresa_id)
        return qs

    def perform_create(self, serializer):
        # O motorista avalia a empresa, mas só depois da entrega concluída
        user = self.request.user
        if not hasattr(user, 'perfil_motorista'):
            raise PermissionDenied("Somente motoristas podem avaliar empresas.")

        motorista = user.perfil_motorista
        carga = serializer.validated_data.get('carga')
        empresa = serializer.validated_data.get('empresa')

        if carga is None:
            raise ValidationError({"carga": "Informe a carga entregue que está sendo avaliada."})

        if carga.motorista_alocado_id != motorista.id:
            raise PermissionDenied("Você não realizou esta entrega.")

        if carga.status != 'finalizado':
            raise ValidationError({"carga": "Só é possível avaliar após a entrega ser finalizada."})

        if empresa is not None and carga.empresa_id != empresa.id:
            raise ValidationError({"empresa": "Esta empresa não é a dona da carga."})

        if carga.empresa_avaliada:
            raise ValidationError({"carga": "Você já avaliou a empresa desta entrega."})

        # Garante que a empresa avaliada é sempre a dona da carga
        serializer.save(caminhoneiro=motorista, empresa=carga.empresa)
        carga.empresa_avaliada = True
        carga.save()


class AvaliacaoCaminhoneiroViewSet(viewsets.ModelViewSet):
    queryset = AvaliacaoCaminhoneiro.objects.all()
    serializer_class = AvaliacaoCaminhoneiroSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = AvaliacaoCaminhoneiro.objects.select_related('empresa', 'caminhoneiro')
        caminhoneiro_id = self.request.query_params.get('caminhoneiro')
        if caminhoneiro_id:
            qs = qs.filter(caminhoneiro_id=caminhoneiro_id)
        return qs

    def perform_create(self, serializer):
        # Aqui a empresa avalia o motorista, mas só depois da entrega concluída
        user = self.request.user
        if not hasattr(user, 'perfil_empresa'):
            raise PermissionDenied("Somente empresas podem avaliar motoristas.")

        empresa = user.perfil_empresa
        carga = serializer.validated_data.get('carga')
        caminhoneiro = serializer.validated_data.get('caminhoneiro')

        if carga is None:
            raise ValidationError({"carga": "Informe a carga entregue que está sendo avaliada."})

        if carga.empresa_id != empresa.id:
            raise PermissionDenied("Esta carga não pertence à sua empresa.")

        if carga.status != 'finalizado':
            raise ValidationError({"carga": "Só é possível avaliar após a entrega ser finalizada."})

        if carga.motorista_alocado_id != getattr(caminhoneiro, 'id', None):
            raise ValidationError({"caminhoneiro": "Este motorista não realizou esta entrega."})

        if carga.motorista_avaliado:
            raise ValidationError({"carga": "Você já avaliou o motorista desta entrega."})

        avaliacao = serializer.save(empresa=empresa)
        carga.motorista_avaliado = True
        carga.save()
        return avaliacao
