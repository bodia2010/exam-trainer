import 'package:flutter/material.dart';

abstract final class ExamColors {
  static const canvas = Color(0xFFFFFBF6);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFF7F0);
  static const ink = Color(0xFF102A43);
  static const inkMuted = Color(0xFF65758B);
  static const teal = Color(0xFF149DA3);
  static const tealDark = Color(0xFF087F84);
  static const tealSoft = Color(0xFFDDF4F2);
  static const coral = Color(0xFFFF715B);
  static const coralSoft = Color(0xFFFFE8E1);
  static const border = Color(0xFFE9E0D7);
  static const progressTrack = Color(0xFFECE8E3);
  static const danger = Color(0xFFC62828);
}

abstract final class ExamSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class ExamRadius {
  static const small = 12.0;
  static const medium = 18.0;
  static const large = 24.0;
}

abstract final class ExamTheme {
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: ExamColors.teal,
      onPrimary: Colors.white,
      secondary: ExamColors.coral,
      onSecondary: Colors.white,
      surface: ExamColors.surface,
      onSurface: ExamColors.ink,
      error: ExamColors.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: ExamColors.canvas,
      dividerColor: ExamColors.border,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(bodyColor: ExamColors.ink, displayColor: ExamColors.ink)
          .copyWith(
            headlineSmall: const TextStyle(
              color: ExamColors.ink,
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            titleLarge: const TextStyle(
              color: ExamColors.ink,
              fontSize: 22,
              height: 1.2,
              fontWeight: FontWeight.w800,
              fontFamily: 'serif',
            ),
            titleMedium: const TextStyle(
              color: ExamColors.ink,
              fontSize: 17,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
            bodyMedium: const TextStyle(
              color: ExamColors.inkMuted,
              fontSize: 14,
              height: 1.45,
            ),
          ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        color: ExamColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExamRadius.medium),
          side: const BorderSide(color: ExamColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ExamColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ExamRadius.small),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 72,
        backgroundColor: ExamColors.surface,
        indicatorColor: ExamColors.tealSoft,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: ExamColors.canvas,
        showDragHandle: true,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: ExamColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ExamRadius.medium),
        ),
      ),
    );
  }
}
