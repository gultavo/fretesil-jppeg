import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_ui.dart';
import '../widgets/star_rating.dart';
import 'perfil_motorista_page.dart';

/// A empresa vê os motoristas candidatos a uma carga e aceita/recusa
/// com base no perfil de cada um.
class CandidatosPage extends StatefulWidget {
  final int cargaId;
  final String cargaTitulo;

  const CandidatosPage({
    super.key,
    required this.cargaId,
    required this.cargaTitulo,
  });

  @override
  State<CandidatosPage> createState() => _CandidatosPageState();
}

class _CandidatosPageState extends State<CandidatosPage> {
  List<dynamic> _candidatos = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await ApiService.candidatosDaCarga(widget.cargaId);
      if (mounted) setState(() => _candidatos = lista);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _aceitar(dynamic c) async {
    final ok = await appConfirmar(
      context,
      titulo: 'Aceitar ${c['caminhoneiro_nome']}?',
      mensagem: 'Este motorista será alocado para a carga e os demais '
          'candidatos serão recusados.',
      confirmar: 'Aceitar',
    );
    if (!ok || !mounted) return;

    final res = await ApiService.aceitarCandidatura(c['id']);
    if (!mounted) return;
    if (res['statusCode'] == 200) {
      AppSnack.success(context, 'Motorista aceito!');
      Navigator.pop(context, true);
    } else {
      AppSnack.error(context, 'Não foi possível aceitar: ${res['body']}');
    }
  }

  Future<void> _recusar(dynamic c) async {
    final ok = await appConfirmar(
      context,
      titulo: 'Recusar candidatura?',
      mensagem: '${c['caminhoneiro_nome']} não será alocado para esta carga.',
      confirmar: 'Recusar',
      destrutivo: true,
    );
    if (!ok || !mounted) return;

    final sucesso = await ApiService.recusarCandidatura(c['id']);
    if (!mounted) return;
    if (sucesso) {
      setState(() => _candidatos.remove(c));
      AppSnack.info(context, 'Candidatura recusada.');
    } else {
      AppSnack.error(context, 'Não foi possível recusar a candidatura.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Candidatos')),
      body: AppBody(
        child: _carregando
            ? const AppLoading()
            : _erro != null
                ? AppErrorState(detail: _erro, onRetry: _carregar)
                : Column(
                    children: [
                      // Cabeçalho com a carga em questão
                      Container(
                        width: double.infinity,
                        color: cs.surface,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CARGA',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.cargaTitulo,
                              style: tt.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: cs.outlineVariant),
                      Expanded(
                        child: _candidatos.isEmpty
                            ? const AppEmptyState(
                                icon: Icons.people_outline,
                                title: 'Nenhum candidato ainda',
                                message:
                                    'Motoristas interessados aparecerão aqui.',
                              )
                            : RefreshIndicator(
                                onRefresh: _carregar,
                                child: ListView.separated(
                                  padding: AppSpacing.list,
                                  itemCount: _candidatos.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: AppSpacing.md),
                                  itemBuilder: (_, i) =>
                                      _card(_candidatos[i]),
                                ),
                              ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _card(dynamic c) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);

    final foto = ApiService.mediaUrl(c['caminhoneiro_foto']);
    final nota = (c['caminhoneiro_media'] as num?)?.toDouble() ?? 0.0;
    final total = c['caminhoneiro_total_avaliacoes'] ?? 0;
    final diamante = c['caminhoneiro_diamante'] == true;
    final cidade = c['caminhoneiro_cidade']?.toString() ?? '';
    final mensagem = c['mensagem']?.toString() ?? '';

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  radius: 28,
                  image: foto != null ? NetworkImage(foto) : null,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c['caminhoneiro_nome']?.toString() ?? '—',
                              style: tt.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (diamante) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Icon(Icons.diamond, size: 15, color: status.info),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          StarRatingDisplay(nota: nota, size: 15),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${Fmt.nota(nota)} ($total)',
                            style: tt.bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                      if (cidade.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          cidade,
                          style: tt.bodySmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
                child: Text(
                  mensagem,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PerfilMotoristaPage(
                        motoristaId: c['caminhoneiro'],
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Ver perfil'),
                  style: AppCompactButton.outlined,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _recusar(c),
                  style: AppCompactButton.text
                      .copyWith(foregroundColor: WidgetStatePropertyAll(cs.error)),
                  child: const Text('Recusar'),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: () => _aceitar(c),
                  style: AppCompactButton.style,
                  child: const Text('Aceitar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
