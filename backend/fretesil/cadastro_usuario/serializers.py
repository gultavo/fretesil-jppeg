# serializers.py
from django.contrib.auth.models import User
from rest_framework import serializers
from .models import Empresa, Caminhoneiro

class EmpresaSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(write_only=True)
    senha = serializers.CharField(write_only=True)

    class Meta:
        model = Empresa
        fields = ['razao_social', 'cnpj', 'email', 'senha']

    def validate_cnpj(self, cnpj):
        if len(cnpj) != 14:
            raise serializers.ValidationError("CNPJ deve ter 14 dígitos")
        return cnpj

    def create(self, validated_data):
        email = validated_data.pop('email')
        senha = validated_data.pop('senha')

        if User.objects.filter(username=email).exists():
            raise serializers.ValidationError("E-mail já cadastrado")

        user = User.objects.create_user(username=email, email=email, password=senha)
        empresa = Empresa.objects.create(user=user, **validated_data)
        return empresa


class CaminhoneiroSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(write_only=True)
    senha = serializers.CharField(write_only=True)

    class Meta:
        model = Caminhoneiro
        fields = ['nome_completo', 'cpf', 'placa_veiculo', 'email', 'senha']

    def validate_cpf(self, cpf):
        if len(cpf) != 11:
            raise serializers.ValidationError("CPF deve ter 11 dígitos")
        return cpf

    def validate_placa_veiculo(self, placa):
        if len(placa) != 7:
            raise serializers.ValidationError("Placa deve ter 7 caracteres")
        return placa

    def create(self, validated_data):
        email = validated_data.pop('email')
        senha = validated_data.pop('senha')

        if User.objects.filter(username=email).exists():
            raise serializers.ValidationError("E-mail já cadastrado")

        user = User.objects.create_user(username=email, email=email, password=senha)
        caminhoneiro = Caminhoneiro.objects.create(user=user, **validated_data)
        return caminhoneiro

class EmpresaReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = '__all__'

class CaminhoneiroReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = Caminhoneiro
        fields = '__all__'