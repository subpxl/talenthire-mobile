import 'package:bombay_casting/core/models/model_helpers.dart';

class BillingTransaction {
  const BillingTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.type,
    this.purpose = '',
    this.cashfreeOrderId = '',
    this.paidAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final num amount;
  final String currency;
  final String status;
  final String type;
  final String purpose;
  final String cashfreeOrderId;
  final DateTime? paidAt;
  final DateTime? createdAt;

  factory BillingTransaction.fromFirestore(String id, Map<String, dynamic> data) {
    return BillingTransaction(
      id: id,
      userId: (data['userId'] ?? '').toString(),
      amount: (data['amount'] as num?) ?? 0,
      currency: (data['currency'] ?? 'INR').toString(),
      status: (data['status'] ?? '').toString(),
      type: (data['type'] ?? data['purpose'] ?? '').toString(),
      purpose: (data['purpose'] ?? '').toString(),
      cashfreeOrderId: (data['cashfreeOrderId'] ?? '').toString(),
      paidAt: parseFlexibleDate(data['paidAt']),
      createdAt: parseFlexibleDate(data['createdAt']),
    );
  }

  DateTime? get occurredAt => paidAt ?? createdAt;

  String get title {
    switch (type) {
      case 'premium_trial':
        return 'Premium Trial';
      case 'premium_monthly':
        return 'Premium Monthly';
      case 'cancellation_charge':
        return 'Cancellation charge';
      case 'agency_premium':
        return 'Agency Premium';
      case 'wallet_topup':
        return 'Wallet top-up';
      default:
        if (type.isNotEmpty) {
          return type
              .split('_')
              .map(
                (part) => part.isEmpty
                    ? part
                    : '${part[0].toUpperCase()}${part.substring(1)}',
              )
              .join(' ');
        }
        return 'Payment';
    }
  }

  String get formattedAmount {
    final value = amount % 1 == 0 ? amount.toInt().toString() : amount.toString();
    if (currency.toUpperCase() == 'INR') return '₹$value';
    return '$currency $value';
  }

  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'failed':
        return 'Failed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.isEmpty ? 'Pending' : status;
    }
  }

  bool get isPaid => status.toLowerCase() == 'completed';
  bool get isCancelled =>
      status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'failed';
}
