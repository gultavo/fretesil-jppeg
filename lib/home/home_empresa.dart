import 'package:flutter/material.dart';

import '../pages/avaliar_motorista_page.dart';
import '../pages/candidatos_page.dart';
import '../pages/perfil_empresa_page.dart';
import '../services/api_service.dart';
<<<<<<< HEAD
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/status_labels.dart';
import '../widgets/app_ui.dart';
=======
import '../pages/candidatos_page.dart';
import '../pages/avaliar_motorista_page.dart';
import '../pages/perfil_empresa_page.dart';
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05

class HomeEmpresa extends StatefulWidget {
  const HomeEmpresa({super.key});

  @override
  State<HomeEmpresa> createState() => _HomeEmpresaState();
}

class _HomeEmpresaState extends State<HomeEmpresa>
    with SingleTickerProviderStateMixin {
  List<dynamic> _cargas = [];
  bool _carregando = true;
  String? _erro;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarCargas();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarCargas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await ApiService.listarCargasEmpresa();
      if (mounted) setState(() => _cargas = lista);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _verCandidatos(Map<String, dynamic> carga) async {
    final mudou = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidatosPage(
          cargaId: carga['id'],
          cargaTitulo: carga['titulo']?.toString() ?? 'Carga',
        ),
      ),
    );
    if (mudou == true) _carregarCargas();
  }

  Future<void> _finalizar(Map<String, dynamic> carga) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalizar entrega?'),
        content: Text('Confirmar que "${carga['titulo']}" foi entregue? '
            'Depois disso você poderá avaliar o motorista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finalizar')),
        ],
      ),
    );
    if (ok != true) return;
    final sucesso = await ApiService.finalizarCarga(carga['id']);
    if (!mounted) return;
    if (sucesso) {
      _carregarCargas();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Entrega finalizada!'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível finalizar.'), backgroundColor: Colors.red));
    }
  }

  Future<void> _avaliar(Map<String, dynamic> carga) async {
    final feito = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvaliarMotoristaPage(
          cargaId: carga['id'],
          caminhoneiroId: carga['motorista_alocado'],
          caminhoneiroNome: carga['motorista_nome']?.toString() ?? 'Motorista',
        ),
      ),
    );
    if (feito == true) _carregarCargas();
  }

  List<dynamic> get _ativas =>
      _cargas.where((c) => c['status'] == 'disponivel').toList();
  List<dynamic> get _emTransito =>
      _cargas.where((c) => c['status'] == 'em_transito').toList();
  List<dynamic> get _finalizadas =>
      _cargas.where((c) => c['status'] == 'finalizado').toList();

  Future<void> _verCandidatos(Map<String, dynamic> carga) async {
    final mudou = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidatosPage(
          cargaId: carga['id'],
          cargaTitulo: carga['titulo']?.toString() ?? 'Carga',
        ),
      ),
    );
    if (mudou == true) _carregarCargas();
  }

  Future<void> _finalizar(Map<String, dynamic> carga) async {
    final ok = await appConfirmar(
      context,
      titulo: 'Finalizar entrega?',
      mensagem: 'Confirmar que "${carga['titulo']}" foi entregue? '
          'Depois disso você poderá avaliar o motorista.',
      confirmar: 'Finalizar',
    );
    if (!ok || !mounted) return;

    final sucesso = await ApiService.finalizarCarga(carga['id']);
    if (!mounted) return;
    if (sucesso) {
      AppSnack.success(context, 'Entrega finalizada!');
      _carregarCargas();
    } else {
      AppSnack.error(context, 'Não foi possível finalizar a entrega.');
    }
  }

  Future<void> _avaliar(Map<String, dynamic> carga) async {
    final feito = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvaliarMotoristaPage(
          cargaId: carga['id'],
          caminhoneiroId: carga['motorista_alocado'],
          caminhoneiroNome: carga['motorista_nome']?.toString() ?? 'Motorista',
        ),
      ),
    );
    if (feito == true) _carregarCargas();
  }

  @override
  Widget build(BuildContext context) {
    final status = AppStatusColors.of(context);
    final cs = Theme.of(context).colorScheme;

    final faturamento = _cargas.fold<double>(
      0,
      (soma, c) =>
          soma + (double.tryParse(c['valor_bruto_frete']?.toString() ?? '') ?? 0),
    );

    return Scaffold(
<<<<<<< HEAD
      appBar: AppBar(
        title: const AppBrandMark(subtitle: 'Painel da empresa'),
        titleSpacing: AppSpacing.lg,
        actions: [
          IconButton(
            icon: const Icon(Icons.business_outlined),
            tooltip: 'Meu perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PerfilEmpresaPage()),
=======
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, inner) => [
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            actions: [
              IconButton(
                icon: const Icon(Icons.business_outlined),
                tooltip: 'Meu perfil',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilEmpresaPage()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Sair',
                onPressed: () async {
                  await ApiService.logout();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (r) => false);
                  }
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo!',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'Painel de controle',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      Icons.business,
                      size: 100,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.onPrimaryContainer,
                unselectedLabelColor:
                    colorScheme.onPrimaryContainer.withOpacity(0.6),
                indicatorColor: colorScheme.onPrimaryContainer,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Ativas (${_ativas.length})'),
                  Tab(text: 'Em Trânsito (${_emTransito.length})'),
                  Tab(text: 'Concluídas (${_finalizadas.length})'),
                ],
              ),
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
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
            Tab(text: 'Ativas (${_ativas.length})'),
            Tab(text: 'Em trânsito (${_emTransito.length})'),
            Tab(text: 'Concluídas (${_finalizadas.length})'),
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
                    label: 'Total de cargas',
                    value: '${_cargas.length}',
                    icon: Icons.inventory_2_outlined,
                    color: cs.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppMetricTile(
                    label: 'Em trânsito',
                    value: '${_emTransito.length}',
                    icon: Icons.local_shipping_outlined,
                    color: status.info,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppMetricTile(
                    label: 'Faturamento',
                    value: Fmt.brlCompacto(faturamento),
                    icon: Icons.attach_money,
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
                          title: 'Falha ao carregar as cargas',
                          detail: 'Servidor: ${ApiService.baseUrl}',
                          onRetry: _carregarCargas,
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _lista(_ativas, 'Nenhuma carga ativa',
                                'Publique uma carga para receber candidatos.'),
                            _lista(_emTransito, 'Nenhuma carga em trânsito',
                                'As cargas com motorista alocado aparecem aqui.'),
                            _lista(_finalizadas, 'Nenhuma carga concluída',
                                'O histórico de entregas aparece aqui.'),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final atualizar = await Navigator.pushNamed(context, '/novaCarga');
          if (atualizar == true) _carregarCargas();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova carga'),
      ),
    );
  }

  Widget _lista(List<dynamic> lista, String vazioTitulo, String vazioMensagem) {
    if (lista.isEmpty) {
      return AppEmptyState(
        icon: Icons.inbox_outlined,
        title: vazioTitulo,
        message: vazioMensagem,
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarCargas,
      child: ListView.separated(
        padding: AppSpacing.list,
        itemCount: lista.length,
<<<<<<< HEAD
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => _CargaEmpresaCard(
=======
        itemBuilder: (ctx, i) => _EmpresaCargaCard(
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
          carga: lista[i],
          onVerCandidatos: () => _verCandidatos(lista[i]),
          onFinalizar: () => _finalizar(lista[i]),
          onAvaliar: () => _avaliar(lista[i]),
<<<<<<< HEAD
=======
        ),
      ),
    );
  }
}

// ─── Chip de estatística ──────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatChip(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
            Text(label,
                style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10)),
          ],
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
        ),
      ),
    );
  }
}

