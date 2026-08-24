import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

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

  void _applyLanguage() {
    final appState = context.read<AppState>();
    appState.setLocale(Locale(languages[selectedIndex].localeCode));
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
                      child: Center(child: Text(AppLocalizations.of(context)!.kemptyStr,
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n?.chooseYourAppLanguage ?? 'Choose your app language',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: languages.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 18,
                        mainAxisSpacing: 18,
                        childAspectRatio: 1.95,
                      ),
                      itemBuilder: (context, index) {
                        final language = languages[index];
                        final selected = selectedIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedIndex = index);
                            // Optionally apply immediately: 
                            // context.read<AppState>().setLocale(Locale(language.localeCode));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  language.native,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.1,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  language.english,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
                      Icon(
                        Icons.verified_user_outlined,
                        size: 21,
                        color: AppColors.accentGreen,
                      ),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.yourDataIs100SafeWithUs,
                        style: TextStyle(
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
