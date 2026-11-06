import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles [ThemeData] from the colour, type and spacing tokens.
///
/// Light only — the admin app ships no dark theme.
class AppTheme {
  const AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primaryDark,
      onPrimaryContainer: AppColors.textOnPrimary,
      secondary: AppColors.accent,
      onSecondary: AppColors.textOnAccent,
      surface: AppColors.surface,
      onSurface: AppColors.textDark,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.background,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      errorContainer: AppColors.errorBg,
      onErrorContainer: AppColors.error,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
      shadow: AppColors.shadowHard,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
      splashColor: AppColors.tintMaroon,
      highlightColor: AppColors.tintMaroon,

      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineSmall: AppTypography.sectionTitle,
        titleMedium: AppTypography.titleMedium,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.caption,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.textOnPrimary,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.displaySmall.copyWith(
          color: AppColors.textOnPrimary,
        ),
      ),

      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x3,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textGrey),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
          textStyle: AppTypography.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.cardRadius,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.border),
          textStyle: AppTypography.labelLarge,
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.cardRadius,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTypography.labelMedium,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.tintMaroon,
        selectedColor: AppColors.primary,
        side: BorderSide.none,
        labelStyle: AppTypography.pill,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x1,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pillRadius),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.sheet),
          ),
        ),
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.sheetRadius),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.transparent,
        indicatorColor: AppColors.tintMaroon,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppTypography.navLabel.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                )
              : AppTypography.navLabel,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textOnPrimary,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.cardRadius),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// The admin's colours laid over [base], the theme the app already runs
  /// with. `AdminTheme` hands this to every admin screen.
  ///
  /// Colours only: [base]'s sizes, shapes and type stay as they are. Since the
  /// 2026-10-06 merge the admin runs inside the customer side's [MaterialApp],
  /// on Material's default theme, and [light] reaches none of it — so every
  /// button that takes its colour from the theme came out the default purple.
  ///
  /// Anything that reads [ColorScheme.primary] follows the brand: filled
  /// buttons fill with it, outlined and text buttons letter their label and
  /// icon in it. A button that names its own colours — Cancel Order's red,
  /// Logout's tint — keeps them, icon included, only while nothing here sets
  /// an icon colour: the framework ranks a theme's icon colour above a
  /// button's own foreground.
  static ThemeData brandOver(ThemeData base) {
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        // The Undo on a SnackBar: white, as [light] has it. Maroon would
        // vanish into the dark bar, and the default is the old lavender.
        inversePrimary: AppColors.textOnPrimary,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          side: _brandOutline,
        ).merge(base.outlinedButtonTheme.style),
      ),
      // MaterialApp sets the caret and selection colour from the app theme,
      // above every route; a nested Theme passes these down instead.
      textSelectionTheme: base.textSelectionTheme.copyWith(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.primary.withValues(alpha: 0.4),
      ),
    );
  }

  /// An outlined button's border in the brand colour. Disabled is left to the
  /// button's own default, so it still reads as disabled.
  static final WidgetStateProperty<BorderSide?> _brandOutline =
      WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? null
            : const BorderSide(color: AppColors.primary),
      );
}
