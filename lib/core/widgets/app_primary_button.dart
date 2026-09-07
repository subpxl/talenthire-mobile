import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppButtonStyle.formHeight,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: AppButtonStyle.banner(),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.onBrand,
                ),
              )
            : Text(label),
      ),
    );
  }
}
