import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────
/// Design system do Frete Sil.
///
/// Nenhuma tela deve declarar cor, raio ou espaçamento próprio: tudo sai
/// daqui, via `Theme.of(context)` ou dos tokens [AppSpacing] / [AppRadius].
/// ─────────────────────────────────────────────────────────────────────────

/// Cores fixas da marca — os únicos literais de cor do app.
abstract final class AppColors {
  /// Âmbar FRETE SIL. Usado como identidade (logo, estrelas, destaques),
  /// nunca como cor de texto sobre fundo claro.
  static const brand = Color(0xFFE8A020);

  // ── Claro ──────────────────────────────────────────────────────────────
  static const _lightPrimary = Color(0xFF8A5B00);
  static const _lightOnPrimary = Color(0xFFFFFFFF);
  static const _lightPrimaryContainer = Color(0xFFFFDFA8);
  static const _lightOnPrimaryContainer = Color(0xFF2C1D00);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightSurfaceLowest = Color(0xFFF7F4EE);
  static const _lightSurfaceLow = Color(0xFFF2EEE6);
  static const _lightSurfaceContainer = Color(0xFFECE7DD);
  static const _lightSurfaceHigh = Color(0xFFE5DFD3);
  static const _lightSurfaceHighest = Color(0xFFDED7C9);
  static const _lightOnSurface = Color(0xFF1F1B14);
  static const _lightOnSurfaceVariant = Color(0xFF6B6355);
  static const _lightOutline = Color(0xFF9A917F);
  static const _lightOutlineVariant = Color(0xFFDDD6C8);

  // ── Escuro (grafite original do painel do caminhoneiro) ────────────────
  static const _darkPrimary = Color(0xFFF0B34A);
  static const _darkOnPrimary = Color(0xFF3D2800);
  static const _darkPrimaryContainer = Color(0xFF5F4000);
  static const _darkOnPrimaryContainer = Color(0xFFFFDFA8);
  static const _darkSurface = Color(0xFF23272F);
  static const _darkSurfaceLowest = Color(0xFF16191F);
  static const _darkSurfaceLow = Color(0xFF1E222A);
  static const _darkSurfaceContainer = Color(0xFF272C35);
  static const _darkSurfaceHigh = Color(0xFF2E3340);
  static const _darkSurfaceHighest = Color(0xFF363C4A);
  static const _darkOnSurface = Color(0xFFE8E0CC);
  static const _darkOnSurfaceVariant = Color(0xFFA09684);
  static const _darkOutline = Color(0xFF5A6170);
  static const _darkOutlineVariant = Color(0xFF2E3340);
}

/// Espaçamentos. Escala de 4 em 4 — nada de números soltos nas telas.
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;

  /// Padding padrão de conteúdo de página (sobra no rodapé p/ o FAB).
  static const page = EdgeInsets.fromLTRB(lg, lg, lg, xxxl);

  /// Padding padrão de lista rolável dentro de abas.
  static const list = EdgeInsets.fromLTRB(lg, md, lg, 96);

  /// Padding interno de card.
  static const card = EdgeInsets.all(lg);

  /// Largura máxima do conteúdo — mantém as telas legíveis na web/desktop.
  static const maxContentWidth = 720.0;
}

/// Raios de canto. Três degraus apenas: etiqueta, controle e card.
abstract final class AppRadius {
  static const tag = 8.0;
  static const control = 12.0;
  static const card = 16.0;

  static const brTag = BorderRadius.all(Radius.circular(tag));
  static const brControl = BorderRadius.all(Radius.circular(control));
  static const brCard = BorderRadius.all(Radius.circular(card));
}

