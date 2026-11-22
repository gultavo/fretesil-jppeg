import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/status_labels.dart';
import '../utils/tipo_carreta.dart';
import '../widgets/app_ui.dart';
import '../widgets/star_rating.dart';
import 'avaliar_motorista_page.dart';
import 'candidatos_page.dart';
import 'perfil_motorista_page.dart';

/// Detalhe completo de uma carga, na visão da empresa.
///
/// Reúne tudo o que o card da lista não cabe mostrar — rota, carreta, valores,
/// descrição, foto — e, quando há motorista alocado, os dados dele.
/// Devolve `true` ao sair se alguma ação mudou a carga (aceite de candidato,
/// finalização ou avaliação), para o painel recarregar.
class DetalhesCargaPage extends StatefulWidget {
  final Map<String, dynamic> carga;

  const DetalhesCargaPage({super.key, required this.carga});

  @override
  State<DetalhesCargaPage> createState() => _DetalhesCargaPageState();
}

class _DetalhesCargaPageState extends State<DetalhesCargaPage> {
  bool _mudou = false;

  Map<String, dynamic> get _c => widget.carga;

  Future<void> _verCandidatos() async {
    final mudou = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CandidatosPage(
          cargaId: _c['id'],
          cargaTitulo: _c['titulo']?.toString() ?? 'Carga',
        ),
      ),
    );
    if (mudou == true && mounted) {
      _mudou = true;
      Navigator.pop(context, true);
    }
  }

  Future<void> _finalizar() async {
    final ok = await appConfirmar(
      context,
      titulo: 'Finalizar entrega?',
      mensagem: 'Confirmar que "${_c['titulo']}" foi entregue? '
          'Depois disso você poderá avaliar o motorista.',
      confirmar: 'Finalizar',
    );
    if (!ok || !mounted) return;

    final sucesso = await ApiService.finalizarCarga(_c['id']);
    if (!mounted) return;
    if (sucesso) {
      AppSnack.success(context, 'Entrega finalizada!');
      Navigator.pop(context, true);
    } else {
      AppSnack.error(context, 'Não foi possível finalizar a entrega.');
    }
  }

  Future<void> _avaliar() async {
    final feito = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AvaliarMotoristaPage(
          cargaId: _c['id'],
          caminhoneiroId: _c['motorista_alocado'],
          caminhoneiroNome: _c['motorista_nome']?.toString() ?? 'Motorista',
        ),
      ),
    );
    if (feito == true && mounted) {
      _mudou = true;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    final visual = statusCarga(context, _c['status']?.toString());

    final foto = ApiService.mediaUrl(_c['foto_carga']);
    final descricao = _c['descricao']?.toString().trim() ?? '';
    final localCarreta = _c['local_carreta']?.toString().trim() ?? '';
    final notaMin = (_c['nota_minima_motorista'] as num?)?.toDouble() ?? 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _mudou);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Detalhes da carga')),
        body: AppBody(
          child: ListView(
            padding: AppSpacing.page,
            children: [
              if (foto != null) ...[
                ClipRRect(
                  borderRadius: AppRadius.brCard,
                  child: Image.network(
                    foto,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _c['titulo']?.toString() ?? 'Sem título',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AppStatusChip(
                    label: visual.label,
                    color: visual.color,
                    icon: visual.icon,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(TipoCarreta.iconeDe(_c),
                      size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Carreta ${TipoCarreta.labelDe(_c).toLowerCase()}',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Rota ────────────────────────────────────────────────────
              const AppSectionHeader(label: 'Rota', icon: Icons.route_outlined),
              const SizedBox(height: AppSpacing.md),
              AppRouteBlock(
                origem: _c['origem']?.toString() ?? '—',
                destino: _c['destino']?.toString() ?? '—',
                empresaDestino: _c['empresa_destino']?.toString(),
                distancia: Fmt.km(_c['distancia_km']),
              ),
              if (localCarreta.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                AppDetailList(
                  itens: [
                    (Icons.rv_hookup_outlined, 'Carreta em', localCarreta),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // ── Valores ─────────────────────────────────────────────────
              const AppSectionHeader(
                label: 'Valores',
                icon: Icons.attach_money,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  AppMetricTile(
                    label: 'Valor bruto',
                    value: Fmt.brl(_c['valor_bruto_frete']),
                    color: status.success,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppMetricTile(
                    label: 'Pedágio',
                    value: Fmt.brl(_c['estimativa_pedagio']),
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppMetricTile(
                    label: 'Comissão',
                    value: Fmt.brl(_c['comissao_app']),
                    color: cs.primary,
                  ),
                ],
              ),
              if (_c['financeiro'] is Map) ...[
                const SizedBox(height: AppSpacing.md),
                AppDetailList(
                  itens: [
                    (
                      Icons.local_gas_station_outlined,
                      'Combustível',
                      Fmt.brl(_c['financeiro']['combustivel']),
                    ),
                    (
                      Icons.receipt_long_outlined,
                      'Total de despesas',
                      Fmt.brl(_c['financeiro']['despesas']),
                    ),
                    (
                      Icons.trending_up,
                      'Lucro estimado do motorista',
                      Fmt.brl(_c['financeiro']['lucro_estimado']),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              // ── Descrição e requisitos ──────────────────────────────────
              if (descricao.isNotEmpty) ...[
                const AppSectionHeader(
                  label: 'Descrição',
                  icon: Icons.notes_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                AppSection(
                  children: [
                    Text(
                      descricao,
                      style: tt.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              AppDetailList(
                itens: [
                  (
                    Icons.star_half_outlined,
                    'Nota mínima',
                    notaMin > 0 ? Fmt.nota(notaMin) : 'Sem exigência',
                  ),
                  (
                    Icons.people_outline,
                    'Candidatos',
                    '${_c['total_candidaturas'] ?? 0}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Motorista alocado ───────────────────────────────────────
              if (_c['motorista_alocado'] != null) ...[
                const AppSectionHeader(
                  label: 'Motorista da viagem',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: AppSpacing.md),
                _motorista(),
                const SizedBox(height: AppSpacing.xl),
              ],

              _acao(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bloco com os dados do motorista alocado ────────────────────────────
  Widget _motorista() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);

    final foto = ApiService.mediaUrl(_c['motorista_foto']);
    final nota = (_c['motorista_media'] as num?)?.toDouble() ?? 0;
    final total = _c['motorista_total_avaliacoes'] ?? 0;
    final diamante = _c['motorista_diamante'] == true;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: AppSpacing.card,
            child: Row(
              children: [
                AppAvatar(
                  radius: 32,
                  image: foto != null ? NetworkImage(foto) : null,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _c['motorista_nome']?.toString() ?? '—',
                              style: tt.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (diamante) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(Icons.diamond, size: 16, color: status.info),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          StarRatingDisplay(nota: nota, size: 16),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${Fmt.nota(nota)} ($total)',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppDetailList(
          itens: [
            (
              Icons.phone_outlined,
              'Telefone',
              _c['motorista_telefone']?.toString() ?? ''
            ),
            (
              Icons.badge_outlined,
              'Placa',
              _c['motorista_placa']?.toString() ?? ''
            ),
            (
              Icons.local_shipping_outlined,
              'Veículo',
              _c['motorista_veiculo']?.toString() ?? ''
            ),
            (
              Icons.location_city,
              'Cidade',
              _c['motorista_cidade']?.toString() ?? ''
            ),
            (
              Icons.timeline,
              'Experiência',
              _c['motorista_experiencia'] == null
                  ? ''
                  : '${_c['motorista_experiencia']} ano(s)'
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  PerfilMotoristaPage(motoristaId: _c['motorista_alocado']),
            ),
          ),
          icon: const Icon(Icons.visibility_outlined, size: 18),
          label: const Text('Ver perfil completo do motorista'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }

  // ─── Ação principal, conforme a etapa da carga ──────────────────────────
  Widget _acao() {
    final status = AppStatusColors.of(context);

    switch (_c['status']) {
      case 'disponivel':
        return AppPrimaryButton(
          label: 'Ver candidatos (${_c['total_candidaturas'] ?? 0})',
          icon: Icons.people_outline,
          onPressed: _verCandidatos,
        );

      case 'aguardando_aceite':
        return AppInfoBanner(
          texto: 'Aguardando ${_c['motorista_nome'] ?? 'o motorista'} '
              'confirmar a carga.',
          icone: Icons.hourglass_top,
          cor: status.warning,
        );

      case 'acoplar_carreta':
        return AppInfoBanner(
          texto: 'O motorista está indo buscar a carreta. '
              'A entrega poderá ser finalizada quando ele estiver em trânsito.',
          icone: Icons.rv_hookup_outlined,
          cor: status.brand,
        );

      case 'em_transito':
        return AppPrimaryButton(
          label: 'Finalizar entrega',
          icon: Icons.check_circle_outline,
          cor: status.success,
          onPressed: _finalizar,
        );

      default:
        if (_c['motorista_alocado'] != null && _c['motorista_avaliado'] != true) {
          return AppPrimaryButton(
            label: 'Avaliar motorista',
            icon: Icons.star_outline,
            onPressed: _avaliar,
          );
        }
        return AppInfoBanner(
          texto: 'Entrega concluída.',
          icone: Icons.check_circle_outline,
          cor: status.success,
        );
    }
  }
}
