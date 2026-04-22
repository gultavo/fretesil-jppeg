from django.db import models
from django.contrib.auth.models import User
from usuarios.models import Empresa, Caminhoneiro
from django.core.validators import MinValueValidator, MaxValueValidator

class Empresa(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='perfil_empresa')
    razao_social = models.CharField(max_length=255)
    cnpj = models.CharField(max_length=14, unique=True)
    endereco_sede = models.CharField(max_length=255, blank=True)
    # Média de notas para o ranking da Blacklist
    media_avaliacao = models.FloatField(default=0.0)

    def __str__(self):
        return self.razao_social

class Caminhoneiro(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='perfil_motorista')
    nome_completo = models.CharField(max_length=255)
    cpf = models.CharField(max_length=11, unique=True)
    placa_veiculo = models.CharField(max_length=7)
    
    # Diferencial: Níveis de Confiança
    pontuacao_experiencia = models.IntegerField(default=0)
    e_diamante = models.BooleanField(default=False)

    def __str__(self):
        return self.nome_completo