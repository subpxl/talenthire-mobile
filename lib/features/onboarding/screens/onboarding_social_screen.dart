import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/widgets/social_platforms.dart';
import 'package:bombay_casting/features/onboarding/first_login_step.dart';
import 'package:bombay_casting/features/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:bombay_casting/features/profile/widgets/social_links_fields_form.dart';

/// Final first-login onboarding step: social media links. Reuses
/// [SocialLinksFieldsForm] -- the same widget used by the standalone Edit
/// Profile screen -- so values stay consistent, and marks the profile as
/// completed once finished.
class OnboardingSocialScreen extends StatefulWidget {
  const OnboardingSocialScreen({super.key});

  @override
  State<OnboardingSocialScreen> createState() =>
      _OnboardingSocialScreenState();
}

class _OnboardingSocialScreenState extends State<OnboardingSocialScreen> {
  final _formKey = GlobalKey<SocialLinksFieldsFormState>();
  late final Map<String, String> _initialUrls;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _initialUrls =
        profile != null ? computeInitialSocialUrls(profile) : const {};
  }

  Future<void> _finish() async {
    if (_saving) return;
    final formState = _formKey.currentState;
    if (formState != null && !formState.validate()) return;

    setState(() => _saving = true);
    final appState = context.read<AppState>();
    try {
      final profile = appState.profile;
      if (profile != null) {
        var updated = profile;
        if (formState != null) {
          final metrics = formState.buildMetrics();
          if (metrics.isNotEmpty) {
            final primary = metrics.first;
            updated = updated
                .mergeFormSection('social', {
                  'primary_platform': primary.platform,
                  'handle': primary.handle,
                  'other_platforms': [
                    for (final metric in metrics.skip(1)) metric.platform,
                  ],
                })
                .copyWith(
                  contact: primary.url,
                  platformMetrics: metrics,
                );
          }
        }
        await appState.updateProfile(
          updated.copyWith(profileCompleted: true),
        );
      }
      await appState.completeSocialOnboarding();
    } catch (_) {
      if (mounted) {
        showAppToast(
          context,
          'Could not save. Try again or skip.',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _skip() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await context.read<AppState>().completeSocialOnboarding();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      step: FirstLoginStep.social,
      icon: Icons.share_outlined,
      title: 'Add your social links',
      subtitle: 'Showcase your work — this appears on your public profile.',
      actionLabel: 'Finish',
      actionLoading: _saving,
      onAction: _finish,
      onSkip: _skip,
      onBack: () => context.read<AppState>().goToPreviousFirstLoginStep(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: SocialLinksFieldsForm(
          key: _formKey,
          initialUrls: _initialUrls,
          platforms: SocialPlatformInfo.onboardingLinkFormPlatforms,
        ),
      ),
    );
  }
}
