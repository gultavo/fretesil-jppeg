import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_ui.dart';

class NovaCargaPage extends StatefulWidget {
  const NovaCargaPage({super.key});

  @override
  State<NovaCargaPage> createState() => _NovaCargaPageState();
}

class _NovaCargaPageState extends State<NovaCargaPage> {
  final _formKey = GlobalKey<FormState>();
  bool _enviando = false;

  final _tituloCtrl = TextEditingController();
  final _origemCtrl = TextEditingController();
  final _destinoCtrl = TextEditingController();
  final _distanciaCtrl = TextEditingController();
  final _valorBrutoCtrl = TextEditingController();
  final _pedagioCtrl = TextEditingController();
  final _notaMinimaCtrl = TextEditingController(text: '0,0');
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

    try {
      final dados = {
        'titulo': _tituloCtrl.text.trim(),
        'origem': _origemCtrl.text.trim(),
        'destino': _destinoCtrl.text.trim(),
        'descricao': _descricaoCtrl.text.trim(),
        'distancia_km': Fmt.parseEntrada(_distanciaCtrl.text),
        'valor_bruto_frete': Fmt.parseEntrada(_valorBrutoCtrl.text),
        'estimativa_pedagio':
            Fmt.tryParseEntrada(_pedagioCtrl.text) ?? 0.0,
        'nota_minima_motorista':
            Fmt.tryParseEntrada(_notaMinimaCtrl.text) ?? 0.0,
      };

      final result = await ApiService.criarCarga(dados, foto: _foto);
      if (!mounted) return;

      if (result['statusCode'] == 201) {
        AppSnack.success(context, 'Carga publicada com sucesso!');
        Navigator.pop(context, true); // true = a lista deve recarregar
      } else {
        final body = result['body'];
        AppSnack.error(
          context,
          body is Map && body.isNotEmpty
              ? body.values.first.toString()
              : 'Erro ao criar a carga.',
        );
      }
    } catch (e) {
      if (mounted) AppSnack.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String? _obrigatorio(String? v, String campo) =>
      (v == null || v.trim().isEmpty) ? 'Informe $campo' : null;

  String? _numeroObrigatorio(String? v, String campo) {
    if (v == null || v.trim().isEmpty) return 'Informe $campo';
    return Fmt.tryParseEntrada(v) == null ? 'Número inválido' : null;
  }

  @override
  Widget build(BuildContext context) {
    final status = AppStatusColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Nova carga')),
      body: AppBody(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: AppSpacing.page,
            children: [
              // ── Informações da carga ──────────────────────────────────
              const AppSectionHeader(
                label: 'Informações da carga',
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _tituloCtrl,
                validator: (v) => _obrigatorio(v, 'o título'),
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ex.: Grãos de soja — Curitiba p/ Santos',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _descricaoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  hintText: 'Detalhes da carga, requisitos, etc.',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              _FotoPicker(
                foto: _foto,
                onPick: () async {
                  final img = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1280,
                    imageQuality: 80,
                  );
                  if (img != null) setState(() => _foto = img);
                },
                onClear: () => setState(() => _foto = null),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Rota ──────────────────────────────────────────────────
              const AppSectionHeader(
                label: 'Rota',
                icon: Icons.route_outlined,
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _origemCtrl,
                validator: (v) => _obrigatorio(v, 'a origem'),
                decoration: InputDecoration(
                  labelText: 'Origem',
                  hintText: 'Cidade, Estado',
                  prefixIcon: Icon(Icons.radio_button_checked,
                      color: status.success),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                controller: _destinoCtrl,
                validator: (v) => _obrigatorio(v, 'o destino'),
                decoration: InputDecoration(
                  labelText: 'Destino',
                  hintText: 'Cidade, Estado',
                  prefixIcon: Icon(Icons.location_on, color: status.danger),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              _CampoNumerico(
                controller: _distanciaCtrl,
                label: 'Distância (km)',
                hint: '0',
                icon: Icons.straighten_outlined,
                validator: (v) => _numeroObrigatorio(v, 'a distância'),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Valores ───────────────────────────────────────────────
              const AppSectionHeader(
                label: 'Valores',
                icon: Icons.attach_money,
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _CampoNumerico(
                      controller: _valorBrutoCtrl,
                      label: 'Valor bruto (R\$)',
                      hint: '0,00',
                      icon: Icons.payments_outlined,
                      validator: (v) => _numeroObrigatorio(v, 'o valor'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _CampoNumerico(
                      controller: _pedagioCtrl,
                      label: 'Pedágio (R\$)',
                      hint: '0,00',
                      icon: Icons.toll_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              _InfoComissao(valorCtrl: _valorBrutoCtrl),
              const SizedBox(height: AppSpacing.xl),

              // ── Requisitos ────────────────────────────────────────────
              const AppSectionHeader(
                label: 'Requisitos',
                icon: Icons.star_outline,
              ),
              const SizedBox(height: AppSpacing.md),

              _CampoNumerico(
                controller: _notaMinimaCtrl,
                label: 'Nota mínima do motorista',
                hint: '0,0 a 5,0',
                icon: Icons.star_half_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = Fmt.tryParseEntrada(v);
                  if (n == null) return 'Número inválido';
                  if (n < 0 || n > 5) return 'Informe um valor entre 0 e 5';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),

              AppPrimaryButton(
                label: 'Publicar carga',
                loadingLabel: 'Publicando…',
                icon: Icons.publish_outlined,
                loading: _enviando,
                onPressed: _salvar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Campo numérico com o teclado e os caracteres corretos.
class _CampoNumerico extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;

  const _CampoNumerico({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

/// Seletor da foto da carga.
class _FotoPicker extends StatelessWidget {
  final XFile? foto;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const _FotoPicker({
    required this.foto,
    required this.onPick,
    required this.onClear,
  });

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
        ),
      );
    }

    final provider = kIsWeb
        ? NetworkImage(foto!.path)
        : FileImage(File(foto!.path)) as ImageProvider;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppRadius.brControl,
          child: Image(
            image: provider,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
          child: CircleAvatar(
            backgroundColor: cs.surface,
            radius: 18,
            child: IconButton(
              tooltip: 'Remover foto',
              padding: EdgeInsets.zero,
              icon: Icon(Icons.close, size: 18, color: cs.error),
              onPressed: onClear,
            ),
          ),
        ),
      ],
    );
  }
}

/// Aviso da comissão do app, recalculado conforme o valor digitado.
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
    final comissao = (Fmt.tryParseEntrada(widget.valorCtrl.text) ?? 0) * 0.01;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.45),
        borderRadius: AppRadius.brControl,
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: cs.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Comissão do app (1%)',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          Text(
            Fmt.brl(comissao),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}
