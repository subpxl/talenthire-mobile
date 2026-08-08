import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transactions'),
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final transactions = appState.transactions;

          if (appState.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'No transactions found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final txn = transactions[index];
              final isCompleted = txn.status == 'completed';
              final currencySymbol = txn.currency == 'INR' ? '₹' : txn.currency;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: isCompleted
                                ? Colors.green.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                            child: Icon(
                              txn.isSubscription ? Icons.workspace_premium : Icons.payment,
                              color: isCompleted ? Colors.green : Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  txn.displayTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(txn.paidAt ?? txn.createdAt),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$currencySymbol${txn.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isCompleted ? Colors.green : Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                txn.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _detailRow('Payment ID', txn.cashfreePaymentId.isNotEmpty
                          ? txn.cashfreePaymentId
                          : txn.paymentId),
                      _detailRow('Order ID', txn.cashfreeOrderId),
                      if (txn.gateway.isNotEmpty) _detailRow('Gateway', txn.gateway),
                      if (txn.expiresAt != null)
                        _detailRow('Valid Until', _formatDate(txn.expiresAt)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
