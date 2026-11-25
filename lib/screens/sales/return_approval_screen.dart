import 'package:flutter/material.dart';
import '../../database/app_database.dart';

class ReturnApprovalScreen extends StatefulWidget {
  final bool readOnly;

  const ReturnApprovalScreen({super.key, this.readOnly = false});

  @override
  State<ReturnApprovalScreen> createState() => _ReturnApprovalScreenState();
}

class _ReturnApprovalScreenState extends State<ReturnApprovalScreen> {
  final db = AppDatabase.instance;
  List<Map<String, dynamic>> requests = [];
  bool loading = true;
  final Set<int> approving = {};

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  void message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> loadRequests() async {
    setState(() => loading = true);
    try {
      final result = await db.getSaleReturnHistory();
      if (!mounted) return;
      setState(() => requests = result);
    } catch (e) {
      message('Pending returns load error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> approve(Map<String, dynamic> request) async {
    final id = (request['id'] as num).toInt();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approve Return?'),
        content: Text(
          'Return: ${request['return_number']}\n'
          'Invoice: ${request['bill_number']}\n'
          'Refund: ${request['total_amount']}\n\n'
          'Approval will complete the refund and restore Good-condition stock. '
          'Damaged items will be recorded separately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => approving.add(id));
    try {
      final result = await db.approveSaleReturn(returnId: id);
      if (!mounted) return;
      message(
        'Approved: ${result['return_id']} | Refund: ${result['refund_status']}',
      );
      await loadRequests();
    } catch (e) {
      message('Approval failed: $e');
    } finally {
      if (mounted) setState(() => approving.remove(id));
    }
  }

  String displayDate(dynamic value) {
    if (value == null) return '-';
    return value.toString().replaceFirst('T', ' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.readOnly ? 'Refund Details' : 'Return Approval'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : loadRequests,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(
                  child: Text('No Pending Return Requests'),
                )
              : RefreshIndicator(
                  onRefresh: loadRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final item = requests[index];
                      final id = (item['id'] as num).toInt();
                      final busy = approving.contains(id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.assignment_return),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${item['return_number']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text('${item['status']}'),
                                  ),
                                ],
                              ),
                              const Divider(),
                              _detail('Invoice', item['bill_number']),
                              _detail('Customer', item['customer_name']),
                              _detail('Refund ID', item['refund_id']),
                              _detail('Refund Amount', item['total_amount']),
                              _detail('Method', item['refund_method']),
                              _detail('Refund Status', item['refund_status']),
                              _detail('Date', displayDate(item['return_date'])),
                              if ((item['reason'] ?? '').toString().isNotEmpty)
                                _detail('Reason', item['reason']),
                              if (!widget.readOnly && item['status'] == 'Pending') ...[
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                  onPressed: busy ? null : () => approve(item),
                                  icon: busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.check_circle),
                                  label: Text(
                                    busy ? 'Processing...' : 'Approve Return & Refund',
                                  ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _detail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text('${value ?? '-'}')),
        ],
      ),
    );
  }
}
