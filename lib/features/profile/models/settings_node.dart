import 'package:flutter/material.dart';

/// A single row inside the Account Settings hierarchy.
///
/// A node is either a *branch* (has [children] grouped into [SettingsSection]s
/// and drills down to another screen), an *article* (opens a static text page),
/// or a *leaf* (performs [onTap], shows a [value], or renders a [toggle]).
class SettingsNode {
  const SettingsNode({
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.valueColor,
    this.children,
    this.article,
    this.onTap,
    this.toggle,
    this.danger = false,
    this.iconColor,
  });

  /// Leading icon for the row.
  final IconData icon;

  /// Primary label.
  final String title;

  /// Optional secondary line under the title.
  final String? subtitle;

  /// Optional trailing status text (e.g. "English", "Verified").
  final String? value;

  /// Optional colour for [value] (e.g. green for "Verified").
  final Color? valueColor;

  /// When non-null this node is a branch: tapping it drills down into a screen
  /// titled [title] showing these sections.
  final List<SettingsSection>? children;

  /// Static article body. Tapping the row opens a readable text page.
  final String? article;

  /// Leaf action. Ignored when [children] or [article] is set.
  final VoidCallback? onTap;

  /// When set the row renders a switch instead of a chevron.
  final SettingsToggle? toggle;

  /// Renders the row in the destructive (red) style.
  final bool danger;

  /// Optional override for the leading icon colour.
  final Color? iconColor;

  bool get isBranch => children != null && children!.isNotEmpty;

  bool get hasArticle => article != null && article!.trim().isNotEmpty;

  bool get hasToggle => toggle != null;

  /// Whether a chevron should be shown for this row.
  bool get showChevron =>
      !hasToggle && (isBranch || hasArticle || onTap != null);
}

/// A togglable leaf. Purely local state for now (no backend wiring).
class SettingsToggle {
  const SettingsToggle({this.initialValue = false, this.onChanged});

  final bool initialValue;
  final ValueChanged<bool>? onChanged;
}

/// A titled group of [SettingsNode]s rendered as one card with an optional
/// header above it.
class SettingsSection {
  const SettingsSection({
    this.title,
    required this.items,
    this.danger = false,
  });

  /// Optional header shown above the card. Rendered in red when [danger].
  final String? title;

  final List<SettingsNode> items;

  /// Colours the section header in the destructive style.
  final bool danger;
}
