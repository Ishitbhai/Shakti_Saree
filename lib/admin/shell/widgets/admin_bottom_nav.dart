import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// One slot in the admin bottom bar.
class AdminNavItem {
  const AdminNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Bottom bar for the admin section.
///
/// Hand-built rather than a Material [NavigationBar] because the design marks
/// the active tab with a rule along the top edge, not a pill behind the icon.
class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const List<AdminNavItem> items = [
    AdminNavItem(label: 'Dashboard', icon: Icons.bar_chart_rounded),
    AdminNavItem(label: 'Products', icon: Icons.inventory_2_outlined),
    AdminNavItem(label: 'Orders', icon: Icons.receipt_long_outlined),
    AdminNavItem(label: 'Users', icon: Icons.people_outline),
    AdminNavItem(label: 'More', icon: Icons.more_horiz),
  ];

  static const double _barHeight = 64;
  static const double _indicatorHeight = 3;
  static const double _indicatorWidth = 52;
  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavSlot(
                    item: items[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AdminNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = selected ? AppColors.primary : AppColors.textMuted;

    return Semantics(
      label: item.label,
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sits flush with the top edge; kept in the layout when
              // unselected so the icons do not shift between tabs.
              Container(
                height: AdminBottomNav._indicatorHeight,
                width: AdminBottomNav._indicatorWidth,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.transparent,
                  borderRadius: AppRadii.pillRadius,
                ),
              ),
              const Spacer(),
              Icon(item.icon, size: AdminBottomNav._iconSize, color: tint),
              const SizedBox(height: AppSpacing.x1),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.navLabel.copyWith(
                  color: tint,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
