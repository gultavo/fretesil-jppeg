"""Testes das melhorias: privacidade, cálculo financeiro e processo de contratação."""
import threading
from decimal import Decimal

from django.contrib.auth.models import User
from django.db import connection
from django.test import TransactionTestCase, override_settings, skipUnlessDBFeature
from rest_framework.test import APIClient, APITestCase

from avaliacao.models import AvaliacaoCaminhoneiro
from cargas.models import Candidatura, Carga
from usuario.models import Caminhoneiro, Empresa


def criar_empresa(n):
    user = User.objects.create_user(f'empresa{n}@x.com', password='pass12345')
    return Empresa.objects.create(
        user=user, razao_social=f'Empresa {n}', cnpj=f'{n:014d}', telefone='4133334444')


def criar_motorista(n, **extra):
    user = User.objects.create_user(f'motorista{n}@x.com', password='pass12345')
    return Caminhoneiro.objects.create(
        user=user, nome_completo=f'Motorista {n}', cpf=f'{n:011d}',
        placa_veiculo=f'ABC{n:04d}', telefone='41999990000', **extra)


def criar_carga(empresa, **extra):
    dados = {
        'titulo': 'Soja', 'origem': 'Curitiba', 'destino': 'Santos',
        'distancia_km': 700, 'valor_bruto_frete': Decimal('5000.00'),
        'estimativa_pedagio': Decimal('200.00'),
    }
    dados.update(extra)
    return Carga.objects.create(empresa=empresa, **dados)


class Base(APITestCase):
    def setUp(self):
        self.empresa = criar_empresa(1)
        self.outra_empresa = criar_empresa(2)
        self.m1 = criar_motorista(1, consumo_medio_km_l=2.5)
        self.m2 = criar_motorista(2, consumo_medio_km_l=3.5)

    def como(self, perfil):
        self.client.force_authenticate(user=perfil.user)

    def candidatar(self, motorista, carga):
        self.como(motorista)
        r = self.client.post(f'/api/fretes/cargas/{carga.id}/candidatar/')
        self.assertEqual(r.status_code, 201, r.content)
        return Candidatura.objects.get(pk=r.data['candidatura']['id'])

    def aceitar(self, candidatura, empresa=None):
        self.como(empresa or self.empresa)
        return self.client.post(f'/api/fretes/candidaturas/{candidatura.id}/aceitar/')


