import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// One tappable line on the More tab.
class MenuEntry {
  const MenuEntry({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  /// Null leaves the row visibly unavailable rather than silently dead.
  final VoidCallback? onTap;
}

/// A captioned card of menu rows — STORE, SYSTEM, and so on.
class MenuSection extends StatelessWidget {
  const MenuSection({super.key, required this.caption, required this.entries});

  final String caption;
  final List<MenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.x3,
            bottom: AppSpacing.x2,
          ),
          child: Text(caption, style: AppTypography.overline),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.cardRadius,
            boxShadow: AppShadows.softShadow,
          ),
          child: Column(
            children: [
              for (final (index, entry) in entries.indexed) ...[
                if (index > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.x4),
                    child: Divider(height: 1),
                  ),
                _MenuRow(entry: entry),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.entry});

  final MenuEntry entry;

  /// Straight from the design; not on the base-4 scale.
  static const double _iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final available = entry.onTap != null;
    final tint = available ? AppColors.primary : AppColors.textMuted;
    final subtitle = entry.subtitle;

    return Semantics(
      label: entry.title,
      button: available,
      enabled: available,
      child: Material(
        color: AppColors.transparent,
        borderRadius: AppRadii.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: entry.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4,
              vertical: AppSpacing.x4,
            ),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Icon(entry.icon, size: _iconSize, color: tint),
                  const SizedBox(width: AppSpacing.x3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            color: available
                                ? AppColors.textDark
                                : AppColors.textMuted,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                      ],
                    ),
                  ),
                  // No chevron where there is nowhere to go — an arrow that
                  // leads nowhere reads as broken.
                  if (available)
                    const Icon(
                      Icons.chevron_right,
                      size: _iconSize,
                      color: AppColors.textMuted,
                    )
                  else
                    Text('Soon', style: AppTypography.caption),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
