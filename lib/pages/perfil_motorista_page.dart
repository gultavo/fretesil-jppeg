import 'dart:io';
<<<<<<< HEAD

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_ui.dart';
=======
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
import '../widgets/star_rating.dart';

/// Preview de uma imagem escolhida (blob URL na web, arquivo no mobile).
ImageProvider _xfileProvider(XFile f) =>
    kIsWeb ? NetworkImage(f.path) : FileImage(File(f.path)) as ImageProvider;

class PerfilMotoristaPage extends StatefulWidget {
  /// Se [motoristaId] for nulo, mostra o perfil do próprio motorista logado
  /// (com edição). Caso contrário, mostra o perfil público (somente leitura).
  final int? motoristaId;

  const PerfilMotoristaPage({super.key, this.motoristaId});

  @override
  State<PerfilMotoristaPage> createState() => _PerfilMotoristaPageState();
}

class _PerfilMotoristaPageState extends State<PerfilMotoristaPage> {
<<<<<<< HEAD
=======
  static const _bg = Color(0xFF1A1D23);
  static const _card = Color(0xFF23272F);
  static const _accent = Color(0xFFE8A020);
  static const _textPrimary = Color(0xFFE8E0CC);
  static const _textMuted = Color(0xFF8A8070);
  static const _green = Color(0xFF4CAF7D);

>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
  bool get _proprio => widget.motoristaId == null;

  Map<String, dynamic>? _perfil;
  bool _carregando = true;
  bool _editando = false;
  bool _salvando = false;
  String? _erro;

  final _bioCtrl = TextEditingController();
  final _cidadeCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _veiculoCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  XFile? _novaFoto;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _cidadeCtrl.dispose();
    _telefoneCtrl.dispose();
    _veiculoCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
<<<<<<< HEAD
    setState(() {
      _carregando = true;
      _erro = null;
    });
=======
    setState(() { _carregando = true; _erro = null; });
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
    try {
      final p = _proprio
          ? await ApiService.perfilCaminhoneiro()
          : await ApiService.perfilMotoristaPublico(widget.motoristaId!);
      _bioCtrl.text = p['bio']?.toString() ?? '';
      _cidadeCtrl.text = p['cidade']?.toString() ?? '';
      _telefoneCtrl.text = p['telefone']?.toString() ?? '';
      _veiculoCtrl.text = p['tipo_veiculo']?.toString() ?? '';
      _expCtrl.text = (p['anos_experiencia'] ?? 0).toString();
      if (mounted) setState(() => _perfil = p);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _escolherFoto() async {
<<<<<<< HEAD
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
=======
    final img = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
    if (img != null) setState(() => _novaFoto = img);
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
<<<<<<< HEAD
      final res = await ApiService.atualizarPerfilMotorista(
        {
          'bio': _bioCtrl.text.trim(),
          'cidade': _cidadeCtrl.text.trim(),
          'telefone': _telefoneCtrl.text.trim(),
          'tipo_veiculo': _veiculoCtrl.text.trim(),
          'anos_experiencia': int.tryParse(_expCtrl.text.trim()) ?? 0,
        },
        foto: _novaFoto,
      );
=======
      final campos = {
        'bio': _bioCtrl.text.trim(),
        'cidade': _cidadeCtrl.text.trim(),
        'telefone': _telefoneCtrl.text.trim(),
        'tipo_veiculo': _veiculoCtrl.text.trim(),
        'anos_experiencia': int.tryParse(_expCtrl.text.trim()) ?? 0,
      };
      final res = await ApiService.atualizarPerfilMotorista(campos, foto: _novaFoto);
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        setState(() {
          _perfil = res['body'];
          _editando = false;
          _novaFoto = null;
        });
<<<<<<< HEAD
        AppSnack.success(context, 'Perfil atualizado!');
      } else {
        AppSnack.error(context, 'Erro ao salvar: ${res['body']}');
      }
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Erro: $e');
=======
        _snack('Perfil atualizado!', _green);
      } else {
        _snack('Erro ao salvar: ${res['body']}', Colors.red);
      }
    } catch (e) {
      if (mounted) _snack('Erro: $e', Colors.red);
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_proprio ? 'Meu perfil' : 'Perfil do motorista'),
        actions: [
          if (_proprio && !_carregando && _erro == null)
            IconButton(
              icon: Icon(_editando ? Icons.close : Icons.edit_outlined),
              tooltip: _editando ? 'Cancelar edição' : 'Editar perfil',
=======
  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1115),
        foregroundColor: _textPrimary,
        title: Text(_proprio ? 'MEU PERFIL' : 'PERFIL DO MOTORISTA',
            style: const TextStyle(letterSpacing: 1.5, fontWeight: FontWeight.w900, fontSize: 15)),
        actions: [
          if (_proprio && !_carregando && _erro == null)
            IconButton(
              icon: Icon(_editando ? Icons.close : Icons.edit_outlined, color: _accent),
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
              onPressed: () => setState(() {
                _editando = !_editando;
                _novaFoto = null;
              }),
            ),
<<<<<<< HEAD
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: AppBody(
        child: _carregando
            ? const AppLoading()
            : _erro != null
                ? AppErrorState(detail: _erro, onRetry: _carregar)
                : _editando
                    ? _edicao()
                    : _visualizacao(),
      ),
    );
  }

  // ─── Visualização ───────────────────────────────────────────────────────
  Widget _visualizacao() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);

