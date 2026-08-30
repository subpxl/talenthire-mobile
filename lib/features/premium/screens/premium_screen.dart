import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/navigation/app_navigation.dart';
import 'package:bombay_casting/core/services/payment_service.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/google_pay_logo.dart';
import 'package:bombay_casting/core/widgets/paytm_logo.dart';
import 'package:bombay_casting/core/widgets/phonepe_logo.dart';
import 'package:bombay_casting/core/widgets/placeholder_avatar.dart';
import 'package:bombay_casting/features/premium/screens/payment_in_progress_screen.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key});

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  bool _othersMenuOpen = false;
  String _selectedUpiAppId = UpiAppOption.phonePe.id;

  Future<void> _startUpiAutopay() async {
    if (_isProcessing) return;

    final appState = context.read<AppState>();
    if (appState.user == null) {
      _showMessage('Sign in to subscribe.');
      return;
    }
    if (appState.isPremiumUser) {
      _showMessage('You already have Premium.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Create subscription at Pay tap so first_charge_at is ~3 days after ₹1 auth.
      final session = await _paymentService.createPremiumSubscription();
      if (!mounted) return;

      final result = await _paymentService.launchUpiMandate(
        session: session,
        upiApp: UpiAppOption.byId(_selectedUpiAppId),
        onFailure: (message) {
          if (!mounted) return;
          _showMessage(message.isEmpty ? 'Payment failed. Try again.' : message);
        },
      );

      if (!mounted) return;

      if (result == PremiumPaymentResult.failure ||
          result == PremiumPaymentResult.cancelled) {
        return;
      }

      AppNavigation.push(
        context,
        PaymentInProgressScreen(subscriptionId: session.subscriptionId),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      if (error.code == 'already-exists') {
        // Server says the user is already premium — refresh profile so the
        // local state catches up, then show a friendly message.
        await context.read<AppState>().refreshProfile();
        if (!mounted) return;
        _showMessage('You are already a Premium member!');
      } else {
        _showMessage(error.message ?? 'Could not start payment.');
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not start payment. Try again.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
                    const Text(
                      '₹1',
                      style: TextStyle(
                        fontSize: 76,
                        height: 0.95,
                        fontWeight: FontWeight.w300,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.for1DayThen299month,
                      style: const TextStyle(
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
            onPressed: _isProcessing ? null : () => Navigator.maybePop(context),
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
    final selected = UpiAppOption.byId(_selectedUpiAppId);
    final isPhonePe = _selectedUpiAppId == UpiAppOption.phonePe.id;
    const otherApps = [UpiAppOption.googlePay, UpiAppOption.paytm];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UpiAppTile(
            app: UpiAppOption.phonePe,
            iconSize: 32,
            isSelected: isPhonePe,
            onTap: _isProcessing
                ? null
                : () => setState(() {
                      _selectedUpiAppId = UpiAppOption.phonePe.id;
                      _othersMenuOpen = false;
                    }),
          ),
          const SizedBox(height: 4),
          if (_othersMenuOpen) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < otherApps.length; i++) ...[
                    if (i > 0)
                      const Divider(
                        height: 1,
                        thickness: 0.7,
                        color: AppColors.divider,
                      ),
                    _UpiAppTile(
                      app: otherApps[i],
                      iconSize: 28,
                      isSelected: _selectedUpiAppId == otherApps[i].id,
                      onTap: _isProcessing
                          ? null
                          : () => setState(() {
                                _selectedUpiAppId = otherApps[i].id;
                                _othersMenuOpen = false;
                              }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
          ],
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isProcessing
                  ? null
                  : () => setState(() => _othersMenuOpen = !_othersMenuOpen),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    if (!isPhonePe) ...[
                      _UpiAppIcon(app: selected, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        selected.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ] else
                      const Text(
                        'Others',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      _othersMenuOpen
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: isPhonePe
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Opens ${selected.label} for UPI Autopay approval',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _startUpiAutopay,
              child: _isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Pay now ₹1'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpiAppIcon extends StatelessWidget {
  const _UpiAppIcon({required this.app, this.size = 32});

  final UpiAppOption app;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (app.id) {
      case 'phonepe':
        return PhonePeLogo(size: size);
      case 'gpay':
        return GooglePayLogo(size: size);
      case 'paytm':
        return PaytmLogo(size: size);
      default:
        return PhonePeLogo(size: size);
    }
  }
}

class _UpiAppTile extends StatelessWidget {
  const _UpiAppTile({
    required this.app,
    required this.isSelected,
    this.iconSize = 32,
    this.onTap,
  });

  final UpiAppOption app;
  final bool isSelected;
  final double iconSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _UpiAppIcon(app: app, size: iconSize),
              const SizedBox(width: 12),
              Text(
                app.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 14, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
