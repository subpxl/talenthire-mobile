import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';

class DeactivatedAccountScreen extends StatefulWidget {
  const DeactivatedAccountScreen({super.key});

  @override
  State<DeactivatedAccountScreen> createState() =>
      _DeactivatedAccountScreenState();
}

class _DeactivatedAccountScreenState extends State<DeactivatedAccountScreen> {
  bool _isReactivating = false;
  bool _isSigningOut = false;

  Future<void> _reactivate() async {
    setState(() => _isReactivating = true);
    try {
      await context.read<AppState>().reactivateAccount();
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        'Could not reactivate account. Please try again.',
        type: AppToastType.error,
      );
    } finally {
      if (mounted) setState(() => _isReactivating = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    await context.read<AppState>().logout();
    if (mounted) setState(() => _isSigningOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final busy = _isReactivating || _isSigningOut;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.pause_circle_outline,
                size: 72,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Account deactivated',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your profile is hidden from agencies and other users. '
                'Reactivate when you are ready to use Bombay Casting again.',
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: busy ? null : _reactivate,
                  child: _isReactivating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Reactivate account'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: busy ? null : _signOut,
                  child: _isSigningOut
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
