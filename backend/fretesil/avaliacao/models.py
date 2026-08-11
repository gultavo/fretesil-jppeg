from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator
from usuario.models import Caminhoneiro, Empresa

class Avaliacao(models.Model):
    # Quem avalia é o caminhoneiro, quem é avaliada é a empresa
    caminhoneiro = models.ForeignKey(Caminhoneiro, on_delete=models.CASCADE)
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE, related_name='feedbacks')
    # A avaliação nasce de uma entrega concluída
    carga = models.ForeignKey(
        'cargas.Carga', on_delete=models.SET_NULL, null=True, blank=True, related_name='avaliacoes_empresa'
    )

    nota = models.PositiveIntegerField(validators=[MinValueValidator(0), MaxValueValidator(5)])
    comentario = models.TextField(blank=True)

    # Diferenciais da Blacklist
    tempo_espera_carregamento = models.DurationField(null=True, blank=True, help_text="Quanto tempo demorou para carregar?")
    tem_banheiro_limpo = models.BooleanField(default=True)
    local_seguro = models.BooleanField(default=True)

    data_avaliacao = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)

        qs = Avaliacao.objects.filter(empresa=self.empresa)
        agg = qs.aggregate(media=models.Avg('nota'), total=models.Count('id'))
        self.empresa.media_avaliacao = round(agg['media'] or 0.0, 2)
        self.empresa.total_avaliacoes = agg['total'] or 0
        self.empresa.save()

    class Meta:
        ordering = ['-data_avaliacao']
        verbose_name_plural = "Avaliações"


class AvaliacaoCaminhoneiro(models.Model):
    empresa = models.ForeignKey(Empresa, on_delete=models.CASCADE)
    caminhoneiro = models.ForeignKey(Caminhoneiro, on_delete=models.CASCADE, related_name='notas_recebidas')
    # A avaliação nasce de uma entrega concluída
    carga = models.ForeignKey(
        'cargas.Carga', on_delete=models.SET_NULL, null=True, blank=True, related_name='avaliacoes_motorista'
    )

    nota = models.PositiveIntegerField(validators=[MinValueValidator(0), MaxValueValidator(5)])
    comentario = models.TextField(blank=True)

    # Critérios específicos para o motorista
    entrega_no_prazo = models.BooleanField(default=True)
    cuidado_com_carga = models.BooleanField(default=True)

    data_avaliacao = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        qs = AvaliacaoCaminhoneiro.objects.filter(caminhoneiro=self.caminhoneiro)
        agg = qs.aggregate(media=models.Avg('nota'), total=models.Count('id'))
        self.caminhoneiro.media_notas = round(agg['media'] or 0.0, 2)
        self.caminhoneiro.total_avaliacoes = agg['total'] or 0
        # "Diamante" = motorista bem avaliado e experiente
        self.caminhoneiro.e_diamante = (
            (agg['total'] or 0) >= 5 and (agg['media'] or 0.0) >= 4.5
        )
        self.caminhoneiro.save()

    class Meta:
        ordering = ['-data_avaliacao']
        verbose_name_plural = "Avaliações de Motoristas"
