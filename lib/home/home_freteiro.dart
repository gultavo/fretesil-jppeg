import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../pages/perfil_motorista_page.dart';
import '../pages/perfil_empresa_page.dart';
import '../pages/avaliar_empresa_page.dart';

class HomeFreteiro extends StatefulWidget {
  const HomeFreteiro({super.key});

  @override
  State<HomeFreteiro> createState() => _HomeFreteiroState();
}

class _HomeFreteiroState extends State<HomeFreteiro>
    with SingleTickerProviderStateMixin {
  List<dynamic> _disponiveis = [];
  List<dynamic> _candidaturas = [];
  List<dynamic> _entregas = [];
  Map<String, dynamic>? _cargaAtiva;
  bool _carregando = true;
  String? _erro;
  late TabController _tabController;

  static const _bg = Color(0xFF1A1D23);
  static const _card = Color(0xFF23272F);
  static const _accent = Color(0xFFE8A020);
  static const _textPrimary = Color(0xFFE8E0CC);
  static const _textMuted = Color(0xFF8A8070);
  static const _green = Color(0xFF4CAF7D);
  static const _blue = Color(0xFF5B8FBF);
  static const _red = Color(0xFFCF6679);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarTudo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

Future<void> _carregarTudo() async {
  setState(() { _carregando = true; _erro = null; });
  try {
    final lista = await ApiService.listarCargasDisponiveis();
    final ativa = await ApiService.cargaAtiva();
    final candidaturas = await ApiService.minhasCandidaturas();
    final entregas = await ApiService.minhasEntregas();
    if (mounted) {
      setState(() {
        _disponiveis = lista;
        _cargaAtiva = ativa;
        _candidaturas = candidaturas;
        _entregas = entregas;
      });
    }
  } catch (e, stack) {
    print('ERRO: $e');
    print('STACK: $stack');
    if (mounted) setState(() => _erro = e.toString());
  } finally {
    if (mounted) setState(() => _carregando = false);
  }
}

  Future<void> _candidatar(Map<String, dynamic> carga) async {
    final confirmou = await _confirmar(
      titulo: 'Candidatar-se a esta carga?',
      mensagem:
          '${carga['titulo']}\n${carga['origem']} → ${carga['destino']}\n\n'
          'A empresa vai analisar seu perfil e decidir se aceita você.',
    );
    if (confirmou != true) return;

    final res = await ApiService.candidatarCarga(carga['id']);
    if (!mounted) return;

    if (res['statusCode'] == 201) {
      _snack('Candidatura enviada! Aguarde a resposta da empresa. 📨', _green);
      _carregarTudo();
    } else {
      final body = res['body'];
      final msg = body is Map && body['erro'] != null
          ? body['erro'].toString()
          : 'Não foi possível se candidatar.';
      _snack(msg, _red);
    }
  }

  Future<void> _avaliarEmpresa(Map<String, dynamic> carga) async {
    final feito = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvaliarEmpresaPage(
          cargaId: carga['id'],
          empresaNome: carga['empresa_nome']?.toString() ?? 'Empresa',
        ),
      ),
    );
    if (feito == true) _carregarTudo();
  }

  void _verPerfilEmpresa(dynamic empresaId) {
    if (empresaId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PerfilEmpresaPage(empresaId: empresaId)),
    );
  }

  Future<bool?> _confirmar({required String titulo, required String mensagem}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: _accent),
        ),
        title: Text(titulo,
            style: const TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
        content: Text(mensagem, style: const TextStyle(color: _textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: _accent, foregroundColor: _bg),
            child: const Text('Confirmar',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        foregroundColor: _textPrimary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _accent.withOpacity(0.4)),
              ),
              child: const Icon(Icons.local_shipping, color: _accent, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FRETE SIL',
                    style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 2)),
                Text('CENTRAL DE CARGAS',
                    style: TextStyle(
                        color: _textMuted, fontSize: 9, letterSpacing: 1.5)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: _accent, size: 22),
            tooltip: 'Meu perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilMotoristaPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: _textMuted, size: 20),
            onPressed: () async {
              await ApiService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (r) => false);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: _accent,
          unselectedLabelColor: _textMuted,
          indicatorColor: _accent,
          indicatorWeight: 2,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: 'DISPONÍVEIS (${_disponiveis.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('MINHA VIAGEM'),
                  if (_cargaAtiva != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(text: 'CANDIDATURAS (${_candidaturas.length})'),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _erro != null
              ? _buildErro()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDisponiveis(),
                    _buildCargaAtiva(),
                    _buildCandidaturas(),
                  ],
                ),
    );
  }

  // ─── Aba: Minhas candidaturas ─────────────────────────────────────────────
  Widget _buildCandidaturas() {
    if (_candidaturas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, color: _textMuted, size: 56),
            SizedBox(height: 12),
            Text('Nenhuma candidatura ainda',
                style: TextStyle(color: _textMuted, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Candidate-se a uma carga na aba "Disponíveis"',
                style: TextStyle(color: _textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: _card,
      onRefresh: _carregarTudo,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _candidaturas.length,
        itemBuilder: (ctx, i) => _CandidaturaCard(candidatura: _candidaturas[i]),
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.signal_wifi_off, color: _red, size: 48),
          const SizedBox(height: 12),
          const Text('Sem conexão com o servidor',
              style: TextStyle(color: _textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _carregarTudo,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _accent, foregroundColor: _bg),
          ),
        ],
      ),
    );
  }

  // ─── Aba: Cargas disponíveis ──────────────────────────────────────────────
  Widget _buildDisponiveis() {
    if (_disponiveis.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: _textMuted, size: 56),
            SizedBox(height: 12),
            Text('Nenhuma carga disponível',
                style: TextStyle(color: _textMuted, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Aguarde novas publicações',
                style: TextStyle(color: _textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: _card,
      onRefresh: _carregarTudo,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _disponiveis.length,
        itemBuilder: (ctx, i) => _CargaCard(
          carga: _disponiveis[i],
          onCandidatar: () => _candidatar(_disponiveis[i]),
        ),
      ),
    );
  }

  // ─── Aba: Carga ativa ─────────────────────────────────────────────────────
  Widget _buildCargaAtiva() {
    final pendentesAvaliar =
        _entregas.where((e) => e['empresa_avaliada'] != true).toList();

    // Nada para mostrar: nem viagem ativa, nem entrega para avaliar
    if (_cargaAtiva == null && pendentesAvaliar.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined,
                color: _textMuted.withOpacity(0.4), size: 72),
            const SizedBox(height: 16),
            const Text('Nenhuma viagem ativa',
                style: TextStyle(
                    color: _textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
            const SizedBox(height: 6),
            const Text('Candidate-se a uma carga na aba anterior',
                style: TextStyle(color: _textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: _card,
      onRefresh: _carregarTudo,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_cargaAtiva != null) _viagemAtivaCard(_cargaAtiva!),
          if (pendentesAvaliar.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('AVALIE SUAS ENTREGAS',
                style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.2)),
            const SizedBox(height: 4),
            const Text('Como foi trabalhar com estas empresas?',
                style: TextStyle(color: _textMuted, fontSize: 12)),
            const SizedBox(height: 10),
            ...pendentesAvaliar.map(_entregaCard),
          ],
        ],
      ),
    );
  }

  Widget _viagemAtivaCard(Map<String, dynamic> c) {
    final valor = _fmt(c['valor_bruto_frete']);
    final pedagio = _fmt(c['estimativa_pedagio']);
    final distancia = (c['distancia_km'] as num?)?.toStringAsFixed(0) ?? '—';
    final empresa = c['empresa_nome'] ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _green.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 8, color: _green),
                  SizedBox(width: 6),
                  Text('EM TRÂNSITO',
                      style: TextStyle(
                          color: _green,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          (c['titulo'] ?? '').toString().toUpperCase(),
          style: const TextStyle(
              color: _accent,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        // Nome da empresa clicável → perfil público
        InkWell(
          onTap: () => _verPerfilEmpresa(c['empresa']),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(empresa,
                  style: const TextStyle(color: _textMuted, fontSize: 13)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 16, color: _textMuted),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2E3340)),
          ),
          child: Column(
            children: [
              _RotaLinha(
                  icon: Icons.radio_button_checked,
                  label: 'ORIGEM',
                  valor: c['origem'] ?? '—',
                  cor: _green),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(
                    height: 24, width: 1, color: _textMuted.withOpacity(0.2)),
              ),
              _RotaLinha(
                  icon: Icons.location_on,
                  label: 'DESTINO',
                  valor: c['destino'] ?? '—',
                  cor: _red),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _MetricBox(label: 'DISTÂNCIA', value: '$distancia km', color: _blue),
            const SizedBox(width: 10),
            _MetricBox(label: 'VALOR BRUTO', value: valor, color: _green),
            const SizedBox(width: 10),
            _MetricBox(label: 'PEDÁGIO', value: pedagio, color: _textMuted),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _entregaCard(dynamic e) {
    final titulo = e['titulo']?.toString() ?? 'Entrega';
    final empresa = e['empresa_nome']?.toString() ?? '—';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _accent.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(
                  color: _textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(empresa, style: const TextStyle(color: _textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _verPerfilEmpresa(e['empresa']),
                icon: const Icon(Icons.visibility_outlined, size: 15, color: _textMuted),
                label: const Text('Ver empresa',
                    style: TextStyle(color: _textMuted, fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _avaliarEmpresa(e),
                icon: const Icon(Icons.star_outline, size: 16),
                label: const Text('Avaliar empresa'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _bg,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return 'R\$ —';
    final d = double.tryParse(v.toString()) ?? 0.0;
    return 'R\$ ${d.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

// ─── Card de carga disponível ─────────────────────────────────────────────
class _CargaCard extends StatelessWidget {
  final Map<String, dynamic> carga;
  final VoidCallback onCandidatar;

  static const _card = Color(0xFF23272F);
  static const _accent = Color(0xFFE8A020);
  static const _textPrimary = Color(0xFFE8E0CC);
  static const _textMuted = Color(0xFF8A8070);
  static const _green = Color(0xFF4CAF7D);
  static const _blue = Color(0xFF5B8FBF);

  const _CargaCard({required this.carga, required this.onCandidatar});

  @override
  Widget build(BuildContext context) {
    final titulo = carga['titulo'] ?? 'Sem título';
    final origem = carga['origem'] ?? '—';
    final destino = carga['destino'] ?? '—';
    final distancia =
        (carga['distancia_km'] as num?)?.toStringAsFixed(0) ?? '—';
    final valor = _fmt(carga['valor_bruto_frete']);
    final empresa = carga['empresa_nome'] ?? '—';
    final notaMin =
        (carga['nota_minima_motorista'] as num?)?.toStringAsFixed(1) ?? '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E3340)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título + distância
            Row(
              children: [
                Expanded(
                  child: Text(titulo,
                      style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _blue.withOpacity(0.3)),
                  ),
                  child: Text('$distancia km',
                      style: const TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Empresa
            Row(
              children: [
                const Icon(Icons.business_outlined,
                    size: 12, color: _textMuted),
                const SizedBox(width: 4),
                Text(empresa,
                    style:
                        const TextStyle(color: _textMuted, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),

            // Rota simples
            Row(
              children: [
                const Icon(Icons.radio_button_checked,
                    size: 13, color: _green),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(origem,
                        style: const TextStyle(
                            color: _textPrimary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                const Icon(Icons.arrow_forward,
                    size: 13, color: _accent),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(destino,
                        style: const TextStyle(
                            color: _textPrimary, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end)),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: Color(0xFF2E3340), height: 1),
            const SizedBox(height: 10),

            // Valor + nota + botão
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VALOR BRUTO',
                        style: TextStyle(
                            color: _textMuted,
                            fontSize: 9,
                            letterSpacing: 1)),
                    Text(valor,
                        style: const TextStyle(
                            color: _green,
                            fontWeight: FontWeight.w900,
                            fontSize: 15)),
                  ],
                ),
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _accent.withOpacity(0.2)),
                  ),
                  child: Text('★ $notaMin mín.',
                      style: const TextStyle(
                          color: _accent, fontSize: 11)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onCandidatar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFE8A020), Color(0xFFC07010)]),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('CANDIDATAR',
                        style: TextStyle(
                            color: Color(0xFF1A1D23),
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return 'R\$ —';
    final d = double.tryParse(v.toString()) ?? 0.0;
    return 'R\$ ${d.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────
class _RotaLinha extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color cor;

  const _RotaLinha(
      {required this.icon,
      required this.label,
      required this.valor,
      required this.cor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: cor),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: cor.withOpacity(0.7),
                    fontSize: 9,
                    letterSpacing: 1.2)),
            Text(valor,
                style: const TextStyle(
                    color: Color(0xFFE8E0CC),
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  static const _bg = Color(0xFF1A1D23);

  const _MetricBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 9,
                    letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ─── Card de candidatura (status do pedido) ───────────────────────────────
class _CandidaturaCard extends StatelessWidget {
  final Map<String, dynamic> candidatura;

  static const _card = Color(0xFF23272F);
  static const _accent = Color(0xFFE8A020);
  static const _textPrimary = Color(0xFFE8E0CC);
  static const _textMuted = Color(0xFF8A8070);
  static const _green = Color(0xFF4CAF7D);
  static const _red = Color(0xFFCF6679);

  const _CandidaturaCard({required this.candidatura});

  @override
  Widget build(BuildContext context) {
    final titulo = candidatura['carga_titulo']?.toString() ?? 'Carga';
    final status = candidatura['status']?.toString() ?? 'pendente';
    final mensagem = candidatura['mensagem']?.toString() ?? '';
    final (label, cor, icone, descricao) = _statusInfo(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(titulo,
                      style: const TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: cor.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icone, size: 12, color: cor),
                      const SizedBox(width: 4),
                      Text(label,
                          style: TextStyle(
                              color: cor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(descricao,
                style: const TextStyle(color: _textMuted, fontSize: 12)),
            if (mensagem.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      size: 13, color: _textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('"$mensagem"',
                        style: const TextStyle(
                            color: _textMuted,
                            fontSize: 12,
                            fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  (String, Color, IconData, String) _statusInfo(String status) {
    switch (status) {
      case 'aceita':
        return (
          'ACEITA',
          _green,
          Icons.check_circle,
          'Você foi aceito! Confira a aba "Minha Viagem".'
        );
      case 'recusada':
        return (
          'RECUSADA',
          _red,
          Icons.cancel,
          'A empresa escolheu outro motorista desta vez.'
        );
      default:
        return (
          'PENDENTE',
          _accent,
          Icons.hourglass_top,
          'Aguardando a empresa analisar seu perfil.'
        );
    }
  }
}
