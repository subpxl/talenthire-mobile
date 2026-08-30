import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';

class AppFormFields extends StatelessWidget {
  const AppFormFields({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: AppFormStyle.fieldGap),
          children[i],
        ],
      ],
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.optional = false,
    this.enabled = true,
    this.trailing,
    this.labelAsPlaceholder = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final bool optional;
  final bool enabled;
  final Widget? trailing;
  final bool labelAsPlaceholder;

  @override
  Widget build(BuildContext context) {
    final placeholder = hint ?? (labelAsPlaceholder ? label : null);
    final field = trailing != null && labelAsPlaceholder
        ? _boxedField(placeholder)
        : TextField(
            controller: controller,
            enabled: enabled,
            readOnly: !enabled,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            maxLines: maxLines,
            style: AppFormStyle.valueStyle,
            decoration: AppFormStyle.inputDecoration(hint: placeholder),
          );
    if (labelAsPlaceholder) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppFormSectionTitle(label, optional: optional),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: AppFormStyle.labelGap),
        field,
      ],
    );
  }

  Widget _boxedField(String? placeholder) {
    return Container(
      width: double.infinity,
      padding: AppFormStyle.fieldPadding,
      decoration: AppFormStyle.fieldBox,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: !enabled,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              maxLines: maxLines,
              style: AppFormStyle.valueStyle,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: AppFormStyle.hintStyle,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AppFormCheckbox extends StatelessWidget {
  const AppFormCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: IgnorePointer(
              child: Checkbox(
                value: value,
                onChanged: (_) {},
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: AppFormStyle.border, width: 1.4),
                activeColor: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class AppReadOnlyField extends StatelessWidget {
  const AppReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.labelAsPlaceholder = false,
  });

  final String label;
  final String value;
  final bool labelAsPlaceholder;

  @override
  Widget build(BuildContext context) {
    final empty = value.trim().isEmpty;
    final box = Container(
      width: double.infinity,
      padding: AppFormStyle.fieldPadding,
      decoration: AppFormStyle.fieldBox,
      child: Text(
        empty ? (labelAsPlaceholder ? label : '-') : value,
        style: empty ? AppFormStyle.hintStyle : AppFormStyle.valueStyle,
      ),
    );
    if (labelAsPlaceholder) return box;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormSectionTitle(label),
        const SizedBox(height: AppFormStyle.labelGap),
        box,
      ],
    );
  }
}

class AppPlatformLinkField extends StatelessWidget {
  const AppPlatformLinkField({
    super.key,
    required this.label,
    required this.icon,
    required this.controller,
    this.hint = 'Paste here your URL',
  });

  final String label;
  final Widget icon;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: AppFormStyle.labelStyle),
            ),
            icon,
          ],
        ),
        const SizedBox(height: AppFormStyle.labelGap),
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          style: AppFormStyle.valueStyle,
          decoration: AppFormStyle.inputDecoration(hint: hint),
        ),
      ],
    );
  }
}

class AppChipField extends StatelessWidget {
  const AppChipField({
    super.key,
    required this.label,
    required this.options,
    required this.isSelected,
    required this.onTap,
    this.optional = false,
  });

  final String label;
  final List<String> options;
  final bool Function(String option) isSelected;
  final ValueChanged<String> onTap;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFormSectionTitle(label, optional: optional),
        const SizedBox(height: AppFormStyle.labelGap),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in options)
              AppPillChip(
                label: option,
                isSelected: isSelected(option),
                onTap: () => onTap(option),
              ),
          ],
        ),
      ],
    );
  }
}