/// Card de carga na visão da empresa.
class _CargaEmpresaCard extends StatelessWidget {
  final Map<String, dynamic> carga;
  final VoidCallback onVerCandidatos;
  final VoidCallback onFinalizar;
  final VoidCallback onAvaliar;

<<<<<<< HEAD
  const _CargaEmpresaCard({
=======
  const _EmpresaCargaCard({
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
    required this.carga,
    required this.onVerCandidatos,
    required this.onFinalizar,
    required this.onAvaliar,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final visual = statusCarga(context, carga['status']?.toString());
    final motorista = carga['motorista_nome'] as String?;

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
                AppStatusChip(
                  label: visual.label,
                  color: visual.color,
                  icon: visual.icon,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            AppRouteLine(
              origem: carga['origem']?.toString() ?? '—',
              destino: carga['destino']?.toString() ?? '—',
              distancia: Fmt.km(carga['distancia_km']),
            ),

            if (motorista != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Motorista: $motorista',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

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
                        color: cs.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
<<<<<<< HEAD
                _acao(context),
=======
                _buildAcao(context, status),
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
              ],
            ),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _acao(BuildContext context) {
    final status = AppStatusColors.of(context);

    switch (carga['status']) {
=======
  Widget _buildAcao(BuildContext context, String status) {
    final style = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 12),
    );

    if (status == 'disponivel') {
      final n = carga['total_candidaturas'] ?? 0;
      return FilledButton.tonalIcon(
        onPressed: onVerCandidatos,
        icon: const Icon(Icons.people_outline, size: 16),
        label: Text('Candidatos ($n)'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    if (status == 'em_transito') {
      return FilledButton.icon(
        onPressed: onFinalizar,
        icon: const Icon(Icons.check_circle_outline, size: 16),
        label: const Text('Finalizar'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    // finalizado
    final temMotorista = carga['motorista_alocado'] != null;
    final avaliado = carga['motorista_avaliado'] == true;
    if (temMotorista && !avaliado) {
      return FilledButton.icon(
        onPressed: onAvaliar,
        icon: const Icon(Icons.star_outline, size: 16),
        label: const Text('Avaliar'),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE8A020),
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (temMotorista && avaliado) {
      return const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.verified, size: 16, color: Colors.green),
        SizedBox(width: 4),
        Text('Avaliado', style: TextStyle(color: Colors.green, fontSize: 12)),
      ]);
    }
    return OutlinedButton(onPressed: null, style: style, child: const Text('Concluído'));
  }

  (String, Color) _statusInfo(String status, ColorScheme cs) {
    switch (status) {
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
      case 'disponivel':
        final n = carga['total_candidaturas'] ?? 0;
        return FilledButton.tonalIcon(
          onPressed: onVerCandidatos,
          icon: const Icon(Icons.people_outline, size: 16),
          label: Text('Candidatos ($n)'),
          style: AppCompactButton.style,
        );

      case 'em_transito':
        return FilledButton.icon(
          onPressed: onFinalizar,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Finalizar'),
          style: AppCompactButton.style,
        );

      default:
        final temMotorista = carga['motorista_alocado'] != null;
        final avaliado = carga['motorista_avaliado'] == true;

        if (temMotorista && !avaliado) {
          return FilledButton.icon(
            onPressed: onAvaliar,
            icon: const Icon(Icons.star_outline, size: 16),
            label: const Text('Avaliar'),
            style: AppCompactButton.style,
          );
        }
        if (temMotorista && avaliado) {
          return AppStatusChip(
            label: 'Avaliado',
            color: status.success,
            icon: Icons.verified,
          );
        }
        return AppStatusChip(
          label: 'Concluído',
          color: status.success,
          icon: Icons.check_circle_outline,
        );
    }
  }
}
