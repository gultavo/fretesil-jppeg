from rest_framework import serializers
from .models import Avaliacao, AvaliacaoCaminhoneiro

# 1. Serializer para Motorista avaliar Empresa
class AvaliacaoSerializer(serializers.ModelSerializer):
    nome_caminhoneiro = serializers.ReadOnlyField(source='caminhoneiro.nome_completo')
    nome_empresa = serializers.ReadOnlyField(source='empresa.razao_social')

    class Meta:
        model = Avaliacao
        fields = [
            'id', 'caminhoneiro', 'nome_caminhoneiro', 'empresa',
            'nome_empresa', 'carga', 'nota', 'comentario',
            'tempo_espera_carregamento', 'tem_banheiro_limpo',
            'local_seguro', 'data_avaliacao'
        ]
        # caminhoneiro e empresa são preenchidos pelo ViewSet (empresa = dona da carga)
        read_only_fields = ['caminhoneiro', 'empresa']

    def validate_nota(self, value):
        if value < 0 or value > 5:
            raise serializers.ValidationError("A nota deve ser entre 0 e 5 estrelas.")
        return value

# 2. Serializer para Empresa avaliar Motorista
class AvaliacaoCaminhoneiroSerializer(serializers.ModelSerializer):
    nome_empresa = serializers.ReadOnlyField(source='empresa.razao_social')
    nome_caminhoneiro = serializers.ReadOnlyField(source='caminhoneiro.nome_completo')

    class Meta:
        model = AvaliacaoCaminhoneiro
        fields = [
            'id', 'empresa', 'nome_empresa', 'caminhoneiro',
            'nome_caminhoneiro', 'carga', 'nota', 'comentario',
            'entrega_no_prazo', 'cuidado_com_carga', 'data_avaliacao'
        ]
        # A empresa é preenchida pelo ViewSet automaticamente
        read_only_fields = ['empresa']

    def validate_nota(self, value):
        if value < 0 or value > 5:
            raise serializers.ValidationError("A nota deve ser entre 0 e 5 estrelas.")
        return value
