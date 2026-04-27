from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from usuario.models import Empresa, Caminhoneiro

class Carga(models.Model):
    STATUS_CHOICES = [
        ('disponivel', 'Disponível'),
        ('em_transito', 'Em Trânsito'),
        ('finalizado', 'Finalizado'),
    ]

    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='cargas_postadas')
    titulo = models.CharField(max_length=100) # Ex: "Grãos de Soja - Curitiba p/ Santos"
    origem = models.CharField(max_length=255)
    destino = models.CharField(max_length=255)
    distancia_km = models.FloatField()
    
    # Valores para o cálculo de Lucro Líquido
    valor_bruto_frete = models.DecimalField(max_digits=10, decimal_places=2)
    estimativa_pedagio = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    comissao_app = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    
    data_publicacao = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='disponivel')
    motorista_alocado = models.ForeignKey(Caminhoneiro, on_delete=models.SET_NULL, null=True, blank=True)

    def __str__(self):
        return f"{self.titulo} - {self.empresa.razao_social}"