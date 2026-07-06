from io import BytesIO
from django.contrib.auth.models import User
from rest_framework.test import APITestCase
from usuario.models import Empresa, Caminhoneiro
from cargas.models import Carga, Candidatura
from avaliacao.models import AvaliacaoCaminhoneiro


def _tiny_png():
    from PIL import Image
    buf = BytesIO()
    Image.new('RGB', (1, 1)).save(buf, format='PNG')
    buf.seek(0)
    buf.name = 'x.png'
    return buf


class FluxoCompletoTests(APITestCase):
    def setUp(self):
        self.emp_user = User.objects.create_user('empresa@x.com', password='pass12345')
        self.empresa = Empresa.objects.create(
            user=self.emp_user, razao_social='Transportes X', cnpj='12345678000199')

        self.mot_user = User.objects.create_user('mot@x.com', password='pass12345')
        self.motorista = Caminhoneiro.objects.create(
            user=self.mot_user, nome_completo='João Motorista',
            cpf='12345678901', placa_veiculo='ABC1D23')

    def auth(self, user):
        self.client.force_authenticate(user=user)

    def test_fluxo_candidatura_aceite_entrega_avaliacao(self):
        # 1. Empresa publica uma carga
        self.auth(self.emp_user)
        r = self.client.post('/api/fretes/cargas/', {
            'titulo': 'Soja', 'origem': 'Curitiba', 'destino': 'Santos',
            'distancia_km': 700, 'valor_bruto_frete': '5000.00',
            'estimativa_pedagio': '200.00', 'nota_minima_motorista': 0,
        })
        self.assertEqual(r.status_code, 201, r.content)
        carga_id = r.data['id']

        # 2. Motorista se candidata (não fica alocado imediatamente)
        self.auth(self.mot_user)
        r = self.client.post(f'/api/fretes/cargas/{carga_id}/candidatar/', {'mensagem': 'Posso pegar!'})
        self.assertEqual(r.status_code, 201, r.content)
        carga = Carga.objects.get(id=carga_id)
        self.assertEqual(carga.status, 'disponivel')  # ainda disponível!
        self.assertIsNone(carga.motorista_alocado)

        # 3. Empresa vê os candidatos e aceita com base no perfil
        self.auth(self.emp_user)
        r = self.client.get(f'/api/fretes/cargas/{carga_id}/candidaturas/')
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual(len(r.data), 1)
        cand_id = r.data[0]['id']

        r = self.client.post(f'/api/fretes/candidaturas/{cand_id}/aceitar/')
        self.assertEqual(r.status_code, 200, r.content)
        carga.refresh_from_db()
        self.assertEqual(carga.status, 'em_transito')
        self.assertEqual(carga.motorista_alocado, self.motorista)

        # 4. Não pode avaliar antes de finalizar
        r = self.client.post('/api/avaliacao/avaliar-caminhoneiro/', {
            'caminhoneiro': self.motorista.id, 'carga': carga_id, 'nota': 5, 'comentario': 'Ótimo'})
        self.assertEqual(r.status_code, 400, r.content)

        # 5. Empresa finaliza a entrega
        r = self.client.post(f'/api/fretes/cargas/{carga_id}/finalizar/')
        self.assertEqual(r.status_code, 200, r.content)
        carga.refresh_from_db()
        self.assertEqual(carga.status, 'finalizado')

        # 6. Agora a empresa avalia o motorista (0-5 estrelas + comentário)
        r = self.client.post('/api/avaliacao/avaliar-caminhoneiro/', {
            'caminhoneiro': self.motorista.id, 'carga': carga_id, 'nota': 5,
            'comentario': 'Excelente motorista, entrega no prazo.'})
        self.assertEqual(r.status_code, 201, r.content)
        self.motorista.refresh_from_db()
        self.assertEqual(self.motorista.media_notas, 5.0)
        self.assertEqual(self.motorista.total_avaliacoes, 1)

        # 7. Não pode avaliar duas vezes a mesma entrega
        r = self.client.post('/api/avaliacao/avaliar-caminhoneiro/', {
            'caminhoneiro': self.motorista.id, 'carga': carga_id, 'nota': 1, 'comentario': 'x'})
        self.assertEqual(r.status_code, 400, r.content)

        # 8. Perfil público do motorista mostra a avaliação
        self.auth(self.mot_user)
        r = self.client.get(f'/api/usuario/motoristas/{self.motorista.id}/')
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual(len(r.data['avaliacoes']), 1)
        self.assertEqual(r.data['media_notas'], 5.0)

    def test_editar_perfil_com_bio_e_foto(self):
        self.auth(self.mot_user)
        r = self.client.patch('/api/usuario/motoristas/me/', {
            'bio': 'Motorista há 10 anos', 'cidade': 'Curitiba',
            'tipo_veiculo': 'Carreta baú', 'anos_experiencia': 10,
            'foto_perfil': _tiny_png(),
        }, format='multipart')
        self.assertEqual(r.status_code, 200, r.content)
        self.motorista.refresh_from_db()
        self.assertEqual(self.motorista.bio, 'Motorista há 10 anos')
        self.assertTrue(self.motorista.foto_perfil)

    def _entrega_finalizada(self):
        """Cria uma carga já finalizada com este motorista alocado."""
        carga = Carga.objects.create(
            empresa=self.empresa, titulo='Entrega', origem='A', destino='B',
            distancia_km=100, valor_bruto_frete='1500.00')
        carga.motorista_alocado = self.motorista
        carga.status = 'finalizado'
        carga.save()
        return carga

    def test_motorista_avalia_empresa_so_apos_entrega(self):
        carga = self._entrega_finalizada()
        self.auth(self.mot_user)

        # Avalia a empresa (0-5 estrelas + comentário + critérios da blacklist)
        r = self.client.post('/api/avaliacao/blacklist/', {
            'carga': carga.id, 'nota': 4, 'comentario': 'Carregou rápido, local seguro.',
            'tem_banheiro_limpo': True, 'local_seguro': True})
        self.assertEqual(r.status_code, 201, r.content)
        self.empresa.refresh_from_db()
        self.assertEqual(self.empresa.media_avaliacao, 4.0)
        self.assertEqual(self.empresa.total_avaliacoes, 1)

        # Não pode avaliar a mesma entrega duas vezes
        r = self.client.post('/api/avaliacao/blacklist/', {
            'carga': carga.id, 'nota': 1, 'comentario': 'x'})
        self.assertEqual(r.status_code, 400, r.content)

        # Perfil público da empresa mostra a avaliação
        r = self.client.get(f'/api/usuario/empresas/{self.empresa.id}/')
        self.assertEqual(r.status_code, 200, r.content)
        self.assertEqual(len(r.data['avaliacoes']), 1)
        self.assertEqual(r.data['media_avaliacao'], 4.0)

    def test_nao_avalia_empresa_antes_de_finalizar(self):
        carga = Carga.objects.create(
            empresa=self.empresa, titulo='EmTransito', origem='A', destino='B',
            distancia_km=100, valor_bruto_frete='1500.00',
            motorista_alocado=self.motorista, status='em_transito')
        self.auth(self.mot_user)
        r = self.client.post('/api/avaliacao/blacklist/', {'carga': carga.id, 'nota': 5, 'comentario': 'ok'})
        self.assertEqual(r.status_code, 400, r.content)

    def test_motorista_nao_avalia_entrega_de_outro(self):
        # Carga finalizada por OUTRO motorista
        outro_user = User.objects.create_user('outro_mot@x.com', password='pass12345')
        outro = Caminhoneiro.objects.create(
            user=outro_user, nome_completo='Outro', cpf='55566677788', placa_veiculo='XYZ9Z99')
        carga = Carga.objects.create(
            empresa=self.empresa, titulo='NaoMinha', origem='A', destino='B',
            distancia_km=100, valor_bruto_frete='1500.00',
            motorista_alocado=outro, status='finalizado')
        self.auth(self.mot_user)  # motorista diferente tenta avaliar
        r = self.client.post('/api/avaliacao/blacklist/', {'carga': carga.id, 'nota': 5, 'comentario': 'ok'})
        self.assertEqual(r.status_code, 403, r.content)

    def test_nota_minima_bloqueia_candidatura(self):
        carga = Carga.objects.create(
            empresa=self.empresa, titulo='Frágil', origem='A', destino='B',
            distancia_km=100, valor_bruto_frete='1000.00', nota_minima_motorista=4.0)
        self.auth(self.mot_user)  # motorista tem media_notas 0.0
        r = self.client.post(f'/api/fretes/cargas/{carga.id}/candidatar/')
        self.assertEqual(r.status_code, 403, r.content)


