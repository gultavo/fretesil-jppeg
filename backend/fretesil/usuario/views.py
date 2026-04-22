from rest_framework import viewsets, permissions
from .models import Empresa, Caminhoneiro
from .serializers import EmpresaSerializer, CaminhoneiroSerializer

class EmpresaViewSet(viewsets.ModelViewSet):
    queryset = Empresa.objects.all()
    serializer_class = EmpresaSerializer
    permission_classes = [permissions.IsAuthenticated]

class CaminhoneiroViewSet(viewsets.ModelViewSet):
    queryset = Caminhoneiro.objects.all()
    serializer_class = CaminhoneiroSerializer
    permission_classes = [permissions.IsAuthenticated]