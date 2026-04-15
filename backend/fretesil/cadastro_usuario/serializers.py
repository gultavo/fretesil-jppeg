import re
from rest_framework import serializers
from .models import Empresa, Caminhoneiro

class EmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = '__all__'

    def validate_cnpj(self, cnpj):
        if len(cnpj) != 14:
            raise serializers.ValidationError("CNPJ deve ter 14 dígitos")
        return cnpj

class CaminhoneiroSerializer(serializers.ModelSerializer):
    class Meta:
        model = Caminhoneiro
        fields = '__all__'

    def validate_cpf(self, cpf):
        if len(cpf) != 11:
            raise serializers.ValidationError("CPF deve ter 11 dígitos")
        return cpf

    def validate_placa_veiculo(self, placa_veiculo):
        if len(placa_veiculo) != 7:
            raise serializers.ValidationError("Placa do veículo deve ter 7 caracteres")
        return placa_veiculo