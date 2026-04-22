from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Carga
from .serializers import CargaSerializer

class CargaViewSet(viewsets.ModelViewSet):
    serializer_class = CargaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        
        # Empresa vê as cargas que ELA criou
        if hasattr(user, 'perfil_empresa'):
            return Carga.objects.filter(empresa=user.perfil_empresa)
        
        # Caminhoneiro vê apenas as disponíveis para pegar
        if hasattr(user, 'perfil_motorista'):
            return Carga.objects.filter(status='disponivel')
            
        return Carga.objects.none()

    def perform_create(self, serializer):
        # Vincula automaticamente a carga à empresa logada no momento da criação
        serializer.save(empresa=self.request.user.perfil_empresa)

    @action(detail=True, methods=['post'], url_path='aceitar-carga')
    def aceitar_carga(self, request, pk=None):
        """ Rota para o motorista clicar no botão 'Pegar Carga' no Flutter """
        carga = self.get_object()
        user = request.user

        if not hasattr(user, 'perfil_motorista'):
            return Response({'erro': 'Somente motoristas podem aceitar cargas.'}, status=status.HTTP_403_FORBIDDEN)

        if carga.status != 'disponivel':
            return Response({'erro': 'Esta carga já foi coletada ou está indisponível.'}, status=status.HTTP_400_BAD_REQUEST)

        # Atualiza o status e vincula o motorista
        carga.motorista_alocado = user.perfil_motorista
        carga.status = 'em_transito'
        carga.save()

        return Response({'mensagem': 'Carga aceita com sucesso! Verifique os detalhes na aba "Minhas Viagens".'})