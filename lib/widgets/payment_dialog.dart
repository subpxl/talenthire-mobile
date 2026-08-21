import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/legal_links.dart';
import 'app_button.dart';

/// Reusable payment dialog for premium upgrade.
class PaymentDialog extends StatefulWidget {
  final String title;
  final String description;
  final double amount;
  final String buttonText;
  final Future<void> Function() onPay;
  final IconData icon;
  final Color accentColor;

  const PaymentDialog({
    super.key,
    required this.title,
    required this.description,
    required this.amount,
    required this.onPay,
    this.buttonText = 'Pay Now',
    this.icon = Icons.payment,
    this.accentColor = AppColors.primary,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    required double amount,
    required Future<void> Function() onPay,
    String buttonText = 'Pay Now',
    IconData icon = Icons.payment,
    Color accentColor = AppColors.primary,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentDialog(
        title: title,
        description: description,
        amount: amount,
        onPay: onPay,
        buttonText: buttonText,
        icon: icon,
        accentColor: accentColor,
      ),
    );
  }
}

class _PaymentDialogState extends State<PaymentDialog> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.accentColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, color: widget.accentColor, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withAlpha(60)),
              ),
              child: Text(
                '₹${widget.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: widget.buttonText,
              isLoading: _isProcessing,
              backgroundColor: widget.accentColor,
              onPressed: _isProcessing
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      await widget.onPay();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () => openLegalPage(context, LegalLinks.refunds),
              child: const Text('Refund & Cancellation Policy'),
            ),
          ],
        ),
      ),
    );
  }
}
