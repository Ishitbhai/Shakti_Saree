import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/formatters.dart';

/// Throwaway screen that renders every design token so they can be eyeballed
/// against the design. Delete once the real screens exist — nothing should
/// ever import this.
class TokenPreview extends StatelessWidget {
  const TokenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Token Preview')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.pagePadding),
        children: const [
          _Section(title: 'Colours', child: _ColourGrid()),
          _Section(title: 'Type scale', child: _TypeSpecimens()),
          _Section(title: 'Formatters', child: _FormatterSamples()),
          _Section(title: 'Radii & shadows', child: _ShapeSamples()),
          SizedBox(height: AppSpacing.x8),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.sectionTitle),
          const SizedBox(height: AppSpacing.x4),
          child,
        ],
      ),
    );
  }
}

class _ColourGrid extends StatelessWidget {
  const _ColourGrid();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.x3,
      runSpacing: AppSpacing.x4,
      children: [
        for (final entry in AppColors.all.entries)
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: entry.value,
                    borderRadius: AppRadii.cardRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(entry.key, style: AppTypography.caption),
                Text(_hex(entry.value), style: AppTypography.caption),
              ],
            ),
          ),
      ],
    );
  }

  static String _hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}';
}

class _TypeSpecimens extends StatelessWidget {
  const _TypeSpecimens();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in AppTypography.all.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}  ·  '
                  '${entry.value.fontSize?.toStringAsFixed(0)}pt  ·  '
                  'w${(entry.value.fontWeight?.value ?? 400)}',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.x1),
                Text('Shakti Saree — 1,248', style: entry.value),
              ],
            ),
          ),
      ],
    );
  }
}

class _FormatterSamples extends StatelessWidget {
  const _FormatterSamples();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('count(1248)', Formatters.count(1248)),
        _row('rupeesFromPaise(629700)', Formatters.rupeesFromPaise(629700)),
        _row(
          'rupeesFromPaise(123456700)',
          Formatters.rupeesFromPaise(123456700),
        ),
        _row('date(DateTime.now())', Formatters.date(now)),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.x2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(child: Text(label, style: AppTypography.caption)),
        Text(value, style: AppTypography.price),
      ],
    ),
  );
}

class _ShapeSamples extends StatelessWidget {
  const _ShapeSamples();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.x4,
      runSpacing: AppSpacing.x4,
      children: [
        _box(
          'card 16\nsoftShadow',
          AppRadii.cardRadius,
          AppShadows.softShadow,
          AppColors.surface,
        ),
        _box(
          'sheet 28',
          AppRadii.sheetRadius,
          AppShadows.softShadow,
          AppColors.surface,
        ),
        _box(
          'pill 999',
          AppRadii.pillRadius,
          AppShadows.softShadow,
          AppColors.surface,
        ),
        _box(
          'brutalShadow',
          AppRadii.cardRadius,
          AppShadows.brutalShadow,
          AppColors.accent,
        ),
      ],
    );
  }

  Widget _box(
    String label,
    BorderRadius radius,
    List<BoxShadow> shadow,
    Color fill,
  ) => Container(
    width: 148,
    height: 76,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: fill,
      borderRadius: radius,
      boxShadow: shadow,
      border: Border.all(color: AppColors.border),
    ),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: AppTypography.caption,
    ),
  );
}
