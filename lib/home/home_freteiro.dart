import 'package:flutter/material.dart';

import '../pages/avaliar_empresa_page.dart';
import '../pages/perfil_empresa_page.dart';
import '../pages/perfil_motorista_page.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/status_labels.dart';
import '../widgets/app_ui.dart';

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
    }
  }

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
    );
    if (!ok || !mounted) return;

    final res = await ApiService.candidatarCarga(carga['id']);
    if (!mounted) return;

    if (res['statusCode'] == 201) {
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
            icon: const Icon(Icons.person_outline),
            tooltip: 'Meu perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilMotoristaPage()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sair',
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
            Tab(text: 'Candidaturas (${_candidaturas.length})'),
          ],
        ),
      ),
      body: AppBody(
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

  // ─── Aba: viagem ativa + entregas a avaliar ─────────────────────────────
  Widget _abaViagem() {
    if (_cargaAtiva == null && _aAvaliar.isEmpty) {
      return const AppEmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'Nenhuma viagem ativa',
        message: 'Candidate-se a uma carga na aba "Disponíveis".',
      );
    }

    return RefreshIndicator(
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
