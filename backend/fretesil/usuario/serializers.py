from rest_framework import serializers
from .models import Empresa, Caminhoneiro

class EmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = ['id', 'user', 'razao_social', 'cnpj', 'media_avaliacao']
        read_only_fields = ['media_avaliacao'] # A média é calculada pelo sistema

    def validate_cnpj(self, value):
        if len(value) != 14:
            raise serializers.ValidationError("CNPJ deve ter 14 dígitos")
        return value

class CaminhoneiroSerializer(serializers.ModelSerializer):
    class Meta:
        model = Caminhoneiro
        fields = ['id', 'user', 'nome_completo', 'cpf', 'placa_veiculo', 'e_diamante']
        read_only_fields = ['e_diamante'] # Só o sistema/admin promove a Diamante

    def validate_cpf(self, value):
        if len(value) != 11:
            raise serializers.ValidationError("CPF deve ter 11 dígitos")
        return value