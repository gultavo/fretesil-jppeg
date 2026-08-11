from decimal import Decimal

from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from usuario.models import Empresa, Caminhoneiro

class Carga(models.Model):
    # Etapas da viagem, na ordem em que acontecem:
    # disponivel → (empresa aceita um candidato) → aguardando_aceite
    #            → (motorista confirma)          → acoplar_carreta
    #            → (motorista acopla e sai)      → em_transito
    #            → (empresa confirma a entrega)  → finalizado
    STATUS_CHOICES = [
        ('disponivel', 'Disponível'),
        ('aguardando_aceite', 'Aguardando aceite do motorista'),
        ('acoplar_carreta', 'Acoplar carreta'),
        ('em_transito', 'Em Trânsito'),
        ('finalizado', 'Concluída'),
    ]

    TIPO_CARRETA_CHOICES = [
        ('sider', 'Sider'),
        ('bau', 'Baú'),
        ('carga_seca', 'Carga seca'),
        ('graneleiro', 'Graneleiro'),
        ('tanque', 'Tanque'),
        ('camara_fria', 'Câmara fria'),
        ('cacamba', 'Caçamba'),
        ('prancha', 'Prancha'),
        ('porta_container', 'Porta-contêiner'),
        ('outro', 'Outro'),
    ]

    # Percentual que o app retém sobre o valor bruto do frete.
    TAXA_COMISSAO = Decimal('0.002')  # 0,2%

    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='cargas_postadas')
    titulo = models.CharField(max_length=100) # Ex: "Grãos de Soja - Curitiba p/ Santos"
    origem = models.CharField(max_length=255)
    destino = models.CharField(max_length=255)
    empresa_destino = models.CharField(
        max_length=255, blank=True,
        help_text="Empresa onde a carga será descarregada"
    )
    local_carreta = models.CharField(
        max_length=255, blank=True,
        help_text="Onde a carreta está para o motorista acoplar"
    )
    tipo_carreta = models.CharField(
        max_length=20, choices=TIPO_CARRETA_CHOICES, default='carga_seca'
    )
    distancia_km = models.FloatField()
    descricao = models.TextField(blank=True)

    # Foto da carga (mercadoria / veículo)
    foto_carga = models.ImageField(upload_to='cargas/fotos/', null=True, blank=True)

    nota_minima_motorista = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(5.0)]
    )

    consumo_veiculo_alocado = models.FloatField(null=True, blank=True) #km/l do motorista

    # Valores para o cálculo de Lucro Líquido
    valor_bruto_frete = models.DecimalField(max_digits=10, decimal_places=2)
    estimativa_pedagio = models.DecimalField(max_digits=10, decimal_places=2, default=0.0)
    comissao_app = models.DecimalField(max_digits=10, decimal_places=2, default=0.0, editable=False)

    data_publicacao = models.DateTimeField(auto_now_add=True)
    data_entrega = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='disponivel')
    motorista_alocado = models.ForeignKey(Caminhoneiro, on_delete=models.SET_NULL, null=True, blank=True)
    # Marca se a empresa já avaliou o motorista desta entrega
    motorista_avaliado = models.BooleanField(default=False)
    # Marca se o motorista já avaliou a empresa desta entrega
    empresa_avaliada = models.BooleanField(default=False)

    def save(self, *args, **kwargs):
        self.comissao_app = Decimal(str(self.valor_bruto_frete)) * self.TAXA_COMISSAO
        super(Carga, self).save(*args, **kwargs)

    def __str__(self):
        return f"{self.titulo} - {self.empresa.razao_social}"


class Candidatura(models.Model):
    """Pedido de um caminhoneiro para pegar uma carga.
    A empresa analisa o perfil do motorista e aceita ou recusa."""
    STATUS_CHOICES = [
        ('pendente', 'Pendente'),
        ('aceita', 'Aceita'),
        ('recusada', 'Recusada'),
        ('cancelada', 'Cancelada pelo motorista'),
    ]

    carga = models.ForeignKey(Carga, on_delete=models.CASCADE, related_name='candidaturas')
    caminhoneiro = models.ForeignKey(Caminhoneiro, on_delete=models.CASCADE, related_name='candidaturas')
    mensagem = models.TextField(blank=True, help_text="Mensagem opcional do motorista para a empresa")
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='pendente')
    data_candidatura = models.DateTimeField(auto_now_add=True)

    class Meta:
        # Um motorista só se candidata uma vez por carga
        unique_together = ('carga', 'caminhoneiro')
        ordering = ['-data_candidatura']

    def __str__(self):
        return f"{self.caminhoneiro.nome_completo} → {self.carga.titulo} ({self.status})"
