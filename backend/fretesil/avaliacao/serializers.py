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
            'nome_empresa', 'nota', 'comentario', 
            'tempo_espera_carregamento', 'tem_banheiro_limpo', 
            'local_seguro', 'data_avaliacao'
        ]
        # O caminhoneiro é preenchido pelo ViewSet automaticamente
        read_only_fields = ['caminhoneiro']

# 2. Serializer para Empresa avaliar Motorista
class AvaliacaoCaminhoneiroSerializer(serializers.ModelSerializer):
    nome_empresa = serializers.ReadOnlyField(source='empresa.razao_social')
    nome_caminhoneiro = serializers.ReadOnlyField(source='caminhoneiro.nome_completo')

    class Meta:
        model = AvaliacaoCaminhoneiro
        fields = [
            'id', 'empresa', 'nome_empresa', 'caminhoneiro', 
            'nome_caminhoneiro', 'nota', 'comentario', 
            'entrega_no_prazo', 'cuidado_com_carga', 'data_avaliacao'
        ]
        # A empresa é preenchida pelo ViewSet automaticamente
        read_only_fields = ['empresa']
