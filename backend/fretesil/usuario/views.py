from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from .models import Empresa, Caminhoneiro
from .serializers import (
    EmpresaSerializer,
    EmpresaPerfilSerializer,
    CaminhoneiroSerializer,
    CaminhoneiroPerfilSerializer,
)


# Somente leitura + ação `me` para o próprio usuário editar o seu perfil.
# Ninguém consegue alterar/apagar o perfil de terceiros por aqui.
class EmpresaViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Empresa.objects.all()
    serializer_class = EmpresaSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_serializer_class(self):
        # Perfil público (retrieve) mostra também as avaliações recebidas
        if self.action in ('retrieve', 'me'):
            return EmpresaPerfilSerializer
        return EmpresaSerializer

    @action(detail=False, methods=['get', 'patch'], url_path='me')
    def me(self, request):
        empresa = getattr(request.user, 'perfil_empresa', None)
        if empresa is None:
            return Response({'erro': 'Usuário não é uma empresa.'}, status=status.HTTP_403_FORBIDDEN)

        if request.method.lower() == 'patch':
            serializer = self.get_serializer(empresa, data=request.data, partial=True)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)

        return Response(self.get_serializer(empresa).data)


class CaminhoneiroViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Caminhoneiro.objects.all()
    serializer_class = CaminhoneiroSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser, JSONParser]

    def get_serializer_class(self):
        # Perfil público (retrieve) mostra também as avaliações recebidas
        if self.action in ('retrieve', 'me'):
            return CaminhoneiroPerfilSerializer
        return CaminhoneiroSerializer

    @action(detail=False, methods=['get', 'patch'], url_path='me')
    def me(self, request):
        motorista = getattr(request.user, 'perfil_motorista', None)
        if motorista is None:
            return Response({'erro': 'Usuário não é um motorista.'}, status=status.HTTP_403_FORBIDDEN)

        if request.method.lower() == 'patch':
            serializer = CaminhoneiroSerializer(
                motorista, data=request.data, partial=True, context={'request': request}
            )
            serializer.is_valid(raise_exception=True)
            serializer.save()

        return Response(
            CaminhoneiroPerfilSerializer(motorista, context={'request': request}).data
        )
