from rest_framework import serializers
from .models import Carga

class CargaSerializer(serializers.ModelSerializer):
    # Campo calculado para o Flutter mostrar o lucro estimado
    lucro_estimado = serializers.SerializerMethodField()

    class Meta:
        model = Carga
        fields = [
            'id', 'empresa', 'titulo', 'origem', 'destino', 
            'distancia_km', 'valor_bruto', 'pedagio', 
            'status', 'motorista_alocado', 'lucro_estimado'
        ]
        read_only_fields = ['status', 'motorista_alocado']

    def get_lucro_estimado(self, obj):
        # Lógica simples de lucro: Bruto - Pedágio - (Diesel estimado)
        # Assumindo consumo médio de 2.5km/L e Diesel a R$ 6.00
        preco_diesel = 6.00
        consumo_medio = 2.5
        gasto_diesel = (obj.distancia_km / consumo_medio) * preco_diesel
        
        lucro = float(obj.valor_bruto) - float(obj.pedagio) - gasto_diesel
        return round(lucro, 2)