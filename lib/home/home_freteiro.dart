import 'package:flutter/material.dart';

import '../pages/avaliar_empresa_page.dart';
import '../pages/perfil_empresa_page.dart';
import '../pages/perfil_motorista_page.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/status_labels.dart';
import '../utils/tipo_carreta.dart';
import '../widgets/app_ui.dart';

/// Painel do caminhoneiro.
///
/// A tela é propositalmente enxuta: textos e botões grandes, uma ação
/// principal por vez e nada de números soltos na parte de cima — boa parte
/// dos motoristas usa o app na estrada e tem mais de 50 anos.
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
  bool _executandoAcao = false;
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

  List<dynamic> get _aAvaliar =>
      _entregas.where((e) => e['empresa_avaliada'] != true).toList();

  // ─── Ações ──────────────────────────────────────────────────────────────
  Future<void> _candidatar(Map<String, dynamic> carga) async {
    final ok = await appConfirmar(
      context,
      titulo: 'Quer esta carga?',
      mensagem: '${carga['titulo']}\n'
          '${carga['origem']} → ${carga['destino']}\n\n'
          'A empresa vai olhar seu perfil e responder.',
      confirmar: 'Quero',
    );
    if (!ok || !mounted) return;

    final res = await ApiService.candidatarCarga(carga['id']);
    if (!mounted) return;

    if (res['statusCode'] == 201) {
      AppSnack.success(context, 'Pedido enviado! Aguarde a resposta.');
      _carregarTudo();
    } else {
      final body = res['body'];
      AppSnack.error(
        context,
        body is Map && body['erro'] != null
            ? body['erro'].toString()
            : 'Não foi possível pedir esta carga.',
      );
    }
  }

  /// Executa uma ação da viagem (aceitar, iniciar, cancelar) e recarrega.
  Future<void> _acaoViagem(
    Future<Map<String, dynamic>> Function(int id) chamada,
    Map<String, dynamic> carga,
    String sucesso,
  ) async {
    setState(() => _executandoAcao = true);
    try {
      final res = await chamada(carga['id']);
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        AppSnack.success(context, sucesso);
        await _carregarTudo();
      } else {
        final body = res['body'];
        AppSnack.error(
          context,
          body is Map && body['erro'] != null
              ? body['erro'].toString()
              : 'Não foi possível concluir a ação.',
        );
      }
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Erro de conexão. Tente de novo.');
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
  }

  Future<void> _aceitarCarga(Map<String, dynamic> c) async {
    final ok = await appConfirmar(
      context,
      titulo: 'Aceitar esta carga?',
      mensagem: '${c['titulo']}\n'
          '${c['origem']} → ${c['destino']}\n\n'
          'Depois de aceitar, o próximo passo é buscar a carreta.',
      confirmar: 'Aceitar',
    );
    if (!ok || !mounted) return;
    await _acaoViagem(ApiService.aceitarCarga, c, 'Carga aceita! Boa viagem.');
  }

  Future<void> _iniciarViagem(Map<String, dynamic> c) async {
    final ok = await appConfirmar(
      context,
      titulo: 'Já acoplou a carreta?',
      mensagem: 'Confirme só depois de engatar a carreta e sair para a '
          'estrada. A carga passa para "Em trânsito".',
      confirmar: 'Sim, já acoplei',
    );
    if (!ok || !mounted) return;
    await _acaoViagem(
      ApiService.iniciarViagem,
      c,
      'Carga em trânsito. Boa viagem!',
    );
  }

  Future<void> _cancelarViagem(Map<String, dynamic> c) async {
    final emTransito = c['status'] == 'em_transito';

    final ok = await appConfirmar(
      context,
      titulo: emTransito ? 'ATENÇÃO: carga em trânsito' : 'Cancelar a viagem?',
      mensagem: emTransito
          ? 'A carga já está na estrada.\n\n'
              'Cancelando agora, ela precisará de RECONDICIONAMENTO: a carreta '
              'terá de ser devolvida e a carga descarregada e reacomodada — os '
              'custos e o prejuízo podem ser cobrados de você, e a empresa será '
              'avisada.\n\n'
              'Só continue se for mesmo necessário.'
          : 'A carga voltará para a lista e outro motorista poderá pegá-la.',
      confirmar: emTransito ? 'Cancelar mesmo assim' : 'Cancelar viagem',
      cancelar: 'Voltar',
      destrutivo: true,
    );
    if (!ok || !mounted) return;
    await _acaoViagem(
      ApiService.cancelarViagem,
      c,
      'Viagem cancelada.',
    );
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

  void _abrirMeuPerfil() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PerfilMotoristaPage()),
      );

  // ─── Tela ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = AppStatusColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const AppBrandMark(subtitle: 'Motorista'),
        titleSpacing: AppSpacing.lg,
        actions: [
          TextButton.icon(
            onPressed: _abrirMeuPerfil,
            icon: const Icon(Icons.person, size: 22),
            label: const Text('Perfil'),
            style: TextButton.styleFrom(
              foregroundColor: cs.primary,
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sair',
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (r) => false);
              }
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          unselectedLabelStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          tabs: [
            const Tab(text: 'Cargas'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Minha viagem'),
                  if (_cargaAtiva != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: status.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Meus pedidos'),
          ],
        ),
      ),
      body: AppBody(
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
                      _abaPedidos(),
                    ],
                  ),
      ),
    );
  }

  // ─── Aba 1: cargas disponíveis ──────────────────────────────────────────
  Widget _abaDisponiveis() {
    if (_disponiveis.isEmpty) {
      return const AppEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Nenhuma carga agora',
        message: 'Puxe a tela para baixo para procurar de novo.',
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarTudo,
      child: ListView.separated(
        padding: AppSpacing.list,
        itemCount: _disponiveis.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (_, i) => _CargaDisponivelCard(
          carga: _disponiveis[i],
          onPedir: () => _candidatar(_disponiveis[i]),
        ),
      ),
    );
  }

  // ─── Aba 2: viagem em andamento ─────────────────────────────────────────
  Widget _abaViagem() {
    if (_cargaAtiva == null && _aAvaliar.isEmpty) {
      return const AppEmptyState(
        icon: Icons.local_shipping_outlined,
        title: 'Você não tem viagem agora',
        message: 'Escolha uma carga na aba "Cargas".',
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarTudo,
      child: ListView(
        padding: AppSpacing.list,
        children: [
          if (_cargaAtiva != null) _viagemAtiva(_cargaAtiva!),
          if (_aAvaliar.isNotEmpty) ...[
            if (_cargaAtiva != null) const SizedBox(height: AppSpacing.xxxl),
            const AppSectionHeader(
              label: 'Avalie suas entregas',
              icon: Icons.star_outline,
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
    final status = AppStatusColors.of(context);
    final visual = statusCarga(context, c['status']?.toString());
    final localCarreta = c['local_carreta']?.toString().trim() ?? '';
    final acoplando = c['status'] == 'acoplar_carreta';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Etapa atual, em letras grandes
        AppInfoBanner(
          texto: instrucaoViagem(c['status']?.toString()),
          icone: visual.icon,
          cor: visual.color,
          tamanhoTexto: 17,
        ),
        const SizedBox(height: AppSpacing.lg),

        _LinhaDoTempo(status: c['status']?.toString()),
        const SizedBox(height: AppSpacing.xl),

        Text(
          c['titulo']?.toString() ?? '—',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: () => _verPerfilEmpresa(c['empresa']),
          borderRadius: AppRadius.brTag,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Icon(Icons.business_outlined,
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    c['empresa_nome']?.toString() ?? '—',
                    style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                  ),
                ),
                Icon(Icons.chevron_right, size: 22, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Onde buscar a carreta — só aparece na etapa de acoplagem
        if (acoplando && localCarreta.isNotEmpty) ...[
          Card(
            child: Padding(
              padding: AppSpacing.card,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.rv_hookup_outlined, size: 28, color: status.brand),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'A CARRETA ESTÁ EM',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          localCarreta,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Rota da viagem, em letras grandes
        AppRouteBlock(
          origem: c['origem']?.toString() ?? '—',
          destino: c['destino']?.toString() ?? '—',
          empresaDestino: c['empresa_destino']?.toString(),
          distancia: Fmt.km(c['distancia_km']),
          ampliado: true,
        ),
        const SizedBox(height: AppSpacing.lg),

        AppDetailList(
          itens: [
            (
              TipoCarreta.iconeDe(c),
              'Carreta',
              TipoCarreta.labelDe(c),
            ),
            (
              Icons.payments_outlined,
              'Valor bruto',
              Fmt.brl(c['valor_bruto_frete']),
            ),
            (
              Icons.percent,
              'Comissão',
              Fmt.brl(c['comissao_app']),
            ),
            (
              Icons.toll_outlined,
              'Pedágio',
              Fmt.brl(c['estimativa_pedagio']),
            ),
            if (c['financeiro'] is Map) ...[
              (
                Icons.local_gas_station_outlined,
                'Combustível',
                Fmt.brl(c['financeiro']['combustivel']),
              ),
              (
                Icons.trending_up,
                'Lucro estimado',
                Fmt.brl(c['financeiro']['lucro_estimado']),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        ..._botoesDaEtapa(c),
      ],
    );
  }

  /// Botão grande da etapa atual + o cancelamento, sempre por último.
  List<Widget> _botoesDaEtapa(Map<String, dynamic> c) {
    final status = AppStatusColors.of(context);
    final s = c['status']?.toString();

    return [
      if (s == 'aguardando_aceite')
        AppPrimaryButton(
          label: 'ACEITAR CARGA',
          loadingLabel: 'Aceitando…',
          icon: Icons.check_circle_outline,
          grande: true,
          cor: status.success,
          loading: _executandoAcao,
          onPressed: _executandoAcao ? null : () => _aceitarCarga(c),
        ),
      if (s == 'acoplar_carreta')
        AppPrimaryButton(
          label: 'JÁ ACOPLEI — SAIR PARA A ESTRADA',
          loadingLabel: 'Registrando…',
          icon: Icons.local_shipping_outlined,
          grande: true,
          loading: _executandoAcao,
          onPressed: _executandoAcao ? null : () => _iniciarViagem(c),
        ),
      if (s == 'em_transito')
        AppInfoBanner(
          texto: 'Ao chegar, a empresa confirma a entrega e a viagem é '
              'concluída.',
          icone: Icons.flag_outlined,
          cor: status.info,
        ),
      const SizedBox(height: AppSpacing.lg),
      OutlinedButton.icon(
        onPressed: _executandoAcao ? null : () => _cancelarViagem(c),
        icon: const Icon(Icons.do_not_disturb_on_outlined, size: 22),
        label: const Text('Cancelar viagem'),
        style: OutlinedButton.styleFrom(
          foregroundColor: status.danger,
          side: BorderSide(color: status.danger.withValues(alpha: 0.6)),
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      if (c['status'] == 'em_transito') ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Cancelar com a carga na estrada gera recondicionamento da carga.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: status.danger),
        ),
      ],
    ];
  }

  Widget _entregaCard(dynamic e) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              e['titulo']?.toString() ?? 'Entrega',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              e['empresa_nome']?.toString() ?? '—',
              style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _avaliarEmpresa(e),
              icon: const Icon(Icons.star_outline, size: 22),
              label: const Text('Avaliar a empresa'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Aba 3: meus pedidos ────────────────────────────────────────────────
  Widget _abaPedidos() {
    if (_candidaturas.isEmpty) {
      return const AppEmptyState(
        icon: Icons.assignment_outlined,
        title: 'Você ainda não pediu nenhuma carga',
        message: 'Escolha uma carga na aba "Cargas".',
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarTudo,
      child: ListView.separated(
        padding: AppSpacing.list,
        itemCount: _candidaturas.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, i) => _PedidoCard(candidatura: _candidaturas[i]),
      ),
    );
  }
}

/// Linha do tempo da viagem: acoplar → em trânsito → concluída.
class _LinhaDoTempo extends StatelessWidget {
  final String? status;

  const _LinhaDoTempo({required this.status});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cores = AppStatusColors.of(context);
    final atual = indiceEtapa(status);

    return Row(
      children: [
        for (var i = 0; i < etapasViagem.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                color: i <= atual ? cores.success : cs.outlineVariant,
              ),
            ),
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= atual
                      ? cores.success.withValues(alpha: 0.15)
                      : cs.surfaceContainerLow,
                  border: Border.all(
                    color: i <= atual ? cores.success : cs.outlineVariant,
                    width: 2,
                  ),
                ),
                child: Icon(
                  etapasViagem[i].icone,
                  size: 22,
                  color: i <= atual ? cores.success : cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                width: 92,
                child: Text(
                  etapasViagem[i].titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == atual ? FontWeight.w800 : FontWeight.w500,
                    color: i <= atual ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Card de carga aberta, na visão do motorista — grande e direto ao ponto.
class _CargaDisponivelCard extends StatelessWidget {
  final Map<String, dynamic> carga;
  final VoidCallback onPedir;

  const _CargaDisponivelCard({required this.carga, required this.onPedir});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = AppStatusColors.of(context);
    final notaMin = (carga['nota_minima_motorista'] as num?)?.toDouble() ?? 0;
    final empresaDestino = carga['empresa_destino']?.toString().trim() ?? '';

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              carga['titulo']?.toString() ?? 'Sem título',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.business_outlined,
                    size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    carga['empresa_nome']?.toString() ?? '—',
                    style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppStatusChip(
                  label: TipoCarreta.labelDe(carga),
                  color: status.info,
                  icon: TipoCarreta.iconeDe(carga),
                ),
                if (notaMin > 0)
                  AppStatusChip(
                    label: 'Nota mínima ${Fmt.nota(notaMin)}',
                    color: status.brand,
                    icon: Icons.star_rounded,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _ponto(context, Icons.radio_button_checked, 'De', status.success,
                carga['origem']?.toString() ?? '—'),
            const SizedBox(height: AppSpacing.sm),
            _ponto(context, Icons.location_on, 'Para', status.danger,
                carga['destino']?.toString() ?? '—'),
            if (empresaDestino.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  'Descarregar em $empresaDestino',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: AppSpacing.md),

            Row(
              children: [
                Expanded(
                  child: _valor(context, 'DISTÂNCIA',
                      Fmt.km(carga['distancia_km']), status.info),
                ),
                Expanded(
                  child: carga['lucro_estimado'] != null
                      ? _valor(context, 'LUCRO ESTIMADO',
                          Fmt.brl(carga['lucro_estimado']), status.success)
                      : _valor(context, 'VALOR BRUTO',
                          Fmt.brl(carga['valor_bruto_frete']), status.success),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            AppPrimaryButton(
              label: 'QUERO ESTA CARGA',
              icon: Icons.how_to_reg_outlined,
              grande: true,
              onPressed: onPedir,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ponto(BuildContext context, IconData icone, String rotulo, Color cor,
      String valor) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 22, color: cor),
        const SizedBox(width: AppSpacing.md),
        Text(
          '$rotulo ',
          style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
        ),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _valor(BuildContext context, String rotulo, String valor, Color cor) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: TextStyle(
            color: cor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Card de acompanhamento de um pedido de carga.
class _PedidoCard extends StatelessWidget {
  final Map<String, dynamic> candidatura;

  const _PedidoCard({required this.candidatura});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visual = statusCandidatura(context, candidatura['status']?.toString());

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              candidatura['carga_titulo']?.toString() ?? 'Carga',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            AppStatusChip(
              label: visual.label,
              color: visual.color,
              icon: visual.icon,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              visual.descricao,
              style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
