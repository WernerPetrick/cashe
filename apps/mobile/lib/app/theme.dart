import 'package:flutter/material.dart';

/// Colour tokens from the Cashe Wallet design (Claude Design, "Cashe Wallet.dc.html").
abstract final class CasheColors {
  static const background = Color(0xFF0F2E3A);
  static const surface = Color(0xFF16394A);
  static const surfaceHover = Color(0xFF1B4153);
  static const input = Color(0xFF133645);
  static const border = Color(0xFF23495A);
  static const outline = Color(0xFF2B5565);
  static const divider = Color(0xFF1E4252);
  static const track = Color(0xFF21485A);
  static const dots = Color(0xFF3B6A74);
  static const amber = Color(0xFFF2B544);
  static const amberHover = Color(0xFFF5C462);
  static const text = Color(0xFFF3EFE6);
  static const textSoft = Color(0xFFC9D6D9);
  static const textBody = Color(0xFFA9BEC4);
  static const muted = Color(0xFF8EA6AD);
  static const faint = Color(0xFF6F8C96);
  static const warning = Color(0xFFF4A08A);
}

const _sans = 'Manrope';
const mono = 'JetBrains Mono';

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: CasheColors.amber,
    onPrimary: CasheColors.background,
    secondary: CasheColors.amber,
    onSecondary: CasheColors.background,
    surface: CasheColors.background,
    onSurface: CasheColors.text,
    surfaceContainer: CasheColors.surface,
    surfaceContainerHigh: CasheColors.surface,
    surfaceContainerHighest: CasheColors.surfaceHover,
    outline: CasheColors.outline,
    outlineVariant: CasheColors.border,
    error: CasheColors.warning,
    onError: CasheColors.background,
    errorContainer: Color(0xFF4A2A2A),
    onErrorContainer: CasheColors.warning,
  );
  final base = ThemeData(
    colorScheme: scheme,
    fontFamily: _sans,
    useMaterial3: true,
  );
  return base.copyWith(
    scaffoldBackgroundColor: CasheColors.background,
    textTheme: _textTheme(base.textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: CasheColors.background,
      foregroundColor: CasheColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: _sans,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: CasheColors.text,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(style: _filled()),
    outlinedButtonTheme: OutlinedButtonThemeData(style: _outlined()),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: CasheColors.textSoft,
        textStyle: const TextStyle(
          fontFamily: _sans,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: const CardThemeData(
      color: CasheColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: CasheColors.border),
      ),
    ),
    inputDecorationTheme: _inputs(),
    dividerTheme: const DividerThemeData(color: CasheColors.divider, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: CasheColors.background,
      showDragHandle: true,
    ),
    dialogTheme: const DialogThemeData(backgroundColor: CasheColors.surface),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: CasheColors.text,
      contentTextStyle: TextStyle(
        fontFamily: _sans,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: CasheColors.background,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: CasheColors.surface,
      selectedColor: CasheColors.amber,
      side: const BorderSide(color: CasheColors.border),
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(
        fontFamily: _sans,
        fontWeight: FontWeight.w700,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: CasheColors.amber,
      linearTrackColor: CasheColors.track,
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: CasheColors.amber,
      thumbColor: CasheColors.amber,
    ),
  );
}

TextTheme _textTheme(TextTheme base) => base
    .apply(
      fontFamily: _sans,
      bodyColor: CasheColors.text,
      displayColor: CasheColors.text,
    )
    .copyWith(
      displayMedium: const TextStyle(
        fontFamily: _sans,
        fontSize: 46,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.4,
        height: 1,
      ),
      displaySmall: const TextStyle(
        fontFamily: _sans,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
      ),
      headlineSmall: const TextStyle(
        fontFamily: _sans,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      titleLarge: const TextStyle(
        fontFamily: _sans,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: const TextStyle(
        fontFamily: _sans,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
      bodyLarge: const TextStyle(
        fontFamily: _sans,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: const TextStyle(
        fontFamily: _sans,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: const TextStyle(
        fontFamily: _sans,
        fontSize: 12.5,
        color: CasheColors.muted,
      ),
    );

ButtonStyle _filled() => FilledButton.styleFrom(
  backgroundColor: CasheColors.amber,
  foregroundColor: CasheColors.background,
  disabledBackgroundColor: CasheColors.amber.withValues(alpha: 0.4),
  disabledForegroundColor: CasheColors.background,
  minimumSize: const Size.fromHeight(56),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
  ),
  textStyle: const TextStyle(
    fontFamily: _sans,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  ),
);

ButtonStyle _outlined() => OutlinedButton.styleFrom(
  foregroundColor: CasheColors.text,
  minimumSize: const Size.fromHeight(52),
  side: const BorderSide(color: CasheColors.outline),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
  ),
  textStyle: const TextStyle(
    fontFamily: _sans,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  ),
);

InputDecorationTheme _inputs() {
  OutlineInputBorder border(Color colour) => OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: colour, width: 1.5),
  );
  return InputDecorationTheme(
    filled: true,
    fillColor: CasheColors.input,
    hintStyle: const TextStyle(color: CasheColors.faint),
    labelStyle: const TextStyle(color: CasheColors.muted),
    floatingLabelStyle: const TextStyle(color: CasheColors.amber),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(CasheColors.outline),
    enabledBorder: border(CasheColors.outline),
    focusedBorder: border(CasheColors.amber),
    errorBorder: border(CasheColors.warning),
    focusedErrorBorder: border(CasheColors.warning),
  );
}
