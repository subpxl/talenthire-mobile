import 'package:flutter/material.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/features/profile/models/settings_node.dart';
import 'package:bombay_casting/features/profile/screens/settings_group_screen.dart';

/// Renders a list of [SettingsSection]s as grouped cards.
///
/// Shared by the root Account Settings screen and every drill-down level so
/// the hierarchy looks identical at any depth.
class SettingsSectionList extends StatelessWidget {
  const SettingsSectionList({
    super.key,
    required this.sections,
    this.footer,
    this.padding,
  });

  final List<SettingsSection> sections;

  /// Optional widget rendered after all sections (e.g. a logout button).
  final Widget? footer;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.md,
            AppSpacing.screenH,
            AppSpacing.scrollBottom,
          ),
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.lg),
          _SettingsSectionView(section: sections[i]),
        ],
        if (footer != null) ...[
          const SizedBox(height: AppSpacing.lg),
          footer!,
        ],
      ],
    );
  }
}

class _SettingsSectionView extends StatelessWidget {
  const _SettingsSectionView({required this.section});

  final SettingsSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.sm),
            child: Text(
              section.title!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color:
                    section.danger ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < section.items.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, indent: 56, endIndent: 16),
                _SettingsRow(node: section.items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatefulWidget {
  const _SettingsRow({required this.node});

  final SettingsNode node;

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow> {
  late bool _toggleValue = widget.node.toggle?.initialValue ?? false;

  void _handleTap() {
    final node = widget.node;
    if (node.isBranch) {
      AppNavigation.push(
        context,
        SettingsGroupScreen(title: node.title, sections: node.children!),
      );
      return;
    }
    if (node.hasArticle) {
      AppNavigation.push(
        context,
        SettingsArticleScreen(title: node.title, body: node.article!),
      );
      return;
    }
    node.onTap?.call();
  }

  void _handleToggle(bool value) {
    setState(() => _toggleValue = value);
    widget.node.toggle?.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final Color titleColor =
        node.danger ? AppColors.primary : AppColors.textPrimary;
    final Color iconColor =
        node.iconColor ?? (node.danger ? AppColors.primary : AppColors.textPrimary);

    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      child: Row(
        children: [
          Icon(node.icon, size: 22, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                if (node.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    node.subtitle!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildTrailing(node),
        ],
      ),
    );

    if (node.hasToggle) {
      // Toggle rows aren't tappable as a whole; only the switch reacts.
      return row;
    }

    return InkWell(
      onTap: node.showChevron ? _handleTap : null,
      child: row,
    );
  }

  Widget _buildTrailing(SettingsNode node) {
    if (node.hasToggle) {
      return Switch.adaptive(
        value: _toggleValue,
        activeThumbColor: AppColors.primary,
        onChanged: _handleToggle,
      );
    }

    final children = <Widget>[];
    if (node.value != null) {
      children.add(
        Flexible(
          child: Text(
            node.value!,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: node.valueColor ?? AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    if (node.showChevron) {
      if (children.isNotEmpty) children.add(const SizedBox(width: 6));
      children.add(
        const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}
