import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_ui.dart';
import '../widgets/star_rating.dart';

/// Preview de uma imagem escolhida (blob URL na web, arquivo no mobile).
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
    setState(() {
      _carregando = true;
      _erro = null;
    });
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
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (img != null) setState(() => _novoLogo = img);
  }

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final res = await ApiService.atualizarPerfilEmpresa(
        {
          'razao_social': _razaoCtrl.text.trim(),
          'descricao': _descricaoCtrl.text.trim(),
          'telefone': _telefoneCtrl.text.trim(),
          'endereco_sede': _enderecoCtrl.text.trim(),
        },
        logo: _novoLogo,
      );
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        setState(() {
          _perfil = res['body'];
          _editando = false;
          _novoLogo = null;
        });
        AppSnack.success(context, 'Perfil atualizado!');
      } else {
        AppSnack.error(context, 'Erro ao salvar: ${res['body']}');
      }
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Erro: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_proprio ? 'Meu perfil' : 'Perfil da empresa'),
        actions: [
          if (_proprio && !_carregando && _erro == null)
            IconButton(
              icon: Icon(_editando ? Icons.close : Icons.edit_outlined),
              tooltip: _editando ? 'Cancelar edição' : 'Editar perfil',
              onPressed: () => setState(() {
                _editando = !_editando;
                _novoLogo = null;
              }),
            ),
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

    final p = _perfil!;
    final logo = ApiService.mediaUrl(p['logo']);
    final nota = (p['media_avaliacao'] as num?)?.toDouble() ?? 0.0;
    final total = p['total_avaliacoes'] ?? 0;
    final avaliacoes = (p['avaliacoes'] as List?) ?? [];
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
      ],
    );
  }

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
      ),
    );
  }

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
}
