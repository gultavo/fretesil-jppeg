import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/star_rating.dart';
import 'perfil_motorista_page.dart';

/// A empresa vê os motoristas candidatos a uma carga e aceita/recusa
/// com base no perfil de cada um.
class CandidatosPage extends StatefulWidget {
  final int cargaId;
  final String cargaTitulo;

  const CandidatosPage({super.key, required this.cargaId, required this.cargaTitulo});

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
    setState(() { _carregando = true; _erro = null; });
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
    final ok = await _confirmar(
      'Aceitar ${c['caminhoneiro_nome']}?',
      'Este motorista será alocado para a carga e os demais candidatos serão recusados.',
    );
    if (ok != true) return;
    final res = await ApiService.aceitarCandidatura(c['id']);
    if (!mounted) return;
    if (res['statusCode'] == 200) {
      _snack('Motorista aceito!', Colors.green);
      Navigator.pop(context, true);
    } else {
      _snack('Erro: ${res['body']}', Colors.red);
    }
  }

  Future<void> _recusar(dynamic c) async {
    final ok = await ApiService.recusarCandidatura(c['id']);
    if (!mounted) return;
    if (ok) {
      setState(() => _candidatos.remove(c));
      _snack('Candidatura recusada.', Colors.orange);
    }
  }

  Future<bool?> _confirmar(String titulo, String msg) => showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(titulo),
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
          ],
        ),
      );

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Candidatos'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text('Erro: $_erro'))
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: cs.surfaceContainerHigh,
                      padding: const EdgeInsets.all(16),
                      child: Text(widget.cargaTitulo,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: _candidatos.isEmpty
                          ? _vazio(cs)
                          : RefreshIndicator(
                              onRefresh: _carregar,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _candidatos.length,
                                itemBuilder: (_, i) => _card(_candidatos[i], cs),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _vazio(ColorScheme cs) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people_outline, size: 56, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text('Nenhum candidato ainda', style: TextStyle(color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          const Text('Motoristas interessados aparecerão aqui.',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      );

  Widget _card(dynamic c, ColorScheme cs) {
    final foto = ApiService.mediaUrl(c['caminhoneiro_foto']);
    final nota = (c['caminhoneiro_media'] as num?)?.toDouble() ?? 0.0;
    final total = c['caminhoneiro_total_avaliacoes'] ?? 0;
    final diamante = c['caminhoneiro_diamante'] == true;
    final cidade = c['caminhoneiro_cidade']?.toString() ?? '';
    final mensagem = c['mensagem']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: cs.surfaceContainerHighest,
              backgroundImage: foto != null ? NetworkImage(foto) : null,
              child: foto == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(c['caminhoneiro_nome']?.toString() ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  if (diamante) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.diamond, size: 15, color: Color(0xFF5B8FBF)),
                  ],
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  StarRatingDisplay(nota: nota, size: 15),
                  const SizedBox(width: 6),
                  Text('${nota.toStringAsFixed(1)} ($total)',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ]),
                if (cidade.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(cidade,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ),
              ]),
            ),
          ]),
          if (mensagem.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('"$mensagem"',
                  style: TextStyle(fontStyle: FontStyle.italic, color: cs.onSurfaceVariant)),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerfilMotoristaPage(motoristaId: c['caminhoneiro']),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('Ver perfil'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _recusar(c),
              style: TextButton.styleFrom(foregroundColor: cs.error),
              child: const Text('Recusar'),
            ),
            const SizedBox(width: 4),
            FilledButton(onPressed: () => _aceitar(c), child: const Text('Aceitar')),
          ]),
        ]),
      ),
    );
  }
}
