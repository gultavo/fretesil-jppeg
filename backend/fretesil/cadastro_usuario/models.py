from django.db import models
from django.contrib.auth.models import User

# Modelo para os dados de Empresa
class Empresa(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    razao_social = models.CharField(max_length=255)
    cnpj = models.CharField(max_length=14, unique=True)

    def __str__(self):
        return self.razao_social

# Modelo para os dados de Caminhoneiro
class Caminhoneiro(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    nome_completo = models.CharField(max_length=255)
    cpf = models.CharField(max_length=11, unique=True)
    placa_veiculo = models.CharField(max_length=7)

    def __str__(self):
        return self.nome_completo

