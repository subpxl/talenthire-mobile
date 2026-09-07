import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/utils/app_strings.dart';
import 'package:bombay_casting/features/onboarding/first_login_step.dart';

class OnboardingStepScaffold extends StatelessWidget {
  const OnboardingStepScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.person_outline,
    this.actionEnabled = true,
    this.actionLoading = false,
    this.onSkip,
    this.onBack,
  });

  final FirstLoginStep step;
  final String title;
  final String subtitle;
  final Widget child;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData icon;
  final bool actionEnabled;
  final bool actionLoading;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: actionLoading ? null : onBack,
              ),
        actions: [
          if (onSkip != null)
            TextButton(
              onPressed: actionLoading ? null : onSkip,
              child: Text(
                context.skipAction,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          child: Column(
            children: [
              _StepDots(activeIndex: step.setupIndex),
              const SizedBox(height: 28),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryLight,
                ),
                child: Icon(icon, size: 30, color: AppColors.primary),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  height: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(child: child),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed:
                      !actionEnabled || actionLoading ? null : onAction,
                  style: AppButtonStyle.banner(),
                  child: actionLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(FirstLoginStep.setupStepCount, (index) {
        final reached = index <= activeIndex;
        return Container(
          width: index == activeIndex ? 18 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: reached ? AppColors.primary : const Color(0xFFE8E8E8),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
