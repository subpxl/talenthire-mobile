import 'package:flutter/material.dart';

enum AppToastType { success, error }

void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.success,
}) {
  final isSuccess = type == AppToastType.success;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 6,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
              size: 20,
            ),
          ],
        ),
      ),
    );
}

void showAppSuccessToast(BuildContext context, String message) {
  showAppToast(context, message);
}
