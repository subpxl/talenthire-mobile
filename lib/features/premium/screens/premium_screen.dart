import 'dart:async';

import 'package:bombay_casting/l10n/app_localizations.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/services/payment_service.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/core/widgets/app_primary_button.dart';
import 'package:bombay_casting/features/premium/premium_paywall_assets.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key, this.showApplyTomorrow = false});

  final bool showApplyTomorrow;

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final PaymentService _paymentService = PaymentService();
  bool _isProcessing = false;
  static const _defaultUpiApp = UpiAppOption.phonePe;
  late final String _backgroundAsset;

  @override
  void initState() {
    super.initState();
    _backgroundAsset = pickPaywallBackgroundAsset();
  }

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
        upiApp: _defaultUpiApp,
      );

      if (!mounted) return;
      if (!result.isSuccess) {
        if (result == PremiumPaymentResult.failure) {
          _showMessage('Payment failed. Try again.');
        }
        return;
      }

      if (mounted) {
        Navigator.of(context).maybePop();
      }
      unawaited(
        appState.waitForPremiumActivation(
          subscriptionId: session.subscriptionId,
        ),
      );
      if (mounted) {
        _showMessage(
          'Activating Premium…',
          type: AppToastType.success,
        );
      }
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      if (error.code == 'already-exists') {
        await context.read<AppState>().refreshProfile();
        if (!mounted) return;
        _showMessage(
          'You are already a Premium member!',
          type: AppToastType.success,
        );
      } else if (error.code == 'resource-exhausted') {
        _showMessage('Daily limit reached. Try again tomorrow.');
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

  void _showMessage(String message, {AppToastType type = AppToastType.error}) {
    showAppToast(context, message, type: type);
  }

  static const _priceGray = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: _buildBackgroundImage(),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.55),
                    Colors.white.withValues(alpha: 0.96),
                  ],
                  stops: const [0.0, 0.38, 0.68, 1.0],
                ),
              ),
            ),
          ),
          _buildCloseControl(context),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 8),
              Flexible(
                flex: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.97),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Column(
                            children: [
                              const Text(
                                'Start Applying',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 26,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Apply to more brand opportunities',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.35,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.95),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _buildTrialPrice(),
                              const SizedBox(height: 10),
                              Text(
                                l10n.for1DayThen299month,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.35,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildFeaturesCard(),
                              if (widget.showApplyTomorrow) const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: _buildBottomPayment(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Image.asset(
      _backgroundAsset,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, error, stackTrace) {
        if (paywallBackgrounds.isEmpty) {
          return const ColoredBox(color: Colors.black);
        }
        return Image.asset(
          paywallBackgrounds.first,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }

  Widget _buildCloseControl(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: SafeArea(
        bottom: false,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _isProcessing ? null : () => Navigator.maybePop(context),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 16, 16),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrialPrice() {
    return Center(
      child: RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        children: [
          TextSpan(
            text: '₹',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: _priceGray,
              height: 1,
              decoration: TextDecoration.none,
            ),
          ),
          TextSpan(
            text: '1',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: _priceGray,
              height: 1,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFeaturesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
      ),
      child: Column(
        children: [
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider.withValues(alpha: 0.6)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPrimaryButton(
            key: const Key('e2e_premium_pay'),
            label: AppLocalizations.of(context)!.startNow,
            onPressed: _startUpiAutopay,
            loading: _isProcessing,
          ),
          if (widget.showApplyTomorrow) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: _isProcessing
                  ? null
                  : () => Navigator.maybePop(context),
              child: const Text(
                'Apply tomorrow',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
