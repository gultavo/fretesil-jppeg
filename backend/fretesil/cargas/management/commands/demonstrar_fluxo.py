from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from django.db import transaction
from django.test import override_settings
from rest_framework.test import APIClient

from cargas.models import Candidatura, Carga
from usuario.models import Caminhoneiro, Empresa


def brl(valor):
    texto = f'{valor:,.2f}'.replace(',', '_').replace('.', ',').replace('_', '.')
    return f'R$ {texto}'


class Desfazer(Exception):
    """Interrompe a transação para não deixar dados da demonstração no banco."""


class Command(BaseCommand):
    help = 'Demonstra pela API o fluxo completo de contratação, sem gravar dados.'

    def handle(self, *args, **options):
        try:
            with override_settings(ALLOWED_HOSTS=['testserver']), transaction.atomic():
                self._executar()
                raise Desfazer
        except Desfazer:
            self.stdout.write('\nDemonstração concluída. Nenhum dado foi mantido no banco.')

    def _post(self, perfil, url, dados=None):
        self.cliente.force_authenticate(user=perfil.user)
        return self.cliente.post(url, dados or {}, format='json')

    def _etapa(self, descricao, resposta, carga_id):
        estado = Carga.objects.get(pk=carga_id).status
        self.stdout.write(f'{descricao:<52} HTTP {resposta.status_code}  carga={estado}')

    def _perfil(self, sufixo, classe, **campos):
        user = User.objects.create_user(f'demo-{sufixo}@fretesil.invalid', password=None)
        return classe.objects.create(user=user, **campos)

    def _executar(self):
        self.cliente = APIClient()
        empresa = self._perfil('empresa', Empresa, razao_social='Empresa Demo', cnpj='00000000000191')
        ana = self._perfil('ana', Caminhoneiro, nome_completo='Motorista A', cpf='00000000191',
                           placa_veiculo='DEM0A01', consumo_medio_km_l=2.5)
        bia = self._perfil('bia', Caminhoneiro, nome_completo='Motorista B', cpf='00000000272',
                           placa_veiculo='DEM0B02', consumo_medio_km_l=3.0)

        self.stdout.write('=== FLUXO DE CONTRATAÇÃO ===')
        r = self._post(empresa, '/api/fretes/cargas/', {
            'titulo': 'Soja Curitiba-Santos', 'origem': 'Curitiba', 'destino': 'Santos',
            'distancia_km': 700, 'valor_bruto_frete': '5000.00',
            'estimativa_pedagio': '200.00', 'preco_combustivel': '6.00',
        })
        carga_id = r.data['id']
        self._etapa('1. Empresa publica a carga', r, carga_id)

        base = f'/api/fretes/cargas/{carga_id}'
        r = self._post(ana, f'{base}/candidatar/')
        cand_a = r.data['candidatura']['id']
        self._etapa('2. Motorista A se candidata', r, carga_id)
        r = self._post(bia, f'{base}/candidatar/')
        cand_b = r.data['candidatura']['id']
        self._etapa('3. Motorista B se candidata', r, carga_id)

        r = self._post(empresa, f'/api/fretes/candidaturas/{cand_a}/aceitar/')
        self._etapa('4. Empresa seleciona o motorista A', r, carga_id)
        estado_b = Candidatura.objects.get(pk=cand_b).status
        self.stdout.write(f'   Candidatura do motorista B ficou: {estado_b}')

        r = self._post(empresa, f'/api/fretes/candidaturas/{cand_b}/aceitar/')
        self._etapa('5. Bloqueio: selecionar também o motorista B', r, carga_id)
        r = self._post(ana, f'{base}/iniciar-viagem/')
        self._etapa('6. Bloqueio: iniciar viagem antes de confirmar', r, carga_id)

        r = self._post(ana, f'{base}/aceitar/')
        self._etapa('7. Motorista A confirma a carga', r, carga_id)
        r = self._post(ana, f'{base}/iniciar-viagem/')
        self._etapa('8. Motorista A acopla e inicia o transporte', r, carga_id)
        r = self._post(empresa, f'{base}/finalizar/')
        self._etapa('9. Empresa confirma a entrega', r, carga_id)
        r = self._post(empresa, f'{base}/finalizar/')
        self._etapa('10. Bloqueio: finalizar novamente', r, carga_id)

        carga = Carga.objects.get(pk=carga_id)
        f = carga.resumo_financeiro()
        self.stdout.write('\n=== EXEMPLO FINANCEIRO ===')
        self.stdout.write(f"Valor bruto:        {brl(f['valor_bruto'])}")
        self.stdout.write(f"Comissão (0,2%):  - {brl(f['comissao'])}")
        self.stdout.write(f"Pedágio:          - {brl(f['pedagio'])}")
        self.stdout.write(
            f"Combustível:      - {brl(f['combustivel'])} "
            f"({carga.distancia_km:.0f} km / {f['consumo_km_l']} km/l = {f['litros']} L "
            f"x {brl(f['preco_combustivel'])})")
        self.stdout.write(f"Total de despesas:  {brl(f['despesas'])}")
        self.stdout.write(f"Lucro estimado:     {brl(f['lucro_estimado'])}")
