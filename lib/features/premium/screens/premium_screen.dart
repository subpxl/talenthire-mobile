import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  static const _paymentsUnavailableMessage =
      'Payments are not available yet. We will enable checkout when billing is ready.';

  void _showPaymentsUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(_paymentsUnavailableMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 14),
                    _buildProfileSection(context),
                    const SizedBox(height: 25),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 26,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                        children: [
                          TextSpan(text: 'Become '),
                          TextSpan(
                            text: 'Premium',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' Member'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(AppLocalizations.of(context)!.k1,
                      style: TextStyle(
                        fontSize: 76,
                        height: 0.95,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context)!.for1DayThen299month,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildFeaturesCard(),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            _buildBottomPayment(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
            ),
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          const Spacer(),
          SizedBox(
            width: 185,
            height: 115,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 20,
                  child: _profileImage(72, PlaceholderAvatar.stackColors[0]),
                ),
                Positioned(
                  left: 55,
                  top: 0,
                  child: _profileImage(100, PlaceholderAvatar.stackColors[1]),
                ),
                Positioned(
                  right: 0,
                  top: 30,
                  child: _profileImage(70, PlaceholderAvatar.stackColors[2]),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _profileImage(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
          ),
        ],
        color: color,
      ),
      child: Icon(Icons.auto_awesome, size: size * 0.45, color: Colors.white),
    );
  }

  Widget _buildFeaturesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _featureRow(
            icon: Icons.movie_filter_outlined,
            iconColor: AppColors.primary,
            title: 'Apply to 1 Lakh+ brand jobs',
            subtitle: 'Unlimited applications',
          ),
          _divider(),
          _featureRow(
            icon: Icons.visibility_outlined,
            iconColor: AppColors.primaryDark,
            title: 'See who viewed you',
            subtitle: 'Know which brands viewed your profile',
          ),
          _divider(),
          _featureRow(
            icon: Icons.card_giftcard_outlined,
            iconColor: AppColors.accentGreen,
            title: 'Get new jobs every day',
            subtitle: 'Fresh brand collabs in your feed',
          ),
        ],
      ),
    );
  }

  Widget _featureRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      thickness: 0.7,
      indent: 14,
      endIndent: 14,
      color: AppColors.divider,
    );
  }

  Widget _buildBottomPayment(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF5F259F),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.phone_android,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.phonepe,
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF333333),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showPaymentsUnavailable(context),
                child: Text(AppLocalizations.of(context)!.change,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPaymentsUnavailable(context),
              child: Text(AppLocalizations.of(context)!.payNow1),
            ),
          ),
        ],
      ),
    );
  }
}
