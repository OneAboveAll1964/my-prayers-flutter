import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light, AppPalette.light);
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    final colors = brightness == Brightness.light
        ? ColorScheme.light(
            primary: palette.accent,
            onPrimary: palette.accentOn,
            secondary: palette.accent,
            onSecondary: palette.accentOn,
            surface: palette.surface,
            onSurface: palette.text,
            error: palette.danger,
            onError: Colors.white,
          )
        : ColorScheme.dark(
            primary: palette.accent,
            onPrimary: palette.accentOn,
            secondary: palette.accent,
            onSecondary: palette.accentOn,
            surface: palette.surface,
            onSurface: palette.text,
            error: palette.danger,
            onError: Colors.white,
          );

    final base11 = base.textTheme.bodyMedium ??
        const TextStyle(fontSize: 15.5, height: 1.45);
    final textTheme = base.textTheme.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
      fontFamily: 'Inter',
      fontFamilyFallback: const ['-apple-system', 'Roboto'],
    ).copyWith(
      bodyMedium: base11.copyWith(
        color: palette.text,
        fontSize: 15.5,
        height: 1.45,
      ),
      bodySmall: base11.copyWith(
        color: palette.textMuted,
        fontSize: 13,
        height: 1.4,
      ),
    );

    return base.copyWith(
      brightness: brightness,
      scaffoldBackgroundColor: palette.bg,
      colorScheme: colors,
      canvasColor: palette.bg,
      cardColor: palette.surface,
      dividerColor: palette.line,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: palette.text, size: 22),
      primaryIconTheme: IconThemeData(color: palette.accent),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.bg,
        foregroundColor: palette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        modalBackgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radius),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: palette.surface2,
        contentTextStyle: TextStyle(color: palette.text),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
      ),
      extensions: [palette],
    );
  }
}