class SegurancaTests(APITestCase):
    """Garante que as brechas de autorização estão fechadas."""

    def setUp(self):
        self.emp_user = User.objects.create_user('emp@x.com', password='pass12345')
        self.empresa = Empresa.objects.create(
            user=self.emp_user, razao_social='Emp', cnpj='11111111000199')

        self.mot_user = User.objects.create_user('mot@x.com', password='pass12345')
        self.motorista = Caminhoneiro.objects.create(
            user=self.mot_user, nome_completo='Motorista Um',
            cpf='11111111111', placa_veiculo='AAA1A11')

        # Um segundo motorista, "vítima" das tentativas de alteração indevida
        self.outro_user = User.objects.create_user('outro@x.com', password='pass12345')
        self.outro = Caminhoneiro.objects.create(
            user=self.outro_user, nome_completo='Motorista Dois',
            cpf='22222222222', placa_veiculo='BBB2B22')

    # 1a — cadastro só aceita POST (registro), nada de listar/editar/apagar
    def test_cadastro_nao_expoe_listagem_nem_escrita(self):
        # Sem autenticação, não dá para listar motoristas por aqui (só POST na rota)
        self.assertEqual(self.client.get('/api/cadastro_usuario/caminhoneiros/').status_code, 405)
        # A rota de detalhe nem existe (create-only): apagar dá 404/405, nunca sucesso
        self.assertIn(
            self.client.delete(f'/api/cadastro_usuario/caminhoneiros/{self.motorista.id}/').status_code,
            (404, 405))
        # POST (registro) continua funcionando
        r = self.client.post('/api/cadastro_usuario/caminhoneiros/', {
            'nome_completo': 'Novo', 'cpf': '33333333333', 'placa_veiculo': 'CCC3C33',
            'email': 'novo@x.com', 'senha': 'senhaforte123'})
        self.assertEqual(r.status_code, 201, r.content)

    # 1b — ninguém edita/apaga o perfil de outro usuário
    def test_nao_edita_perfil_de_terceiro(self):
        self.client.force_authenticate(user=self.mot_user)
        r = self.client.patch(f'/api/usuario/motoristas/{self.outro.id}/', {'bio': 'hackeado'})
        self.assertIn(r.status_code, (403, 405))
        r = self.client.delete(f'/api/usuario/motoristas/{self.outro.id}/')
        self.assertIn(r.status_code, (403, 405))
        self.outro.refresh_from_db()
        self.assertNotEqual(self.outro.bio, 'hackeado')
        # Mas consegue ler o perfil público e editar o SEU via /me/
        self.assertEqual(
            self.client.get(f'/api/usuario/motoristas/{self.outro.id}/').status_code, 200)
        self.assertEqual(
            self.client.patch('/api/usuario/motoristas/me/', {'bio': 'ok'}).status_code, 200)

    # 1c — motorista não altera/apaga carga disponível
    def test_motorista_nao_altera_carga(self):
        carga = Carga.objects.create(
            empresa=self.empresa, titulo='Soja', origem='A', destino='B',
            distancia_km=100, valor_bruto_frete='1000.00')
        self.client.force_authenticate(user=self.mot_user)
        self.assertEqual(
            self.client.patch(f'/api/fretes/cargas/{carga.id}/', {'valor_bruto_frete': '1.00'}).status_code,
            405)
        self.assertEqual(self.client.delete(f'/api/fretes/cargas/{carga.id}/').status_code, 405)
        carga.refresh_from_db()
        self.assertEqual(str(carga.valor_bruto_frete), '1000.00')
