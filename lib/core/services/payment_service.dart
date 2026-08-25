import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/subs/cfsubsupi.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/subs/cfsubsupipayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
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
      environment: data['environment'] as String? ?? 'sandbox',
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

enum PremiumPaymentResult {
  success,
  failure,
  cancelled,
}

class PaymentService {
  PaymentService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

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

  /// Cancels the signed-in user's Cashfree Autopay mandate and ends Premium.
  Future<PremiumVerificationResult> cancelPremiumSubscription() async {
    final callable = _functions.httpsCallable('cancelPremiumSubscription');
    final result = await callable.call<Map<String, dynamic>>({});
    return PremiumVerificationResult.fromMap(result.data);
  }

  Future<PremiumPaymentResult> launchUpiMandate({
    required PremiumSubscriptionSession session,
    required UpiAppOption upiApp,
    void Function(String subscriptionId)? onVerify,
    void Function(String message)? onFailure,
  }) async {
    final completer = Completer<PremiumPaymentResult>();

    _gateway.setCallback(
      (subscriptionId) {
        onVerify?.call(subscriptionId);
        if (!completer.isCompleted) {
          completer.complete(PremiumPaymentResult.success);
        }
      },
      (CFErrorResponse errorResponse, String orderId) {
        final message = errorResponse.getMessage() ?? 'Payment failed';
        onFailure?.call(message);
        if (!completer.isCompleted) {
          completer.complete(PremiumPaymentResult.failure);
        }
      },
    );

    try {
      final cfSession = CFSubscriptionSessionBuilder()
          .setEnvironment(_mapEnvironment(session.environment))
          .setSubscriptionId(session.subscriptionId)
          .setSubscriptionSessionId(session.subscriptionSessionId)
          .build();

      final subsUpi = CFSubsUPIBuilder()
          .setChannel(CFSubsUPIChannel.INTENT)
          .setUPIID(upiApp.launchId)
          .build();

      final subsUpiPayment = CFSubsUPIPaymentBuilder()
          .setSession(cfSession)
          .setUPI(subsUpi)
          .build();

      _gateway.doPayment(subsUpiPayment);
    } on CFException catch (error) {
      onFailure?.call(error.message);
      return PremiumPaymentResult.failure;
    } catch (error) {
      onFailure?.call(error.toString());
      return PremiumPaymentResult.failure;
    }

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => PremiumPaymentResult.cancelled,
    );
  }

  CFEnvironment _mapEnvironment(String raw) {
    return raw == 'production' ? CFEnvironment.PRODUCTION : CFEnvironment.SANDBOX;
  }
}