class PrivacidadeTests(Base):
    def test_outro_motorista_nao_ve_dados_pessoais(self):
        self.como(self.m2)
        for url in (f'/api/usuario/motoristas/{self.m1.id}/', '/api/usuario/motoristas/'):
            r = self.client.get(url)
            perfil = r.data if isinstance(r.data, dict) else \
                next(p for p in r.data if p['id'] == self.m1.id)
            for campo in ('cpf', 'telefone', 'placa_veiculo', 'user', 'consumo_medio_km_l'):
                self.assertNotIn(campo, perfil)
            self.assertEqual(perfil['nome_completo'], 'Motorista 1')

    def test_motorista_ve_os_proprios_dados(self):
        self.como(self.m1)
        r = self.client.get('/api/usuario/motoristas/me/')
        self.assertEqual(r.data['cpf'], self.m1.cpf)
        self.assertEqual(r.data['telefone'], self.m1.telefone)

    def test_empresa_ve_contato_so_durante_a_viagem_e_nunca_o_cpf(self):
        carga = criar_carga(self.empresa)
        self.como(self.empresa)
        r = self.client.get(f'/api/usuario/motoristas/{self.m1.id}/')
        self.assertNotIn('telefone', r.data)

        carga.motorista_alocado = self.m1
        carga.status = 'em_transito'
        carga.save()
        r = self.client.get(f'/api/usuario/motoristas/{self.m1.id}/')
        self.assertEqual(r.data['telefone'], self.m1.telefone)
        self.assertEqual(r.data['placa_veiculo'], self.m1.placa_veiculo)
        self.assertNotIn('cpf', r.data)

        self.como(self.outra_empresa)
        r = self.client.get(f'/api/usuario/motoristas/{self.m1.id}/')
        self.assertNotIn('telefone', r.data)

    def test_cadastro_nao_devolve_cpf(self):
        self.client.force_authenticate(user=None)
        r = self.client.post('/api/cadastro_usuario/caminhoneiros/', {
            'nome_completo': 'Novo', 'cpf': '98765432100', 'placa_veiculo': 'CCC3C33',
            'email': 'novo@x.com', 'senha': 'senhaforte123'})
        self.assertEqual(r.status_code, 201, r.content)
        self.assertNotIn('cpf', r.data)
        self.assertNotIn('user', r.data)

    def test_cpf_nao_pode_ser_alterado_pelo_perfil(self):
        self.como(self.m1)
        self.client.patch('/api/usuario/motoristas/me/', {'cpf': '00000000000'})
        self.m1.refresh_from_db()
        self.assertEqual(self.m1.cpf, f'{1:011d}')

    def test_rotas_exigem_autenticacao(self):
        self.client.force_authenticate(user=None)
        for url in ('/api/usuario/motoristas/', '/api/fretes/cargas/', '/api/avaliacao/blacklist/'):
            self.assertEqual(self.client.get(url).status_code, 401, url)

    def test_avaliacao_nao_pode_ser_alterada_nem_apagada(self):
        carga = criar_carga(self.empresa, motorista_alocado=self.m1, status='finalizado')
        avaliacao = AvaliacaoCaminhoneiro.objects.create(
            empresa=self.empresa, caminhoneiro=self.m1, carga=carga, nota=5)
        self.como(self.m1)
        url = f'/api/avaliacao/avaliar-caminhoneiro/{avaliacao.id}/'
        self.assertEqual(self.client.patch(url, {'nota': 0}).status_code, 405)
        self.assertEqual(self.client.delete(url).status_code, 405)


class FinanceiroTests(Base):
    def test_exemplo_numerico_desconta_comissao(self):
        carga = criar_carga(self.empresa, consumo_veiculo_alocado=2.5,
                            preco_combustivel=Decimal('6.00'))
        r = carga.resumo_financeiro()
        self.assertEqual(r['valor_bruto'], Decimal('5000.00'))
        self.assertEqual(r['comissao'], Decimal('10.00'))
        self.assertEqual(r['pedagio'], Decimal('200.00'))
        self.assertEqual(r['litros'], Decimal('280.00'))
        self.assertEqual(r['combustivel'], Decimal('1680.00'))
        self.assertEqual(r['despesas'], Decimal('1890.00'))
        self.assertEqual(r['lucro_estimado'], Decimal('3110.00'))

    def test_preco_informado_na_carga_muda_o_lucro(self):
        self.como(self.empresa)
        r = self.client.post('/api/fretes/cargas/', {
            'titulo': 'Soja', 'origem': 'A', 'destino': 'B', 'distancia_km': 700,
            'valor_bruto_frete': '5000.00', 'estimativa_pedagio': '200.00',
            'preco_combustivel': '6.50',
        })
        self.assertEqual(r.status_code, 201, r.content)
        self.como(self.m1)
        r = self.client.get(f"/api/fretes/cargas/{r.data['id']}/")
        self.assertEqual(r.data['financeiro']['combustivel'], '1820.00')
        self.assertEqual(r.data['lucro_estimado'], 2970.0)

    @override_settings(PRECO_COMBUSTIVEL_PADRAO=Decimal('7.25'))
    def test_preco_padrao_vem_da_configuracao(self):
        self.assertEqual(criar_carga(self.empresa).preco_combustivel, Decimal('7.25'))

    def test_lucro_pode_ser_negativo(self):
        carga = criar_carga(self.empresa, valor_bruto_frete=Decimal('1000.00'),
                            consumo_veiculo_alocado=2.5)
        self.assertEqual(carga.resumo_financeiro()['lucro_estimado'], Decimal('-882.00'))

    def test_sem_consumo_nao_inventa_lucro(self):
        semconsumo = criar_motorista(3)
        carga = criar_carga(self.empresa)
        self.como(semconsumo)
        r = self.client.get(f'/api/fretes/cargas/{carga.id}/')
        self.assertIsNone(r.data['lucro_estimado'])
        self.assertIsNone(r.data['financeiro'])

    def test_rejeita_valores_invalidos(self):
        self.como(self.empresa)
        base = {'titulo': 'X', 'origem': 'A', 'destino': 'B', 'distancia_km': 100,
                'valor_bruto_frete': '100.00', 'estimativa_pedagio': '0.00',
                'preco_combustivel': '6.00'}
        for campo, valor in (('distancia_km', 0), ('valor_bruto_frete', '-1.00'),
                             ('estimativa_pedagio', '-1.00'), ('preco_combustivel', '0.00')):
            r = self.client.post('/api/fretes/cargas/', {**base, campo: valor})
            self.assertEqual(r.status_code, 400, campo)


