import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfupi.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfupipayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/subs/cfsubsupi.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/subs/cfsubsupipayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsubssession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';

class UpiAppOption {
  const UpiAppOption({
    required this.id,
    required this.label,
    required this.androidPackage,
    required this.iosScheme,
  });

  final String id;
  final String label;
  final String androidPackage;
  final String iosScheme;

  String get launchId => Platform.isIOS ? iosScheme : androidPackage;

  static const phonePe = UpiAppOption(
    id: 'phonepe',
    label: 'PhonePe',
    androidPackage: 'com.phonepe.app',
    iosScheme: 'phonepe://',
  );

  static const googlePay = UpiAppOption(
    id: 'gpay',
    label: 'Google Pay',
    androidPackage: 'com.google.android.apps.nbu.paisa.user',
    iosScheme: 'gpay://',
  );

  static const paytm = UpiAppOption(
    id: 'paytm',
    label: 'Paytm',
    androidPackage: 'net.one97.paytm',
    iosScheme: 'paytmmp://',
  );

  static const List<UpiAppOption> supported = [phonePe, googlePay, paytm];

  static UpiAppOption byId(String id) {
    return supported.firstWhere(
      (app) => app.id == id,
      orElse: () => phonePe,
    );
  }
}

class PremiumSubscriptionSession {
  const PremiumSubscriptionSession({
    required this.subscriptionId,
    required this.subscriptionSessionId,
    required this.environment,
    required this.firstChargeAt,
  });

  final String subscriptionId;
  final String subscriptionSessionId;
  final String environment;
  final String firstChargeAt;

  factory PremiumSubscriptionSession.fromMap(Map<String, dynamic> data) {
    return PremiumSubscriptionSession(
      subscriptionId: data['subscriptionId'] as String,
      subscriptionSessionId: data['subscriptionSessionId'] as String,
      environment: _parseEnvironment(data['environment']),
      firstChargeAt: data['firstChargeAt'] as String? ?? '',
    );
  }
}

class PremiumVerificationResult {
  const PremiumVerificationResult({
    required this.status,
    required this.isPremium,
    this.authorizationStatus,
  });

  final String status;
  final bool isPremium;
  final String? authorizationStatus;

  factory PremiumVerificationResult.fromMap(Map<String, dynamic> data) {
    return PremiumVerificationResult(
      status: data['status'] as String? ?? 'UNKNOWN',
      isPremium: data['isPremium'] == true,
      authorizationStatus: data['authorizationStatus'] as String?,
    );
  }
}

class CancellationChargeSession {
  const CancellationChargeSession({
    required this.orderId,
    required this.paymentSessionId,
    required this.environment,
    required this.amount,
    required this.alreadyCancelled,
    this.chargeWaived = false,
    this.periodEndAt = '',
  });

  final String orderId;
  final String paymentSessionId;
  final String environment;
  final int amount;
  final bool alreadyCancelled;
  final bool chargeWaived;
  final String periodEndAt;

  factory CancellationChargeSession.fromMap(Map<String, dynamic> data) {
    return CancellationChargeSession(
      orderId: data['orderId'] as String? ?? '',
      paymentSessionId: data['paymentSessionId'] as String? ?? '',
      environment: _parseEnvironment(data['environment']),
      amount: (data['amount'] as num?)?.toInt() ?? 299,
      alreadyCancelled: data['alreadyCancelled'] == true,
      chargeWaived: data['chargeWaived'] == true,
      periodEndAt: data['periodEndAt'] as String? ?? '',
    );
  }
}

String _parseEnvironment(Object? raw) {
  final value = raw?.toString().trim();
  if (value == 'production' || value == 'sandbox') {
    return value!;
  }
  throw FormatException(
    'Cashfree environment missing or invalid in server response: $raw',
  );
}

enum PremiumPaymentResult {
  success,
  failure,
  cancelled;

  bool get isSuccess => this == success;
}

