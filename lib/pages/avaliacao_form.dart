import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_ui.dart';
import '../widgets/star_rating.dart';

/// Resultado bruto de uma chamada de avaliação à API.
typedef EnvioAvaliacao = Future<Map<String, dynamic>> Function({
  required int nota,
  required String comentario,
  required bool opcaoA,
  required bool opcaoB,
});

/// Formulário de avaliação usado nas duas pontas (empresa avalia motorista,
/// motorista avalia empresa). As telas só trocam os textos e a chamada de API,
/// então a estrutura visual vive aqui em uma única versão.
class AvaliacaoForm extends StatefulWidget {
  /// Título da barra superior.
  final String titulo;

  /// Nome de quem está sendo avaliado.
  final String avaliado;

  /// Pergunta que aparece sob o nome.
  final String pergunta;

  /// Texto de apoio do campo de comentário.
  final String hintComentario;

  /// Rótulos dos dois critérios de sim/não.
  final String rotuloOpcaoA;
  final String rotuloOpcaoB;

  final EnvioAvaliacao onEnviar;

  const AvaliacaoForm({
    super.key,
    required this.titulo,
    required this.avaliado,
    required this.pergunta,
    required this.hintComentario,
    required this.rotuloOpcaoA,
    required this.rotuloOpcaoB,
    required this.onEnviar,
  });

  @override
  State<AvaliacaoForm> createState() => _AvaliacaoFormState();
}

class _AvaliacaoFormState extends State<AvaliacaoForm> {
  static const _rotulosNota = [
    'Selecione uma nota',
    'Péssimo',
    'Ruim',
    'Regular',
    'Bom',
    'Excelente',
  ];

  int _nota = 5;
  bool _opcaoA = true;
  bool _opcaoB = true;
  bool _enviando = false;
  final _comentarioCtrl = TextEditingController();

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      final res = await widget.onEnviar(
        nota: _nota,
        comentario: _comentarioCtrl.text.trim(),
        opcaoA: _opcaoA,
        opcaoB: _opcaoB,
      );
      if (!mounted) return;

      if (res['statusCode'] == 201) {
        AppSnack.success(context, 'Avaliação registrada. Obrigado!');
        Navigator.pop(context, true);
      } else {
        final body = res['body'];
        AppSnack.error(
          context,
          body is Map && body.isNotEmpty
              ? body.values.first.toString()
              : body.toString(),
        );
      }
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: AppBody(
        child: ListView(
          padding: AppSpacing.page,
          children: [
            const SizedBox(height: AppSpacing.sm),
            AppPageIntro(title: widget.avaliado, subtitle: widget.pergunta),
            const SizedBox(height: AppSpacing.xxl),

            AppSection(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StarRatingInput(
                  value: _nota,
                  onChanged: (v) => setState(() => _nota = v),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _rotulosNota[_nota],
                  style: tt.titleSmall?.copyWith(
                    color: _nota == 0 ? cs.onSurfaceVariant : cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            AppSection(
              title: 'Detalhes',
              children: [
                TextField(
                  controller: _comentarioCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Comentário (opcional)',
                    hintText: widget.hintComentario,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  value: _opcaoA,
                  onChanged: (v) => setState(() => _opcaoA = v),
                  title: Text(widget.rotuloOpcaoA, style: tt.bodyMedium),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: _opcaoB,
                  onChanged: (v) => setState(() => _opcaoB = v),
                  title: Text(widget.rotuloOpcaoB, style: tt.bodyMedium),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            AppPrimaryButton(
              label: 'Enviar avaliação',
              loadingLabel: 'Enviando…',
              icon: Icons.send_outlined,
              loading: _enviando,
              onPressed: _nota == 0 ? null : _enviar,
            ),
          ],
        ),
      ),
    );
  }
}
