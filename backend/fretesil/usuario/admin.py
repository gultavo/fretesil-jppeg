from django.contrib import admin
from .models import Empresa, Caminhoneiro
from avaliacao.models import Avaliacao, AvaliacaoCaminhoneiro

# 1. Configura as avaliações que a Empresa recebeu (Caminhoneiro -> Empresa)
class AvaliacaoEmpresaInline(admin.TabularInline):
    model = Avaliacao
    extra = 0
    # Bloqueia a edição de todos os campos
    readonly_fields = [
        'caminhoneiro', 'nota', 'comentario', 
        'tempo_espera_carregamento', 'tem_banheiro_limpo', 
        'local_seguro', 'data_avaliacao'
    ]
    can_delete = False
    
    # Remove a permissão de adicionar avaliações direto por aqui
    def has_add_permission(self, request, obj=None):
        return False

# 2. Configura as avaliações que o Caminhoneiro recebeu (Empresa -> Caminhoneiro)
class AvaliacaoRecebidaInline(admin.TabularInline):
    model = AvaliacaoCaminhoneiro
    extra = 0
    # Bloqueia a edição de todos os campos
    readonly_fields = [
        'empresa', 'nota', 'comentario', 
        'entrega_no_prazo', 'cuidado_com_carga', 'data_avaliacao'
    ]
    can_delete = False

    # Remove a permissão de adicionar avaliações direto por aqui
    def has_add_permission(self, request, obj=None):
        return False

# 3. Configura a página da Empresa no Admin
@admin.register(Empresa)
class EmpresaAdmin(admin.ModelAdmin):
    list_display = ('razao_social', 'cnpj', 'media_avaliacao')
    # Média é calculada pelo sistema, então fica em apenas leitura
    readonly_fields = ('media_avaliacao',)
    inlines = [AvaliacaoEmpresaInline]

# 4. Configura a página do Caminhoneiro no Admin
@admin.register(Caminhoneiro)
class CaminhoneiroAdmin(admin.ModelAdmin):
    # Usei apenas os campos que o Django confirmou que existem no seu model
    list_display = ('nome_completo', 'cpf', 'media_notas')
    readonly_fields = ('media_notas',)
    inlines = [AvaliacaoRecebidaInline]
