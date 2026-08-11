import 'dart:io';
<<<<<<< HEAD

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_ui.dart';
import '../widgets/star_rating.dart';

/// Preview de uma imagem escolhida (blob URL na web, arquivo no mobile).
=======
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/star_rating.dart';

>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
ImageProvider _xfileProvider(XFile f) =>
    kIsWeb ? NetworkImage(f.path) : FileImage(File(f.path)) as ImageProvider;

/// Perfil da empresa. Se [empresaId] for nulo, mostra o perfil da própria
/// empresa logada (com edição). Caso contrário, mostra o perfil público
/// (somente leitura) — usado quando o motorista visita a empresa.
class PerfilEmpresaPage extends StatefulWidget {
  final int? empresaId;

  const PerfilEmpresaPage({super.key, this.empresaId});

  @override
  State<PerfilEmpresaPage> createState() => _PerfilEmpresaPageState();
}

class _PerfilEmpresaPageState extends State<PerfilEmpresaPage> {
  bool get _proprio => widget.empresaId == null;

  Map<String, dynamic>? _perfil;
  bool _carregando = true;
  bool _editando = false;
  bool _salvando = false;
  String? _erro;

  final _razaoCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();
  final _enderecoCtrl = TextEditingController();
  XFile? _novoLogo;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _razaoCtrl.dispose();
    _descricaoCtrl.dispose();
    _telefoneCtrl.dispose();
    _enderecoCtrl.dispose();
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
          ? await ApiService.perfilEmpresa()
          : await ApiService.perfilEmpresaPublico(widget.empresaId!);
      _razaoCtrl.text = p['razao_social']?.toString() ?? '';
      _descricaoCtrl.text = p['descricao']?.toString() ?? '';
      _telefoneCtrl.text = p['telefone']?.toString() ?? '';
      _enderecoCtrl.text = p['endereco_sede']?.toString() ?? '';
      if (mounted) setState(() => _perfil = p);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _escolherLogo() async {
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
    if (img != null) setState(() => _novoLogo = img);
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
<<<<<<< HEAD
      final res = await ApiService.atualizarPerfilEmpresa(
        {
          'razao_social': _razaoCtrl.text.trim(),
          'descricao': _descricaoCtrl.text.trim(),
          'telefone': _telefoneCtrl.text.trim(),
          'endereco_sede': _enderecoCtrl.text.trim(),
        },
        logo: _novoLogo,
      );
=======
      final campos = {
        'razao_social': _razaoCtrl.text.trim(),
        'descricao': _descricaoCtrl.text.trim(),
        'telefone': _telefoneCtrl.text.trim(),
        'endereco_sede': _enderecoCtrl.text.trim(),
      };
      final res = await ApiService.atualizarPerfilEmpresa(campos, logo: _novoLogo);
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        setState(() {
          _perfil = res['body'];
          _editando = false;
          _novoLogo = null;
        });
<<<<<<< HEAD
        AppSnack.success(context, 'Perfil atualizado!');
      } else {
        AppSnack.error(context, 'Erro ao salvar: ${res['body']}');
      }
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Erro: $e');
=======
        _snack('Perfil atualizado!', Colors.green);
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
        title: Text(_proprio ? 'Meu perfil' : 'Perfil da empresa'),
=======
  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_proprio ? 'Meu perfil' : 'Perfil da empresa'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
        actions: [
          if (_proprio && !_carregando && _erro == null)
            IconButton(
              icon: Icon(_editando ? Icons.close : Icons.edit_outlined),
<<<<<<< HEAD
              tooltip: _editando ? 'Cancelar edição' : 'Editar perfil',
=======
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
              onPressed: () => setState(() {
                _editando = !_editando;
                _novoLogo = null;
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

=======
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text('Erro: $_erro'))
              : _editando
                  ? _buildEdicao(cs)
                  : _buildVisualizacao(cs),
    );
  }

  Widget _buildVisualizacao(ColorScheme cs) {
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
    final p = _perfil!;
    final logo = ApiService.mediaUrl(p['logo']);
    final nota = (p['media_avaliacao'] as num?)?.toDouble() ?? 0.0;
    final total = p['total_avaliacoes'] ?? 0;
    final avaliacoes = (p['avaliacoes'] as List?) ?? [];
<<<<<<< HEAD
    final descricao = p['descricao']?.toString() ?? '';

    return ListView(
      padding: AppSpacing.page,
      children: [
        Center(
          child: Column(
            children: [
              AppAvatar(
                radius: 52,
                fallbackIcon: Icons.business,
                image: logo != null ? NetworkImage(logo) : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                p['razao_social']?.toString() ?? '—',
                textAlign: TextAlign.center,
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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
              descricao.isNotEmpty
                  ? descricao
                  : 'Nenhuma descrição informada.',
              style: tt.bodyMedium?.copyWith(
                height: 1.5,
                color:
                    descricao.isNotEmpty ? cs.onSurface : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        AppDetailList(
          itens: [
            (Icons.badge_outlined, 'CNPJ', p['cnpj']?.toString() ?? ''),
            (
              Icons.location_on_outlined,
              'Sede',
              p['endereco_sede']?.toString() ?? ''
            ),
            (Icons.phone_outlined, 'Telefone', p['telefone']?.toString() ?? ''),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        const AppSectionHeader(
          label: 'Avaliações dos motoristas',
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
              radius: 48,
              backgroundColor: cs.surfaceContainerHighest,
              backgroundImage: logo != null ? NetworkImage(logo) : null,
              child: logo == null ? const Icon(Icons.business, size: 44) : null,
            ),
            const SizedBox(height: 12),
            Text(p['razao_social']?.toString() ?? '—',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            StarRatingDisplay(nota: nota, size: 24),
            const SizedBox(height: 4),
            Text('${nota.toStringAsFixed(1)} · $total avaliação(ões)',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 20),
        if (p['descricao']?.toString().isNotEmpty == true)
          _card(cs, 'SOBRE', p['descricao'].toString()),
        _detalhes(cs, p),
        const SizedBox(height: 20),
        Text('AVALIAÇÕES DOS MOTORISTAS',
            style: TextStyle(
                color: cs.primary, fontWeight: FontWeight.w800,
                letterSpacing: 1, fontSize: 12)),
        const SizedBox(height: 10),
        if (avaliacoes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: Text('Ainda não há avaliações.',
                    style: TextStyle(color: cs.onSurfaceVariant))),
          )
        else
          ...avaliacoes.map((a) => _avaliacaoCard(cs, a)),
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
                Icon(Icons.person_outline, size: 15, color: cs.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    a['nome_caminhoneiro']?.toString() ?? 'Motorista',
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
            if (a['tem_banheiro_limpo'] == true || a['local_seguro'] == true) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (a['tem_banheiro_limpo'] == true)
                    AppTag(label: 'Banheiro limpo', color: status.success),
                  if (a['local_seguro'] == true)
                    AppTag(label: 'Local seguro', color: status.success),
                ],
              ),
            ],
          ],
        ),
=======
  Widget _card(ColorScheme cs, String titulo, String conteudo) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(titulo,
              style: TextStyle(
                  color: cs.primary, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(conteudo, style: const TextStyle(height: 1.4)),
        ]),
      );

  Widget _detalhes(ColorScheme cs, Map<String, dynamic> p) {
    final linhas = <(IconData, String)>[
      (Icons.badge_outlined, 'CNPJ: ${p['cnpj'] ?? ''}'),
      (Icons.location_on_outlined, p['endereco_sede']?.toString() ?? ''),
      (Icons.phone_outlined, p['telefone']?.toString() ?? ''),
    ].where((l) => l.$2.replaceAll('CNPJ: ', '').trim().isNotEmpty).toList();

    if (linhas.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: linhas
            .map((l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(children: [
                    Icon(l.$1, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l.$2)),
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
    final logoAtual = ApiService.mediaUrl(_perfil?['logo']);

    return ListView(
      padding: AppSpacing.page,
      children: [
        Center(
          child: AppAvatar(
            radius: 52,
            fallbackIcon: Icons.business,
            onEdit: _escolherLogo,
            image: _novoLogo != null
                ? _xfileProvider(_novoLogo!)
                : (logoAtual != null ? NetworkImage(logoAtual) : null),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text(
            'Toque no logo para alterar',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        AppSection(
          title: 'Dados do perfil',
          children: [
            TextField(
              controller: _razaoCtrl,
              decoration: const InputDecoration(labelText: 'Razão social'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _descricaoCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                hintText: 'Conte o que a sua empresa transporta…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _enderecoCtrl,
              decoration: const InputDecoration(labelText: 'Endereço da sede'),
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
  Widget _avaliacaoCard(ColorScheme cs, dynamic a) {
    final nota = (a['nota'] as num?)?.toDouble() ?? 0.0;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.person_outline, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(a['nome_caminhoneiro']?.toString() ?? 'Motorista',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            StarRatingDisplay(nota: nota, size: 15),
          ]),
          if (a['comentario']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(a['comentario'].toString(),
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.3)),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 6, children: [
            if (a['tem_banheiro_limpo'] == true) _tag(cs, 'Banheiro limpo'),
            if (a['local_seguro'] == true) _tag(cs, 'Local seguro'),
          ]),
        ]),
      ),
    );
  }

  Widget _tag(ColorScheme cs, String txt) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green.withOpacity(0.35)),
        ),
        child: Text(txt,
            style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.w600)),
      );

  Widget _buildEdicao(ColorScheme cs) {
    final logoAtual = ApiService.mediaUrl(_perfil?['logo']);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: GestureDetector(
            onTap: _escolherLogo,
            child: Stack(alignment: Alignment.bottomRight, children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: cs.surfaceContainerHighest,
                backgroundImage: _novoLogo != null
                    ? _xfileProvider(_novoLogo!)
                    : (logoAtual != null ? NetworkImage(logoAtual) : null),
                child: (_novoLogo == null && logoAtual == null)
                    ? const Icon(Icons.business, size: 44)
                    : null,
              ),
              CircleAvatar(
                radius: 15,
                backgroundColor: cs.primary,
                child: Icon(Icons.camera_alt, size: 15, color: cs.onPrimary),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Center(child: Text('Toque no logo para alterar',
            style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11))),
        const SizedBox(height: 20),
        _campo(_razaoCtrl, 'Razão social'),
        _campo(_descricaoCtrl, 'Descrição', maxLines: 4),
        _campo(_enderecoCtrl, 'Endereço da sede'),
        _campo(_telefoneCtrl, 'Telefone', teclado: TextInputType.phone),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: _salvando
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: Text(_salvando ? 'Salvando…' : 'Salvar perfil'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _campo(TextEditingController c, String label,
      {int maxLines = 1, TextInputType? teclado}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: teclado,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
>>>>>>> 645521c15e0b2b5b2e92297907b72bf3b3e4ab05
}
