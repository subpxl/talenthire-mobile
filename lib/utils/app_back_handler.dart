import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/exit_confirm_dialog.dart';

/// Android system back: go to home tab first, then ask before exiting.
Future<void> handleMainScreenBack(
  BuildContext context, {
  required int selectedTabIndex,
  required VoidCallback goToHomeTab,
}) async {
  if (selectedTabIndex != 0) {
    goToHomeTab();
    return;
  }

  final shouldExit = await showExitConfirmDialog(context);
  if (shouldExit && context.mounted) {
    SystemNavigator.pop();
  }
}

/// Android system back on auth/setup screens: confirm before exiting.
Future<void> handleExitBack(BuildContext context) async {
  final shouldExit = await showExitConfirmDialog(context);
  if (shouldExit && context.mounted) {
    SystemNavigator.pop();
  }
}
