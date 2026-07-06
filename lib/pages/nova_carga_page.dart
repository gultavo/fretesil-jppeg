import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class NovaCargaPage extends StatefulWidget {
  const NovaCargaPage({super.key});

  @override
  State<NovaCargaPage> createState() => _NovaCargaPageState();
}

class _NovaCargaPageState extends State<NovaCargaPage> {
  final _formKey = GlobalKey<FormState>();
  bool _enviando = false;

  // Controllers
  final _tituloCtrl = TextEditingController();
  final _origemCtrl = TextEditingController();
  final _destinoCtrl = TextEditingController();
  final _distanciaCtrl = TextEditingController();
  final _valorBrutoCtrl = TextEditingController();
  final _pedagioCtrl = TextEditingController();
  final _notaMinimaCtrl = TextEditingController(text: '0.0');
  final _descricaoCtrl = TextEditingController();
  XFile? _foto;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _tituloCtrl.dispose();
    _origemCtrl.dispose();
    _destinoCtrl.dispose();
    _distanciaCtrl.dispose();
    _valorBrutoCtrl.dispose();
    _pedagioCtrl.dispose();
    _notaMinimaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

      setState(() => _enviando = true);

      // helper para converter "1.500,00" → 1500.0
      double _toDouble(String v) =>
          double.parse(v.trim().replaceAll('.', '').replaceAll(',', '.'));

      try {
        final dados = {
          'titulo': _tituloCtrl.text.trim(),
          'origem': _origemCtrl.text.trim(),
          'destino': _destinoCtrl.text.trim(),
          'descricao': _descricaoCtrl.text.trim(),
          'distancia_km': _toDouble(_distanciaCtrl.text),
          'valor_bruto_frete': _toDouble(_valorBrutoCtrl.text),
          'estimativa_pedagio': _pedagioCtrl.text.trim().isEmpty
              ? 0.0
              : _toDouble(_pedagioCtrl.text),
          'nota_minima_motorista': _notaMinimaCtrl.text.trim().isEmpty
              ? 0.0
              : _toDouble(_notaMinimaCtrl.text),
        };

      final result = await ApiService.criarCarga(dados, foto: _foto);
      print('RESPONSE: ${result['body']}'); // ← F12 → Console
      print('STATUS: ${result['statusCode']}');
      if (!mounted) return;

      if (result['statusCode'] == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Carga publicada com sucesso!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true); // true = atualiza a lista
      } else {
        final body = result['body'];
        final mensagem = body is Map
            ? body.values.first.toString()
            : 'Erro ao criar carga.';
        _mostrarErro(mensagem);
      }
    } catch (e) {
      _mostrarErro(e.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Nova Carga'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Seção: Informações básicas ────────────────────────────
            _SectionHeader(label: 'Informações da Carga', icon: Icons.inventory_2_outlined),
            const SizedBox(height: 12),

            _CampoTexto(
              controller: _tituloCtrl,
              label: 'Título',
              hint: 'Ex: Grãos de Soja — Curitiba p/ Santos',
              icon: Icons.label_outline,
              validator: (v) => v == null || v.trim().isEmpty ? 'Informe o título' : null,
            ),
            const SizedBox(height: 12),

            _CampoTexto(
              controller: _descricaoCtrl,
              label: 'Descrição (opcional)',
              hint: 'Detalhes da carga, requisitos, etc.',
              icon: Icons.notes_outlined,
            ),
            const SizedBox(height: 12),

            _FotoPicker(
              foto: _foto,
              onPick: () async {
                final img = await ImagePicker().pickImage(
                    source: ImageSource.gallery, maxWidth: 1280, imageQuality: 80);
                if (img != null) setState(() => _foto = img);
              },
              onClear: () => setState(() => _foto = null),
            ),
            const SizedBox(height: 12),

            // ── Seção: Rota ───────────────────────────────────────────
            _SectionHeader(label: 'Rota', icon: Icons.route_outlined),
            const SizedBox(height: 12),

            _CampoTexto(
              controller: _origemCtrl,
              label: 'Origem',
              hint: 'Cidade, Estado',
              icon: Icons.radio_button_checked,
              iconColor: Colors.green,
              validator: (v) => v == null || v.trim().isEmpty ? 'Informe a origem' : null,
            ),
            const SizedBox(height: 12),

            _CampoTexto(
              controller: _destinoCtrl,
              label: 'Destino',
              hint: 'Cidade, Estado',
              icon: Icons.location_on,
              iconColor: Colors.red,
              validator: (v) => v == null || v.trim().isEmpty ? 'Informe o destino' : null,
            ),
            const SizedBox(height: 12),

            _CampoNumerico(
              controller: _distanciaCtrl,
              label: 'Distância (km)',
              hint: '0',
              icon: Icons.straighten_outlined,
              decimal: false,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe a distância';
                if (double.tryParse(v) == null) return 'Número inválido';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Seção: Valores ────────────────────────────────────────
            _SectionHeader(label: 'Valores', icon: Icons.attach_money),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _CampoNumerico(
                    controller: _valorBrutoCtrl,
                    label: 'Valor bruto (R\$)',
                    hint: '0,00',
                    icon: Icons.payments_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Informe o valor';
                      if (double.tryParse(v) == null) return 'Número inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CampoNumerico(
                    controller: _pedagioCtrl,
                    label: 'Estimativa pedágio (R\$)',
                    hint: '0,00',
                    icon: Icons.toll_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Comissão calculada automaticamente
            _InfoComissao(valorCtrl: _valorBrutoCtrl),
            const SizedBox(height: 20),

            // ── Seção: Requisitos ─────────────────────────────────────
            _SectionHeader(label: 'Requisitos', icon: Icons.star_outline),
            const SizedBox(height: 12),

            _CampoNumerico(
              controller: _notaMinimaCtrl,
              label: 'Nota mínima do motorista (0.0 – 5.0)',
              hint: '0.0',
              icon: Icons.star_half_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final n = double.tryParse(v);
                if (n == null) return 'Número inválido';
                if (n < 0 || n > 5) return 'Entre 0.0 e 5.0';
                return null;
              },
            ),
            const SizedBox(height: 32),

            // ── Botão salvar ──────────────────────────────────────────
            FilledButton.icon(
              onPressed: _enviando ? null : _salvar,
              icon: _enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.publish_outlined),
              label: Text(_enviando ? 'Publicando...' : 'Publicar Carga'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Cabeçalho de seção ───────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: cs.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }
}

// ─── Campo de texto genérico ──────────────────────────────────────────────
class _CampoTexto extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color? iconColor;
  final String? Function(String?)? validator;

  const _CampoTexto({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.iconColor,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: iconColor ?? cs.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: cs.surface,
      ),
    );
  }
}

