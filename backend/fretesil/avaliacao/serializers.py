from rest_framework import serializers
from .models import Avaliacao

class AvaliacaoSerializer(serializers.ModelSerializer):
    # Mostra o nome de quem avaliou e para quem, em vez de apenas o ID
    nome_caminhoneiro = serializers.ReadOnlyField(source='caminhoneiro.nome_completo')
    nome_empresa = serializers.ReadOnlyField(source='empresa.razao_social')

    class Meta:
        model = Avaliacao
        fields = [
            'id', 'caminhoneiro', 'nome_caminhoneiro', 'empresa', 
            'nome_empresa', 'nota', 'comentario', 
            'demora_carregamento', 'tem_banheiro'
        ]