import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Peças de interface compartilhadas por todas as telas.
///
/// Cada padrão visual que aparecia repetido (e ligeiramente diferente) em
/// várias telas vive aqui em uma única versão.
/// ─────────────────────────────────────────────────────────────────────────

/// Envelope padrão do corpo de uma tela: limita a largura em telas grandes
/// e centraliza o conteúdo. Todo `body:` de Scaffold passa por aqui.
class AppBody extends StatelessWidget {
  final Widget child;

  const AppBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.maxContentWidth),
        child: child,
      ),
    );
  }
}

/// Título + subtítulo centralizados no topo de uma tela de formulário.
class AppPageIntro extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppPageIntro({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Cabeçalho de seção: rótulo em caixa alta, ícone e régua até a margem.
class AppSectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const AppSectionHeader({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: cs.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }
}

/// Card com título interno, usado para agrupar campos de formulário
/// e blocos de informação.
class AppSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  const AppSection({
    super.key,
    this.title,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Etiqueta de estado (Disponível / Em trânsito / Aceita / …).
///
/// Sempre desenhada como fundo translúcido + contorno da mesma matiz, para
/// funcionar nos dois temas sem ajuste.
class AppStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const AppStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brTag,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta discreta de atributo ("No prazo", "Local seguro").
class AppTag extends StatelessWidget {
  final String label;
  final Color color;

  const AppTag({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brTag,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Bloco de métrica usado nas faixas de resumo das duas home.
///
/// Unifica o `_StatChip` da empresa com o `_MetricBox` do freteiro.
class AppMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color color;

  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: AppRadius.brTag,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: color),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 9,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Linha compacta origem → destino, com a distância no meio.
class AppRouteLine extends StatelessWidget {
  final String origem;
  final String destino;
  final String? distancia;

  const AppRouteLine({
    super.key,
    required this.origem,
    required this.destino,
    this.distancia,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);

    return Row(
      children: [
        Icon(Icons.radio_button_checked, size: 14, color: status.success),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            origem,
            style: tt.bodySmall?.copyWith(color: cs.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (distancia != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            distancia!,
            style: tt.bodySmall?.copyWith(
              color: status.info,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else
          const SizedBox(width: AppSpacing.sm),
        Icon(Icons.location_on, size: 14, color: status.danger),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            destino,
            style: tt.bodySmall?.copyWith(color: cs.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

/// Rota em bloco, com rótulos ORIGEM/DESTINO — para telas de detalhe.
class AppRouteBlock extends StatelessWidget {
  final String origem;
  final String destino;

  const AppRouteBlock({
    super.key,
    required this.origem,
    required this.destino,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = AppStatusColors.of(context);

    return Card(
      child: Padding(
        padding: AppSpacing.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linha(context, Icons.radio_button_checked, 'ORIGEM', origem,
                status.success),
            Padding(
              padding: const EdgeInsets.only(left: 9),
              child: Container(
                height: AppSpacing.xxl,
                width: 2,
                color: cs.outlineVariant,
              ),
            ),
            _linha(context, Icons.location_on, 'DESTINO', destino,
                status.danger),
          ],
        ),
      ),
    );
  }

  Widget _linha(BuildContext context, IconData icon, String label,
      String valor, Color cor) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: cor),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lista de pares ícone / rótulo / valor, usada nos dois perfis.
class AppDetailList extends StatelessWidget {
  /// Cada item é `(ícone, rótulo, valor)`. Itens com valor vazio somem.
  final List<(IconData, String, String)> itens;

  const AppDetailList({super.key, required this.itens});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visiveis = itens.where((i) => i.$3.trim().isNotEmpty).toList();
    if (visiveis.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < visiveis.length; i++) ...[
              if (i > 0) Divider(color: cs.outlineVariant),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(visiveis[i].$1, size: 18, color: cs.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      visiveis[i].$2,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        visiveis[i].$3,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado vazio padronizado.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: cs.outlineVariant),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: tt.titleSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estado de erro padronizado, com ação de recarregar.
class AppErrorState extends StatelessWidget {
  final String title;
  final String? detail;
  final VoidCallback onRetry;

  const AppErrorState({
    super.key,
    this.title = 'Não foi possível carregar',
    this.detail,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final status = AppStatusColors.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: status.danger),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detail!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão principal de uma tela: largura total, altura fixa, estado de carga.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final String? loadingLabel;
  final IconData? icon;
  final bool loading;
  final VoidCallback? onPressed;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loadingLabel,
    this.icon,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = Text(loading ? (loadingLabel ?? label) : label);
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );

    if (loading) {
      return FilledButton.icon(
        onPressed: null,
        style: style,
        icon: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: cs.onSurfaceVariant,
          ),
        ),
        label: child,
      );
    }
    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: 20),
        label: child,
      );
    }
    return FilledButton(onPressed: onPressed, style: style, child: child);
  }
}

/// Botão compacto para as ações dentro de cards de lista.
abstract final class AppCompactButton {
  static ButtonStyle get style => FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      );

  /// Variante com cor própria — para ações de destaque (ex.: "Avaliar").
  static ButtonStyle colored(Color background, Color foreground) =>
      FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      );

  static ButtonStyle get outlined => OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      );

  static ButtonStyle get text => TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      );
}

/// Avatar circular com imagem remota, ícone de reserva e botão opcional
/// de troca de foto.
class AppAvatar extends StatelessWidget {
  final ImageProvider? image;
  final IconData fallbackIcon;
  final double radius;
  final VoidCallback? onEdit;

  const AppAvatar({
    super.key,
    this.image,
    this.fallbackIcon = Icons.person,
    this.radius = 48,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: cs.surfaceContainerHigh,
      backgroundImage: image,
      child: image == null
          ? Icon(fallbackIcon, size: radius, color: cs.onSurfaceVariant)
          : null,
    );

    if (onEdit == null) return avatar;

    return GestureDetector(
      onTap: onEdit,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatar,
          CircleAvatar(
            radius: 16,
            backgroundColor: cs.primary,
            child: Icon(Icons.camera_alt, size: 16, color: cs.onPrimary),
          ),
        ],
      ),
    );
  }
}

/// Mensagens de retorno padronizadas.
///
/// A cor vem sempre da paleta semântica, nunca de `Colors.green`/`Colors.red`.
abstract final class AppSnack {
  static void success(BuildContext context, String msg) =>
      _show(context, msg, AppStatusColors.of(context).success, Icons.check_circle);

  static void error(BuildContext context, String msg) =>
      _show(context, msg, AppStatusColors.of(context).danger, Icons.error_outline);

  static void info(BuildContext context, String msg) =>
      _show(context, msg, AppStatusColors.of(context).info, Icons.info_outline);

  static void warning(BuildContext context, String msg) => _show(
      context, msg, AppStatusColors.of(context).warning, Icons.warning_amber);

  static void _show(
      BuildContext context, String msg, Color cor, IconData icone) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: cor,
        content: Row(
          children: [
            Icon(icone, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo de confirmação padronizado. Devolve `true` se confirmado.
Future<bool> appConfirmar(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String confirmar = 'Confirmar',
  String cancelar = 'Cancelar',
  bool destrutivo = false,
}) async {
  final cs = Theme.of(context).colorScheme;
  final resposta = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destrutivo
              ? FilledButton.styleFrom(
                  backgroundColor: cs.error,
                  foregroundColor: cs.onError,
                )
              : null,
          child: Text(confirmar),
        ),
      ],
    ),
  );
  return resposta ?? false;
}

/// Indicador de carregamento centralizado — mesma aparência em toda tela.
class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Marca do app exibida no `AppBar` das telas iniciais.
class AppBrandMark extends StatelessWidget {
  final String subtitle;

  const AppBrandMark({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final status = AppStatusColors.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: status.brand.withValues(alpha: 0.15),
            borderRadius: AppRadius.brTag,
            border: Border.all(color: status.brand.withValues(alpha: 0.4)),
          ),
          child: Icon(Icons.local_shipping, color: status.brand, size: 18),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FRETE SIL',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.8,
              ),
            ),
            Text(
              subtitle.toUpperCase(),
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 9,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