// ─── Campo numérico ───────────────────────────────────────────────────────
class _CampoNumerico extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool decimal;
  final String? Function(String?)? validator;

  const _CampoNumerico({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.decimal = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: cs.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: cs.surface,
      ),
    );
  }
}

// ─── Seletor de foto da carga ─────────────────────────────────────────────
class _FotoPicker extends StatelessWidget {
  final XFile? foto;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _FotoPicker({required this.foto, required this.onPick, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (foto == null) {
      return OutlinedButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.add_a_photo_outlined, size: 18),
        label: const Text('Adicionar foto da carga'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    final provider = kIsWeb
        ? NetworkImage(foto!.path)
        : FileImage(File(foto!.path)) as ImageProvider;
    return Stack(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image(
          image: provider,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
      Positioned(
        top: 6,
        right: 6,
        child: CircleAvatar(
          backgroundColor: cs.surface,
          radius: 16,
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.close, size: 18, color: cs.error),
            onPressed: onClear,
          ),
        ),
      ),
    ]);
  }
}

// ─── Card de comissão calculada ───────────────────────────────────────────
class _InfoComissao extends StatefulWidget {
  final TextEditingController valorCtrl;

  const _InfoComissao({required this.valorCtrl});

  @override
  State<_InfoComissao> createState() => _InfoComissaoState();
}

class _InfoComissaoState extends State<_InfoComissao> {
  @override
  void initState() {
    super.initState();
    widget.valorCtrl.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.valorCtrl.removeListener(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final valor = double.tryParse(widget.valorCtrl.text) ?? 0.0;
    final comissao = valor * 0.01;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            'Comissão do app (1%): ',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          Text(
            'R\$ ${comissao.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: cs.primary),
          ),
        ],
      ),
    );
  }
}
