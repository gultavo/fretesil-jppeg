from django.contrib import admin
from .models import Avaliacao, AvaliacaoCaminhoneiro

# Adiciona as tabelas ao Painel de Administração
admin.site.register(Avaliacao)
admin.site.register(AvaliacaoCaminhoneiro)
