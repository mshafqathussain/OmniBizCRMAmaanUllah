import 'package:flutter/material.dart';
import '../../database/app_database.dart';

class CustomerLedgerScreen extends StatelessWidget {
  final Map<String, dynamic> customer;

  const CustomerLedgerScreen({
    super.key,
    required this.customer,
  });

  String money(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0.0;
    return 'Rs. ${amount.toStringAsFixed(2)}';
  }

  String formatDate(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return value?.toString() ?? '-';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final customerId = customer['id'] as int;
    final customerName = customer['name']?.toString() ?? 'Customer';
    final mobile = customer['mobile']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Ledger'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: AppDatabase.instance.getCustomerLedger(customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load ledger: ${snapshot.error}'),
            );
          }

          final entries = snapshot.data ?? [];
          double totalDebit = 0;
          double totalCredit = 0;

          for (final entry in entries) {
            final amount = (entry['amount'] as num?)?.toDouble() ?? 0;
            if (entry['entry_type'] == 'Debit') {
              totalDebit += amount;
            } else {
              totalCredit += amount;
            }
          }

          final closingBalance = entries.isEmpty
              ? 0.0
              : (entries.last['running_balance'] as num?)?.toDouble() ?? 0.0;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (mobile.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(mobile),
                      ],
                      const SizedBox(height: 5),
                      const Text('Customer Account Statement'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      context,
                      'Total Debit',
                      money(totalDebit),
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryCard(
                      context,
                      'Total Credit',
                      money(totalCredit),
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Closing Balance'),
                      const SizedBox(height: 6),
                      Text(
                        money(closingBalance),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        closingBalance > 0
                            ? 'Receivable from customer'
                            : closingBalance < 0
                                ? 'Customer advance'
                                : 'Account settled',
                        style: TextStyle(
                          color: closingBalance > 0
                              ? Colors.orange
                              : closingBalance < 0
                                  ? Colors.green
                                  : Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Transaction History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (entries.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('No transactions found for this customer.'),
                    ),
                  ),
                )
              else
                ...entries.map((entry) {
                  final isDebit = entry['entry_type'] == 'Debit';
                  final amount =
                      (entry['amount'] as num?)?.toDouble() ?? 0.0;
                  final runningBalance =
                      (entry['running_balance'] as num?)?.toDouble() ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isDebit
                            ? Colors.red.withValues(alpha: 0.12)
                            : Colors.green.withValues(alpha: 0.12),
                        child: Icon(
                          isDebit ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isDebit ? Colors.red : Colors.green,
                        ),
                      ),
                      title: Text(
                        entry['transaction_type']?.toString() ?? 'Transaction',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formatDate(entry['transaction_date'])),
                          Text('Reference: ${entry['reference'] ?? '-'}'),
                          if ((entry['note']?.toString() ?? '').isNotEmpty)
                            Text('Note: ${entry['note']}'),
                          Text('Balance: ${money(runningBalance)}'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        '${isDebit ? '+' : '-'}${money(amount)}',
                        style: TextStyle(
                          color: isDebit ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    String title,
    String value,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
