from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator

class Empresa(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='perfil_empresa')
    razao_social = models.CharField(max_length=255)
    cnpj = models.CharField(max_length=14, unique=True)
    endereco_sede = models.CharField(max_length=255, blank=True)

    # Perfil público / apresentação
    descricao = models.TextField(blank=True, help_text="Sobre a empresa")
    telefone = models.CharField(max_length=20, blank=True)
    logo = models.ImageField(upload_to='empresas/logos/', null=True, blank=True)

    # Média de notas para o ranking da Blacklist
    nota_corte_padrao = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(5.0)]
    )

    media_avaliacao = models.FloatField(default=0.0, editable=False)
    total_avaliacoes = models.PositiveIntegerField(default=0, editable=False)

    def __str__(self):
        return self.razao_social

class Caminhoneiro(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='perfil_motorista')
    nome_completo = models.CharField(max_length=255)
    cpf = models.CharField(max_length=11, unique=True)
    placa_veiculo = models.CharField(max_length=7)

    # Perfil rico do caminhoneiro
    bio = models.TextField(blank=True, help_text="Apresentação / sobre você")
    cidade = models.CharField(max_length=120, blank=True)
    telefone = models.CharField(max_length=20, blank=True)
    tipo_veiculo = models.CharField(max_length=120, blank=True, help_text="Ex: Carreta baú, Bitrem, Truck")
    anos_experiencia = models.PositiveIntegerField(default=0)
    consumo_medio_km_l = models.FloatField(
        null=True, blank=True, validators=[MinValueValidator(0.1)],
        help_text="Consumo médio do veículo, em km/l"
    )
    foto_perfil = models.ImageField(upload_to='motoristas/fotos/', null=True, blank=True)

    media_notas = models.FloatField(default=0.0, editable=False)
    total_avaliacoes = models.PositiveIntegerField(default=0, editable=False)
    e_diamante = models.BooleanField(default=False)

    def __str__(self):
        return self.nome_completo
