from django.db import models
from django.contrib.auth.models import User
from django.core.validators import MinValueValidator, MaxValueValidator

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

    class Meta:
        verbose_name_plural = "Avaliações"