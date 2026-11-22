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

class PerfilMotoristaPage extends StatefulWidget {
  /// Se [motoristaId] for nulo, mostra o perfil do próprio motorista logado
  /// (com edição). Caso contrário, mostra o perfil público (somente leitura).
  final int? motoristaId;

  const PerfilMotoristaPage({super.key, this.motoristaId});

  @override
  State<PerfilMotoristaPage> createState() => _PerfilMotoristaPageState();
}

class _PerfilMotoristaPageState extends State<PerfilMotoristaPage> {
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
  final _consumoCtrl = TextEditingController();
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
    _consumoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final p = _proprio
          ? await ApiService.perfilCaminhoneiro()
          : await ApiService.perfilMotoristaPublico(widget.motoristaId!);
      _bioCtrl.text = p['bio']?.toString() ?? '';
      _cidadeCtrl.text = p['cidade']?.toString() ?? '';
      _telefoneCtrl.text = p['telefone']?.toString() ?? '';
      _veiculoCtrl.text = p['tipo_veiculo']?.toString() ?? '';
      _expCtrl.text = (p['anos_experiencia'] ?? 0).toString();
      _consumoCtrl.text =
          p['consumo_medio_km_l']?.toString().replaceAll('.', ',') ?? '';
      if (mounted) setState(() => _perfil = p);
    } catch (e) {
      if (mounted) setState(() => _erro = e.toString());
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _escolherFoto() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );
    if (img != null) setState(() => _novaFoto = img);
  }

  Future<void> _salvar() async {
    final consumoTexto = _consumoCtrl.text.trim();
    final consumo = Fmt.tryParseDecimal(consumoTexto);
    if (consumoTexto.isNotEmpty && (consumo == null || consumo < 0.1)) {
      AppSnack.error(context, 'Informe um consumo válido em km/l.');
      return;
    }

    setState(() => _salvando = true);
    try {
      final res = await ApiService.atualizarPerfilMotorista(
        {
          'bio': _bioCtrl.text.trim(),
          'cidade': _cidadeCtrl.text.trim(),
          'telefone': _telefoneCtrl.text.trim(),
          'tipo_veiculo': _veiculoCtrl.text.trim(),
          'anos_experiencia': int.tryParse(_expCtrl.text.trim()) ?? 0,
          'consumo_medio_km_l': consumo ?? '',
        },
        foto: _novaFoto,
      );
      if (!mounted) return;
      if (res['statusCode'] == 200) {
        setState(() {
          _perfil = res['body'];
          _editando = false;
          _novaFoto = null;
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
        title: Text(_proprio ? 'Meu perfil' : 'Perfil do motorista'),
        actions: [
          if (_proprio && !_carregando && _erro == null)
            IconButton(
              icon: Icon(_editando ? Icons.close : Icons.edit_outlined),
              tooltip: _editando ? 'Cancelar edição' : 'Editar perfil',
              onPressed: () => setState(() {
                _editando = !_editando;
                _novaFoto = null;
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
    final status = AppStatusColors.of(context);

    final p = _perfil!;
    final foto = ApiService.mediaUrl(p['foto_perfil']);
    final nota = (p['media_notas'] as num?)?.toDouble() ?? 0.0;
    final total = p['total_avaliacoes'] ?? 0;
    final diamante = p['e_diamante'] == true;
    final avaliacoes = (p['avaliacoes'] as List?) ?? [];
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
      ),
    );
  }

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
              controller: _consumoCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Consumo médio (km/l)',
                hintText: 'Ex.: 2,5',
                helperText: 'Usado para estimar o lucro de cada frete',
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
}
