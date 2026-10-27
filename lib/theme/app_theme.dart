import "dart:math" as math;
import "dart:ui" show lerpDouble;

import "package:flutter/material.dart";

import "app_colors.dart";
import "hud_shapes.dart";

/// Famílias tipográficas da marca. As fontes vão embutidas no app
/// (`assets/fonts/`), então o APK funciona offline e não "pisca" ao abrir.
class AppFonts {
  AppFonts._();

  /// Títulos, números e rótulos HUD: geométrica e angulosa, combina com os
  /// cantos cortados.
  static const String display = "ChakraPetch";

  /// Corpo de texto: alta legibilidade para reviews longas.
  static const String body = "Inter";
}

/// Estilo dos rótulos HUD em caixa alta (seções, botões, etiquetas).
TextStyle hudLabelStyle({
  double fontSize = 13,
  Color color = AppColors.textPrimary,
  double letterSpacing = 1.4,
}) {
  return TextStyle(
    fontFamily: AppFonts.display,
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    letterSpacing: letterSpacing,
    color: color,
    height: 1.1,
  );
}

/// Números grandes (notas, horas, nível): a "tela de dano" do CritHit.
TextStyle hudNumberStyle({
  double fontSize = 22,
  Color color = AppColors.textPrimary,
}) {
  return TextStyle(
    fontFamily: AppFonts.display,
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    color: color,
    height: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}

/// Constrói o [ThemeData] com a identidade visual do CritHit (v2, CP6):
/// tema escuro, Crit Red como cor da marca, dourado para estrelas, títulos
/// em Chakra Petch, corpo em Inter e os cantos cortados da linguagem HUD.
ThemeData buildCritHitTheme() {
  final ThemeData base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: AppFonts.body,
  );

  TextStyle display(double size, FontWeight weight) => TextStyle(
    fontFamily: AppFonts.display,
    fontSize: size,
    fontWeight: weight,
    color: AppColors.textPrimary,
    height: 1.15,
  );

  final TextTheme textTheme = base.textTheme
      .apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      )
      .copyWith(
        headlineMedium: display(30, FontWeight.w700),
        headlineSmall: display(25, FontWeight.w700),
        titleLarge: display(20, FontWeight.w700),
        titleMedium: display(16, FontWeight.w600),
        bodyLarge: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 16,
          color: AppColors.textPrimary,
          height: 1.45,
        ),
        bodyMedium: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.45,
        ),
        bodySmall: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12,
          color: AppColors.textSecondary,
          height: 1.35,
        ),
        labelLarge: hudLabelStyle(fontSize: 14, letterSpacing: 1.2),
      );

  final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accentGold,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        outline: AppColors.stroke,
        outlineVariant: AppColors.stroke,
      );

  final ButtonStyle hudButtonBase = ButtonStyle(
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    shape: WidgetStatePropertyAll(HudShapes.panel(cut: 10)),
    textStyle: WidgetStatePropertyAll(
      hudLabelStyle(fontSize: 14, letterSpacing: 1.2),
    ),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: colorScheme,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: display(22, FontWeight.w700),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: HudInputBorder(),
      enabledBorder: HudInputBorder(),
      focusedBorder: HudInputBorder(
        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: HudInputBorder(
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: HudInputBorder(
        borderSide: BorderSide(color: AppColors.danger, width: 1.5),
      ),
      hintStyle: TextStyle(color: AppColors.textMuted),
      labelStyle: TextStyle(color: AppColors.textSecondary),
      floatingLabelStyle: TextStyle(color: AppColors.primary),
      errorStyle: TextStyle(color: AppColors.danger),
      prefixIconColor: AppColors.textSecondary,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.surfaceAlt,
        disabledForegroundColor: AppColors.textMuted,
        elevation: 0,
      ).merge(hudButtonBase),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ).merge(hudButtonBase),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(foregroundColor: AppColors.textPrimary)
          .merge(hudButtonBase)
          .copyWith(
            shape: WidgetStatePropertyAll(
              HudShapes.outlined(cut: 10, color: AppColors.textMuted),
            ),
          ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: hudLabelStyle(fontSize: 13, letterSpacing: 1),
        shape: HudShapes.panel(cut: 6),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        shape: HudShapes.panel(cut: 8),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.16),
      indicatorShape: HudShapes.panel(cut: 8),
      surfaceTintColor: Colors.transparent,
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => hudLabelStyle(
          fontSize: 11,
          letterSpacing: 1,
          color: states.contains(WidgetState.selected)
              ? AppColors.textPrimary
              : AppColors.textSecondary,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      side: const BorderSide(color: AppColors.stroke),
      labelStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      checkmarkColor: AppColors.primary,
      shape: HudShapes.outlined(cut: 7),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      contentTextStyle: const TextStyle(
        fontFamily: AppFonts.body,
        color: AppColors.background,
        fontWeight: FontWeight.w600,
      ),
      shape: HudShapes.panel(cut: 10),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceAlt,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceAlt,
      shape: HudShapes.outlined(cut: 16),
      titleTextStyle: display(20, FontWeight.w700),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surfaceAlt,
      shape: HudShapes.panel(cut: 16),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceAlt,
      shape: HudShapes.outlined(cut: 10),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(HudShapes.panel(cut: 8)),
        side: const WidgetStatePropertyAll(BorderSide(color: AppColors.stroke)),
        textStyle: WidgetStatePropertyAll(
          hudLabelStyle(fontSize: 12, letterSpacing: 1),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.surface,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.textPrimary
              : AppColors.textSecondary,
        ),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: ShapeDecoration(
        color: AppColors.surfaceAlt,
        shape: HudShapes.outlined(cut: 6),
      ),
      textStyle: const TextStyle(
        fontFamily: AppFonts.body,
        fontSize: 12,
        color: AppColors.textPrimary,
      ),
    ),
    dividerColor: AppColors.stroke,
    dividerTheme: const DividerThemeData(color: AppColors.stroke, space: 1),
  );
}

