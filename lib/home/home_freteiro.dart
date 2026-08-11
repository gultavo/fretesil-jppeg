import 'package:flutter/material.dart';

import '../pages/avaliar_empresa_page.dart';
import '../pages/perfil_empresa_page.dart';
import '../pages/perfil_motorista_page.dart';
import '../services/api_service.dart';
<<<<<<< HEAD
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/status_labels.dart';
import '../widgets/app_ui.dart';
=======
import '../pages/perfil_motorista_page.dart';
import '../pages/perfil_empresa_page.dart';
import '../pages/avaliar_empresa_page.dart';
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05

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

<<<<<<< HEAD
  Future<void> _carregarTudo() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
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
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
=======
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
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
    }
  }

<<<<<<< HEAD
  List<dynamic> get _pendentes =>
      _candidaturas.where((c) => c['status'] == 'pendente').toList();
  List<dynamic> get _aAvaliar =>
      _entregas.where((e) => e['empresa_avaliada'] != true).toList();

  Future<void> _candidatar(Map<String, dynamic> carga) async {
    final ok = await appConfirmar(
      context,
      titulo: 'Candidatar-se a esta carga?',
      mensagem: '${carga['titulo']}\n'
          '${carga['origem']} → ${carga['destino']}\n\n'
          'A empresa vai analisar seu perfil e decidir se aceita você.',
      confirmar: 'Candidatar',
=======
  Future<void> _candidatar(Map<String, dynamic> carga) async {
    final confirmou = await _confirmar(
      titulo: 'Candidatar-se a esta carga?',
      mensagem:
          '${carga['titulo']}\n${carga['origem']} → ${carga['destino']}\n\n'
          'A empresa vai analisar seu perfil e decidir se aceita você.',
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
    );
    if (!ok || !mounted) return;

    final res = await ApiService.candidatarCarga(carga['id']);
    if (!mounted) return;

    if (res['statusCode'] == 201) {
<<<<<<< HEAD
      AppSnack.success(
          context, 'Candidatura enviada! Aguarde a resposta da empresa.');
      _carregarTudo();
    } else {
      final body = res['body'];
      AppSnack.error(
        context,
        body is Map && body['erro'] != null
            ? body['erro'].toString()
            : 'Não foi possível se candidatar.',
      );
=======
      _snack('Candidatura enviada! Aguarde a resposta da empresa. 📨', _green);
      _carregarTudo();
    } else {
      final body = res['body'];
      final msg = body is Map && body['erro'] != null
          ? body['erro'].toString()
          : 'Não foi possível se candidatar.';
      _snack(msg, _red);
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
    }
  }

  Future<void> _avaliarEmpresa(Map<String, dynamic> carga) async {
    final feito = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvaliarEmpresaPage(
          cargaId: carga['id'],
          empresaNome: carga['empresa_nome']?.toString() ?? 'Empresa',
<<<<<<< HEAD
=======
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
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
        ),
      ),
    );
    if (feito == true) _carregarTudo();
  }

  void _verPerfilEmpresa(dynamic empresaId) {
    if (empresaId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilEmpresaPage(empresaId: empresaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = AppStatusColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const AppBrandMark(subtitle: 'Central de cargas'),
        titleSpacing: AppSpacing.lg,
        actions: [
          IconButton(
<<<<<<< HEAD
            icon: const Icon(Icons.person_outline),
=======
            icon: const Icon(Icons.person_outline, color: _accent, size: 22),
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
            tooltip: 'Meu perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilMotoristaPage()),
            ),
          ),
          IconButton(
<<<<<<< HEAD
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sair',
=======
            icon: const Icon(Icons.logout, color: _textMuted, size: 20),
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: TabBar(
          controller: _tabController,
<<<<<<< HEAD
=======
          labelColor: _accent,
          unselectedLabelColor: _textMuted,
          indicatorColor: _accent,
          indicatorWeight: 2,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
          tabs: [
            Tab(text: 'Disponíveis (${_disponiveis.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Minha viagem'),
                  if (_cargaAtiva != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: status.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
<<<<<<< HEAD
            Tab(text: 'Candidaturas (${_candidaturas.length})'),
          ],
        ),
      ),
      body: AppBody(
=======
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
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
        child: Column(
          children: [
            // ── Faixa de resumo ───────────────────────────────────────────
            Container(
              color: cs.surface,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  AppMetricTile(
                    label: 'Cargas abertas',
                    value: '${_disponiveis.length}',
                    icon: Icons.inventory_2_outlined,
                    color: cs.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppMetricTile(
                    label: 'Aguardando',
                    value: '${_pendentes.length}',
                    icon: Icons.hourglass_top,
                    color: status.warning,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppMetricTile(
                    label: 'Entregas feitas',
                    value: '${_entregas.length}',
                    icon: Icons.check_circle_outline,
                    color: status.success,
                  ),
                ],
              ),
            ),
            Divider(color: cs.outlineVariant),

            // ── Conteúdo das abas ─────────────────────────────────────────
            Expanded(
              child: _carregando
                  ? const AppLoading()
                  : _erro != null
                      ? AppErrorState(
                          title: 'Sem conexão com o servidor',
                          detail: 'Servidor: ${ApiService.baseUrl}',
                          onRetry: _carregarTudo,
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _abaDisponiveis(),
                            _abaViagem(),
                            _abaCandidaturas(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Aba: cargas disponíveis ────────────────────────────────────────────
  Widget _abaDisponiveis() {
    if (_disponiveis.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nenhuma carga disponível',
        message: 'Aguarde novas publicações das empresas.',
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarTudo,
      child: ListView.separated(
        padding: AppSpacing.list,
        itemCount: _disponiveis.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => _CargaDisponivelCard(
          carga: _disponiveis[i],
          onCandidatar: () => _candidatar(_disponiveis[i]),
        ),
      ),
    );
  }

<<<<<<< HEAD
  // ─── Aba: viagem ativa + entregas a avaliar ─────────────────────────────
  Widget _abaViagem() {
    if (_cargaAtiva == null && _aAvaliar.isEmpty) {
      return const AppEmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'Nenhuma viagem ativa',
        message: 'Candidate-se a uma carga na aba "Disponíveis".',
=======
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
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
      );
    }

    return RefreshIndicator(
<<<<<<< HEAD
      onRefresh: _carregarTudo,
      child: ListView(
        padding: AppSpacing.list,
        children: [
          if (_cargaAtiva != null) _viagemAtiva(_cargaAtiva!),
          if (_aAvaliar.isNotEmpty) ...[
            if (_cargaAtiva != null) const SizedBox(height: AppSpacing.xxl),
            const AppSectionHeader(
              label: 'Avalie suas entregas',
              icon: Icons.star_outline,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Como foi trabalhar com estas empresas?',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final e in _aAvaliar) ...[
              _entregaCard(e),
              const SizedBox(height: AppSpacing.md),
=======
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
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
            ],
          ],
        ],
      ),
    );
  }

  Widget _viagemAtiva(Map<String, dynamic> c) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);

<<<<<<< HEAD
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
=======
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
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
      children: [
        AppStatusChip(
          label: 'Em trânsito',
          color: status.info,
          icon: Icons.local_shipping_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          c['titulo']?.toString() ?? '—',
          style: tt.headlineSmall?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () => _verPerfilEmpresa(c['empresa']),
          borderRadius: AppRadius.brTag,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  c['empresa_nome']?.toString() ?? '—',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        AppRouteBlock(
          origem: c['origem']?.toString() ?? '—',
          destino: c['destino']?.toString() ?? '—',
        ),
        const SizedBox(height: AppSpacing.lg),

        Row(
          children: [
            AppMetricTile(
              label: 'Distância',
              value: Fmt.km(c['distancia_km']),
              color: status.info,
            ),
            const SizedBox(width: AppSpacing.sm),
            AppMetricTile(
              label: 'Valor bruto',
              value: Fmt.brl(c['valor_bruto_frete']),
              color: status.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            AppMetricTile(
              label: 'Pedágio',
              value: Fmt.brl(c['estimativa_pedagio']),
              color: cs.onSurfaceVariant,
            ),
          ],
        ),
      ],
    );
  }

  Widget _entregaCard(dynamic e) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e['titulo']?.toString() ?? 'Entrega',
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              e['empresa_nome']?.toString() ?? '—',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _verPerfilEmpresa(e['empresa']),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Ver empresa'),
                  style: AppCompactButton.outlined,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _avaliarEmpresa(e),
                  icon: const Icon(Icons.star_outline, size: 16),
                  label: const Text('Avaliar'),
                  style: AppCompactButton.style,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Aba: minhas candidaturas ───────────────────────────────────────────
  Widget _abaCandidaturas() {
    if (_candidaturas.isEmpty) {
      return const AppEmptyState(
        icon: Icons.assignment_outlined,
        title: 'Nenhuma candidatura ainda',
        message: 'Candidate-se a uma carga na aba "Disponíveis".',
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarTudo,
      child: ListView.separated(
        padding: AppSpacing.list,
        itemCount: _candidaturas.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => _CandidaturaCard(candidatura: _candidaturas[i]),
      ),
    );
  }
}

/// Card de carga aberta, na visão do motorista.
class _CargaDisponivelCard extends StatelessWidget {
  final Map<String, dynamic> carga;
  final VoidCallback onCandidatar;

  const _CargaDisponivelCard({required this.carga, required this.onCandidatar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    final notaMin = (carga['nota_minima_motorista'] as num?)?.toDouble() ?? 0;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    carga['titulo']?.toString() ?? 'Sem título',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (notaMin > 0)
                  AppStatusChip(
                    label: '${Fmt.nota(notaMin)} mín.',
                    color: status.brand,
                    icon: Icons.star_rounded,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.business_outlined,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    carga['empresa_nome']?.toString() ?? '—',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            AppRouteLine(
              origem: carga['origem']?.toString() ?? '—',
              destino: carga['destino']?.toString() ?? '—',
              distancia: Fmt.km(carga['distancia_km']),
            ),

            const SizedBox(height: AppSpacing.md),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VALOR BRUTO',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Fmt.brl(carga['valor_bruto_frete']),
                      style: TextStyle(
                        color: status.success,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: onCandidatar,
                  icon: const Icon(Icons.how_to_reg_outlined, size: 16),
                  label: const Text('Candidatar'),
                  style: AppCompactButton.style,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de acompanhamento de candidatura.
class _CandidaturaCard extends StatelessWidget {
  final Map<String, dynamic> candidatura;

  const _CandidaturaCard({required this.candidatura});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final visual = statusCandidatura(context, candidatura['status']?.toString());
    final mensagem = candidatura['mensagem']?.toString() ?? '';

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    candidatura['carga_titulo']?.toString() ?? 'Carga',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppStatusChip(
                  label: visual.label,
                  color: visual.color,
                  icon: visual.icon,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              visual.descricao,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (mensagem.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: AppRadius.brTag,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        mensagem,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
