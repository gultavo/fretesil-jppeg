from rest_framework import serializers
from .models import Empresa, Caminhoneiro
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from avaliacao.models import AvaliacaoCaminhoneiro, Avaliacao
from cargas.models import Carga


class EmpresaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Empresa
        fields = [
            'id', 'user', 'razao_social', 'cnpj', 'endereco_sede',
            'descricao', 'telefone', 'logo', 'media_avaliacao', 'total_avaliacoes',
        ]
        read_only_fields = ['user', 'cnpj', 'media_avaliacao', 'total_avaliacoes']

    def to_representation(self, instance):
        dados = super().to_representation(instance)
        request = self.context.get('request')
        if request is None or request.user.pk != instance.user_id:
            dados.pop('user', None)
        return dados


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
    # Visíveis apenas para o próprio motorista.
    CAMPOS_DO_DONO = ('user', 'cpf', 'consumo_medio_km_l')
    # Visíveis também para a empresa com uma viagem em andamento com ele.
    CAMPOS_DE_CONTATO = ('telefone', 'placa_veiculo')

    class Meta:
        model = Caminhoneiro
        fields = [
            'id', 'user', 'nome_completo', 'cpf', 'placa_veiculo',
            'bio', 'cidade', 'telefone', 'tipo_veiculo', 'anos_experiencia',
            'consumo_medio_km_l', 'foto_perfil', 'media_notas',
            'total_avaliacoes', 'e_diamante',
        ]
        read_only_fields = ['user', 'cpf', 'media_notas', 'total_avaliacoes', 'e_diamante']

    def _motoristas_contratados(self, user):
        """IDs dos motoristas em viagem ativa com a empresa logada (uma consulta só)."""
        if 'motoristas_contratados' not in self.context:
            empresa = getattr(user, 'perfil_empresa', None)
            ids = set()
            if empresa is not None:
                ids = set(Carga.objects.filter(
                    empresa=empresa, status__in=Carga.ETAPAS_ATIVAS,
                ).values_list('motorista_alocado_id', flat=True))
            self.context['motoristas_contratados'] = ids
        return self.context['motoristas_contratados']

    def to_representation(self, instance):
        dados = super().to_representation(instance)
        request = self.context.get('request')
        user = getattr(request, 'user', None)
        if user is not None and user.pk == instance.user_id:
            return dados

        for campo in self.CAMPOS_DO_DONO:
            dados.pop(campo, None)
        if user is None or not user.is_authenticated \
                or instance.pk not in self._motoristas_contratados(user):
            for campo in self.CAMPOS_DE_CONTATO:
                dados.pop(campo, None)
        return dados


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