class ContratacaoTests(Base):
    def test_dois_candidatos_e_empresa_seleciona_um(self):
        carga = criar_carga(self.empresa)
        c1 = self.candidatar(self.m1, carga)
        c2 = self.candidatar(self.m2, carga)

        self.assertEqual(self.aceitar(c1).status_code, 200)

        carga.refresh_from_db(); c1.refresh_from_db(); c2.refresh_from_db()
        self.assertEqual(carga.status, 'aguardando_aceite')
        self.assertEqual(carga.motorista_alocado, self.m1)
        self.assertEqual(carga.consumo_veiculo_alocado, 2.5)
        self.assertEqual((c1.status, c2.status), ('aceita', 'recusada'))

        # O segundo não pode mais ser contratado nem agir sobre a carga
        self.assertEqual(self.aceitar(c2).status_code, 400)
        self.como(self.m2)
        self.assertIn(self.client.post(f'/api/fretes/cargas/{carga.id}/aceitar/').status_code,
                      (403, 404))
        carga.refresh_from_db()
        self.assertEqual(carga.motorista_alocado, self.m1)

    def test_motorista_em_viagem_nao_e_contratado_em_outra_carga(self):
        carga_a = criar_carga(self.empresa)
        carga_b = criar_carga(self.outra_empresa)
        ca = self.candidatar(self.m1, carga_a)
        cb = self.candidatar(self.m1, carga_b)

        self.assertEqual(self.aceitar(ca).status_code, 200)
        self.assertEqual(self.aceitar(cb, self.outra_empresa).status_code, 400)
        carga_b.refresh_from_db()
        self.assertEqual(carga_b.status, 'disponivel')
        self.assertIsNone(carga_b.motorista_alocado)

    def test_motorista_em_viagem_nao_se_candidata(self):
        criar_carga(self.empresa, motorista_alocado=self.m1, status='em_transito')
        nova = criar_carga(self.empresa)
        self.como(self.m1)
        r = self.client.post(f'/api/fretes/cargas/{nova.id}/candidatar/')
        self.assertEqual(r.status_code, 400)

    def test_nao_aceita_candidatura_recusada_ou_cancelada(self):
        carga = criar_carga(self.empresa)
        c1 = self.candidatar(self.m1, carga)
        self.como(self.empresa)
        self.client.post(f'/api/fretes/candidaturas/{c1.id}/recusar/')
        self.assertEqual(self.aceitar(c1).status_code, 400)
        carga.refresh_from_db()
        self.assertEqual(carga.status, 'disponivel')

    def test_nao_recusa_candidatura_ja_aceita(self):
        carga = criar_carga(self.empresa)
        c1 = self.candidatar(self.m1, carga)
        self.aceitar(c1)
        r = self.client.post(f'/api/fretes/candidaturas/{c1.id}/recusar/')
        self.assertEqual(r.status_code, 400)
        c1.refresh_from_db()
        self.assertEqual(c1.status, 'aceita')

    def test_empresa_nao_decide_candidatura_de_outra(self):
        carga = criar_carga(self.empresa)
        c1 = self.candidatar(self.m1, carga)
        self.assertEqual(self.aceitar(c1, self.outra_empresa).status_code, 404)

    def test_desistencia_devolve_a_vaga_aos_outros_candidatos(self):
        carga = criar_carga(self.empresa)
        c1 = self.candidatar(self.m1, carga)
        c2 = self.candidatar(self.m2, carga)
        self.aceitar(c1)

        self.como(self.m1)
        self.assertEqual(self.client.post(f'/api/fretes/cargas/{carga.id}/cancelar/').status_code, 200)

        carga.refresh_from_db(); c1.refresh_from_db(); c2.refresh_from_db()
        self.assertEqual(carga.status, 'disponivel')
        self.assertIsNone(carga.motorista_alocado)
        self.assertIsNone(carga.consumo_veiculo_alocado)
        self.assertEqual((c1.status, c2.status), ('cancelada', 'pendente'))
        self.assertEqual(self.aceitar(c2).status_code, 200)

    def test_recusa_manual_nao_volta_apos_desistencia(self):
        carga = criar_carga(self.empresa)
        c1 = self.candidatar(self.m1, carga)
        c2 = self.candidatar(self.m2, carga)
        self.como(self.empresa)
        self.client.post(f'/api/fretes/candidaturas/{c2.id}/recusar/')
        self.aceitar(c1)
        self.como(self.m1)
        self.client.post(f'/api/fretes/cargas/{carga.id}/cancelar/')
        c2.refresh_from_db()
        self.assertEqual(c2.status, 'recusada')

    def test_quem_desistiu_pode_se_candidatar_de_novo(self):
        carga = criar_carga(self.empresa)
        c1 = self.candidatar(self.m1, carga)
        self.aceitar(c1)
        self.como(self.m1)
        self.client.post(f'/api/fretes/cargas/{carga.id}/cancelar/')
        self.assertEqual(self.candidatar(self.m1, carga).pk, c1.pk)
        c1.refresh_from_db()
        self.assertEqual(c1.status, 'pendente')

    def test_transicoes_fora_de_ordem_sao_bloqueadas(self):
        acoes = {
            'disponivel': [],
            'aguardando_aceite': ['iniciar-viagem'],
            'acoplar_carreta': ['aceitar'],
            'em_transito': ['aceitar', 'iniciar-viagem'],
            'finalizado': ['aceitar', 'iniciar-viagem', 'cancelar'],
        }
        for estado, proibidas in acoes.items():
            carga = criar_carga(self.empresa, motorista_alocado=self.m1, status=estado)
            self.como(self.m1)
            for acao in proibidas:
                r = self.client.post(f'/api/fretes/cargas/{carga.id}/{acao}/')
                self.assertEqual(r.status_code, 400, f'{estado}/{acao}')
            carga.refresh_from_db()
            self.assertEqual(carga.status, estado)
            carga.delete()

    def test_finalizar_duas_vezes_preserva_a_data(self):
        carga = criar_carga(self.empresa, motorista_alocado=self.m1, status='em_transito')
        self.como(self.empresa)
        self.assertEqual(self.client.post(f'/api/fretes/cargas/{carga.id}/finalizar/').status_code, 200)
        carga.refresh_from_db()
        data = carga.data_entrega
        self.assertEqual(self.client.post(f'/api/fretes/cargas/{carga.id}/finalizar/').status_code, 400)
        carga.refresh_from_db()
        self.assertEqual(carga.data_entrega, data)

    def test_lista_de_disponiveis_nao_traz_a_viagem_do_motorista(self):
        minha = criar_carga(self.empresa, motorista_alocado=self.m1, status='em_transito')
        aberta = criar_carga(self.empresa)
        self.como(self.m1)
        ids = [c['id'] for c in self.client.get('/api/fretes/cargas/?status=disponivel').data]
        self.assertEqual(ids, [aberta.id])
        self.assertNotIn(minha.id, ids)

    def test_fluxo_completo_persiste_os_dados(self):
        self.como(self.empresa)
        r = self.client.post('/api/fretes/cargas/', {
            'titulo': 'Soja', 'origem': 'Curitiba', 'destino': 'Santos', 'distancia_km': 700,
            'valor_bruto_frete': '5000.00', 'estimativa_pedagio': '200.00',
            'preco_combustivel': '6.00',
        })
        carga_id = r.data['id']
        carga = Carga.objects.get(pk=carga_id)
        c1 = self.candidatar(self.m1, carga)
        self.candidatar(self.m2, carga)
        self.aceitar(c1)
        self.como(self.m1)
        self.client.post(f'/api/fretes/cargas/{carga_id}/aceitar/')
        self.client.post(f'/api/fretes/cargas/{carga_id}/iniciar-viagem/')
        self.como(self.empresa)
        self.client.post(f'/api/fretes/cargas/{carga_id}/finalizar/')

        salva = Carga.objects.get(pk=carga_id)
        self.assertEqual(salva.status, 'finalizado')
        self.assertEqual(salva.motorista_alocado, self.m1)
        self.assertIsNotNone(salva.data_entrega)
        self.assertEqual(salva.comissao_app, Decimal('10.00'))
        self.assertEqual(salva.preco_combustivel, Decimal('6.00'))
        self.assertEqual(salva.resumo_financeiro()['lucro_estimado'], Decimal('3110.00'))
        self.assertEqual(
            sorted(salva.candidaturas.values_list('status', flat=True)), ['aceita', 'recusada'])


