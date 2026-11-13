import 'package:flutter/material.dart';

/// Design system: Primary #2563EB · Secondary #F59E0B · Tertiary #16A34A · Neutral #0F172A,
/// tipografi Plus Jakarta Sans, permukaan lavender, sudut membulat.
/// Tetap kontras tinggi & tombol min 48dp untuk pemakaian di lapangan (PRD 6).
class AppColors {
  // Palet inti
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const secondary = Color(0xFFF59E0B);
  static const tertiary = Color(0xFF16A34A);
  static const neutral = Color(0xFF0F172A);
  static const danger = Color(0xFFDC2626);

  // Permukaan (light)
  static const background = Color(0xFFE9ECFA);
  static const surface = Color(0xFFF5F6FF);
  static const surfaceHigh = Color(0xFFE2E7FA);
  static const border = Color(0xFFC7CFEE);

  // Status stok
  static const ok = tertiary;
  static const warning = Color(0xFFD97706); // amber lebih gelap agar teks terbaca
  static const critical = danger;
}

const _font = 'PlusJakartaSans';

ColorScheme _scheme(Brightness b) {
  if (b == Brightness.light) {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDCE4FD),
      onPrimaryContainer: Color(0xFF1E3A8A),
      secondary: AppColors.secondary,
      onSecondary: AppColors.neutral,
      secondaryContainer: Color(0xFFFDEFC8),
      onSecondaryContainer: Color(0xFF78350F),
      tertiary: AppColors.tertiary,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFD7F5DF),
      onTertiaryContainer: Color(0xFF14532D),
      error: AppColors.danger,
      onError: Colors.white,
      errorContainer: Color(0xFFFDE2E2),
      onErrorContainer: Color(0xFF7F1D1D),
      surface: AppColors.background,
      onSurface: AppColors.neutral,
      onSurfaceVariant: Color(0xFF475569),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: AppColors.surface,
      surfaceContainer: AppColors.surface,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: Color(0xFFD9DFF6),
      outline: Color(0xFF8A94B8),
      outlineVariant: AppColors.border,
      inverseSurface: Color(0xFF1E293B),
      onInverseSurface: Colors.white,
      inversePrimary: Color(0xFF93B4FA),
      shadow: Color(0x1A0F172A),
      scrim: Color(0x990F172A),
    );
  }
  return const ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF4F86F7),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: Color(0xFFDCE4FD),
    secondary: Color(0xFFFBBF24),
    onSecondary: AppColors.neutral,
    secondaryContainer: Color(0xFF5B3B08),
    onSecondaryContainer: Color(0xFFFDEFC8),
    tertiary: Color(0xFF22C55E),
    onTertiary: AppColors.neutral,
    tertiaryContainer: Color(0xFF14532D),
    onTertiaryContainer: Color(0xFFD7F5DF),
    error: Color(0xFFF87171),
    onError: AppColors.neutral,
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFDE2E2),
    surface: AppColors.neutral,
    onSurface: Color(0xFFE2E8F0),
    onSurfaceVariant: Color(0xFF94A3B8),
    surfaceContainerLowest: Color(0xFF0B1120),
    surfaceContainerLow: Color(0xFF172033),
    surfaceContainer: Color(0xFF1A2438),
    surfaceContainerHigh: Color(0xFF232F47),
    surfaceContainerHighest: Color(0xFF2C3957),
    outline: Color(0xFF64748B),
    outlineVariant: Color(0xFF334155),
    inverseSurface: Color(0xFFE2E8F0),
    onInverseSurface: AppColors.neutral,
    inversePrimary: AppColors.primary,
    shadow: Colors.black,
    scrim: Colors.black,
  );
}

ThemeData buildTheme(Brightness b) {
  final cs = _scheme(b);
  final base = ThemeData(colorScheme: cs, useMaterial3: true, brightness: b, fontFamily: _font);
  final text = base.textTheme.copyWith(
    headlineLarge: base.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
    titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    labelLarge: base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
  );
  const minSize = Size(48, 52);
  final btnShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  final cardColor = cs.surfaceContainerLow;

  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: cs.surface,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: cs.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: _font, fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface, letterSpacing: -0.3),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: minSize,
        shape: btnShape,
        textStyle: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: minSize,
        shape: btnShape,
        foregroundColor: cs.onSurface,
        side: BorderSide(color: cs.outline),
        textStyle: const TextStyle(fontFamily: _font, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: btnShape, textStyle: const TextStyle(fontFamily: _font, fontWeight: FontWeight.w600)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      extendedTextStyle: const TextStyle(fontFamily: _font, fontSize: 16, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.primary, width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: cs.error)),
      prefixIconColor: cs.onSurfaceVariant,
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: cs.outlineVariant),
      backgroundColor: cardColor,
      selectedColor: cs.primaryContainer,
      labelStyle: TextStyle(fontFamily: _font, fontWeight: FontWeight.w600, color: cs.onSurface),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: btnShape,
        selectedBackgroundColor: cs.primary,
        selectedForegroundColor: cs.onPrimary,
        minimumSize: minSize,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : cs.outline),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? cs.primary : cs.surfaceContainerHighest),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cardColor,
      elevation: 0,
      height: 72,
      indicatorColor: cs.primary,
      indicatorShape: const CircleBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? cs.onPrimary : cs.onSurfaceVariant)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
            fontFamily: _font,
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? cs.primary : cs.onSurfaceVariant,
          )),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: cs.inverseSurface,
      contentTextStyle: TextStyle(fontFamily: _font, color: cs.onInverseSurface, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: cs.outlineVariant, space: 1),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 12,
      iconColor: cs.onSurfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: cs.primary, linearTrackColor: cs.surfaceContainerHigh),
  );
}

Color statusColor(String status) => switch (status) {
      'critical' => AppColors.critical,
      'warning' => AppColors.warning,
      _ => AppColors.ok,
    };

/// Ikon dalam lingkaran berwarna (gaya tombol ikon pada design system).
class IconCircle extends StatelessWidget {
  const IconCircle(this.icon, {super.key, required this.color, this.size = 44, this.filled = true});
  final IconData icon;
  final Color color;
  final double size;
  final bool filled;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: filled ? color : color.withValues(alpha: 0.14), shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.5, color: filled ? Colors.white : color),
      );
}
