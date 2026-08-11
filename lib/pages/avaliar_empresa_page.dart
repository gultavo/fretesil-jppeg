import 'package:flutter/material.dart';
<<<<<<< HEAD

import '../services/api_service.dart';
import 'avaliacao_form.dart';

/// Tela onde o motorista avalia a empresa após a entrega.
///
/// A estrutura visual vem de [AvaliacaoForm], compartilhada com
/// `AvaliarMotoristaPage`.
class AvaliarEmpresaPage extends StatelessWidget {
=======
import '../services/api_service.dart';
import '../widgets/star_rating.dart';

/// Tela onde o motorista avalia a empresa após a entrega (0-5 estrelas + comentário).
class AvaliarEmpresaPage extends StatefulWidget {
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
  final int cargaId;
  final String empresaNome;

  const AvaliarEmpresaPage({
    super.key,
    required this.cargaId,
    required this.empresaNome,
  });

  @override
<<<<<<< HEAD
  Widget build(BuildContext context) {
    return AvaliacaoForm(
      titulo: 'Avaliar empresa',
      avaliado: empresaNome,
      pergunta: 'Como foi carregar com esta empresa?',
      hintComentario: 'Conte como foi o carregamento, o pátio, a espera…',
      rotuloOpcaoA: 'Banheiro limpo',
      rotuloOpcaoB: 'Local seguro',
      onEnviar: ({
        required int nota,
        required String comentario,
        required bool opcaoA,
        required bool opcaoB,
      }) =>
          ApiService.avaliarEmpresa(
        cargaId: cargaId,
        nota: nota,
        comentario: comentario,
        temBanheiroLimpo: opcaoA,
        localSeguro: opcaoB,
=======
  State<AvaliarEmpresaPage> createState() => _AvaliarEmpresaPageState();
}

class _AvaliarEmpresaPageState extends State<AvaliarEmpresaPage> {
  static const _bg = Color(0xFF1A1D23);
  static const _card = Color(0xFF23272F);
  static const _accent = Color(0xFFE8A020);
  static const _textPrimary = Color(0xFFE8E0CC);
  static const _textMuted = Color(0xFF8A8070);

  int _nota = 5;
  final _comentarioCtrl = TextEditingController();
  bool _banheiroLimpo = true;
  bool _localSeguro = true;
  bool _enviando = false;

  static const _labels = ['', 'Péssimo', 'Ruim', 'Regular', 'Bom', 'Excelente'];

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      final res = await ApiService.avaliarEmpresa(
        cargaId: widget.cargaId,
        nota: _nota,
        comentario: _comentarioCtrl.text.trim(),
        temBanheiroLimpo: _banheiroLimpo,
        localSeguro: _localSeguro,
      );
      if (!mounted) return;
      if (res['statusCode'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Avaliação registrada! Obrigado.'),
          backgroundColor: Color(0xFF4CAF7D),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context, true);
      } else {
        final body = res['body'];
        final msg = body is Map ? body.values.first.toString() : body.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Avaliar empresa'),
        backgroundColor: const Color(0xFF0F1115),
        foregroundColor: _textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Text(widget.empresaNome,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: _textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('Como foi carregar com esta empresa?',
                style: TextStyle(color: _textMuted)),
          ),
          const SizedBox(height: 20),
          StarRatingInput(value: _nota, onChanged: (v) => setState(() => _nota = v)),
          Center(
            child: Text(_labels[_nota],
                style: const TextStyle(
                    color: _accent, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 4,
            style: const TextStyle(color: _textPrimary),
            decoration: InputDecoration(
              labelText: 'Comentário',
              hintText: 'Conte como foi o carregamento, o pátio, a espera…',
              labelStyle: const TextStyle(color: _textMuted),
              hintStyle: TextStyle(color: _textMuted.withOpacity(0.6)),
              filled: true,
              fillColor: _card,
              alignLabelWithHint: true,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2E3340)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accent),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _banheiroLimpo,
            onChanged: (v) => setState(() => _banheiroLimpo = v),
            title: const Text('Banheiro limpo', style: TextStyle(color: _textPrimary)),
            activeColor: _accent,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _localSeguro,
            onChanged: (v) => setState(() => _localSeguro = v),
            title: const Text('Local seguro', style: TextStyle(color: _textPrimary)),
            activeColor: _accent,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: _enviando
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _bg))
                : const Icon(Icons.send),
            label: Text(_enviando ? 'Enviando…' : 'Enviar avaliação'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: _bg,
              minimumSize: const Size.fromHeight(52),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
      ),
    );
  }
}
