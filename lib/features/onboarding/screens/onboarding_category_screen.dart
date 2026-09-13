import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_filter_widgets.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/widgets/option_picker.dart';
import 'package:bombay_casting/features/onboarding/first_login_step.dart';
import 'package:bombay_casting/features/onboarding/widgets/onboarding_step_scaffold.dart';

/// First-login onboarding step: select talent category (multiselect pills).
///
/// Saves into the same `personal.categories` field (and `profile.talent`)
/// used by the standalone Edit Profile "Personal" screen, so the value is
/// reused/shared rather than duplicated.
class OnboardingCategoryScreen extends StatefulWidget {
  const OnboardingCategoryScreen({super.key});

  @override
  State<OnboardingCategoryScreen> createState() =>
      _OnboardingCategoryScreenState();
}

class _OnboardingCategoryScreenState extends State<OnboardingCategoryScreen> {
  final Set<String> _selected = {};
  String _selectedAge = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    if (profile != null) {
      final personal = profile.formSection('personal');
      final stored = personal['categories'];
      if (stored is List && stored.isNotEmpty) {
        _selected.addAll(
          stored
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty && item != 'Any'),
        );
      } else if (profile.talent.trim().isNotEmpty &&
          profile.talent.toLowerCase() != 'influencer') {
        _selected.add(profile.talent.trim());
      }
      _selectedAge = (personal['age'] ??
              (profile.age != null ? '${profile.age}' : _selectedAge))
          .toString();
    }
  }

  Future<void> _pickAge() async {
    final value = await showOptionPicker(
      context: context,
      title: 'Age',
      options: ProfileOptions.ages,
      selected: _selectedAge,
    );
    if (value != null) setState(() => _selectedAge = value);
  }

  void _toggle(String option) {
    setState(() {
      if (!_selected.remove(option)) _selected.add(option);
    });
  }

  Future<void> _continue() async {
    if (_saving) return;
    setState(() => _saving = true);
    final appState = context.read<AppState>();
    try {
      final profile = appState.profile;
      if (profile != null && _selected.isNotEmpty) {
        final updated = profile
            .mergeFormSection('personal', {
              'categories': _selected.toList(),
              'age': _selectedAge,
            })
            .copyWith(
              talent: _selected.join(', '),
              age: int.tryParse(_selectedAge.replaceAll(RegExp(r'[^0-9]'), '')),
            );
        await appState.updateProfile(updated);
      }
      await appState.completeCategoryOnboarding();
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
      await context.read<AppState>().completeCategoryOnboarding();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      step: FirstLoginStep.category,
      icon: Icons.category_outlined,
      title: 'What best describes you?',
      subtitle:
          'Select all categories that match your talent. You can update this anytime.',
      actionLabel: 'Next',
      actionEnabled: _selected.isNotEmpty && _selectedAge.isNotEmpty,
      actionLoading: _saving,
      onAction: _continue,
      onSkip: _skip,
      onBack: () => context.read<AppState>().goToPreviousFirstLoginStep(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final option in ProfileOptions.talentCategories)
                  AppPillChip(
                    label: option,
                    isSelected: _selected.contains(option),
                    onTap: () => _toggle(option),
                  ),
              ],
            ),
            const SizedBox(height: 28),
            _StylishAgePicker(
              value: _selectedAge,
              onTap: _pickAge,
            ),
          ],
        ),
      ),
    );
  }
}

class _StylishAgePicker extends StatelessWidget {
  const _StylishAgePicker({
    required this.value,
    required this.onTap,
  });

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your age',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Ink(
              decoration: BoxDecoration(
                color: hasValue ? AppColors.primaryLight : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: hasValue
                      ? AppColors.primary.withAlpha(150)
                      : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasValue
                            ? AppColors.primary.withAlpha(40)
                            : Colors.grey.shade100,
                      ),
                      child: Icon(
                        Icons.cake_outlined,
                        size: 18,
                        color: hasValue
                            ? AppColors.primary
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasValue ? '$value years old' : 'Select your age',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              hasValue ? FontWeight.w600 : FontWeight.w500,
                          color: hasValue
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasValue
                            ? AppColors.primary.withAlpha(30)
                            : Colors.grey.shade100,
                      ),
                      child: Icon(
                        Icons.expand_more,
                        size: 20,
                        color: hasValue
                            ? AppColors.primary
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
