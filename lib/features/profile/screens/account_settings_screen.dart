import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bombay_casting/app/app_state.dart';
import 'package:bombay_casting/core/models/model_helpers.dart';
import 'package:bombay_casting/core/services/payment_service.dart';
import 'package:bombay_casting/core/theme/app_theme.dart';
import 'package:bombay_casting/l10n/app_localizations.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoggingOut = false;
  bool _isCancelling = false;

  static const _terminalStatuses = {
    'CUSTOMER_CANCELLED',
    'CANCELLED',
    'EXPIRED',
    'LINK_EXPIRED',
    'COMPLETED',
  };

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppState>().user?.id;

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
        title: Text(AppLocalizations.of(context)!.accountSettings,
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
          _SettingsCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 14,
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 22),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(AppLocalizations.of(context)!.contactPrivacy,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.chatGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsCard(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                14,
              ),
              child: uid == null
                  ? _emptySubscriptionSection(context)
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('subscriptions')
                          .doc(uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data();
                        return _subscriptionSection(context, data);
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoggingOut ? null : _logout,
              child: _isLoggingOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(AppLocalizations.of(context)!.logout),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => _confirmDeleteAccount(context),
              child: Text(AppLocalizations.of(context)!.deleteAccount,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptySubscriptionSection(BuildContext context) {
    return _subscriptionSection(context, null);
  }

  Widget _subscriptionSection(
    BuildContext context,
    Map<String, dynamic>? data,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = context.watch<AppState>().isPremiumUser;
    final transactions = _transactionsFromSubscription(data);
    final canCancel = _canCancel(
      status: data?['subscription_status']?.toString(),
      isPremium: isPremium,
      hasSubscription: data != null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.subscriptions,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(l10n.recentTransactions, style: context.caption),
        const SizedBox(height: AppSpacing.md),
        if (transactions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(l10n.noTransactionsYet, style: context.caption),
          )
        else
          ...transactions.map((item) => _TransactionTile(item: item)),
        if (canCancel) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              onPressed: _isCancelling ? null : _confirmCancelSubscription,
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
      ],
    );
  }

  bool _canCancel({
    required String? status,
    required bool isPremium,
    required bool hasSubscription,
  }) {
    if (!hasSubscription && !isPremium) return false;
    if (isPremium) return true;
    final normalized = (status ?? '').toUpperCase();
    if (normalized.isEmpty) return false;
    return !_terminalStatuses.contains(normalized);
  }

  List<_TransactionItem> _transactionsFromSubscription(
    Map<String, dynamic>? data,
  ) {
    if (data == null) return const [];

    final status = (data['subscription_status'] ?? '').toString();
    final createdAt = parseFlexibleDate(data['created_at']);
    final firstChargeAt = parseFlexibleDate(data['first_charge_at']);
    final authAmount = data['authorization_amount'] ?? 1;
    final recurringAmount = data['recurring_amount'] ?? 299;
    final now = DateTime.now();
    final monthlyUpcoming =
        firstChargeAt != null && firstChargeAt.isAfter(now);

    return [
      _TransactionItem(
        title: 'Premium Trial',
        amount: '₹$authAmount',
        date: createdAt == null ? '' : DateFormat('d MMM yyyy').format(createdAt),
        status: _displayStatus(status, upcoming: false),
        isCancelled: _terminalStatuses.contains(status.toUpperCase()),
      ),
      _TransactionItem(
        title: 'Premium Monthly',
        amount: '₹$recurringAmount',
        date: firstChargeAt == null
            ? ''
            : DateFormat('d MMM yyyy').format(firstChargeAt),
        status: _displayStatus(status, upcoming: monthlyUpcoming),
        isCancelled: _terminalStatuses.contains(status.toUpperCase()),
      ),
    ];
  }

  String _displayStatus(String status, {required bool upcoming}) {
    final normalized = status.toUpperCase();
    if (_terminalStatuses.contains(normalized)) return 'Cancelled';
    if (upcoming) return 'Upcoming';
    if (normalized == 'ACTIVE') return 'Paid';
    if (normalized.isEmpty) return 'Pending';
    return 'Pending';
  }

  Future<void> _confirmCancelSubscription() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ConfirmDialog(
        title: l10n.cancelPremiumTitle,
        message: l10n.cancelPremiumMessage,
      ),
    );
    if (confirmed != true || !mounted) return;
    await _cancelSubscription();
  }

  Future<void> _cancelSubscription() async {
    setState(() => _isCancelling = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await _paymentService.cancelPremiumSubscription();
      if (!mounted) return;
      await context.read<AppState>().refreshProfile();
      if (!mounted) return;
      _showMessage(l10n.subscriptionCancelled);
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      if (error.code == 'failed-precondition') {
        _showMessage(l10n.noActiveSubscription);
      } else {
        _showMessage(error.message ?? l10n.couldNotCancelSubscription);
      }
    } catch (_) {
      if (!mounted) return;
      _showMessage(l10n.couldNotCancelSubscription);
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    await context.read<AppState>().logout();
    if (!mounted) return;
    setState(() => _isLoggingOut = false);
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => const _ConfirmDialog(
        title: 'Are you sure?',
      ),
    );
    if (first != true || !context.mounted) return;

    await showDialog<bool>(
      context: context,
      builder: (context) => const _ConfirmDialog(
        title: 'Are you definitely sure?',
        message: 'Nothing can be recovered.',
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _TransactionItem {
  const _TransactionItem({
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    this.isCancelled = false,
  });

  final String title;
  final String amount;
  final String date;
  final String status;
  final bool isCancelled;
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.item});

  final _TransactionItem item;

  @override
  Widget build(BuildContext context) {
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
                if (item.date.isNotEmpty) Text(item.date, style: context.caption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                item.amount,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.status,
                style: context.caption.copyWith(
                  color: item.isCancelled
                      ? AppColors.textSecondary
                      : AppColors.accentGreen,
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

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    this.message,
  });

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 10),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.bodyMedium,
              ),
            ],
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(AppLocalizations.of(context)!.no),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: Text(AppLocalizations.of(context)!.yes),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
