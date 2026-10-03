import 'package:flutter/material.dart';

@immutable
class SleepColors extends ThemeExtension<SleepColors> {
  const SleepColors({
    required this.background,
    required this.surface,
    required this.accent,
    required this.primary,
    required this.secondary,
    required this.muted,
    required this.border,
    required this.ink,
  });
  final Color background,
      surface,
      accent,
      primary,
      secondary,
      muted,
      border,
      ink;
  static const night = SleepColors(
    background: Color(0xFF080D1B),
    surface: Color(0xFF131A2C),
    accent: Color(0xFFB6A2EF),
    primary: Color(0xFFE9E5FB),
    secondary: Color(0xFFBBB5D7),
    muted: Color(0xFF9690B3),
    border: Color(0xFF514974),
    ink: Color(0xFF19132B),
  );
  static const light = SleepColors(
    background: Color(0xFFF7F4F0),
    surface: Color(0xFFEDE7EF),
    accent: Color(0xFF78618F),
    primary: Color(0xFF332C3F),
    secondary: Color(0xFF60536F),
    muted: Color(0xFF71657C),
    border: Color(0xFF97859F),
    ink: Color(0xFFFCF8FF),
  );
  @override
  SleepColors copyWith() => this;
  @override
  SleepColors lerp(covariant SleepColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return SleepColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      accent: mix(accent, other.accent),
      primary: mix(primary, other.primary),
      secondary: mix(secondary, other.secondary),
      muted: mix(muted, other.muted),
      border: mix(border, other.border),
      ink: mix(ink, other.ink),
    );
  }
}

extension SleepTheme on BuildContext {
  SleepColors get colors => Theme.of(this).extension<SleepColors>()!;
  String get assetTheme =>
      Theme.of(this).brightness == Brightness.dark ? 'night' : 'light';
}

ThemeData sleepTheme(Brightness brightness) {
  final c = brightness == Brightness.dark
      ? SleepColors.night
      : SleepColors.light;
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: 'NotoSansSC',
    scaffoldBackgroundColor: c.background,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: c.accent,
          brightness: brightness,
        ).copyWith(
          primary: c.accent,
          onPrimary: c.ink,
          surface: c.surface,
          onSurface: c.primary,
          outline: c.border,
        ),
  );
  return base.copyWith(
    extensions: [c],
    textTheme: base.textTheme.copyWith(
      headlineLarge: TextStyle(
        fontFamily: 'NotoSerifSC',
        fontSize: 32,
        height: 44 / 32,
        fontWeight: FontWeight.w400,
        color: c.primary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'NotoSerifSC',
        fontSize: 18,
        height: 28 / 18,
        color: c.primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'NotoSansSC',
        fontSize: 17,
        height: 26 / 17,
        color: c.secondary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'NotoSansSC',
        fontSize: 13,
        height: 21 / 13,
        color: c.secondary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'NotoSansSC',
        fontSize: 12,
        height: 1.5,
        color: c.muted,
      ),
      labelLarge: TextStyle(
        fontFamily: 'NotoSansSC',
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w500,
        color: c.primary,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.background,
      foregroundColor: c.primary,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.ink,
        minimumSize: const Size(double.infinity, 58),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        minimumSize: const Size(44, 44),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: c.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: c.background,
    ),
  );
}
