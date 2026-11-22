from decimal import Decimal, ROUND_HALF_UP

from django.conf import settings
from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from usuario.models import Empresa, Caminhoneiro


def preco_combustivel_padrao():
    return settings.PRECO_COMBUSTIVEL_PADRAO


def _centavos(valor):
    return Decimal(valor).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)


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

    # Etapas em que a carga ocupa o motorista alocado.
    ETAPAS_ATIVAS = ('aguardando_aceite', 'acoplar_carreta', 'em_transito')

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
    preco_combustivel = models.DecimalField(
        max_digits=6, decimal_places=2, default=preco_combustivel_padrao,
        validators=[MinValueValidator(Decimal('0.01'))],
        help_text="Preço do litro de combustível usado na estimativa"
    )

    data_publicacao = models.DateTimeField(auto_now_add=True)
    data_entrega = models.DateTimeField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='disponivel')
    motorista_alocado = models.ForeignKey(Caminhoneiro, on_delete=models.SET_NULL, null=True, blank=True)
    # Marca se a empresa já avaliou o motorista desta entrega
    motorista_avaliado = models.BooleanField(default=False)
    # Marca se o motorista já avaliou a empresa desta entrega
    empresa_avaliada = models.BooleanField(default=False)

    def save(self, *args, **kwargs):
        self.comissao_app = _centavos(Decimal(str(self.valor_bruto_frete)) * self.TAXA_COMISSAO)
        super(Carga, self).save(*args, **kwargs)

    def resumo_financeiro(self, consumo_km_l=None):
        """Lucro = valor bruto - comissão - pedágio - combustível."""
        consumo = consumo_km_l or self.consumo_veiculo_alocado
        if not consumo:
            return None

        bruto = _centavos(Decimal(str(self.valor_bruto_frete)))
        pedagio = _centavos(Decimal(str(self.estimativa_pedagio)))
        preco = _centavos(Decimal(str(self.preco_combustivel)))
        comissao = _centavos(bruto * self.TAXA_COMISSAO)
        litros = Decimal(str(self.distancia_km)) / Decimal(str(consumo))
        combustivel = _centavos(litros * preco)
        despesas = comissao + pedagio + combustivel

        return {
            'valor_bruto': bruto,
            'comissao': comissao,
            'pedagio': pedagio,
            'consumo_km_l': float(consumo),
            'litros': _centavos(litros),
            'preco_combustivel': preco,
            'combustivel': combustivel,
            'despesas': despesas,
            'lucro_estimado': bruto - despesas,
        }

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
    # Recusada só porque outro motorista foi escolhido: volta a valer se ele desistir.
    recusa_automatica = models.BooleanField(default=False)
    data_candidatura = models.DateTimeField(auto_now_add=True)

    class Meta:
        # Um motorista só se candidata uma vez por carga
        unique_together = ('carga', 'caminhoneiro')
        ordering = ['-data_candidatura']

    def __str__(self):
        return f"{self.caminhoneiro.nome_completo} → {self.carga.titulo} ({self.status})"