/// Borda de campo de texto com os cantos cortados da linguagem HUD.
///
/// O Material só traz bordas arredondadas ou sublinhadas para os inputs,
/// então desenhamos o chanfro aqui.
class HudInputBorder extends InputBorder {
  const HudInputBorder({
    super.borderSide = const BorderSide(color: AppColors.stroke),
    this.cut = 10,
  });

  final double cut;

  @override
  bool get isOutline => true;

  Path _path(Rect rect) {
    return Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right - cut, rect.top)
      ..lineTo(rect.right, rect.top + cut)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left + cut, rect.bottom)
      ..lineTo(rect.left, rect.bottom - cut)
      ..close();
  }

  @override
  HudInputBorder copyWith({BorderSide? borderSide}) {
    return HudInputBorder(borderSide: borderSide ?? this.borderSide, cut: cut);
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _path(rect.deflate(borderSide.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none) return;
    final Rect r = rect.deflate(borderSide.width / 2);
    if (gapStart == null || gapExtent <= 0 || gapPercentage <= 0) {
      canvas.drawPath(_path(r), borderSide.toPaint());
      return;
    }
    // Rótulo flutuando sobre a borda: deixa um vão na linha de cima, como o
    // OutlineInputBorder do Material (mesmo respiro de 4 px de cada lado).
    const double gapPadding = 4;
    final double extent = lerpDouble(
      0,
      gapExtent + gapPadding * 2,
      gapPercentage,
    )!;
    final double gapLeft = r.left + math.max(0, gapStart - gapPadding);
    final double gapRight = math.min(gapLeft + extent, r.right - cut);
    final Path path = Path()
      ..moveTo(gapRight, r.top)
      ..lineTo(r.right - cut, r.top)
      ..lineTo(r.right, r.top + cut)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.left + cut, r.bottom)
      ..lineTo(r.left, r.bottom - cut)
      ..lineTo(r.left, r.top)
      ..lineTo(gapLeft, r.top);
    canvas.drawPath(path, borderSide.toPaint());
  }

  @override
  ShapeBorder scale(double t) {
    return HudInputBorder(borderSide: borderSide.scale(t), cut: cut * t);
  }
}