=======
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _erro != null
              ? _buildErro()
              : _editando
                  ? _buildEdicao()
                  : _buildVisualizacao(),
    );
  }

  Widget _buildErro() => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(_erro ?? '', style: const TextStyle(color: _textMuted)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _carregar,
              style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: _bg),
              child: const Text('Tentar novamente')),
        ]),
      );

  // ─── Visualização ─────────────────────────────────────────────────────────
  Widget _buildVisualizacao() {
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
    final p = _perfil!;
    final foto = ApiService.mediaUrl(p['foto_perfil']);
    final nota = (p['media_notas'] as num?)?.toDouble() ?? 0.0;
    final total = p['total_avaliacoes'] ?? 0;
    final diamante = p['e_diamante'] == true;
    final avaliacoes = (p['avaliacoes'] as List?) ?? [];
<<<<<<< HEAD
    final bio = p['bio']?.toString() ?? '';

    return ListView(
      padding: AppSpacing.page,
      children: [
        Center(
          child: Column(
            children: [
              AppAvatar(
                radius: 52,
                image: foto != null ? NetworkImage(foto) : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      p['nome_completo']?.toString() ?? '—',
                      textAlign: TextAlign.center,
                      style: tt.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (diamante) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.diamond, color: status.info, size: 20),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              StarRatingDisplay(nota: nota, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${Fmt.nota(nota)} · $total avaliação(ões)',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        AppSection(
          title: 'Sobre',
          children: [
            Text(
              bio.isNotEmpty ? bio : 'Nenhuma bio informada.',
              style: tt.bodyMedium?.copyWith(
                height: 1.5,
                color: bio.isNotEmpty ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        AppDetailList(
          itens: [
            (Icons.location_city, 'Cidade', p['cidade']?.toString() ?? ''),
            (Icons.local_shipping, 'Veículo', p['tipo_veiculo']?.toString() ?? ''),
            (Icons.badge_outlined, 'Placa', p['placa_veiculo']?.toString() ?? ''),
            (
              Icons.timeline,
              'Experiência',
              '${p['anos_experiencia'] ?? 0} ano(s)'
            ),
            (Icons.phone, 'Telefone', p['telefone']?.toString() ?? ''),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        const AppSectionHeader(
          label: 'Avaliações das empresas',
          icon: Icons.star_outline,
        ),
        const SizedBox(height: AppSpacing.md),
        if (avaliacoes.isEmpty)
          const AppEmptyState(
            icon: Icons.star_border_rounded,
            title: 'Ainda não há avaliações',
          )
        else
          for (final a in avaliacoes) ...[
            _avaliacaoCard(a),
            const SizedBox(height: AppSpacing.md),
          ],
=======

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Column(children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: _card,
              backgroundImage: foto != null ? NetworkImage(foto) : null,
              child: foto == null
                  ? const Icon(Icons.person, size: 52, color: _textMuted)
                  : null,
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(p['nome_completo']?.toString() ?? '—',
                    style: const TextStyle(
                        color: _textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              if (diamante) ...[
                const SizedBox(width: 6),
                const Icon(Icons.diamond, color: Color(0xFF5B8FBF), size: 20),
              ],
            ]),
            const SizedBox(height: 6),
            StarRatingDisplay(nota: nota, size: 24),
            const SizedBox(height: 4),
            Text('${nota.toStringAsFixed(1)} · $total avaliação(ões)',
                style: const TextStyle(color: _textMuted, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 20),

        _infoCard('SOBRE', p['bio']?.toString().isNotEmpty == true
            ? p['bio'].toString()
            : 'Nenhuma bio informada.'),

        _detalhes(p),

        const SizedBox(height: 20),
        const Text('AVALIAÇÕES', style: TextStyle(
            color: _accent, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 13)),
        const SizedBox(height: 10),
        if (avaliacoes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('Ainda não há avaliações.',
                style: TextStyle(color: _textMuted))),
          )
        else
          ...avaliacoes.map(_avaliacaoCard),
        const SizedBox(height: 24),
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
      ],
    );
  }

<<<<<<< HEAD
  Widget _avaliacaoCard(dynamic a) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);
    final nota = (a['nota'] as num?)?.toDouble() ?? 0.0;

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business_outlined,
                    size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    a['nome_empresa']?.toString() ?? 'Empresa',
                    style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StarRatingDisplay(nota: nota, size: 15),
              ],
            ),
            if (a['comentario']?.toString().isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                a['comentario'].toString(),
                style: tt.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
              ),
            ],
            if (a['entrega_no_prazo'] == true ||
                a['cuidado_com_carga'] == true) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (a['entrega_no_prazo'] == true)
                    AppTag(label: 'No prazo', color: status.success),
                  if (a['cuidado_com_carga'] == true)
                    AppTag(label: 'Cuidou da carga', color: status.success),
                ],
              ),
            ],
          ],
        ),
=======
  Widget _infoCard(String titulo, String conteudo) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2E3340)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo, style: const TextStyle(
              color: _accent, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(conteudo, style: const TextStyle(color: _textPrimary, height: 1.4)),
        ]),
      );

  Widget _detalhes(Map<String, dynamic> p) {
    final linhas = <(IconData, String, String)>[
      (Icons.location_city, 'Cidade', p['cidade']?.toString() ?? ''),
      (Icons.local_shipping, 'Veículo', p['tipo_veiculo']?.toString() ?? ''),
      (Icons.badge_outlined, 'Placa', p['placa_veiculo']?.toString() ?? ''),
      (Icons.timeline, 'Experiência', '${p['anos_experiencia'] ?? 0} ano(s)'),
      (Icons.phone, 'Telefone', p['telefone']?.toString() ?? ''),
    ].where((l) => l.$3.trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E3340)),
      ),
      child: Column(
        children: linhas
            .map((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Icon(l.$1, size: 18, color: _textMuted),
                    const SizedBox(width: 12),
                    Text('${l.$2}: ',
                        style: const TextStyle(color: _textMuted, fontSize: 13)),
                    Expanded(
                      child: Text(l.$3,
                          style: const TextStyle(color: _textPrimary, fontSize: 13),
                          textAlign: TextAlign.end),
                    ),
                  ]),
                ))
            .toList(),
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
      ),
    );
  }

