from rest_framework import viewsets
from .models import Empresa, Caminhoneiro
from .serializers import EmpresaSerializer, CaminhoneiroSerializer

class EmpresaViewSet(viewsets.ModelViewSet):
    queryset = Empresa.objects.all()
    serializer_class = EmpresaSerializer

class CaminhoneiroViewSet(viewsets.ModelViewSet):
    queryset = Caminhoneiro.objects.all() #queryset é a consulta ao banco de dados, pega todos os registros
    serializer_class = CaminhoneiroSerializer
