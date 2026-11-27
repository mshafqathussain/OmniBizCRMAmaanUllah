import 'package:flutter/material.dart';
import '../../database/app_database.dart';

class SalesReturnScreen extends StatefulWidget {
  const SalesReturnScreen({super.key});

  @override
  State<SalesReturnScreen> createState() => _SalesReturnScreenState();
}

class _SalesReturnScreenState extends State<SalesReturnScreen> {
  final db = AppDatabase.instance;
  final invoiceController = TextEditingController();
  final reasonController = TextEditingController();

  Map<String, dynamic>? sale;
  List<Map<String, dynamic>> items = [];
  final Map<int, TextEditingController> quantities = {};
  final Map<int, String> conditions = {};

  String refundMethod = 'Cash';
  bool loading = false;
  int? draftId;

  @override
  void dispose() {
    invoiceController.dispose();
    reasonController.dispose();
    for (final c in quantities.values) {
      c.dispose();
    }
    super.dispose();
  }

  void message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  Future<void> searchInvoice() async {
    final invoice = invoiceController.text.trim();
    if (invoice.isEmpty) {
      message('Please enter the invoice number.');
      return;
    }

    setState(() => loading = true);
    try {
      final result = await db.getSaleForReturn(invoice);
      if (!mounted) return;

      for (final c in quantities.values) {
        c.dispose();
      }
      quantities.clear();
      conditions.clear();

      if (result == null) {
        setState(() {
          sale = null;
          items = [];
        });
        message('Invoice not found.');
        return;
      }

      final loadedItems =
          List<Map<String, dynamic>>.from(result['items'] as List);

      for (final item in loadedItems) {
        final id = (item['id'] as num).toInt();
        quantities[id] = TextEditingController();
        conditions[id] = 'Good';
      }

      setState(() {
        sale = Map<String, dynamic>.from(result['sale'] as Map);
        items = loadedItems;
      });
    } catch (e) {
      message('Invoice search error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Map<String, dynamic> draftData() {
    return {
      'reason': reasonController.text,
      'refund_method': refundMethod,
      'quantities': quantities.map(
        (id, controller) => MapEntry(id.toString(), controller.text),
      ),
      'conditions': conditions.map(
        (id, value) => MapEntry(id.toString(), value),
      ),
    };
  }

  Future<void> saveDraft() async {
    try {
      final result = await db.saveSaleReturnDraft(
        draftId: draftId,
        invoiceNumber: invoiceController.text,
        formData: draftData(),
      );
      draftId = (result['id'] as num).toInt();
      if (mounted) setState(() {});
      message('Draft saved successfully: ${result['draft_number']}');
    } catch (e) {
      message('Draft could not be saved: $e');
    }
  }

  Future<void> openDrafts() async {
    try {
      final drafts = await db.getSaleReturnDrafts();
      if (!mounted) return;

      if (drafts.isEmpty) {
        message('No saved drafts found.');
        return;
      }

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Saved Return Drafts',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
              ),
              ...drafts.map((d) => ListTile(
                leading: const Icon(Icons.drafts_outlined),
                title: Text('${d['draft_number']}'),
                subtitle: Text(
                  'Invoice: ${d['invoice_number'] ?? 'Not entered'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    await db.deleteSaleReturnDraft(
                      (d['id'] as num).toInt(),
                    );
                    if (context.mounted) Navigator.pop(context);
                    if (mounted) openDrafts();
                  },
                ),
                onTap: () => Navigator.pop(context, d),
              )),
            ],
          ),
        ),
      );

      if (selected == null || !mounted) return;
      await loadDraft((selected['id'] as num).toInt());
    } catch (e) {
      message('Draft list error: $e');
    }
  }

  Future<void> loadDraft(int id) async {
    try {
      final draft = await db.getSaleReturnDraft(id);
      if (draft == null) {
        message('Draft not found.');
        return;
      }

      final data = Map<String, dynamic>.from(draft['form_data'] as Map);
      draftId = id;
      invoiceController.text = (draft['invoice_number'] ?? '').toString();
      reasonController.text = (data['reason'] ?? '').toString();
      refundMethod = (data['refund_method'] ?? 'Cash').toString();

      final result = await db.getSaleForReturn(invoiceController.text);
      if (result != null) {
        for (final c in quantities.values) {
          c.dispose();
        }
        quantities.clear();
        conditions.clear();

        final loaded =
            List<Map<String, dynamic>>.from(result['items'] as List);
        final savedQuantities =
            Map<String, dynamic>.from(data['quantities'] ?? {});
        final savedConditions =
            Map<String, dynamic>.from(data['conditions'] ?? {});

        for (final item in loaded) {
          final itemId = (item['id'] as num).toInt();
          quantities[itemId] = TextEditingController(
            text: (savedQuantities[itemId.toString()] ?? '').toString(),
          );
          conditions[itemId] =
              (savedConditions[itemId.toString()] ?? 'Good').toString();
        }

        setState(() {
          sale = Map<String, dynamic>.from(result['sale'] as Map);
          items = loaded;
        });
      } else {
        setState(() {
          sale = null;
          items = [];
        });
      }
      if (mounted) setState(() {});
      message('Draft resumed successfully.');
    } catch (e) {
      message('Draft load error: $e');
    }
  }

  Future<void> submitRequest() async {
    if (sale == null) {
      message('Please search for the original invoice first.');
      return;
    }

    final selectedItems = <Map<String, dynamic>>[];
    for (final item in items) {
      final id = (item['id'] as num).toInt();
      final qty = double.tryParse(quantities[id]?.text.trim() ?? '') ?? 0;
      if (qty <= 0) continue;

      selectedItems.add({
        'sale_item_id': id,
        'return_quantity': qty,
        'item_condition': conditions[id] ?? 'Good',
      });
    }

    if (selectedItems.isEmpty) {
      message('Please enter a return quantity for at least one item.');
      return;
    }

    setState(() => loading = true);
    try {
      final result = await db.createSaleReturnRequest(
        invoiceNumber: invoiceController.text,
        items: selectedItems,
        refundMethod: refundMethod,
        reason: reasonController.text,
      );

      if (draftId != null) {
        await db.deleteSaleReturnDraft(draftId!);
      }

      if (!mounted) return;
      setState(() {
        draftId = null;
        sale = null;
        items = [];
        invoiceController.clear();
        reasonController.clear();
        quantities.clear();
        conditions.clear();
      });

      message(
        'Request Pending Approval: ${result['return_number']} | '
        'Refund: ${result['refund_id']}',
      );
    } catch (e) {
      message('Request could not be submitted: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7, top: 12),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF159AB0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Sales Return'),
        actions: [
          IconButton(
            tooltip: 'Saved Drafts',
            onPressed: openDrafts,
            icon: const Icon(Icons.drafts_outlined),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFEFF9FC),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Original Sale Invoice',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: invoiceController,
                          decoration: const InputDecoration(
                            labelText: 'Invoice Number',
                            hintText: 'OB-000001',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.receipt_long),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: loading ? null : searchInvoice,
                        style: FilledButton.styleFrom(backgroundColor: teal),
                        child: const Text('Search'),
                      ),
                    ],
                  ),
                  if (sale != null) ...[
                    const Divider(height: 24),
                    Text('Customer: ${sale!['customer_name'] ?? 'Walk-in'}'),
                    Text('Invoice: ${sale!['bill_number']}'),
                    Text('Sale Total: Rs. ${sale!['total']}'),
                    Text('Paid: Rs. ${sale!['paid']}'),
                    Text('Date: ${sale!['sale_date']}'),
                  ],
                ],
              ),
            ),
          ),
          if (sale != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Return Items',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    ...items.map((item) {
                      final id = (item['id'] as num).toInt();
                      final available =
                          (item['available_return_quantity'] as num).toDouble();

                      return Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4FBFD),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA8E4EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['product_name']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Sold: ${item['quantity']}  |  Already returned: '
                              '${item['previously_returned_quantity']}  |  '
                              'Available: $available',
                            ),
                            Text('Unit Price: Rs. ${item['price']}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: quantities[id],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: const InputDecoration(
                                      labelText: 'Return Quantity',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: conditions[id],
                                    decoration: const InputDecoration(
                                      labelText: 'Condition',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'Good',
                                        child: Text('Good'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Damaged',
                                        child: Text('Damaged'),
                                      ),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() => conditions[id] = v);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Refund Details',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    fieldLabel('Refund Method'),
                    DropdownButtonFormField<String>(
                      value: refundMethod,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: const ['Cash', 'Bank Transfer', 'Raast', 'JazzCash', 'EasyPaisa', 'Other']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => refundMethod = v);
                      },
                    ),
                    fieldLabel('Return Reason'),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Return ki wajah (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : saveDraft,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading || sale == null ? null : submitRequest,
                  icon: const Icon(Icons.send),
                  label: const Text('Submit Request'),
                  style: FilledButton.styleFrom(backgroundColor: teal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}
