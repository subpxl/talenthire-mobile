import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/navigation/app_navigation.dart';
import 'package:bombay_casting/providers/app_state.dart';
import 'package:bombay_casting/screens/account_settings_screen.dart';
import 'package:bombay_casting/screens/gethelpscreen.dart';
import 'package:bombay_casting/screens/selectlanguage.dart';
import 'package:bombay_casting/screens/userprofilepage/editprofileviewscreen.dart';
import 'package:bombay_casting/theme/app_theme.dart';
import 'package:bombay_casting/widgets/app_screen_layout.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return AppScreenLayout(
      title: 'Profile',
      body: AppScrollBody(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenH),
              child: _buildProfileHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
              child: _buildPremiumCard(context),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSettingsTile(
              icon: Icons.chat_outlined,
              title: 'Get help',
              onTap: () => AppNavigation.push(context, const GetHelpScreen()),
            ),
            AppSettingsTile(
              icon: Icons.translate,
              title: 'Change language',
              onTap: () => AppNavigation.push(context, const LanguageScreen()),
            ),
            AppSettingsTile(
              icon: Icons.settings_outlined,
              title: 'Account Settings',
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
    final phone = (user?.mobile ?? '').trim().isEmpty
        ? (user?.email ?? '')
        : user!.mobile;
    final details = [
      if (profile?.age != null) '${profile!.age} years',
      if ((profile?.talent ?? '').isNotEmpty) profile!.talent,
      if (profile != null && profile.niches.isNotEmpty)
        profile.niches.take(2).join(', '),
      if (profile != null &&
          profile.niches.isEmpty &&
          profile.languages.isNotEmpty)
        profile.languages.join(', '),
    ].where((item) => item.isNotEmpty).join(', ');
    final location = [
      profile?.city ?? '',
      profile?.state ?? '',
    ].where((item) => item.isNotEmpty).join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.divider,
              backgroundImage: (profile?.profileImage ?? '').isNotEmpty
                  ? CachedNetworkImageProvider(profile!.profileImage)
                  : null,
              child: (profile?.profileImage ?? '').isEmpty
                  ? Icon(Icons.image_outlined, size: 36, color: AppColors.textHint)
                  : null,
            ),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, size: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              if (phone.isNotEmpty) Text(phone, style: context.bodyMedium),
              if (details.isNotEmpty) Text(details, style: context.caption),
              if (location.isNotEmpty) Text(location, style: context.caption),
              const SizedBox(height: AppSpacing.sm + 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      AppNavigation.push(context, const EditProfileScreen()),
                  child: const Text('Update Profile'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    final isPremium = context.watch<AppState>().profile?.isPremium ?? false;
    return Material(
      color: AppColors.primaryTint,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: isPremium
            ? null
            : () => AppNavigation.openPremiumScreen(context),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 14,
          ),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium_outlined, color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(
                child: Text(
                  isPremium
                      ? 'You are a Premium Member'
                      : 'Become a Premium Member',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                isPremium ? 'ACTIVE' : 'JOIN',
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


