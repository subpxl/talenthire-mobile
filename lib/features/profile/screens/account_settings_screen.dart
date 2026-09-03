import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/features/onboarding/screens/get_help_screen.dart';
import 'package:bombay_casting/features/onboarding/screens/select_language_screen.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _isLoggingOut = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(AppLocalizations.of(context)!.accountSettings,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.scrollBottom,
        ),
        children: [
          _SettingsCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(AppLocalizations.of(context)!.contactPrivacy,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.chatGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsLinkTile(
                  icon: Icons.chat_outlined,
                  title: AppLocalizations.of(context)!.getHelp,
                  onTap: () => AppNavigation.push(
                    context,
                    const GetHelpScreen(),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _SettingsLinkTile(
                  icon: Icons.translate,
                  title: AppLocalizations.of(context)!.changeLanguage,
                  onTap: () => AppNavigation.push(
                    context,
                    const LanguageScreen(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Manage account',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _SettingsCard(
            child: Column(
              children: [
                _SettingsLinkTile(
                  icon: Icons.pause_circle_outline,
                  title: 'Deactivate account',
                  onTap: () => _confirmDeactivateAccount(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _SettingsLinkTile(
                  icon: Icons.delete_outline,
                  title: AppLocalizations.of(context)!.deleteAccount,
                  onTap: () => _confirmDeleteAccount(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: _isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : TextButton(
                    onPressed: _logout,
                    child: Text(
                      AppLocalizations.of(context)!.logout,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
          ),
        ],
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
    await showDialog<bool>(
      context: context,
      builder: (context) => const AccountConfirmDialog(
        title: 'Deactivate account?',
        message: 'You can come back later by logging in again.',
      ),
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => const AccountConfirmDialog(
        title: 'Are you sure?',
      ),
    );
    if (first != true || !context.mounted) return;

    await showDialog<bool>(
      context: context,
      builder: (context) => const AccountConfirmDialog(
        title: 'Are you definitely sure?',
        message: 'Nothing can be recovered.',
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SettingsLinkTile extends StatelessWidget {
  const _SettingsLinkTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.textHint,
        size: 20,
      ),
      onTap: onTap,
    );
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
