from rest_framework import serializers
from .models import Carga

class CargaSerializer(serializers.ModelSerializer):
    lucro_estimado = serializers.SerializerMethodField()
    empresa_nome = serializers.CharField(source='empresa.razao_social', read_only=True)

    class Meta:
        model = Carga
        fields = [
            'id', 'empresa', 'empresa_nome', 'titulo', 'origem', 'destino',
            'distancia_km', 'valor_bruto_frete', 'estimativa_pedagio',
            'status', 'motorista_alocado', 'nota_minima_motorista',
            'consumo_veiculo_alocado', 'lucro_estimado',
        ]
        read_only_fields = [
            'empresa', 'comissao_app', 'status',
            'motorista_alocado', 'data_publicacao', 'consumo_veiculo_alocado',
        ]

    def get_lucro_estimado(self, obj):
        if not obj.consumo_veiculo_alocado:
            return None
        from decimal import Decimal
        preco_diesel = Decimal('6.0')
        consumo = Decimal(str(obj.consumo_veiculo_alocado))
        distancia = Decimal(str(obj.distancia_km))
        gasto_diesel = (distancia / consumo) * preco_diesel
        lucro = obj.valor_bruto_frete - obj.estimativa_pedagio - gasto_diesel
        return round(float(lucro), 2)