from rest_framework import serializers
from .models import Empresa, Caminhoneiro
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from avaliacao.models import AvaliacaoCaminhoneiro, Avaliacao


class EmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = [
            'id', 'user', 'razao_social', 'cnpj', 'endereco_sede',
            'descricao', 'telefone', 'logo', 'media_avaliacao', 'total_avaliacoes',
        ]
        read_only_fields = ['user', 'media_avaliacao', 'total_avaliacoes']

    def validate_cnpj(self, value):
        if len(value) != 14:
            raise serializers.ValidationError("CNPJ deve ter 14 dígitos")
        return value


class AvaliacaoEmpresaRecebidaSerializer(serializers.ModelSerializer):
    """Avaliação exibida no perfil público da empresa (feita por motoristas)."""
    nome_caminhoneiro = serializers.ReadOnlyField(source='caminhoneiro.nome_completo')
    foto_caminhoneiro = serializers.ImageField(source='caminhoneiro.foto_perfil', read_only=True)

    class Meta:
        model = Avaliacao
        fields = [
            'id', 'nome_caminhoneiro', 'foto_caminhoneiro', 'nota', 'comentario',
            'tem_banheiro_limpo', 'local_seguro', 'data_avaliacao',
        ]


class EmpresaPerfilSerializer(EmpresaSerializer):
    """Perfil público da empresa, com as avaliações recebidas dos motoristas."""
    avaliacoes = AvaliacaoEmpresaRecebidaSerializer(source='feedbacks', many=True, read_only=True)

    class Meta(EmpresaSerializer.Meta):
        fields = EmpresaSerializer.Meta.fields + ['avaliacoes']


class CaminhoneiroSerializer(serializers.ModelSerializer):
    class Meta:
        model = Caminhoneiro
        fields = [
            'id', 'user', 'nome_completo', 'cpf', 'placa_veiculo',
            'bio', 'cidade', 'telefone', 'tipo_veiculo', 'anos_experiencia',
            'foto_perfil', 'media_notas', 'total_avaliacoes', 'e_diamante',
        ]
        read_only_fields = ['user', 'media_notas', 'total_avaliacoes', 'e_diamante']

    def validate_cpf(self, value):
        if len(value) != 11:
            raise serializers.ValidationError("CPF deve ter 11 dígitos")
        return value


class AvaliacaoRecebidaSerializer(serializers.ModelSerializer):
    """Avaliação exibida no perfil público do motorista."""
    nome_empresa = serializers.ReadOnlyField(source='empresa.razao_social')
    logo_empresa = serializers.ImageField(source='empresa.logo', read_only=True)

    class Meta:
        model = AvaliacaoCaminhoneiro
        fields = [
            'id', 'nome_empresa', 'logo_empresa', 'nota', 'comentario',
            'entrega_no_prazo', 'cuidado_com_carga', 'data_avaliacao',
        ]


class CaminhoneiroPerfilSerializer(CaminhoneiroSerializer):
    """Perfil público do caminhoneiro, com as avaliações recebidas."""
    avaliacoes = AvaliacaoRecebidaSerializer(source='notas_recebidas', many=True, read_only=True)

    class Meta(CaminhoneiroSerializer.Meta):
        fields = CaminhoneiroSerializer.Meta.fields + ['avaliacoes']


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
