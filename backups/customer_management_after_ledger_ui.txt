import 'package:flutter/material.dart';
import '../../database/app_database.dart';
import 'customer_ledger_screen.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState
    extends State<CustomerManagementScreen> {
  final db = AppDatabase.instance;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> customers = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCustomers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadCustomers() async {
    setState(() => loading = true);
    try {
      final result = await db.getCustomers(query: searchController.text);
      if (!mounted) return;
      setState(() {
        customers = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      showMessage('Could not load customers: $e');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> showCustomerForm({Map<String, dynamic>? customer}) async {
    final editing = customer != null;
    final formKey = GlobalKey<FormState>();

    final name = TextEditingController(text: customer?['name']?.toString() ?? '');
    final mobile = TextEditingController(text: customer?['mobile']?.toString() ?? '');
    final whatsapp = TextEditingController(text: customer?['whatsapp']?.toString() ?? '');
    final cnic = TextEditingController(text: customer?['cnic']?.toString() ?? '');
    final email = TextEditingController(text: customer?['email']?.toString() ?? '');
    final business = TextEditingController(text: customer?['business_name']?.toString() ?? '');
    final address = TextEditingController(text: customer?['address']?.toString() ?? '');
    final contact = TextEditingController(text: customer?['additional_contact']?.toString() ?? '');
    final balance = TextEditingController(
      text: customer?['opening_balance']?.toString() ?? '0',
    );
    final notes = TextEditingController(text: customer?['notes']?.toString() ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(editing ? 'Edit Customer' : 'Add Customer'),
        content: SizedBox(
          width: 450,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(name, 'Customer Name', required: true),
                  _field(mobile, 'Mobile Number', keyboard: TextInputType.phone),
                  _field(whatsapp, 'WhatsApp Number', keyboard: TextInputType.phone),
                  _field(cnic, 'CNIC'),
                  _field(email, 'Email', keyboard: TextInputType.emailAddress),
                  _field(business, 'Business Name'),
                  _field(address, 'Address', lines: 2),
                  _field(contact, 'Additional Contact'),
                  _field(
                    balance,
                    'Opening Balance',
                    keyboard: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  _field(notes, 'Notes', lines: 3),
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
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final openingBalance = double.tryParse(balance.text.trim());
              if (openingBalance == null ||
                  !openingBalance.isFinite ||
                  openingBalance < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter a valid opening balance')),
                );
                return;
              }

              try {
                if (editing) {
                  await db.updateCustomer(
                    id: customer['id'] as int,
                    name: name.text,
                    mobile: mobile.text,
                    whatsapp: whatsapp.text,
                    cnic: cnic.text,
                    email: email.text,
                    businessName: business.text,
                    address: address.text,
                    additionalContact: contact.text,
                    openingBalance: openingBalance,
                    notes: notes.text,
                  );
                } else {
                  await db.addCustomer(
                    name: name.text,
                    mobile: mobile.text,
                    whatsapp: whatsapp.text,
                    cnic: cnic.text,
                    email: email.text,
                    businessName: business.text,
                    address: address.text,
                    additionalContact: contact.text,
                    openingBalance: openingBalance,
                    notes: notes.text,
                  );
                }

                if (!mounted) return;
                Navigator.pop(dialogContext);
                showMessage(editing
                    ? 'Customer updated successfully.'
                    : 'Customer added successfully.');
                await loadCustomers();
              } catch (e) {
                if (!mounted) return;
                showMessage('Could not save customer: $e');
              }
            },
            child: Text(editing ? 'Update' : 'Save Customer'),
          ),
        ],
      ),
    );

    name.dispose();
    mobile.dispose();
    whatsapp.dispose();
    cnic.dispose();
    email.dispose();
    business.dispose();
    address.dispose();
    contact.dispose();
    balance.dispose();
    notes.dispose();
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType? keyboard,
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
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                ? 'This field is required'
                : null
            : null,
      ),
    );
  }

  Future<void> showDetails(Map<String, dynamic> customer) async {
    final fields = <String, String>{
      'Customer Name': '${customer['name'] ?? '-'}',
      'Mobile Number': '${customer['mobile'] ?? '-'}',
      'WhatsApp Number': '${customer['whatsapp'] ?? '-'}',
      'CNIC': '${customer['cnic'] ?? '-'}',
      'Email': '${customer['email'] ?? '-'}',
      'Business Name': '${customer['business_name'] ?? '-'}',
      'Address': '${customer['address'] ?? '-'}',
      'Additional Contact': '${customer['additional_contact'] ?? '-'}',
      'Opening Balance': 'Rs. ${customer['opening_balance'] ?? 0}',
      'Notes': '${customer['notes'] ?? '-'}',
    };

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: fields.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('${entry.key}: ${entry.value}'),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteCustomer(Map<String, dynamic> customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: Text(
          'Are you sure you want to delete ${customer['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await db.deleteCustomer(customer['id'] as int);
      showMessage('Customer deleted successfully.');
      await loadCustomers();
    } catch (e) {
      showMessage('Customer could not be deleted: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        actions: [
          IconButton(
            onPressed: loadCustomers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCustomerForm(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: (_) => loadCustomers(),
              decoration: InputDecoration(
                hintText: 'Search by name, mobile, WhatsApp or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    searchController.clear();
                    loadCustomers();
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                const Text(
                  'Customer List',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('Total: ${customers.length}'),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : customers.isEmpty
                    ? const Center(
                        child: Text('No customers found. Add your first customer.'),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final customer = customers[index];
                          final name = customer['name']?.toString() ?? 'Customer';
                          final mobile = customer['mobile']?.toString() ?? '';
                          final balance =
                              (customer['opening_balance'] as num?)?.toDouble() ?? 0;

                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'C',
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${mobile.isEmpty ? 'No mobile number' : mobile}\n'
                                'Opening Balance: Rs. ${balance.toStringAsFixed(2)}',
                              ),
                              isThreeLine: true,
                              onTap: () => showDetails(customer),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    showCustomerForm(customer: customer);
                                  } else if (value == 'delete') {
                                    deleteCustomer(customer);
                                  } else if (value == 'details') {
                                    showDetails(customer);
                                  } else if (value == 'ledger') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CustomerLedgerScreen(
                                          customer: customer,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'ledger',
                                    child: Text('Customer Ledger'),
                                  ),
                                  PopupMenuItem(
                                    value: 'details',
                                    child: Text('View Details'),
                                  ),
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit Customer'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete Customer'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
