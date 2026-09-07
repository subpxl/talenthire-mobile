import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/billing_transaction.dart';
import 'package:bombay_casting/core/models/model_helpers.dart';
import 'package:bombay_casting/core/services/payment_service.dart';
import 'package:bombay_casting/core/widgets/app_success_toast.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/features/profile/screens/account_settings_screen.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';

class PaymentAndSubscriptionScreen extends StatefulWidget {
  const PaymentAndSubscriptionScreen({super.key});

  @override
  State<PaymentAndSubscriptionScreen> createState() =>
      _PaymentAndSubscriptionScreenState();
}

class _PaymentAndSubscriptionScreenState
    extends State<PaymentAndSubscriptionScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isCancelling = false;
  bool _syncedBillingHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncBillingHistoryOnce());
  }

  Future<void> _syncBillingHistoryOnce() async {
    if (_syncedBillingHistory) return;
    _syncedBillingHistory = true;
    await _paymentService.syncBillingHistory();
  }

  static const _terminalStatuses = {
    'CUSTOMER_CANCELLED',
    'CANCELLED',
    'EXPIRED',
    'LINK_EXPIRED',
    'COMPLETED',
  };

  bool _canCancel({
    required String? status,
    required bool isPremium,
    required bool hasSubscription,
    required bool cancelAtPeriodEnd,
  }) {
    if (cancelAtPeriodEnd) return false;
    if (!hasSubscription && !isPremium) return false;
    if (isPremium) return true;
    final normalized = (status ?? '').toUpperCase();
    if (normalized.isEmpty) return false;
    return !_terminalStatuses.contains(normalized);
  }

  DateTime? _prepaidPeriodEnd(Map<String, dynamic>? data) {
    if (data == null) return null;
    if (data['cancel_at_period_end'] == true) {
      return parseFlexibleDate(data['period_end_at']);
    }
    final lastCharged = parseFlexibleDate(data['last_charged_at']);
    if (lastCharged != null) {
      return lastCharged.add(const Duration(days: 30));
    }
    final firstCharge = parseFlexibleDate(data['first_charge_at']);
    if (firstCharge == null || firstCharge.isAfter(DateTime.now())) {
      return null;
    }
    var periodEnd = firstCharge.add(const Duration(days: 30));
    while (!periodEnd.isAfter(DateTime.now())) {
      periodEnd = periodEnd.add(const Duration(days: 30));
    }
    return periodEnd;
  }

  bool _isPrepaidCurrentPeriod(Map<String, dynamic>? data) {
    final end = _prepaidPeriodEnd(data);
    return end != null && end.isAfter(DateTime.now());
  }

  Future<void> _confirmCancelSubscription(Map<String, dynamic>? subscription) async {
    final l10n = AppLocalizations.of(context)!;
    final prepaid = _isPrepaidCurrentPeriod(subscription);
    final periodEnd = _prepaidPeriodEnd(subscription);
    final prepaidMessage = periodEnd == null
        ? 'Your ₹299 for this period is already paid. Cancel Autopay now with no extra charge. You keep Premium until the period ends.'
        : 'Your ₹299 for this period is already paid until ${DateFormat('d MMM yyyy').format(periodEnd)}. Cancel Autopay now with no extra charge. You keep Premium until then.';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AccountConfirmDialog(
        title: l10n.cancelPremiumTitle,
        message: prepaid ? prepaidMessage : l10n.cancelPremiumMessage,
      ),
    );
    if (confirmed != true || !mounted) return;
    await _cancelSubscription();
  }

  Future<void> _cancelSubscription() async {
    setState(() => _isCancelling = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final session = await _paymentService.createCancellationCharge();
      if (!mounted) return;

      if (session.alreadyCancelled) {
        await context.read<AppState>().refreshProfile();
        if (!mounted) return;
        if (session.chargeWaived) {
          final end = DateTime.tryParse(session.periodEndAt);
          _showMessage(
            end == null
                ? 'Autopay cancelled. You keep Premium until this paid period ends.'
                : 'Autopay cancelled. You keep Premium until ${DateFormat('d MMM yyyy').format(end.toLocal())}.',
            type: AppToastType.success,
          );
        } else {
          _showMessage(l10n.subscriptionCancelled, type: AppToastType.success);
        }
        return;
      }

      final paymentResult = await _paymentService.launchUpiOneTimePayment(
        session: session,
        upiApp: UpiAppOption.phonePe,
      );
      if (!mounted) return;
      if (!paymentResult.isSuccess) {
        if (paymentResult == PremiumPaymentResult.failure) {
          _showMessage(l10n.cancellationChargeIncomplete);
        }
        return;
      }

      await _paymentService.completeCancellationAfterCharge(
        orderId: session.orderId,
      );
      if (!mounted) return;
      await context.read<AppState>().refreshProfile();
      if (!mounted) return;
      _showMessage(l10n.subscriptionCancelled, type: AppToastType.success);
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      if (error.code == 'failed-precondition') {
        final message = error.message ?? '';
        if (message.contains('PhonePe') || message.contains('₹299')) {
          _showMessage(l10n.cancellationChargeIncomplete);
        } else {
          _showMessage(l10n.noActiveSubscription);
        }
      } else {
        _showMessage(error.message ?? l10n.couldNotCancelSubscription);
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage(l10n.couldNotCancelSubscription);
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  void _showMessage(String message, {AppToastType type = AppToastType.error}) {
    showAppToast(context, message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = context.watch<AppState>().user?.id;
    final isPremium = context.watch<AppState>().isPremiumUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Payment and subscription',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.md,
          AppSpacing.screenH,
          AppSpacing.scrollBottom,
        ),
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: uid == null
                  ? _body(
                      l10n: l10n,
                      isPremium: false,
                      canCancel: false,
                      subscription: null,
                      transactions: const [],
                    )
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('subscriptions')
                          .doc(uid)
                          .snapshots(),
                      builder: (context, subscriptionSnapshot) {
                        final data = subscriptionSnapshot.data?.data();
                        final canCancel = _canCancel(
                          status: data?['subscription_status']?.toString(),
                          isPremium: isPremium,
                          hasSubscription: data != null,
                          cancelAtPeriodEnd: data?['cancel_at_period_end'] == true,
                        );
                        return StreamBuilder<
                            QuerySnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('transactions')
                              .where('userId', isEqualTo: uid)
                              .orderBy('createdAt', descending: true)
                              .limit(30)
                              .snapshots(),
                          builder: (context, transactionsSnapshot) {
                            final transactions = transactionsSnapshot.data?.docs
                                    .map(
                                      (doc) => BillingTransaction.fromFirestore(
                                        doc.id,
                                        doc.data(),
                                      ),
                                    )
                                    .toList() ??
                                const <BillingTransaction>[];

                            return _body(
                              l10n: l10n,
                              isPremium: isPremium,
                              canCancel: canCancel,
                              subscription: data,
                              transactions: transactions,
                              loadingTransactions:
                                  transactionsSnapshot.connectionState ==
                                      ConnectionState.waiting,
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body({
    required AppLocalizations l10n,
    required bool isPremium,
    required bool canCancel,
    required Map<String, dynamic>? subscription,
    required List<BillingTransaction> transactions,
    bool loadingTransactions = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.subscriptions,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(l10n.recentTransactions, style: context.caption),
        const SizedBox(height: AppSpacing.md),
        if (loadingTransactions && transactions.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(l10n.noTransactionsYet, style: context.caption),
          )
        else
          ...transactions.map((item) => _TransactionTile(item: item)),
        const SizedBox(height: AppSpacing.sm),
        Text(
          isPremium
              ? l10n.youAreAPremiumMember
              : l10n.becomeAPremiumMember,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _cancelCopy(l10n, subscription),
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: canCancel && !_isCancelling
                ? () => _confirmCancelSubscription(subscription)
                : null,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
            child: _isCancelling
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.cancelSubscription),
          ),
        ),
      ],
    );
  }

  String _cancelCopy(
    AppLocalizations l10n,
    Map<String, dynamic>? subscription,
  ) {
    final periodEnd = _prepaidPeriodEnd(subscription);
    final date = periodEnd == null
        ? ''
        : DateFormat('d MMM yyyy').format(periodEnd);
    if (subscription?['cancel_at_period_end'] == true &&
        periodEnd != null &&
        periodEnd.isAfter(DateTime.now())) {
      return 'Autopay is cancelled. You keep Premium until $date because this period is already paid.';
    }
    if (_isPrepaidCurrentPeriod(subscription)) {
      return 'Your ₹299 for this period is already paid until $date. You can cancel Autopay now with no extra charge and keep Premium until then.';
    }
    return l10n.cancelPremiumMessage;
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});

  final BillingTransaction item;

  @override
  Widget build(BuildContext context) {
    final occurredAt = item.occurredAt;
    final dateLabel = occurredAt == null
        ? ''
        : DateFormat('d MMM yyyy').format(occurredAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_rupee,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (dateLabel.isNotEmpty)
                  Text(dateLabel, style: context.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.formattedAmount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.displayStatus,
                style: context.caption.copyWith(
                  color: item.isPaid
                      ? AppColors.accentGreen
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