/// Cores semânticas de estado, resolvidas por brilho.
///
/// Use sempre estas em vez de `Colors.green` / `Colors.red` / `Colors.orange`,
/// para que os estados continuem legíveis nos dois temas.
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  /// Âmbar da marca (logo, estrelas, selos).
  final Color brand;

  /// Concluído, aceito, no prazo.
  final Color success;

  /// Disponível, pendente, aguardando.
  final Color warning;

  /// Em trânsito, distância, informação neutra.
  final Color info;

  /// Recusado, erro, destino.
  final Color danger;

  const AppStatusColors({
    required this.brand,
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
  });

  static const _light = AppStatusColors(
    brand: AppColors.brand,
    success: Color(0xFF2E7D51),
    warning: Color(0xFFB8730A),
    info: Color(0xFF2F6690),
    danger: Color(0xFFB3261E),
  );

  static const _dark = AppStatusColors(
    brand: AppColors.brand,
    success: Color(0xFF4CAF7D),
    warning: Color(0xFFE8A020),
    info: Color(0xFF5B8FBF),
    danger: Color(0xFFCF6679),
  );

  static AppStatusColors of(BuildContext context) =>
      Theme.of(context).extension<AppStatusColors>() ?? _light;

  @override
  AppStatusColors copyWith({
    Color? brand,
    Color? success,
    Color? warning,
    Color? info,
    Color? danger,
  }) {
    return AppStatusColors(
      brand: brand ?? this.brand,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      brand: Color.lerp(brand, other.brand, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

/// Temas claro e escuro construídos a partir da mesma receita de componentes.
abstract final class AppTheme {
  static ThemeData get light => _build(_lightScheme, AppStatusColors._light);
  static ThemeData get dark => _build(_darkScheme, AppStatusColors._dark);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors._lightPrimary,
    onPrimary: AppColors._lightOnPrimary,
    primaryContainer: AppColors._lightPrimaryContainer,
    onPrimaryContainer: AppColors._lightOnPrimaryContainer,
    surface: AppColors._lightSurface,
    surfaceContainerLowest: AppColors._lightSurfaceLowest,
    surfaceContainerLow: AppColors._lightSurfaceLow,
    surfaceContainer: AppColors._lightSurfaceContainer,
    surfaceContainerHigh: AppColors._lightSurfaceHigh,
    surfaceContainerHighest: AppColors._lightSurfaceHighest,
    onSurface: AppColors._lightOnSurface,
    onSurfaceVariant: AppColors._lightOnSurfaceVariant,
    outline: AppColors._lightOutline,
    outlineVariant: AppColors._lightOutlineVariant,
    error: AppStatusColors._light.danger,
    onError: Colors.white,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors._darkPrimary,
    onPrimary: AppColors._darkOnPrimary,
    primaryContainer: AppColors._darkPrimaryContainer,
    onPrimaryContainer: AppColors._darkOnPrimaryContainer,
    surface: AppColors._darkSurface,
    surfaceContainerLowest: AppColors._darkSurfaceLowest,
    surfaceContainerLow: AppColors._darkSurfaceLow,
    surfaceContainer: AppColors._darkSurfaceContainer,
    surfaceContainerHigh: AppColors._darkSurfaceHigh,
    surfaceContainerHighest: AppColors._darkSurfaceHighest,
    onSurface: AppColors._darkOnSurface,
    onSurfaceVariant: AppColors._darkOnSurfaceVariant,
    outline: AppColors._darkOutline,
    outlineVariant: AppColors._darkOutlineVariant,
    error: AppStatusColors._dark.danger,
    onError: const Color(0xFF3A0907),
  );

  static ThemeData _build(ColorScheme cs, AppStatusColors status) {
    final base = ThemeData(colorScheme: cs, useMaterial3: true);
    final tt = base.textTheme;

    return base.copyWith(
      scaffoldBackgroundColor: cs.surfaceContainerLowest,
      extensions: [status],

      // ── AppBar: neutra em todas as telas, separada por um fio ──────────
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: tt.titleMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: cs.onSurfaceVariant),
        actionsIconTheme: IconThemeData(color: cs.onSurfaceVariant),
        shape: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),

      // ── Cards: sem sombra, contorno de 1px, raio único ─────────────────
      cardTheme: CardThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),

      // ── Campos de formulário ───────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        prefixIconColor: cs.onSurfaceVariant,
        suffixIconColor: cs.onSurfaceVariant,
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: BorderSide(color: cs.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brControl,
          borderSide: BorderSide(color: cs.error, width: 1.6),
        ),
      ),

      // ── Botões: mesmo raio, mesmo peso de texto ────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brControl),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brControl),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brControl),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brControl),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: cs.primaryContainer,
          selectedForegroundColor: cs.onPrimaryContainer,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brControl),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        extendedTextStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brControl),
      ),

      // ── Abas ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: cs.outlineVariant,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Feedback ───────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brControl),
        contentTextStyle: TextStyle(
          color: cs.onInverseSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brCard,
          side: BorderSide(color: cs.outlineVariant),
        ),
        titleTextStyle: tt.titleMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary),
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: cs.onSurfaceVariant,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brControl),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainer,
        side: BorderSide(color: cs.outlineVariant),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brTag),
        labelStyle: TextStyle(fontSize: 12, color: cs.onSurface),
      ),
    );
  }
}
