from rest_framework import serializers
from .models import Carga, Candidatura


class CargaSerializer(serializers.ModelSerializer):
    lucro_estimado = serializers.SerializerMethodField()
    empresa_nome = serializers.CharField(source='empresa.razao_social', read_only=True)
    empresa_logo = serializers.ImageField(source='empresa.logo', read_only=True)
    motorista_nome = serializers.CharField(source='motorista_alocado.nome_completo', read_only=True)
    total_candidaturas = serializers.SerializerMethodField()

    class Meta:
        model = Carga
        fields = [
            'id', 'empresa', 'empresa_nome', 'empresa_logo', 'titulo', 'descricao',
            'origem', 'destino', 'distancia_km', 'foto_carga',
            'valor_bruto_frete', 'estimativa_pedagio', 'comissao_app',
            'status', 'motorista_alocado', 'motorista_nome', 'motorista_avaliado',
            'empresa_avaliada', 'nota_minima_motorista', 'consumo_veiculo_alocado',
            'lucro_estimado', 'data_publicacao', 'data_entrega', 'total_candidaturas',
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
