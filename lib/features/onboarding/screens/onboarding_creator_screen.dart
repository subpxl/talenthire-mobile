import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/features/onboarding/first_login_step.dart';
import 'package:bombay_casting/features/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:bombay_casting/features/profile/widgets/content_creator_fields_form.dart';

/// First-login onboarding step: "For content creators" fields, all on a
/// single screen. Reuses [ContentCreatorFieldsForm] -- the same widget used
/// by the standalone Edit Profile screen -- so values stay consistent.
class OnboardingCreatorScreen extends StatefulWidget {
  const OnboardingCreatorScreen({super.key});

  @override
  State<OnboardingCreatorScreen> createState() =>
      _OnboardingCreatorScreenState();
}

class _OnboardingCreatorScreenState extends State<OnboardingCreatorScreen> {
  static const _section = 'creator';

  final _formKey = GlobalKey<ContentCreatorFieldsFormState>();
  late final Map<String, dynamic> _initialData;
  late final List<String> _initialNiches;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _initialData = profile?.formSection(_section) ?? const {};
    _initialNiches = profile?.niches ?? const [];
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    final appState = context.read<AppState>();
    try {
      final formState = _formKey.currentState;
      final profile = appState.profile;
      if (formState != null && profile != null) {
        final updated = profile
            .mergeFormSection(_section, formState.buildData())
            .copyWith(niches: formState.selectedNiches);
        await appState.updateProfile(updated);
      }
      await appState.completeCreatorOnboarding();
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
      await context.read<AppState>().completeCreatorOnboarding();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      step: FirstLoginStep.creator,
      title: 'For content creators',
      subtitle: 'Add details brands look for when picking creators to work with.',
      actionLabel: 'Next',
      actionLoading: _saving,
      onAction: _continue,
      onSkip: _skip,
      onBack: () => context.read<AppState>().goToPreviousFirstLoginStep(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 8),
        child: ContentCreatorFieldsForm(
          key: _formKey,
          initialData: _initialData,
          initialNiches: _initialNiches,
        ),
      ),
    );
  }
}
