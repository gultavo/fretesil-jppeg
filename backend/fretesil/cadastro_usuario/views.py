from rest_framework import viewsets
from .models import Empresa, Caminhoneiro
from .serializers import (
    EmpresaSerializer, EmpresaReadSerializer,
    CaminhoneiroSerializer, CaminhoneiroReadSerializer,
)

class EmpresaViewSet(viewsets.ModelViewSet):
    queryset = Empresa.objects.all()

    def get_serializer_class(self):
        if self.action == 'create':
            return EmpresaSerializer       # POST → cria User + Empresa
        return EmpresaReadSerializer       # GET, PUT, PATCH, DELETE → leitura normal

class CaminhoneiroViewSet(viewsets.ModelViewSet):
    queryset = Caminhoneiro.objects.all()

    def get_serializer_class(self):
        if self.action == 'create':
            return CaminhoneiroSerializer  # POST → cria User + Caminhoneiro
        return CaminhoneiroReadSerializer  # GET, PUT, PATCH, DELETE → leitura normal