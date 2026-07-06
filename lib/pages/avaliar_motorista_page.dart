import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/star_rating.dart';

/// Tela onde a empresa avalia o motorista após a entrega (0-5 estrelas + comentário).
class AvaliarMotoristaPage extends StatefulWidget {
  final int cargaId;
  final int caminhoneiroId;
  final String caminhoneiroNome;

  const AvaliarMotoristaPage({
    super.key,
    required this.cargaId,
    required this.caminhoneiroId,
    required this.caminhoneiroNome,
  });

  @override
  State<AvaliarMotoristaPage> createState() => _AvaliarMotoristaPageState();
}

class _AvaliarMotoristaPageState extends State<AvaliarMotoristaPage> {
  int _nota = 5;
  final _comentarioCtrl = TextEditingController();
  bool _noPrazo = true;
  bool _cuidado = true;
  bool _enviando = false;

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      final res = await ApiService.avaliarMotorista(
        caminhoneiroId: widget.caminhoneiroId,
        cargaId: widget.cargaId,
        nota: _nota,
        comentario: _comentarioCtrl.text.trim(),
        entregaNoPrazo: _noPrazo,
        cuidadoComCarga: _cuidado,
      );
      if (!mounted) return;
      if (res['statusCode'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Avaliação registrada! Obrigado.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context, true);
      } else {
        final body = res['body'];
        final msg = body is Map ? body.values.first.toString() : body.toString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  static const _labels = ['', 'Péssimo', 'Ruim', 'Regular', 'Bom', 'Excelente'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avaliar motorista'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Text(widget.caminhoneiroNome,
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text('Como foi a entrega?',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ),
          const SizedBox(height: 20),

          StarRatingInput(value: _nota, onChanged: (v) => setState(() => _nota = v)),
          Center(
            child: Text(_labels[_nota],
                style: tt.titleMedium?.copyWith(
                    color: cs.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _comentarioCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Comentário',
              hintText: 'Conte como foi trabalhar com este motorista…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),

          SwitchListTile(
            value: _noPrazo,
            onChanged: (v) => setState(() => _noPrazo = v),
            title: const Text('Entregou no prazo'),
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: _cuidado,
            onChanged: (v) => setState(() => _cuidado = v),
            title: const Text('Cuidou bem da carga'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _enviando ? null : _enviar,
            icon: _enviando
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send),
            label: Text(_enviando ? 'Enviando…' : 'Enviar avaliação'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ],
      ),
    );
  }
}
