import 'package:flutter/material.dart';

class AppTokens {
  AppTokens._();

  static const accentLight = Color(0xFF1F8A4C);
  static const accentLightStrong = Color(0xFF186B3B);
  static const accentLightSoft = Color(0xFFE6F3EC);
  static const accentDark = Color(0xFF34C97A);
  static const accentDarkStrong = Color(0xFF2BB96D);
  static const accentDarkSoft = Color(0xFF173626);

  static const bgLight = Color(0xFFFBFBFA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surface2Light = Color(0xFFF3F3F1);
  static const surface3Light = Color(0xFFE8E8E4);
  static const lineLight = Color(0xFFE6E6E1);
  static const lineStrongLight = Color(0xFFD2D2CC);
  static const textLight = Color(0xFF15171A);
  static const textMutedLight = Color(0xFF5A5F66);
  static const textSubtleLight = Color(0xFF898E95);

  static const bgDark = Color(0xFF0E1013);
  static const surfaceDark = Color(0xFF16191D);
  static const surface2Dark = Color(0xFF1C2025);
  static const surface3Dark = Color(0xFF232830);
  static const lineDark = Color(0xFF232830);
  static const lineStrongDark = Color(0xFF2F353D);
  static const textDark = Color(0xFFF1F3F5);
  static const textMutedDark = Color(0xFFB6BBC2);
  static const textSubtleDark = Color(0xFF8A8F96);

  static const danger = Color(0xFFB13B3B);

  static const radiusSm = 8.0;
  static const radius = 14.0;
  static const radiusLg = 22.0;

  static const tabBarHeight = 64.0;
  static const headerHeight = 56.0;

  static const durationFast = Duration(milliseconds: 120);
  static const duration = Duration(milliseconds: 200);
  static const ease = Cubic(0.2, 0.7, 0.2, 1);
}

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.accent,
    required this.accentStrong,
    required this.accentSoft,
    required this.accentOn,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.textMuted,
    required this.textSubtle,
    required this.danger,
  });

  final Color accent;
  final Color accentStrong;
  final Color accentSoft;
  final Color accentOn;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color line;
  final Color lineStrong;
  final Color text;
  final Color textMuted;
  final Color textSubtle;
  final Color danger;

  static const light = AppPalette(
    accent: AppTokens.accentLight,
    accentStrong: AppTokens.accentLightStrong,
    accentSoft: AppTokens.accentLightSoft,
    accentOn: Colors.white,
    bg: AppTokens.bgLight,
    surface: AppTokens.surfaceLight,
    surface2: AppTokens.surface2Light,
    surface3: AppTokens.surface3Light,
    line: AppTokens.lineLight,
    lineStrong: AppTokens.lineStrongLight,
    text: AppTokens.textLight,
    textMuted: AppTokens.textMutedLight,
    textSubtle: AppTokens.textSubtleLight,
    danger: AppTokens.danger,
  );

  static const dark = AppPalette(
    accent: AppTokens.accentDark,
    accentStrong: AppTokens.accentDarkStrong,
    accentSoft: AppTokens.accentDarkSoft,
    accentOn: AppTokens.bgDark,
    bg: AppTokens.bgDark,
    surface: AppTokens.surfaceDark,
    surface2: AppTokens.surface2Dark,
    surface3: AppTokens.surface3Dark,
    line: AppTokens.lineDark,
    lineStrong: AppTokens.lineStrongDark,
    text: AppTokens.textDark,
    textMuted: AppTokens.textMutedDark,
    textSubtle: AppTokens.textSubtleDark,
    danger: AppTokens.danger,
  );

  @override
  AppPalette copyWith({
    Color? accent,
    Color? accentStrong,
    Color? accentSoft,
    Color? accentOn,
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? surface3,
    Color? line,
    Color? lineStrong,
    Color? text,
    Color? textMuted,
    Color? textSubtle,
    Color? danger,
  }) {
    return AppPalette(
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentSoft: accentSoft ?? this.accentSoft,
      accentOn: accentOn ?? this.accentOn,
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textSubtle: textSubtle ?? this.textSubtle,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentOn: Color.lerp(accentOn, other.accentOn, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSubtle: Color.lerp(textSubtle, other.textSubtle, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
