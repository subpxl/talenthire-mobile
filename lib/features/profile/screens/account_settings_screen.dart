import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/utils/legal_links.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/features/admin/screens/admin_reports_screen.dart';
import 'package:bombay_casting/features/onboarding/screens/get_help_screen.dart';
import 'package:bombay_casting/features/onboarding/screens/select_language_screen.dart';
import 'package:bombay_casting/features/profile/models/settings_node.dart';
import 'package:bombay_casting/features/profile/screens/edit_personal_details_form.dart';
import 'package:bombay_casting/features/profile/screens/edit_verification_form.dart';
import 'package:bombay_casting/features/profile/screens/settings_group_screen.dart';
import 'package:bombay_casting/features/profile/widgets/settings_section_list.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';

/// Root of the Account Settings hierarchy.
///
/// Rows either open an existing screen, a static help article, an external
/// page, or a confirmation dialog. Branches drill down via [SettingsGroupScreen].
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  static const _languageNames = <String, String>{
    'hi': 'Hindi',
    'en': 'English',
    'mr': 'Marathi',
    'gu': 'Gujarati',
    'bn': 'Bengali',
    'kn': 'Kannada',
    'ta': 'Tamil',
    'ml': 'Malayalam',
  };

  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SettingsAppBar(
        title: AppLocalizations.of(context)!.accountSettings,
      ),
      body: SettingsSectionList(
        sections: _buildSections(context),
        footer: _buildLogout(context),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Level 1 — main list
  // ---------------------------------------------------------------------------

  List<SettingsSection> _buildSections(BuildContext context) {
    final appState = context.watch<AppState>();
    final localeCode = appState.appLocale?.languageCode;
    final languageName = _languageNames[localeCode] ?? 'English';
    final l10n = AppLocalizations.of(context)!;

    return [
      SettingsSection(
        title: 'Account',
        items: [
          SettingsNode(
            icon: Icons.person_outline,
            title: 'Profile & Account',
            subtitle: 'Name, gender, email & personal details',
            onTap: () =>
                AppNavigation.push(context, const EditPersonalFieldsScreen()),
          ),
          SettingsNode(
            icon: Icons.verified_user_outlined,
            title: 'Verification & Trust',
            subtitle: 'Verify your profile & build trust',
            children: _verificationChildren(),
          ),
        ],
      ),
      SettingsSection(
        title: 'Preferences',
        items: [
          SettingsNode(
            icon: Icons.translate,
            title: l10n.changeLanguage,
            value: languageName,
            onTap: () => AppNavigation.push(context, const LanguageScreen()),
          ),
        ],
      ),
      SettingsSection(
        title: 'Support & Legal',
        items: [
          SettingsNode(
            icon: Icons.support_agent_outlined,
            title: 'Help & Support',
            subtitle: 'Help centre, FAQs, safety & contact',
            children: _helpChildren(),
          ),
          SettingsNode(
            icon: Icons.description_outlined,
            title: 'Legal',
            subtitle: 'Policies, terms & guidelines',
            children: _legalChildren(context),
          ),
        ],
      ),
      if (appState.isAdmin)
        SettingsSection(
          items: [
            SettingsNode(
              icon: Icons.flag_outlined,
              title: l10n.adminReports,
              subtitle: 'Review user reports by type',
              onTap: () => AppNavigation.push(
                context,
                const AdminReportsScreen(),
              ),
            ),
          ],
        ),
      SettingsSection(
        title: 'Danger Zone',
        danger: true,
        items: [
          SettingsNode(
            icon: Icons.pause_circle_outline,
            title: 'Deactivate Account',
            subtitle: 'Sign in again and reactivate when ready',
            danger: true,
            onTap: () => _confirmDeactivateAccount(context),
          ),
          SettingsNode(
            icon: Icons.delete_outline,
            title: l10n.deleteAccount,
            subtitle: 'Permanently delete your account',
            danger: true,
            onTap: () => _confirmDeleteAccount(context),
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Level 2 — Verification & Trust
  // ---------------------------------------------------------------------------

  List<SettingsSection> _verificationChildren() {
    return [
      SettingsSection(
        items: [
          SettingsNode(
            icon: Icons.badge_outlined,
            title: 'Verify your profile',
            subtitle: 'Submit documents to build trust',
            onTap: _openVerification,
          ),
          SettingsNode(
            icon: Icons.info_outline,
            title: 'How verification works',
            subtitle: 'What we review and what to prepare',
            article:
                'Verification helps agencies trust that you are a real person. '
                'Open Verify your profile to upload the documents requested in '
                'the form, such as a PAN card and a clear photo of yourself.\n\n'
                'Use the same name that appears on your ID, and make sure the '
                'photo is well lit and unobstructed. Reviews can take time. You '
                'can still browse casting calls while your documents are being '
                'checked.\n\n'
                'If something is rejected, update the file and submit again. '
                'Keep details accurate — mismatched names or blurry images are '
                'the most common reasons a review is delayed.',
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Level 2 — Help & Support
  // ---------------------------------------------------------------------------

  List<SettingsSection> _helpChildren() {
    return [
      SettingsSection(
        items: [
          SettingsNode(
            icon: Icons.help_outline,
            title: 'Help Centre',
            subtitle: 'Browse topics and common questions',
            children: _helpCentreChildren(),
          ),
          SettingsNode(
            icon: Icons.quiz_outlined,
            title: 'FAQs',
            subtitle: 'Answers about profile, jobs and payments',
            children: _faqChildren(),
          ),
          SettingsNode(
            icon: Icons.shield_outlined,
            title: 'Safety & Scams',
            subtitle: 'Stay safe while applying for castings',
            children: _safetyChildren(),
          ),
          SettingsNode(
            icon: Icons.mail_outline,
            title: 'Contact Support',
            subtitle: 'Reach us through the Bombay Casting website',
            onTap: () => openLegalPage(context, LegalLinks.website),
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Level 3 — Help Centre
  // ---------------------------------------------------------------------------

  List<SettingsSection> _helpCentreChildren() {
    final l10n = AppLocalizations.of(context)!;
    return [
      SettingsSection(
        items: [
          SettingsNode(
            icon: Icons.support_agent_outlined,
            title: l10n.getHelp,
            subtitle: 'Open the full help guide',
            onTap: () => AppNavigation.push(context, const GetHelpScreen()),
          ),
        ],
      ),
      SettingsSection(
        title: 'Getting started',
        items: [
          SettingsNode(
            icon: Icons.person_outline,
            title: 'Complete your creator profile',
            article:
                'Open Profile and tap Edit Profile. Add a clear photo, your '
                'city, talent categories, languages, and social links so '
                'agencies can find you.\n\n'
                'A complete profile with a recognisable photo and a short bio '
                'is more likely to be shortlisted. You can update these details '
                'anytime from Profile & Account in settings.',
          ),
          SettingsNode(
            icon: Icons.work_outline,
            title: 'Browse and apply to jobs',
            article:
                'Open casting calls from Home. Read the brief, check dates and '
                'location, then tap Apply if the role fits.\n\n'
                'Premium members can submit applications, message agencies, and '
                'call from a job. Saved roles appear under Home → Saved, and '
                'roles you have applied to appear under Home → Applied.',
          ),
          SettingsNode(
            icon: Icons.workspace_premium_outlined,
            title: 'Premium membership',
            article:
                'Premium unlocks applying to jobs, chatting with agencies, and '
                'contacting casting teams from a role.\n\n'
                'Open Profile and tap Become a Premium Member, or manage an '
                'existing plan from Payment and subscription in Get help. Stay '
                'on the checkout screen until payment finishes, and do not pay '
                'twice if a charge is still pending.',
          ),
        ],
      ),
      SettingsSection(
        title: 'On this app',
        items: [
          SettingsNode(
            icon: Icons.favorite_border,
            title: 'Saved creators and jobs',
            article:
                'Tap the heart on a job card to save it. Saved jobs appear '
                'under Home → Saved.\n\n'
                'Tap the heart on a creator profile to save it. Saved creators '
                'appear under Creators → Saved. Use these lists to come back to '
                'roles and people you want to revisit later.',
          ),
          SettingsNode(
            icon: Icons.chat_bubble_outline,
            title: 'Talking to an agency',
            article:
                'After you subscribe, you can chat or call from a job to talk '
                'to the casting team about that role.\n\n'
                'Keep the conversation about the brief, your availability, and '
                'what the production needs. Never share OTPs, bank details, or '
                'pay anyone to be considered — see Safety & Scams for more.',
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Level 3 — FAQs
  // ---------------------------------------------------------------------------

  List<SettingsSection> _faqChildren() {
    return [
      SettingsSection(
        items: [
          SettingsNode(
            icon: Icons.badge_outlined,
            title: 'Profile & account',
            subtitle: 'Editing details, visibility and verification',
            children: _faqProfileChildren(),
          ),
          SettingsNode(
            icon: Icons.movie_filter_outlined,
            title: 'Jobs & castings',
            subtitle: 'Applying, tracking and contacting agencies',
            children: _faqJobsChildren(),
          ),
          SettingsNode(
            icon: Icons.payments_outlined,
            title: 'Payments & Premium',
            subtitle: 'Plans, checkout and refunds',
            children: _faqPaymentsChildren(),
          ),
        ],
      ),
    ];
  }

  List<SettingsSection> _faqProfileChildren() {
    return [
      SettingsSection(
        items: [
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'How do I edit my personal details?',
            article:
                'Go to Account Settings → Profile & Account. There you can '
                'update your name, gender, email, phone, WhatsApp number, '
                'languages, categories, and about text.\n\n'
                'Save the form when you are done. Use a number you can receive '
                'calls on, because agencies may contact you about a role.',
          ),
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'Who can see my creator profile?',
            article:
                'Agencies and production teams on Bombay Casting Company can '
                'view your public profile when you apply, or when they browse '
                'talent.\n\n'
                'Keep your photo and bio up to date so the right people can '
                'recognise you. Private documents you upload for verification '
                'are used for review, not shown as part of your public profile.',
          ),
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'How do I get verified?',
            article:
                'Open Account Settings → Verification & Trust → Verify your '
                'profile. Upload the requested ID and photo, then submit.\n\n'
                'There is no separate fee for submitting documents in the app. '
                'If a file is unclear, replace it and submit again. You can '
                'read How verification works on the Verification & Trust page.',
          ),
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'Can I temporarily hide my profile?',
            article:
                'Yes. Use Deactivate Account in the Danger Zone at the bottom '
                'of Account Settings. Your profile stays hidden until you sign '
                'in and tap Reactivate.\n\n'
                'Deactivate if you need a break. Delete Account permanently '
                'removes the account and cannot be undone, so only use that if '
                'you are sure you will not come back.',
          ),
        ],
      ),
    ];
  }

  List<SettingsSection> _faqJobsChildren() {
    return [
      SettingsSection(
        items: [
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'How do I apply for a casting?',
            article:
                'Open a casting call from Home, read the brief, then tap Apply. '
                'Premium members can submit applications directly from the app.\n\n'
                'Apply only when you match the role, city, and dates. A focused '
                'application is more useful to the casting team than applying to '
                'every open call.',
          ),
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'Where do I see jobs I saved or applied to?',
            article:
                'Use the heart on a job card to save it. Saved jobs appear '
                'under Home → Saved.\n\n'
                'Open Home → Applied to see updates on jobs you have already '
                'applied to. Those two lists are the place to track roles you '
                'care about.',
          ),
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'Can I talk to the agency about a role?',
            article:
                'Yes, after you subscribe. Open the job and use chat or call to '
                'reach the casting team.\n\n'
                'Ask about the brief, call time, or what to prepare. Do not '
                'share one-time passwords, and do not pay anyone outside the '
                'app to be shortlisted.',
          ),
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'Which jobs can I browse without Premium?',
            article:
                'You can browse open casting calls on Home without a paid plan. '
                'Premium is what lets you apply, message, and contact agencies '
                'from a role.\n\n'
                'Use Saved to keep roles you want to come back to after you '
                'subscribe.',
          ),
        ],
      ),
    ];
  }

  List<SettingsSection> _faqPaymentsChildren() {
    return [
      SettingsSection(
        items: [
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'How do I become a Premium member?',
            article:
                'Open Profile and tap Become a Premium Member, then choose a '
                'plan and complete checkout in the app.\n\n'
                'You can also open Get help → Payment and subscription to '
                'manage or cancel an existing plan.',
          ),
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'What payment methods are supported?',
            article:
                'Payments are processed through the in-app checkout. UPI and '
                'other methods shown at checkout depend on your bank and device.\n\n'
                'Use only the checkout inside the app. Bombay Casting will not '
                'ask you to pay an individual over WhatsApp, UPI, or cash to '
                'unlock a role.',
          ),
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'My payment is pending. What should I do?',
            article:
                'Stay on the payment screen until it finishes. If it stays '
                'pending, wait a few minutes, then check your subscription. Do '
                'not pay twice.\n\n'
                'If nothing updates, open Get help and contact us from there, '
                'or use Contact Support to reach us through the website.',
          ),
          SettingsNode(
            icon: Icons.article_outlined,
            title: 'How do refunds and cancellations work?',
            article:
                'Refund eligibility depends on the plan and the timing of the '
                'request. Read the full policy on our website, listed under '
                'Legal → Refunds & Cancellation.\n\n'
                'To stop future renewals, open Get help → Payment and '
                'subscription and follow the cancel flow there.',
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Level 3 — Safety & Scams
  // ---------------------------------------------------------------------------

  List<SettingsSection> _safetyChildren() {
    return [
      SettingsSection(
        items: [
          SettingsNode(
            icon: Icons.report_gmailerrorred_outlined,
            title: 'How to spot a fake casting',
            article:
                'Treat a role as suspicious if someone asks you to pay to apply, '
                'to share an OTP, or to move the conversation off the app before '
                'you have applied.\n\n'
                'Real castings on Bombay Casting Company have a brief you can '
                'read in the app. Fees for Premium are paid only through in-app '
                'checkout, never to a person claiming to be a coordinator.',
          ),
          SettingsNode(
            icon: Icons.lock_outline,
            title: 'Protecting your personal information',
            article:
                'Share contact details through the app when you choose to apply '
                'or message. Do not send copies of your ID, bank details, or '
                'passwords to anyone who messages you privately.\n\n'
                'Verification documents belong only in Verification & Trust. '
                'If someone claiming to be from Bombay Casting asks you to '
                'WhatsApp your PAN, voter ID, or OTP, do not reply — that is '
                'not how we verify accounts.',
          ),
          SettingsNode(
            icon: Icons.money_off_outlined,
            title: 'We never ask you to pay for a role',
            article:
                'You should never pay to be considered for a casting. Premium '
                'is an app subscription paid in checkout, not a casting fee.\n\n'
                'If a person asks for money, gifts, or travel booked through '
                'their personal UPI to “confirm” a role, stop and report it. '
                'Use Contact Support from Help & Support, or open the website '
                'from Legal.',
          ),
          SettingsNode(
            icon: Icons.groups_outlined,
            title: 'Community guidelines in short',
            article:
                'Be honest on your profile, apply only to roles that fit, and '
                'keep messages professional. Harassment, fake documents, or '
                'impersonating an agency can get an account removed.\n\n'
                'The full Community Guidelines and Casting Guidelines are under '
                'Legal in Account Settings.',
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Level 2 — Legal
  // ---------------------------------------------------------------------------

  List<SettingsSection> _legalChildren(BuildContext context) {
    return [
      SettingsSection(
        items: [
          SettingsNode(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () => openLegalPage(context, LegalLinks.privacy),
          ),
          SettingsNode(
            icon: Icons.gavel_outlined,
            title: 'Terms of Service',
            onTap: () => openLegalPage(context, LegalLinks.terms),
          ),
          SettingsNode(
            icon: Icons.groups_outlined,
            title: 'Community Guidelines',
            onTap: () => openLegalPage(context, LegalLinks.website),
          ),
          SettingsNode(
            icon: Icons.movie_filter_outlined,
            title: 'Casting Guidelines',
            onTap: () => openLegalPage(context, LegalLinks.website),
          ),
          SettingsNode(
            icon: Icons.receipt_long_outlined,
            title: 'Refunds & Cancellation',
            onTap: () => openLegalPage(context, LegalLinks.refunds),
          ),
        ],
      ),
    ];
  }

  // ---------------------------------------------------------------------------
  // Leaf actions
  // ---------------------------------------------------------------------------

  void _openVerification() {
    if (!AppNavigation.requireSubscription(context)) return;
    AppNavigation.push(context, const EditVerificationFormScreen());
  }

  Widget _buildLogout(BuildContext context) {
    return Center(
      child: _isLoggingOut
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 18, color: AppColors.primary),
              label: Text(
                AppLocalizations.of(context)!.logout,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await context.read<AppState>().logout();
    if (!mounted) return;
    setState(() => _isLoggingOut = false);
  }

  Future<void> _confirmDeactivateAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const AccountConfirmDialog(
        title: 'Deactivate account?',
        message: 'Your profile will be hidden from others. Sign in again and '
            'tap Reactivate when you want to come back.',
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await context.read<AppState>().deactivateAccount();
    } catch (error) {
      if (!context.mounted) return;
      showAppToast(
        context,
        'Could not deactivate account. Please try again.',
        type: AppToastType.error,
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => const AccountConfirmDialog(
        title: 'Are you sure?',
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (context) => const AccountConfirmDialog(
        title: 'Are you definitely sure?',
        message: 'Nothing can be recovered.',
      ),
    );
    if (second != true || !context.mounted) return;

    try {
      await context.read<AppState>().deleteAccount();
    } catch (_) {
      if (!context.mounted) return;
      showAppToast(
        context,
        'Could not delete account. Please try again.',
        type: AppToastType.error,
      );
    }
  }
}

class AccountConfirmDialog extends StatelessWidget {
  const AccountConfirmDialog({
    super.key,
    required this.title,
    this.message,
  });

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.bodyMedium,
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.no),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: Text(AppLocalizations.of(context)!.yes),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
