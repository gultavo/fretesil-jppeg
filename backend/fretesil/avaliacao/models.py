from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from usuario.models import Caminhoneiro, Empresa

class Avaliacao(models.Model):
    # Quem avalia é o caminhoneiro, quem é avaliada é a empresa
    caminhoneiro = models.ForeignKey(Caminhoneiro, on_delete=models.CASCADE)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='feedbacks')
    
    nota = models.PositiveIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comentario = models.TextField()
    
    # Diferenciais da Blacklist
    tempo_espera_carregamento = models.DurationField(help_text="Quanto tempo demorou para carregar?")
    tem_banheiro_limpo = models.BooleanField(default=True)
    local_seguro = models.BooleanField(default=True)
    
    data_avaliacao = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)

        media = Avaliacao.objects.filter(empresa=self.empresa).aggregate(models.Avg('nota'))['nota__avg']
        self.empresa.media_avaliacao = media or 0.0
        self.empresa.save()

    class Meta:
        verbose_name_plural = "Avaliações"

class AvaliacaoCaminhoneiro(models.Model):
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE)
    caminhoneiro = models.ForeignKey(Caminhoneiro, on_delete=models.CASCADE, related_name='notas_recebidas')
    
    nota = models.PositiveIntegerField(validators=[MinValueValidator(1), MaxValueValidator(5)])
    comentario = models.TextField()
    
    # Critérios específicos para o motorista
    entrega_no_prazo = models.BooleanField(default=True)
    cuidado_com_carga = models.BooleanField(default=True)
    
    data_avaliacao = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        media = AvaliacaoCaminhoneiro.objects.filter(caminhoneiro=self.caminhoneiro).aggregate(models.Avg('nota'))['nota__avg']
        self.caminhoneiro.media_notas = media or 0.0
        self.caminhoneiro.save()

    class Meta:
        verbose_name_plural = "Avaliações de Motoristas"