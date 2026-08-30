import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textHint,
          size: 22,
        ),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
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
  }
}

class AppFilterChipRow extends StatelessWidget {
  const AppFilterChipRow({
    super.key,
    required this.options,
    required this.selectedChips,
    required this.onToggle,
  });

  final List<String> options;
  final Set<String> selectedChips;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isAllOption = option == 'All' || option.toLowerCase() == 'any';
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
            onTap: () => onToggle(option),
          );
        },
      ),
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
  });

  final TextEditingController searchController;
  final String searchHint;
  final List<String> chipOptions;
  final Set<String> selectedChips;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onChipToggled;
  final VoidCallback? onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.screenV,
        AppSpacing.screenH,
        AppSpacing.sm,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AppSearchField(
                  controller: searchController,
                  hintText: searchHint,
                  onChanged: onSearchChanged,
                ),
              ),
              if (onFilterTap != null) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    onPressed: onFilterTap,
                    icon: const Icon(Icons.tune, color: AppColors.textPrimary, size: 22),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          AppFilterChipRow(
            options: chipOptions,
            selectedChips: selectedChips,
            onToggle: onChipToggled,
          ),
        ],
      ),
    );
  }
}
