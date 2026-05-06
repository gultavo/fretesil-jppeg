from rest_framework import serializers
from .models import Empresa, Caminhoneiro    
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

class EmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = ['id', 'user', 'razao_social', 'cnpj', 'media_avaliacao']
        read_only_fields = ['media_avaliacao']

    def validate_cnpj(self, value):
        if len(value) != 14:
            raise serializers.ValidationError("CNPJ deve ter 14 dígitos")
        return value

class CaminhoneiroSerializer(serializers.ModelSerializer):
    class Meta:
        model = Caminhoneiro
        fields = ['id', 'user', 'nome_completo', 'cpf', 'placa_veiculo', 'e_diamante']
        read_only_fields = ['e_diamante']

    def validate_cpf(self, value):
        if len(value) != 11:
            raise serializers.ValidationError("CPF deve ter 11 dígitos")
        return value

class CustomTokenSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        user = self.user

        if hasattr(user, 'perfil_empresa'):
            data['tipo_usuario'] = 'empresa'
        elif hasattr(user, 'perfil_motorista'):
            data['tipo_usuario'] = 'freteiro'
        else:
            raise serializers.ValidationError(
                'Usuário sem perfil cadastrado. Contate o suporte.'
            )
        return data