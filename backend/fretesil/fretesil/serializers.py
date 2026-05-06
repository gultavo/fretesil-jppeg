# fretesil/serializers.py
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from usuario.models import Empresa, Caminhoneiro

class CustomTokenSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        user = self.user

        tem_empresa = Empresa.objects.filter(user=user).exists()
        tem_motorista = Caminhoneiro.objects.filter(user=user).exists()

        print('USER ID:', user.pk)
        print('TEM EMPRESA:', tem_empresa)
        print('TEM MOTORISTA:', tem_motorista)

        if tem_empresa:
            data['tipo_usuario'] = 'empresa'
        elif tem_motorista:
            data['tipo_usuario'] = 'freteiro'
        else:
            raise serializers.ValidationError(
                'Usuário sem perfil cadastrado. Contate o suporte.'
            )
        return data