@skipUnlessDBFeature('has_select_for_update')
class ConcorrenciaTests(TransactionTestCase):
    """Só faz sentido em banco com bloqueio de linha (PostgreSQL)."""

    def _em_paralelo(self, chamadas):
        barreira = threading.Barrier(len(chamadas))
        respostas = []

        def executar(user, url):
            try:
                cliente = APIClient()
                cliente.force_authenticate(user=user)
                barreira.wait(timeout=10)
                respostas.append(cliente.post(url).status_code)
            finally:
                connection.close()

        threads = [threading.Thread(target=executar, args=c) for c in chamadas]
        for t in threads:
            t.start()
        for t in threads:
            t.join(timeout=30)
        return sorted(respostas)

    def test_empresa_seleciona_dois_candidatos_ao_mesmo_tempo(self):
        empresa = criar_empresa(1)
        m1, m2 = criar_motorista(1), criar_motorista(2)
        carga = criar_carga(empresa)
        c1 = Candidatura.objects.create(carga=carga, caminhoneiro=m1)
        c2 = Candidatura.objects.create(carga=carga, caminhoneiro=m2)

        codigos = self._em_paralelo([
            (empresa.user, f'/api/fretes/candidaturas/{c1.id}/aceitar/'),
            (empresa.user, f'/api/fretes/candidaturas/{c2.id}/aceitar/'),
        ])

        self.assertEqual(codigos, [200, 400])
        self.assertEqual(Candidatura.objects.filter(carga=carga, status='aceita').count(), 1)

    def test_duas_empresas_contratam_o_mesmo_motorista_ao_mesmo_tempo(self):
        e1, e2 = criar_empresa(1), criar_empresa(2)
        motorista = criar_motorista(1)
        c1 = Candidatura.objects.create(carga=criar_carga(e1), caminhoneiro=motorista)
        c2 = Candidatura.objects.create(carga=criar_carga(e2), caminhoneiro=motorista)

        codigos = self._em_paralelo([
            (e1.user, f'/api/fretes/candidaturas/{c1.id}/aceitar/'),
            (e2.user, f'/api/fretes/candidaturas/{c2.id}/aceitar/'),
        ])

        self.assertEqual(codigos, [200, 400])
        self.assertEqual(
            Carga.objects.filter(motorista_alocado=motorista, status__in=Carga.ETAPAS_ATIVAS).count(), 1)
