from rest_framework import viewsets, permissions
from .models import Avaliacao
from .serializers import AvaliacaoSerializer

class AvaliacaoViewSet(viewsets.ModelViewSet):
    queryset = Avaliacao.objects.all()
    serializer_class = AvaliacaoSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Permite ver todas as avaliações (útil para a comunidade ver a reputação das empresas)
        return Avaliacao.objects.all()

    def perform_create(self, serializer):
        # Salva a avaliação vinculando ao motorista que está logado
        if hasattr(self.request.user, 'perfil_motorista'):
            serializer.save(caminhoneiro=self.request.user.perfil_motorista)