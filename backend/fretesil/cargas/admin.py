from django.contrib import admin
from .models import Carga, Candidatura


class CandidaturaInline(admin.TabularInline):
    model = Candidatura
    extra = 0
    readonly_fields = ('caminhoneiro', 'mensagem', 'data_candidatura')


@admin.register(Carga)
class CargaAdmin(admin.ModelAdmin):
    list_display = ('titulo', 'empresa', 'status', 'motorista_alocado', 'valor_bruto_frete')
    list_filter = ('status',)
    search_fields = ('titulo', 'origem', 'destino')
    inlines = [CandidaturaInline]


@admin.register(Candidatura)
class CandidaturaAdmin(admin.ModelAdmin):
    list_display = ('caminhoneiro', 'carga', 'status', 'data_candidatura')
    list_filter = ('status',)
