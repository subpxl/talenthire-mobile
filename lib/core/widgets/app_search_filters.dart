import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.compact = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fontSize = compact ? 13.0 : 14.0;
    final iconSize = compact ? 18.0 : 22.0;
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(
        fontSize: fontSize,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.textHint,
          fontSize: fontSize,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: AppColors.textHint,
          size: iconSize,
        ),
        prefixIconConstraints: compact
            ? const BoxConstraints(minWidth: 36, minHeight: 36)
            : null,
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        constraints: compact
            ? const BoxConstraints.tightFor(
                height: AppSearchAndChips.searchRowHeight,
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
    if (!compact) return field;
    return SizedBox(height: AppSearchAndChips.searchRowHeight, child: field);
  }
}

class AppFilterChipRow extends StatelessWidget {
  const AppFilterChipRow({
    super.key,
    required this.options,
    required this.selectedChips,
    required this.onToggle,
    this.solidYellow = false,
  });

  final List<String> options;
  final Set<String> selectedChips;
  final ValueChanged<String> onToggle;
  final bool solidYellow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSearchAndChips.chipRowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final option = options[index];
          final isAllOption = index == 0 ||
              option == 'All' ||
              option.toLowerCase() == 'any';
          final isSelected = isAllOption
              ? (selectedChips.isEmpty ||
                  selectedChips.contains('Any') ||
                  selectedChips.contains('All'))
              : (selectedChips.contains(option) &&
                  !selectedChips.contains('Any') &&
                  !selectedChips.contains('All'));
          return AppPillChip(
            label: option,
            isSelected: isSelected,
            showCheckmark: isSelected && !isAllOption,
            fontWeight: FontWeight.w700,
            solidYellow: solidYellow,
            onTap: () => onToggle(option),
          );
        },
      ),
    );
  }
}

class AppSearchWithFilter extends StatelessWidget {
  const AppSearchWithFilter({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.onSearchChanged,
    this.onFilterTap,
  });

  final TextEditingController searchController;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppSearchField(
            controller: searchController,
            hintText: searchHint,
            onChanged: onSearchChanged,
            compact: true,
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: onFilterTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.tune,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AppSearchAndChips extends StatelessWidget {
  const AppSearchAndChips({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.chipOptions,
    required this.selectedChips,
    required this.onSearchChanged,
    required this.onChipToggled,
    this.onFilterTap,
    this.solidYellowChips = false,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.screenH,
      4,
      AppSpacing.screenH,
      4,
    ),
  });

  final TextEditingController searchController;
  final String searchHint;
  final List<String> chipOptions;
  final Set<String> selectedChips;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onChipToggled;
  final VoidCallback? onFilterTap;
  final bool solidYellowChips;
  final EdgeInsetsGeometry padding;

  static const searchRowHeight = 40.0;
  static const chipRowHeight = 28.0;
  static const gap = 6.0;

  static double heightFor(EdgeInsetsGeometry padding) {
    final resolved = padding.resolve(TextDirection.ltr);
    return resolved.top +
        searchRowHeight +
        gap +
        chipRowHeight +
        resolved.bottom;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSearchWithFilter(
            searchController: searchController,
            searchHint: searchHint,
            onSearchChanged: onSearchChanged,
            onFilterTap: onFilterTap,
          ),
          const SizedBox(height: 6),
          AppFilterChipRow(
            options: chipOptions,
            selectedChips: selectedChips,
            onToggle: onChipToggled,
            solidYellow: solidYellowChips,
          ),
        ],
      ),
    );
  }
}
