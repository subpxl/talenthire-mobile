import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_avatar.dart';
import '../widgets/app_section_title.dart';
import '../widgets/payment_dialog.dart';
import 'edit_profile_screen.dart';
import 'my_applications_screen.dart';
import 'saved_jobs_screen.dart';
import 'transactions_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import '../widgets/youtube_shorts_player.dart';
import '../widgets/optimized_network_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              children: [
                AppAvatar(
                  radius: 50,
                  imageUrl: profile?.profileImage,
                  initials: state.user?.name.isNotEmpty == true
                      ? state.user!.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
                      : '?',
                ),
                if (profile?.isVerified == true)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: AppColors.onPrimary, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              state.user?.name ?? 'User',
              style: context.text.headlineSmall,
            ),
            if (profile != null) ...[
              const SizedBox(height: 4),
              Text(
                profile.talent.isNotEmpty ? profile.talent[0].toUpperCase() + profile.talent.substring(1) : 'Unknown',
                style: TextStyle(color: context.colors.primary, fontSize: 14),
              ),
            ],
            if (state.user?.email.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                state.user!.email,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            if (profile != null && profile.city.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    profile.city,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
            if (profile != null && profile.contact.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Contact: ${profile.contact}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
            if (profile != null && profile.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                profile.address,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),

            if (profile != null && profile.photos.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: AppSectionTitle('Photos'),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: profile.photos.length,
                itemBuilder: (ctx, i) {
                  final isProfile = profile.photos[i] == profile.profileImage;
                  return GestureDetector(
                    onTap: () {
                      state.setProfilePhoto(profile.photos[i]);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile photo updated!')),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isProfile
                            ? Border.all(color: context.colors.primary, width: 3)
                            : null,
                        image: DecorationImage(
                          image: OptimizedNetworkImage.provider(
                            profile.photos[i],
                            context: ctx,
                            width: 80,
                            height: 80,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: isProfile
                          ? Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.check_circle,
                                  color: context.colors.primary,
                                  size: 20,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            if (profile != null &&
                (profile.shortIntroVideoLink.isNotEmpty ||
                    profile.achievementsVideoLink.isNotEmpty ||
                    profile.previousWorksVideoLink.isNotEmpty)) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: AppSectionTitle('YouTube Shorts'),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (profile.shortIntroVideoLink.isNotEmpty) ...[
                      YoutubeShortsCard(
                        title: 'Short Intro',
                        youtubeUrl: profile.shortIntroVideoLink,
                        showLockOverlay: !profile.canPostYoutubeLinks,
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (profile.achievementsVideoLink.isNotEmpty) ...[
                      YoutubeShortsCard(
                        title: 'Achievements',
                        youtubeUrl: profile.achievementsVideoLink,
                        showLockOverlay: !profile.canPostYoutubeLinks,
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (profile.previousWorksVideoLink.isNotEmpty)
                      YoutubeShortsCard(
                        title: 'Previous Works',
                        youtubeUrl: profile.previousWorksVideoLink,
                        showLockOverlay: !profile.canPostYoutubeLinks,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildSubscriptionBadge(context, state),
            const SizedBox(height: 16),

            if (profile != null && profile.socialLinks.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: AppSectionTitle('Social Links', icon: Icons.link),
              ),
              ...profile.socialLinks.map(
                (link) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.link, color: context.colors.primary),
                  title: Text(link.name),
                  subtitle: Text(
                    link.url,
                    style: TextStyle(color: context.colors.secondary),
                  ),
                  trailing: const Icon(Icons.open_in_new, size: 18, color: AppColors.textMuted),
                  onTap: () => launchExternalUrl(link.url, context: context),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),

            _buildProfileMenu(
              context,
              icon: Icons.edit,
              title: 'Edit Profile',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            _buildProfileMenu(
              context,
              icon: Icons.work_history,
              title: 'My Applications',
              subtitle: '${state.applications.length} active',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
                );
              },
            ),
            _buildProfileMenu(
              context,
              icon: Icons.bookmark,
              title: 'Saved Jobs',
              subtitle: '${state.savedJobs.length} saved',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedJobsScreen()),
                );
              },
            ),
            _buildProfileMenu(
              context,
              icon: Icons.receipt_long,
              title: 'My Transactions',
              subtitle: '${state.transactions.length} transactions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TransactionsScreen()),
                );
              },
            ),
            _buildProfileMenu(
              context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            _buildProfileMenu(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => state.logout(),
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('Log Out', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionBadge(BuildContext context, AppState state) {
    final isPremium = state.profile?.isPremium ?? false;

    if (isPremium) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.tertiary.withAlpha(30),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.tertiary.withAlpha(80)),
        ),
        child: const Row(
          children: [
            Icon(Icons.star, color: AppColors.tertiary),
            SizedBox(width: 8),
            Text(
              'Premium Verified Member',
              style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () {
        PaymentDialog.show(
          context,
          title: 'Upgrade to Premium',
          description: 'Get verified, post YouTube Shorts, and apply to unlimited jobs.',
          amount: AppPricing.premiumUpgrade,
          icon: Icons.star,
          accentColor: AppColors.tertiary,
          onPay: () async {
            final success = await state.upgradeToPremium();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Upgraded to Premium!' : 'Payment failed'),
                ),
              );
            }
          },
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              context.colors.primaryContainer,
              AppColors.tertiary.withAlpha(40),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.star_border, color: context.colors.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Free Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Upgrade to Premium for ₹200',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.colors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenu(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.primary.withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.colors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
          : null,
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
