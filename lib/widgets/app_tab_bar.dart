import 'package:flutter/material.dart';
import 'package:bombay_casting/theme/app_theme.dart';

class AppTabItem {
  const AppTabItem({required this.label, this.indicatorWidth});

  final String label;
  final double? indicatorWidth;
}

class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onChanged,
    this.spacing = 24,
  });

  final List<AppTabItem> tabs;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          _TabChip(
            label: tabs[i].label,
            isSelected: selectedIndex == i,
            indicatorWidth: tabs[i].indicatorWidth,
            onTap: () => onChanged(i),
          ),
        ],
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.indicatorWidth,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double? indicatorWidth;

  @override
  Widget build(BuildContext context) {
    final width = indicatorWidth ?? (label.length * 9.0).clamp(24.0, 56.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.innerTab,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: AppDurations.innerTab,
              style: TextStyle(
                color: isSelected ? AppColors.textPrimary : AppColors.textHint,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              child: Text(label),
            ),
            const SizedBox(height: AppSpacing.xs),
            AnimatedContainer(
              duration: AppDurations.innerTab,
              curve: Curves.easeOutCubic,
              height: 2,
              width: isSelected ? width : 0,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
