from rest_framework import serializers
from .models import Carga

class CargaSerializer(serializers.ModelSerializer):
    # Campo calculado para o Flutter mostrar o lucro estimado
    lucro_estimado = serializers.SerializerMethodField()

    class Meta:
        model = Carga
        fields = [
            'id', 'empresa', 'titulo', 'origem', 'destino', 
            'distancia_km', 'valor_bruto_frete', 'estimativa_pedagio', 
            'status', 'motorista_alocado', 'lucro_estimado', 'nota_minima_motorista',
            'consumo_veiculo_alocado', 'lucro_estimado'
        ]
        read_only_fields = ['status', 'motorista_alocado']

    def get_lucro_estimado(self, obj):
        from decimal import Decimal
        preco_diesel = Decimal(6.0)
        consumo_medio = Decimal(str(obj.consumo_veiculo_alocado))
        distancia_km = Decimal(str(obj.distancia_km))
        gasto_diesel = (distancia_km / consumo_medio) * preco_diesel
        
        lucro = float(obj.valor_bruto_frete) - float(obj.estimativa_pedagio) - gasto_diesel
        return round(float(lucro), 2)