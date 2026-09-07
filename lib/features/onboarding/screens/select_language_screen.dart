import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/utils/app_strings.dart';
import 'package:bombay_casting/features/onboarding/first_login_step.dart';
import 'package:bombay_casting/features/onboarding/widgets/onboarding_step_scaffold.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, this.isOnboarding = false});

  final bool isOnboarding;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  int selectedIndex = 1; // Default to English initially

  final languages = const [
    Language(native: 'हिंदी', english: 'Hindi', localeCode: 'hi'),
    Language(native: 'English', english: 'English', localeCode: 'en'),
    Language(native: 'मराठी', english: 'Marathi', localeCode: 'mr'),
    Language(native: 'ગુજરાતી', english: 'Gujarati', localeCode: 'gu'),
    Language(native: 'বাংলা', english: 'Bengali', localeCode: 'bn'),
    Language(native: 'ಕನ್ನಡ', english: 'Kannada', localeCode: 'kn'),
    Language(native: 'தமிழ்', english: 'Tamil', localeCode: 'ta'),
    Language(native: 'മലയാളം', english: 'Malayalam', localeCode: 'ml'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      final localeCode = appState.appLocale?.languageCode ?? 'en';
      final index = languages.indexWhere((l) => l.localeCode == localeCode);
      if (index != -1) {
        setState(() => selectedIndex = index);
      }
    });
  }

  Future<void> _applyLanguage() async {
    final locale = Locale(languages[selectedIndex].localeCode);
    final appState = context.read<AppState>();
    if (widget.isOnboarding) {
      await appState.completeLanguageOnboarding(locale);
      return;
    }
    await appState.setLocale(locale);
    if (!mounted) return;
    Navigator.maybePop(context);
  }

  Widget _languageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: languages.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 2.05,
      ),
      itemBuilder: (context, index) {
        final language = languages[index];
        final selected = selectedIndex == index;

        return GestureDetector(
          onTap: () => setState(() => selectedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  language.native,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.1,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  language.english,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n?.chooseYourAppLanguage ?? 'Choose your app language';

    if (widget.isOnboarding) {
      return OnboardingStepScaffold(
        step: FirstLoginStep.language,
        icon: Icons.translate_outlined,
        title: title,
        subtitle: context.chooseLanguageSubtitle,
        actionLabel: context.nextAction,
        onAction: _applyLanguage,
        onBack: () => context.read<AppState>().goToPreviousFirstLoginStep(),
        child: SingleChildScrollView(child: _languageGrid()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(l10n?.changeLanguage ?? 'Change language'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 28),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                        color: AppColors.primaryLight,
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.kemptyStr,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _languageGrid(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_user_outlined,
                        size: 21,
                        color: AppColors.accentGreen,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.yourDataIs100SafeWithUs,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyLanguage,
                      style: AppButtonStyle.banner(),
                      child: Text(AppLocalizations.of(context)!.update),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Language {
  final String native;
  final String english;
  final String localeCode;

  const Language({
    required this.native,
    required this.english,
    required this.localeCode,
  });
}
