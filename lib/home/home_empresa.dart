import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
  setState(() { _carregando = true; _erro = null; });
  try {
    final lista = await ApiService.listarCargasEmpresa();
    if (mounted) setState(() => _cargas = lista);
  } catch (e, stack) {
    print('ERRO: $e');        // ← abre F12 → Console para ver
    print('STACK: $stack');
    if (mounted) setState(() => _erro = e.toString());
  } finally {
    if (mounted) setState(() => _carregando = false);
  }
}

  List<dynamic> get _ativas =>
      _cargas.where((c) => c['status'] == 'disponivel').toList();
  List<dynamic> get _emTransito =>
      _cargas.where((c) => c['status'] == 'em_transito').toList();
  List<dynamic> get _finalizadas =>
      _cargas.where((c) => c['status'] == 'finalizado').toList();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
            ),
          ),
        ],
        body: Column(
          children: [
            // ── Resumo numérico ───────────────────────────────────────────
            _buildResumo(colorScheme, textTheme),

            // ── Conteúdo das tabs ─────────────────────────────────────────
            Expanded(
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _erro != null
                      ? _buildErro()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildListaCargas(_ativas, colorScheme),
                            _buildListaCargas(_emTransito, colorScheme),
                            _buildListaCargas(_finalizadas, colorScheme),
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
      label: const Text('Nova Carga'),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
    );
  }

  Widget _buildResumo(ColorScheme cs, TextTheme tt) {
    final totalValor = _cargas.fold<double>(
        0,
        (sum, c) =>
            sum + (double.tryParse(c['valor_bruto_frete']?.toString() ?? '0') ?? 0));

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          _StatChip(
            label: 'Total cargas',
            value: '${_cargas.length}',
            icon: Icons.inventory_2_outlined,
            color: cs.primary,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Em trânsito',
            value: '${_emTransito.length}',
            icon: Icons.local_shipping_outlined,
            color: Colors.orange,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Faturamento',
            value: 'R\$ ${(totalValor / 1000).toStringAsFixed(1)}k',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildErro() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Falha ao carregar cargas',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(ApiService.baseUrl,
              style:
                  const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _carregarCargas,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildListaCargas(List<dynamic> lista, ColorScheme cs) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text('Nenhuma carga nesta categoria',
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarCargas,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: lista.length,
        itemBuilder: (ctx, i) => _EmpresaCargaCard(carga: lista[i]),
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
        ),
      ),
    );
  }
}

// ─── Card de carga da empresa ─────────────────────────────────────────────
class _EmpresaCargaCard extends StatelessWidget {
  final Map<String, dynamic> carga;

  const _EmpresaCargaCard({required this.carga});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final titulo = carga['titulo'] ?? 'Sem título';
    final origem = carga['origem'] ?? '—';
    final destino = carga['destino'] ?? '—';
    final status = carga['status'] ?? 'disponivel';
    final distancia =
        (carga['distancia_km'] as num?)?.toStringAsFixed(0) ?? '—';
    final valor = double.tryParse(
            carga['valor_bruto_frete']?.toString() ?? '0') ??
        0.0;
    final motorista = carga['motorista_nome'] as String?;

    final (statusLabel, statusColor) = _statusInfo(status, colorScheme);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha 1: título + status
            Row(
              children: [
                Expanded(
                  child: Text(titulo,
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Linha 2: rota
            Row(
              children: [
                const Icon(Icons.radio_button_checked,
                    size: 14, color: Colors.green),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(origem,
                        style: textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Text('$distancia km',
                    style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(Icons.location_on, size: 14, color: Colors.red),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(destino,
                        style: textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end)),
              ],
            ),

            if (motorista != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 13, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Motorista: $motorista',
                      style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Linha 3: valor + ações
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('VALOR BRUTO',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 9,
                            letterSpacing: 1)),
                    Text(
                      'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 15),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Abrir detalhes')),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('Detalhes'),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusInfo(String status, ColorScheme cs) {
    switch (status) {
      case 'disponivel':
        return ('Disponível', Colors.orange);
      case 'em_transito':
        return ('Em Trânsito', Colors.blue);
      case 'finalizado':
        return ('Concluído', Colors.green);
      default:
        return (status, cs.onSurfaceVariant);
    }
  }
}
