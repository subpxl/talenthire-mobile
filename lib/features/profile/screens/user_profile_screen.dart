import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/core/deep_links/deep_link_target.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/features/profile/screens/account_settings_screen.dart';
import 'package:bombay_casting/features/profile/screens/edit_profile_view_screen.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_screen_layout.dart';
import 'package:bombay_casting/core/widgets/share_link_button.dart';
import 'package:bombay_casting/core/widgets/verified_tick.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.profile;
    final user = appState.user;
    final uid = user?.id.trim();
    final name = (user?.name ?? '').trim();
    final shareMessage = name.isEmpty
        ? 'Check out my profile on Bombay Casting Company'
        : 'Check out $name on Bombay Casting Company';
    return AppScreenLayout(
      title: AppLocalizations.of(context)!.navProfile,
      actions: [
        if (uid != null && uid.isNotEmpty)
          ShareLinkButton(
            url: DeepLinkTarget.creatorUrl(uid),
            message: shareMessage,
          ),
      ],
      body: AppScrollBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.sm,
                AppSpacing.screenH,
                0,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfilePhotoPicker(profile: profile),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 14),
                    _buildProfileHeader(context),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                0,
              ),
              child: _buildPremiumCard(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.md,
                AppSpacing.screenH,
                0,
              ),
              child: EditProfileSectionList(profile: profile, user: user),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSettingsTile(
              key: const Key('e2e_profile_settings'),
              icon: Icons.settings_outlined,
              title: AppLocalizations.of(context)!.accountSettings,
              onTap: () =>
                  AppNavigation.push(context, const AccountSettingsScreen()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final appState = context.watch<AppState>();
    final user = appState.user;
    final profile = appState.profile;
    final name = (user?.name ?? '').trim().isEmpty ? 'Your profile' : user!.name;
    final email = (user?.email ?? '').trim();
    final talent = (profile?.talent ?? '').trim();
    final influencerLabel = talent.isEmpty
        ? 'Influencer'
        : '${talent[0].toUpperCase()}${talent.substring(1)}';

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  name,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (profile?.isVerified == true || profile?.isPremium == true) ...[
                const SizedBox(width: 6),
                const VerifiedTick(size: 20),
              ],
            ],
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              textAlign: TextAlign.left,
              style: context.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    influencerLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    final isPremium = context.watch<AppState>().isPremiumUser;
    return Material(
      color: AppColors.bannerStart,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('e2e_premium_cta'),
        onTap: isPremium
            ? null
            : () => AppNavigation.openPremiumScreen(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  isPremium
                      ? AppLocalizations.of(context)!.youAreAPremiumMember
                      : AppLocalizations.of(context)!.becomeAPremiumMember,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                isPremium
                    ? AppLocalizations.of(context)!.active
                    : AppLocalizations.of(context)!.join,
                style: context.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isPremium ? AppColors.accentGreen : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
