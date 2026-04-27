from rest_framework import viewsets, permissions
from .models import Avaliacao, AvaliacaoCaminhoneiro
from .serializers import AvaliacaoSerializer, AvaliacaoCaminhoneiroSerializer


class AvaliacaoViewSet(viewsets.ModelViewSet):
    queryset = Avaliacao.objects.all()
    serializer_class = AvaliacaoSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        if hasattr(self.request.user, 'perfil_motorista'):
            serializer.save(caminhoneiro=self.request.user.perfil_motorista)
        else:
            raise serializers.ValidationError("Somente motoristas podem avaliar empresas.")

class AvaliacaoCaminhoneiroViewSet(viewsets.ModelViewSet):
    queryset = AvaliacaoCaminhoneiro.objects.all()
    serializer_class = AvaliacaoCaminhoneiroSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        # Aqui a empresa avalia o motorista
        if hasattr(self.request.user, 'perfil_empresa'):
            serializer.save(empresa=self.request.user.perfil_empresa)
        else:
            raise serializers.ValidationError({"erro": "Somente empresas podem avaliar motoristas."})
