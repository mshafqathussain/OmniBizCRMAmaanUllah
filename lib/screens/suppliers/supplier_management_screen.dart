import 'package:flutter/material.dart';
import '../../database/app_database.dart';

class SupplierManagementScreen extends StatefulWidget {
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

class _SupplierManagementScreenState
    extends State<SupplierManagementScreen> {
  final db = AppDatabase.instance;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> suppliers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSuppliers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadSuppliers() async {
    if (mounted) setState(() => loading = true);
    try {
      final result = await db.getSuppliers(query: searchController.text);
      if (!mounted) return;
      setState(() {
        suppliers = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage('Unable to load suppliers: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String val(Map<String, dynamic> data, String key) {
    final value = data[key];
    return value == null || value.toString().trim().isEmpty
        ? '—'
        : value.toString();
  }

  String money(dynamic value) {
    final amount = (value as num?)?.toDouble() ?? 0;
    return 'Rs ${amount.toStringAsFixed(2)}';
  }

  Widget field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: required
            ? (v) => v == null || v.trim().isEmpty
                ? 'Please enter $label'
                : null
            : null,
      ),
    );
  }

  Future<void> showSupplierForm({
    Map<String, dynamic>? supplier,
  }) async {
    final editing = supplier != null;
    final formKey = GlobalKey<FormState>();

    final c = <String, TextEditingController>{
      'name': TextEditingController(text: supplier?['name']?.toString() ?? ''),
      'company': TextEditingController(text: supplier?['company_name']?.toString() ?? ''),
      'mobile': TextEditingController(text: supplier?['mobile']?.toString() ?? ''),
      'whatsapp': TextEditingController(text: supplier?['whatsapp']?.toString() ?? ''),
      'email': TextEditingController(text: supplier?['email']?.toString() ?? ''),
      'cnic': TextEditingController(text: supplier?['cnic_ntn']?.toString() ?? ''),
      'contact': TextEditingController(text: supplier?['contact_person']?.toString() ?? ''),
      'category': TextEditingController(text: supplier?['supplier_category']?.toString() ?? ''),
      'address': TextEditingController(text: supplier?['address']?.toString() ?? ''),
      'city': TextEditingController(text: supplier?['city']?.toString() ?? ''),
      'country': TextEditingController(text: supplier?['country']?.toString() ?? 'Pakistan'),
      'balance': TextEditingController(text: supplier?['balance']?.toString() ?? '0'),
      'credit': TextEditingController(text: supplier?['credit_limit']?.toString() ?? '0'),
      'terms': TextEditingController(text: supplier?['payment_terms']?.toString() ?? ''),
      'bank': TextEditingController(text: supplier?['bank_name']?.toString() ?? ''),
      'account': TextEditingController(text: supplier?['bank_account']?.toString() ?? ''),
      'iban': TextEditingController(text: supplier?['bank_iban']?.toString() ?? ''),
      'notes': TextEditingController(text: supplier?['notes']?.toString() ?? ''),
    };

    String status = supplier?['status']?.toString() ?? 'Active';
    const statuses = ['Active', 'Inactive', 'On Hold'];

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) => AlertDialog(
            title: Text(editing ? 'Edit Supplier' : 'Add Supplier'),
            content: SizedBox(
              width: 520,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Basic Information',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      field(c['name']!, 'Supplier Name', required: true),
                      field(c['company']!, 'Company Name'),
                      field(c['category']!, 'Supplier Category'),
                      field(c['contact']!, 'Contact Person'),
                      field(c['mobile']!, 'Mobile Number',
                          keyboard: TextInputType.phone),
                      field(c['whatsapp']!, 'WhatsApp Number',
                          keyboard: TextInputType.phone),
                      field(c['email']!, 'Email Address',
                          keyboard: TextInputType.emailAddress),
                      field(c['cnic']!, 'CNIC / NTN'),
                      const SizedBox(height: 5),
                      const Text('Address Information',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      field(c['address']!, 'Address', lines: 2),
                      field(c['city']!, 'City'),
                      field(c['country']!, 'Country'),
                      const SizedBox(height: 5),
                      const Text('Financial Information',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      field(c['balance']!, 'Opening Balance',
                          keyboard: const TextInputType.numberWithOptions(decimal: true)),
                      field(c['credit']!, 'Credit Limit',
                          keyboard: const TextInputType.numberWithOptions(decimal: true)),
                      field(c['terms']!, 'Payment Terms'),
                      DropdownButtonFormField<String>(
                        value: statuses.contains(status) ? status : 'Active',
                        decoration: const InputDecoration(
                          labelText: 'Supplier Status',
                          border: OutlineInputBorder(),
                        ),
                        items: statuses
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => status = v);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Bank Information',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      field(c['bank']!, 'Bank Name'),
                      field(c['account']!, 'Bank Account Number'),
                      field(c['iban']!, 'IBAN'),
                      const SizedBox(height: 5),
                      const Text('Additional Information',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      field(c['notes']!, 'Notes', lines: 3),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.save),
                label: Text(editing ? 'Update Supplier' : 'Save Supplier'),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final balance =
                      double.tryParse(c['balance']!.text.trim()) ?? double.nan;
                  final credit =
                      double.tryParse(c['credit']!.text.trim()) ?? double.nan;

                  if (!balance.isFinite ||
                      balance < 0 ||
                      !credit.isFinite ||
                      credit < 0) {
                    showMessage('Enter valid Opening Balance and Credit Limit.');
                    return;
                  }

                  try {
                    final args = {
                      'name': c['name']!.text,
                      'mobile': c['mobile']!.text,
                      'address': c['address']!.text,
                      'balance': balance,
                      'companyName': c['company']!.text,
                      'whatsapp': c['whatsapp']!.text,
                      'email': c['email']!.text,
                      'cnicNtn': c['cnic']!.text,
                      'city': c['city']!.text,
                      'country': c['country']!.text,
                      'contactPerson': c['contact']!.text,
                      'supplierCategory': c['category']!.text,
                      'creditLimit': credit,
                      'paymentTerms': c['terms']!.text,
                      'bankName': c['bank']!.text,
                      'bankAccount': c['account']!.text,
                      'bankIban': c['iban']!.text,
                      'status': status,
                      'notes': c['notes']!.text,
                    };

                    if (editing) {
                      await db.updateSupplier(
                        id: supplier['id'] as int,
                        name: args['name'] as String,
                        mobile: args['mobile'] as String,
                        address: args['address'] as String,
                        balance: balance,
                        companyName: args['companyName'] as String,
                        whatsapp: args['whatsapp'] as String,
                        email: args['email'] as String,
                        cnicNtn: args['cnicNtn'] as String,
                        city: args['city'] as String,
                        country: args['country'] as String,
                        contactPerson: args['contactPerson'] as String,
                        supplierCategory: args['supplierCategory'] as String,
                        creditLimit: credit,
                        paymentTerms: args['paymentTerms'] as String,
                        bankName: args['bankName'] as String,
                        bankAccount: args['bankAccount'] as String,
                        bankIban: args['bankIban'] as String,
                        status: status,
                        notes: args['notes'] as String,
                      );
                    } else {
                      await db.addSupplier(
                        name: args['name'] as String,
                        mobile: args['mobile'] as String,
                        address: args['address'] as String,
                        balance: balance,
                        companyName: args['companyName'] as String,
                        whatsapp: args['whatsapp'] as String,
                        email: args['email'] as String,
                        cnicNtn: args['cnicNtn'] as String,
                        city: args['city'] as String,
                        country: args['country'] as String,
                        contactPerson: args['contactPerson'] as String,
                        supplierCategory: args['supplierCategory'] as String,
                        creditLimit: credit,
                        paymentTerms: args['paymentTerms'] as String,
                        bankName: args['bankName'] as String,
                        bankAccount: args['bankAccount'] as String,
                        bankIban: args['bankIban'] as String,
                        status: status,
                        notes: args['notes'] as String,
                      );
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                    await loadSuppliers();
                    showMessage(editing
                        ? 'Supplier updated successfully.'
                        : 'Supplier added successfully.');
                  } catch (e) {
                    showMessage('Unable to save supplier: $e');
                  }
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      for (final controller in c.values) {
        controller.dispose();
      }
    }
  }

  void showSupplierDetails(Map<String, dynamic> s) {
    final details = <List<String>>[
      ['Supplier Name', val(s, 'name')],
      ['Company', val(s, 'company_name')],
      ['Category', val(s, 'supplier_category')],
      ['Contact Person', val(s, 'contact_person')],
      ['Mobile', val(s, 'mobile')],
      ['WhatsApp', val(s, 'whatsapp')],
      ['Email', val(s, 'email')],
      ['CNIC / NTN', val(s, 'cnic_ntn')],
      ['Address', val(s, 'address')],
      ['City', val(s, 'city')],
      ['Country', val(s, 'country')],
      ['Opening Balance', money(s['balance'])],
      ['Credit Limit', money(s['credit_limit'])],
      ['Payment Terms', val(s, 'payment_terms')],
      ['Bank Name', val(s, 'bank_name')],
      ['Bank Account', val(s, 'bank_account')],
      ['IBAN', val(s, 'bank_iban')],
      ['Status', val(s, 'status')],
      ['Notes', val(s, 'notes')],
    ];

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supplier Details'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: details.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(item[0],
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(flex: 6, child: Text(item[1])),
                  ],
                ),
              )).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteSupplier(Map<String, dynamic> s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier?'),
        content: Text('Are you sure you want to delete ${s['name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await db.deleteSupplier(s['id'] as int);
      await loadSuppliers();
      showMessage('Supplier deleted.');
    } catch (e) {
      showMessage('Unable to delete supplier: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Management'),
        actions: [
          IconButton(
            onPressed: loadSuppliers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSupplierForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Supplier'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: TextField(
              controller: searchController,
              onChanged: (_) => loadSuppliers(),
              decoration: InputDecoration(
                hintText: 'Search supplier, company, mobile or WhatsApp',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    searchController.clear();
                    loadSuppliers();
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text('Suppliers (${suppliers.length})',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Text('Opening balances',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : suppliers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 58, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(searchController.text.isEmpty
                                ? 'No suppliers added yet'
                                : 'No matching suppliers found'),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => showSupplierForm(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Supplier'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadSuppliers,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
                          itemCount: suppliers.length,
                          itemBuilder: (context, index) {
                            final s = suppliers[index];
                            final name = val(s, 'name');
                            final status = val(s, 'status');

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                leading: CircleAvatar(
                                  child: Text(name.substring(0, 1).toUpperCase()),
                                ),
                                title: Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (val(s, 'company_name') != '—')
                                      Text(val(s, 'company_name')),
                                    Text(val(s, 'mobile')),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text('Opening: ${money(s['balance'])}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Chip(
                                          label: Text(status,
                                              style: const TextStyle(
                                                  fontSize: 11)),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                onTap: () => showSupplierDetails(s),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == 'details') {
                                      showSupplierDetails(s);
                                    } else if (action == 'edit') {
                                      showSupplierForm(supplier: s);
                                    } else if (action == 'delete') {
                                      deleteSupplier(s);
                                    }
                                  },
                                  itemBuilder: (ctx) => const [
                                    PopupMenuItem(
                                      value: 'details',
                                      child: Text('View Details'),
                                    ),
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit Supplier'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete Supplier'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
