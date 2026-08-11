from rest_framework import serializers
from .models import Carga, Candidatura


class CargaSerializer(serializers.ModelSerializer):
    lucro_estimado = serializers.SerializerMethodField()
    empresa_nome = serializers.CharField(source='empresa.razao_social', read_only=True)
    empresa_logo = serializers.ImageField(source='empresa.logo', read_only=True)
    empresa_telefone = serializers.CharField(source='empresa.telefone', read_only=True)
    tipo_carreta_display = serializers.CharField(source='get_tipo_carreta_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    total_candidaturas = serializers.SerializerMethodField()

    # Dados do motorista alocado — a empresa vê tudo isso no detalhe da carga
    # em trânsito.
    motorista_nome = serializers.CharField(source='motorista_alocado.nome_completo', read_only=True)
    motorista_foto = serializers.ImageField(source='motorista_alocado.foto_perfil', read_only=True)
    motorista_telefone = serializers.CharField(source='motorista_alocado.telefone', read_only=True)
    motorista_cidade = serializers.CharField(source='motorista_alocado.cidade', read_only=True)
    motorista_placa = serializers.CharField(source='motorista_alocado.placa_veiculo', read_only=True)
    motorista_veiculo = serializers.CharField(source='motorista_alocado.tipo_veiculo', read_only=True)
    motorista_experiencia = serializers.IntegerField(source='motorista_alocado.anos_experiencia', read_only=True)
    motorista_media = serializers.FloatField(source='motorista_alocado.media_notas', read_only=True)
    motorista_total_avaliacoes = serializers.IntegerField(
        source='motorista_alocado.total_avaliacoes', read_only=True)
    motorista_diamante = serializers.BooleanField(source='motorista_alocado.e_diamante', read_only=True)

    class Meta:
        model = Carga
        fields = [
            'id', 'empresa', 'empresa_nome', 'empresa_logo', 'empresa_telefone',
            'titulo', 'descricao', 'origem', 'destino', 'empresa_destino',
            'local_carreta', 'tipo_carreta', 'tipo_carreta_display',
            'distancia_km', 'foto_carga',
            'valor_bruto_frete', 'estimativa_pedagio', 'comissao_app',
            'status', 'status_display', 'motorista_alocado', 'motorista_avaliado',
            'empresa_avaliada', 'nota_minima_motorista', 'consumo_veiculo_alocado',
            'lucro_estimado', 'data_publicacao', 'data_entrega', 'total_candidaturas',
            'motorista_nome', 'motorista_foto', 'motorista_telefone',
            'motorista_cidade', 'motorista_placa', 'motorista_veiculo',
            'motorista_experiencia', 'motorista_media',
            'motorista_total_avaliacoes', 'motorista_diamante',
        ]
        read_only_fields = [
            'empresa', 'comissao_app', 'status',
            'motorista_alocado', 'motorista_avaliado', 'empresa_avaliada',
            'data_publicacao', 'data_entrega', 'consumo_veiculo_alocado',
        ]

    def get_total_candidaturas(self, obj):
        return obj.candidaturas.filter(status='pendente').count()

    def get_lucro_estimado(self, obj):
        if not obj.consumo_veiculo_alocado:
            return None
        from decimal import Decimal
        preco_diesel = Decimal('6.0')
        consumo = Decimal(str(obj.consumo_veiculo_alocado))
        distancia = Decimal(str(obj.distancia_km))
        gasto_diesel = (distancia / consumo) * preco_diesel
        lucro = obj.valor_bruto_frete - obj.estimativa_pedagio - gasto_diesel
        return round(float(lucro), 2)


class CandidaturaSerializer(serializers.ModelSerializer):
    caminhoneiro_nome = serializers.ReadOnlyField(source='caminhoneiro.nome_completo')
    caminhoneiro_foto = serializers.ImageField(source='caminhoneiro.foto_perfil', read_only=True)
    caminhoneiro_media = serializers.ReadOnlyField(source='caminhoneiro.media_notas')
    caminhoneiro_total_avaliacoes = serializers.ReadOnlyField(source='caminhoneiro.total_avaliacoes')
    caminhoneiro_diamante = serializers.ReadOnlyField(source='caminhoneiro.e_diamante')
    caminhoneiro_cidade = serializers.ReadOnlyField(source='caminhoneiro.cidade')
    carga_titulo = serializers.ReadOnlyField(source='carga.titulo')

    class Meta:
        model = Candidatura
        fields = [
            'id', 'carga', 'carga_titulo', 'caminhoneiro', 'caminhoneiro_nome',
            'caminhoneiro_foto', 'caminhoneiro_media', 'caminhoneiro_total_avaliacoes',
            'caminhoneiro_diamante', 'caminhoneiro_cidade', 'mensagem', 'status',
            'data_candidatura',
        ]
        read_only_fields = ['caminhoneiro', 'status', 'data_candidatura']