<<<<<<< HEAD
  // ─── Edição ─────────────────────────────────────────────────────────────
  Widget _edicao() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final fotoAtual = ApiService.mediaUrl(_perfil?['foto_perfil']);

    return ListView(
      padding: AppSpacing.page,
      children: [
        Center(
          child: AppAvatar(
            radius: 52,
            onEdit: _escolherFoto,
            image: _novaFoto != null
                ? _xfileProvider(_novaFoto!)
                : (fotoAtual != null ? NetworkImage(fotoAtual) : null),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            'Toque na foto para alterar',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        AppSection(
          title: 'Dados do perfil',
          children: [
            TextField(
              controller: _bioCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Fale sobre sua experiência…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _cidadeCtrl,
              decoration: const InputDecoration(labelText: 'Cidade'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _veiculoCtrl,
              decoration: const InputDecoration(
                labelText: 'Tipo de veículo',
                hintText: 'Ex.: Carreta baú',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _expCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Anos de experiência',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _telefoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        AppPrimaryButton(
          label: 'Salvar perfil',
          loadingLabel: 'Salvando…',
          icon: Icons.save_outlined,
          loading: _salvando,
          onPressed: _salvar,
        ),
      ],
    );
  }
=======
  Widget _avaliacaoCard(dynamic a) {
    final nota = (a['nota'] as num?)?.toDouble() ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E3340)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.business, size: 14, color: _textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(a['nome_empresa']?.toString() ?? 'Empresa',
                style: const TextStyle(
                    color: _textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
          StarRatingDisplay(nota: nota, size: 15),
        ]),
        if (a['comentario']?.toString().isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(a['comentario'].toString(),
              style: const TextStyle(color: _textMuted, fontSize: 13, height: 1.3)),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 6, children: [
          if (a['entrega_no_prazo'] == true) _tag('No prazo', _green),
          if (a['cuidado_com_carga'] == true) _tag('Cuidou da carga', _green),
        ]),
      ]),
    );
  }

  Widget _tag(String txt, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.withOpacity(0.35)),
        ),
        child: Text(txt, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w600)),
      );

  // ─── Edição ───────────────────────────────────────────────────────────────
  Widget _buildEdicao() {
    final fotoAtual = ApiService.mediaUrl(_perfil?['foto_perfil']);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: GestureDetector(
            onTap: _escolherFoto,
            child: Stack(alignment: Alignment.bottomRight, children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: _card,
                backgroundImage: _novaFoto != null
                    ? _xfileProvider(_novaFoto!)
                    : (fotoAtual != null ? NetworkImage(fotoAtual) : null),
                child: (_novaFoto == null && fotoAtual == null)
                    ? const Icon(Icons.person, size: 52, color: _textMuted)
                    : null,
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, size: 16, color: _bg),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        const Center(child: Text('Toque na foto para alterar',
            style: TextStyle(color: _textMuted, fontSize: 11))),
        const SizedBox(height: 20),

        _campo(_bioCtrl, 'Bio', maxLines: 4, hint: 'Fale sobre sua experiência…'),
        _campo(_cidadeCtrl, 'Cidade'),
        _campo(_veiculoCtrl, 'Tipo de veículo', hint: 'Ex: Carreta baú'),
        _campo(_expCtrl, 'Anos de experiência', teclado: TextInputType.number),
        _campo(_telefoneCtrl, 'Telefone', teclado: TextInputType.phone),
        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: _salvando
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _bg))
              : const Icon(Icons.save),
          label: Text(_salvando ? 'Salvando…' : 'Salvar perfil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: _bg,
            minimumSize: const Size.fromHeight(50),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _campo(TextEditingController c, String label,
      {int maxLines = 1, String? hint, TextInputType? teclado}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: teclado,
        style: const TextStyle(color: _textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: _textMuted),
          hintStyle: TextStyle(color: _textMuted.withOpacity(0.6)),
          filled: true,
          fillColor: _card,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2E3340)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _accent),
          ),
        ),
      ),
    );
  }
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
}
