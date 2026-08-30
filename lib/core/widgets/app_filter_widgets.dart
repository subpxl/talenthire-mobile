import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';

/// Standardized dropdown field used across filters and profile forms.
class AppDropdownField extends StatelessWidget {
  const AppDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.isEmpty ? (hint ?? '') : value;
    final isPlaceholder = value.isEmpty && hint != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayValue,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPlaceholder
                          ? Colors.grey.shade400
                          : Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Standardized chip/pill button used across filters and edit forms.
class AppPillChip extends StatelessWidget {
  const AppPillChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor = AppColors.primary,
    this.showCheckmark = false,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final bool showCheckmark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor.withAlpha(150)
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? activeColor : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            if (showCheckmark && isSelected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check, size: 12, color: activeColor),
            ] else if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(
                icon,
                size: 12,
                color: isSelected ? activeColor : Colors.grey.shade600,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standardized section title for filter and form sections.
class AppFormSectionTitle extends StatelessWidget {
  const AppFormSectionTitle(
    this.title, {
    super.key,
    this.optional = false,
    this.optionalText = 'Optional',
  });

  final String title;
  final bool optional;
  final String optionalText;

  @override
  Widget build(BuildContext context) {
    if (optional) {
      return Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            optionalText,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );
    }
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}

/// Standardized slider value badge.
class AppSliderBadge extends StatelessWidget {
  const AppSliderBadge(
    this.text, {
    super.key,
    this.color = const Color(0xFFDC1C38),
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
