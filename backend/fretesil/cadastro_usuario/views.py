from rest_framework import viewsets, status
from rest_framework.response import Response
from .models import Empresa, Caminhoneiro
from usuario.models import Empresa, Caminhoneiro
from .serializers import (
    EmpresaSerializer, EmpresaReadSerializer,
    CaminhoneiroSerializer, CaminhoneiroReadSerializer,
)

class EmpresaViewSet(viewsets.ModelViewSet):
    queryset = Empresa.objects.all()

    def get_serializer_class(self):
        if self.action == 'create':
            return EmpresaSerializer
        return EmpresaReadSerializer

    def create(self, request, *args, **kwargs):
        serializer = EmpresaSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        empresa = serializer.save()
        read = EmpresaReadSerializer(empresa)
        return Response(read.data, status=status.HTTP_201_CREATED)


class CaminhoneiroViewSet(viewsets.ModelViewSet):
    queryset = Caminhoneiro.objects.all()

    def get_serializer_class(self):
        if self.action == 'create':
            return CaminhoneiroSerializer
        return CaminhoneiroReadSerializer

    def create(self, request, *args, **kwargs):
        serializer = CaminhoneiroSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        caminhoneiro = serializer.save()
        read = CaminhoneiroReadSerializer(caminhoneiro)
        return Response(read.data, status=status.HTTP_201_CREATED)