import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfdropcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/api/cftheme/cftheme.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfexceptions.dart';
import 'dart:async';
import '../models/models.dart';

/// Cashfree payment service.
class CashfreeService {
  static final CashfreeService _instance = CashfreeService._internal();
  factory CashfreeService() => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Explicitly set region to match deployed function region
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // Payment gateway service
  final CFPaymentGatewayService _cfPaymentGatewayService =
      CFPaymentGatewayService();

  // Completer for payment results
  Completer<PaymentStatus>? _paymentCompleter;

  // Last error from Cashfree SDK (for debugging)
  String? _lastSdkError;

  CashfreeService._internal() {
    _cfPaymentGatewayService.setCallback(verifyPayment, onError);
  }

  void verifyPayment(String orderId) {
    debugPrint('✅ CashfreeService.verifyPayment called for order: $orderId');
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(PaymentStatus.completed);
    }
  }

  void onError(CFErrorResponse errorResponse, String orderId) {
    _lastSdkError = errorResponse.getMessage();
    debugPrint(
        '❌ CashfreeService.onError: order=$orderId, error=${errorResponse.getMessage()}, status=${errorResponse.getStatus()}');
    if (_paymentCompleter != null && !_paymentCompleter!.isCompleted) {
      _paymentCompleter!.complete(PaymentStatus.failed);
    }
  }

  String? get lastError => _lastSdkError;

  // ===== Create a payment order =====
  Future<Payment?> initiatePayment({
    required String userId,
    required double amount,
    required String purpose,
  }) async {
    _lastSdkError = null;
    try {
      debugPrint('🔄 Calling createCashfreeOrder: userId=$userId, amount=$amount, purpose=$purpose');

      // 1. Create order via Cloud Function (explicit region us-central1)
      final result = await _functions.httpsCallable('createCashfreeOrder').call({
        'userId': userId,
        'amount': amount,
        'purpose': purpose,
      });

      debugPrint('✅ Cloud Function returned: ${result.data}');

      // Firebase callable returns Map<dynamic, dynamic> — must convert
      final data = Map<String, dynamic>.from(result.data as Map);

      final String orderId = data['orderId'] as String;
      final String paymentSessionId = data['paymentSessionId'] as String;
      final String envStr = data['environment'] as String? ?? 'sandbox';

      debugPrint('📦 orderId=$orderId, sessionId=${paymentSessionId.substring(0, 20)}...');

      final environment =
          envStr == 'sandbox' ? CFEnvironment.SANDBOX : CFEnvironment.PRODUCTION;

      _paymentCompleter = Completer<PaymentStatus>();

      try {
        final session = CFSessionBuilder()
            .setEnvironment(environment)
            .setOrderId(orderId)
            .setPaymentSessionId(paymentSessionId)
            .build();

        debugPrint('✅ CFSession built successfully');

        final theme = CFThemeBuilder()
            .setNavigationBarBackgroundColorColor('#190C35')
            .setPrimaryFont('Roboto')
            .setSecondaryFont('Roboto')
            .build();

        final cfDropCheckoutPayment = CFDropCheckoutPaymentBuilder()
            .setSession(session)
            .setTheme(theme)
            .build();

        debugPrint('🚀 Calling doPayment — Cashfree UI should open now...');
        _cfPaymentGatewayService.doPayment(cfDropCheckoutPayment);
        debugPrint('✅ doPayment called — waiting for user action...');

        // Wait for verifyPayment or onError callback
        final paymentStatus = await _paymentCompleter!.future;
        _paymentCompleter = null;

        debugPrint('📊 Payment status from SDK: $paymentStatus, lastError=$_lastSdkError');

        if (paymentStatus == PaymentStatus.failed) {
          debugPrint('❌ Payment failed at SDK level. Reason: $_lastSdkError');
          return Payment(
            id: orderId,
            userId: userId,
            amount: amount,
            purpose: purpose,
            status: PaymentStatus.failed,
          );
        }

        // Wait briefly for webhook to update Firestore
        await Future.delayed(const Duration(seconds: 3));

        // Fetch latest payment status from Firestore
        final paymentDoc =
            await _firestore.collection('payments').doc(orderId).get();
        if (paymentDoc.exists) {
          final paymentStatusStr =
              paymentDoc.data()?['status'] as String? ?? 'pending';
          debugPrint('📄 Firestore payment status: $paymentStatusStr');
          final finalStatus = paymentStatusFromString(paymentStatusStr);

          return Payment(
            id: orderId,
            userId: userId,
            amount: amount,
            purpose: purpose,
            status: finalStatus,
          );
        } else {
          debugPrint('⚠️ Payment doc not found in Firestore for $orderId');
        }
      } on CFException catch (e) {
        debugPrint('❌ CFException: ${e.message}');
        _lastSdkError = e.message;
      }

      return null;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('❌ FirebaseFunctionsException: code=${e.code}, message=${e.message}, details=${e.details}');
      _lastSdkError = e.message;
      return null;
    } catch (e, stack) {
      debugPrint('❌ Payment initiation error: $e\n$stack');
      _lastSdkError = e.toString();
      return null;
    }
  }

  // ===== Premium Upgrade (₹200 for influencer) =====
  Future<bool> upgradeToPremium(String userId) async {
    final payment = await initiatePayment(
      userId: userId,
      amount: AppPricing.premiumUpgrade,
      purpose: 'premium_upgrade',
    );

    if (payment != null && payment.status == PaymentStatus.completed) {
      return true;
    }
    debugPrint('upgradeToPremium failed. lastError=$_lastSdkError');
    return false;
  }
}


