import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/services/payment_service.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';

class PaymentInProgressScreen extends StatefulWidget {
  const PaymentInProgressScreen({
    super.key,
    required this.subscriptionId,
  });

  final String subscriptionId;

  @override
  State<PaymentInProgressScreen> createState() =>
      _PaymentInProgressScreenState();
}

class _PaymentInProgressScreenState extends State<PaymentInProgressScreen> {
  final PaymentService _paymentService = PaymentService();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  Timer? _pollTimer;
  Timer? _timeoutTimer;
  String _statusMessage = 'Waiting for UPI mandate approval…';
  bool _isComplete = false;
  bool _hasFailed = false;
  bool _hasTimedOut = false;

  static const _pollInterval = Duration(seconds: 3);
  static const _maxWaitDuration = Duration(minutes: 8);

  /// The uid that initiated this payment flow.
  /// Captured once at [initState] and treated as immutable throughout the
  /// lifecycle of this screen. All callbacks validate against this id before
  /// acting, so switching accounts while this screen is active can never
  /// accidentally grant premium to the newly signed-in user.
  late final String _ownerUserId;

  @override
  void initState() {
    super.initState();
    // Capture the uid synchronously, before any async work starts.
    _ownerUserId = context.read<AppState>().user?.id ?? '';
    if (_ownerUserId.isEmpty) {
      // No authenticated user – nothing to do.
      return;
    }
    _listenForPremiumActivation();
    _pollVerification();
    _timeoutTimer = Timer(_maxWaitDuration, _onWaitTimedOut);
  }

  /// Returns true only when the user who initiated this payment is still the
  /// currently signed-in user. Guards every async callback.
  bool _isStillOwner() {
    if (!mounted) return false;
    final currentUid = context.read<AppState>().user?.id;
    return currentUid == _ownerUserId;
  }

  void _stopWaiting() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  void _listenForPremiumActivation() {
    _profileSub = FirebaseFirestore.instance
        .collection('profiles')
        .doc(_ownerUserId)
        .snapshots()
        .listen((snapshot) {
      // Guard: only act if the original payment owner is still signed in.
      if (!mounted || !_isStillOwner()) {
        // A different user is now signed in – cancel listener to avoid any
        // side-effects for the new session.
        _profileSub?.cancel();
        _profileSub = null;
        return;
      }
      final status = snapshot.data()?['subscription_status']?.toString();
      if (status == 'premium') {
        unawaited(_onPremiumActivated());
      }
    });
  }

  void _pollVerification() {
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!mounted || _isComplete || _hasFailed) return;

      // Guard: stop polling if a different user has signed in.
      if (!_isStillOwner()) {
        _stopWaiting();
        return;
      }

      try {
        final result = await _paymentService.verifyPremiumSubscription(
          subscriptionId: widget.subscriptionId,
        );
        if (!mounted || _isComplete) return;

        // Re-check ownership after the async call returns.
        if (!_isStillOwner()) {
          _stopWaiting();
          return;
        }

        if (result.isPremium) {
          await _onPremiumActivated();
          return;
        }

        if (result.status == 'CUSTOMER_CANCELLED' ||
            result.status == 'CANCELLED' ||
            result.status == 'LINK_EXPIRED') {
          setState(() {
            _hasFailed = true;
            _statusMessage = 'Mandate was not approved. You can try again.';
          });
          _stopWaiting();
        }
      } catch (_) {
        // Keep polling; webhook may still arrive.
      }
    });
  }

  void _onWaitTimedOut() {
    if (!mounted || _isComplete || _hasFailed) return;
    if (!_isStillOwner()) return;

    _pollTimer?.cancel();
    setState(() {
      _hasTimedOut = true;
      _statusMessage =
          'This is taking longer than expected. If you already approved the mandate, '
          'Premium may still activate shortly. You can wait here or go back and try again.';
    });
  }

  Future<void> _onPremiumActivated() async {
    if (_isComplete) return;

    // Final ownership guard before modifying app state.
    if (!_isStillOwner()) return;

    _stopWaiting();
    _isComplete = true;

    await context.read<AppState>().refreshProfile();

    if (!mounted) return;
    setState(() {
      _statusMessage = 'Success';
    });

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Success')),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _stopWaiting();
    _profileSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWaiting = !_isComplete && !_hasFailed;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isWaiting)
                const CircularProgressIndicator(),
              if (_isComplete)
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.accentGreen,
                  size: 56,
                ),
              if (_hasFailed)
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 56,
                ),
              if (_hasTimedOut && isWaiting)
                const Icon(
                  Icons.schedule,
                  color: AppColors.textSecondary,
                  size: 56,
                ),
              const SizedBox(height: 20),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: _hasFailed
                      ? Colors.redAccent
                      : AppColors.textSecondary,
                ),
              ),
              if (isWaiting && !_hasTimedOut) ...[
                const SizedBox(height: 12),
                Text(
                  'Complete approval in your UPI app, then return here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.85),
                  ),
                ),
              ],
              if (_hasTimedOut && isWaiting) ...[
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Go back and try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