class PaymentService {
  PaymentService({FirebaseFunctions? functions})
      : _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'asia-south1');

  final FirebaseFunctions _functions;
  final CFPaymentGatewayService _gateway = CFPaymentGatewayService();

  Future<PremiumSubscriptionSession> createPremiumSubscription() async {
    final callable = _functions.httpsCallable('createPremiumSubscription');
    final result = await callable.call<Map<String, dynamic>>({});
    return PremiumSubscriptionSession.fromMap(result.data);
  }

  /// Verifies the subscription status for the signed-in user.
  ///
  /// [subscriptionId] should be the ID returned by [createPremiumSubscription].
  /// Passing it lets the Cloud Function cross-validate ownership and reject any
  /// mismatched subscription document in Firestore.
  Future<PremiumVerificationResult> verifyPremiumSubscription({
    String? subscriptionId,
  }) async {
    final callable = _functions.httpsCallable('verifyPremiumSubscription');
    final result = await callable.call<Map<String, dynamic>>(
      subscriptionId != null ? {'subscriptionId': subscriptionId} : {},
    );
    return PremiumVerificationResult.fromMap(result.data);
  }

  /// Backfills billing transactions from legacy subscription fields.
  Future<void> syncBillingHistory() async {
    try {
      await _functions.httpsCallable('syncBillingHistory').call();
    } catch (_) {
      // Best-effort; the transactions stream still shows anything already stored.
    }
  }

  /// Starts a ₹299 PhonePe UPI charge, or cancels immediately with no extra
  /// charge when the current 30-day period is already prepaid.
  Future<CancellationChargeSession> createCancellationCharge() async {
    final callable = _functions.httpsCallable('createCancellationCharge');
    final result = await callable.call<Map<String, dynamic>>({});
    return CancellationChargeSession.fromMap(result.data);
  }

  /// Confirms the ₹299 PhonePe payment with Cashfree, then cancels Autopay.
  Future<PremiumVerificationResult> completeCancellationAfterCharge({
    required String orderId,
  }) async {
    final callable = _functions.httpsCallable('completeCancellationAfterCharge');
    final result = await callable.call<Map<String, dynamic>>({
      'orderId': orderId,
    });
    return PremiumVerificationResult.fromMap(result.data);
  }

  /// Cancels Autopay. ₹299 is required only during trial; a prepaid period
  /// cancels with no extra charge.
  Future<PremiumVerificationResult> cancelPremiumSubscription() async {
    final callable = _functions.httpsCallable('cancelPremiumSubscription');
    final result = await callable.call<Map<String, dynamic>>({});
    return PremiumVerificationResult.fromMap(result.data);
  }

  Future<PremiumPaymentResult> launchUpiOneTimePayment({
    required CancellationChargeSession session,
    required UpiAppOption upiApp,
  }) {
    return _runGatewayPayment(() {
      final cfSession = CFSessionBuilder()
          .setEnvironment(_mapEnvironment(session.environment))
          .setOrderId(session.orderId)
          .setPaymentSessionId(session.paymentSessionId)
          .build();

      final upi = CFUPIBuilder()
          .setChannel(CFUPIChannel.INTENT)
          .setUPIID(upiApp.launchId)
          .build();

      _gateway.doPayment(
        CFUPIPaymentBuilder().setSession(cfSession).setUPI(upi).build(),
      );
    });
  }

  Future<PremiumPaymentResult> launchUpiMandate({
    required PremiumSubscriptionSession session,
    required UpiAppOption upiApp,
  }) {
    return _runGatewayPayment(() {
      final cfSession = CFSubscriptionSessionBuilder()
          .setEnvironment(_mapEnvironment(session.environment))
          .setSubscriptionId(session.subscriptionId)
          .setSubscriptionSessionId(session.subscriptionSessionId)
          .build();

      final subsUpi = CFSubsUPIBuilder()
          .setChannel(CFSubsUPIChannel.INTENT)
          .setUPIID(upiApp.launchId)
          .build();

      _gateway.doPayment(
        CFSubsUPIPaymentBuilder().setSession(cfSession).setUPI(subsUpi).build(),
      );
    });
  }

  /// User-cancel and timeout stay [PremiumPaymentResult.cancelled].
  /// Only a real gateway/SDK error is [PremiumPaymentResult.failure].
  Future<PremiumPaymentResult> _runGatewayPayment(
    void Function() startPayment,
  ) async {
    final completer = Completer<PremiumPaymentResult>();

    _gateway.setCallback(
      (id) {
        if (!completer.isCompleted) {
          completer.complete(PremiumPaymentResult.success);
        }
      },
      (CFErrorResponse error, String _) {
        if (!completer.isCompleted) {
          completer.complete(_resultFromError(error));
        }
      },
    );

    try {
      startPayment();
    } on CFException {
      return PremiumPaymentResult.failure;
    } catch (_) {
      return PremiumPaymentResult.failure;
    }

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => PremiumPaymentResult.cancelled,
    );
  }

  PremiumPaymentResult _resultFromError(CFErrorResponse error) {
    final text = [
      error.getStatus(),
      error.getCode(),
      error.getType(),
      error.getMessage(),
    ].whereType<String>().join(' ').toLowerCase();
    if (text.contains('cancel') || text.contains('user dropped')) {
      return PremiumPaymentResult.cancelled;
    }
    return PremiumPaymentResult.failure;
  }

  CFEnvironment _mapEnvironment(String raw) {
    return raw == 'production' ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX;
  }
}
