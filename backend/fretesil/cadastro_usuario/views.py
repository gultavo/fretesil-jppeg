from rest_framework import mixins, viewsets, status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from usuario.models import Empresa, Caminhoneiro
from .serializers import (
    EmpresaSerializer, EmpresaReadSerializer,
    CaminhoneiroSerializer, CaminhoneiroReadSerializer,
)


# Estes endpoints existem SOMENTE para o cadastro público (POST).
# Listar/editar/apagar perfis é feito nas rotas autenticadas de `usuario`.
class EmpresaViewSet(mixins.CreateModelMixin, viewsets.GenericViewSet):
    queryset = Empresa.objects.all()
    serializer_class = EmpresaSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = EmpresaSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        empresa = serializer.save()
        read = EmpresaReadSerializer(empresa)
        return Response(read.data, status=status.HTTP_201_CREATED)


class CaminhoneiroViewSet(mixins.CreateModelMixin, viewsets.GenericViewSet):
    queryset = Caminhoneiro.objects.all()
    serializer_class = CaminhoneiroSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = CaminhoneiroSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        caminhoneiro = serializer.save()
        read = CaminhoneiroReadSerializer(caminhoneiro)
        return Response(read.data, status=status.HTTP_201_CREATED)
