from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.exceptions import PermissionDenied
from .models import Carga
from .serializers import CargaSerializer

class CargaViewSet(viewsets.ModelViewSet):
    serializer_class = CargaSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if hasattr(user, 'perfil_empresa'):
            return Carga.objects.filter(empresa=user.perfil_empresa)
        if hasattr(user, 'perfil_motorista'):
            return Carga.objects.filter(status='disponivel')
        return Carga.objects.none()

    def perform_create(self, serializer):
        if not hasattr(self.request.user, 'perfil_empresa'):
            raise PermissionDenied('Somente empresas podem criar cargas.')
        serializer.save(empresa=self.request.user.perfil_empresa)

    @action(detail=False, methods=['get'], url_path='ativa')
    def ativa(self, request):
        if not hasattr(request.user, 'perfil_motorista'):
            return Response({'erro': 'Apenas motoristas.'}, status=403)
        carga = Carga.objects.filter(
            motorista_alocado=request.user.perfil_motorista,
            status='em_transito'
        ).first()
        if not carga:
            return Response(None, status=200)
        return Response(CargaSerializer(carga).data)

    @action(detail=True, methods=['post'], url_path='aceitar-carga')
    def aceitar_carga(self, request, pk=None):
        user = request.user
        carga = self.get_object()

        if not hasattr(user, 'perfil_motorista'):
            return Response({'erro': 'Somente motoristas podem aceitar cargas.'}, status=status.HTTP_403_FORBIDDEN)

        motorista = user.perfil_motorista

        if motorista.media_notas < carga.nota_minima_motorista:
            return Response({'erro': 'Você não tem nota suficiente.'}, status=status.HTTP_403_FORBIDDEN)

        if carga.status != 'disponivel':
            return Response({'erro': 'Carga indisponível.'}, status=status.HTTP_400_BAD_REQUEST)

        carga.motorista_alocado = motorista
        carga.consumo_veiculo_alocado = None
        carga.status = 'em_transito'
        carga.save()

        return Response({'mensagem': 'Carga aceita com sucesso!'})