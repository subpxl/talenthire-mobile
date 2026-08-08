import 'package:cloud_firestore/cloud_firestore.dart';

class AppTransaction {
  final String id;
  final String userId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final String status;
  final String type;
  final String purpose;
  final String paymentId;
  final String cashfreeOrderId;
  final String cashfreePaymentId;
  final String gateway;
  final String? subscriptionId;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final DateTime createdAt;

  AppTransaction({
    required this.id,
    this.userId = '',
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    this.currency = 'INR',
    required this.status,
    this.type = 'payment',
    this.purpose = '',
    this.paymentId = '',
    this.cashfreeOrderId = '',
    this.cashfreePaymentId = '',
    this.gateway = 'cashfree',
    this.subscriptionId,
    this.expiresAt,
    this.paidAt,
    required this.createdAt,
  });

  bool get isSubscription => type == 'subscription' || purpose == 'premium_upgrade';

  String get displayTitle {
    if (isSubscription) return 'Premium Subscription';
    if (toUserId == 'platform') return 'Platform Payment';
    if (fromUserId == userId) return 'Payment Sent';
    return 'Payment Received';
  }

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      return DateTime.tryParse(value.toString());
    }

    return AppTransaction(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      fromUserId: json['fromUserId']?.toString() ?? '',
      toUserId: json['toUserId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'INR',
      status: json['status']?.toString() ?? 'pending',
      type: json['type']?.toString() ?? 'payment',
      purpose: json['purpose']?.toString() ?? '',
      paymentId: json['paymentId']?.toString() ?? json['id']?.toString() ?? '',
      cashfreeOrderId:
          json['cashfreeOrderId']?.toString() ?? json['id']?.toString() ?? '',
      cashfreePaymentId: json['cashfreePaymentId']?.toString() ?? '',
      gateway: json['gateway']?.toString() ?? 'cashfree',
      subscriptionId: json['subscriptionId']?.toString(),
      expiresAt: parseDate(json['expiresAt'] ?? json['expires_at']),
      paidAt: parseDate(json['paidAt'] ?? json['paid_at']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
    );
  }
}
