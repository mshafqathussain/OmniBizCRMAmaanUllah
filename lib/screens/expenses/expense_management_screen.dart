import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../database/app_database.dart';

class ExpenseManagementScreen extends StatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  State<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState extends State<ExpenseManagementScreen> {
  final _formKey = GlobalKey<FormState>();

  final amountController = TextEditingController();
  final paidController = TextEditingController();
  final vendorController = TextEditingController();
  final descriptionController = TextEditingController();

  DateTime expenseDate = DateTime.now();
  String mainCategory = 'Office Expenses';
  String typeCategory = 'Utilities';
  String expenseType = 'Electricity Bill';
  String paymentMethod = 'Cash';
  String paymentStatus = 'Paid';
  String frequency = 'One Time';
  String selectedSection = 'New Expense';

  final List<String> mainCategories = [
    'Office Expenses',
    'Shop Expenses',
    'Employee Expenses',
    'Transport',
    'Marketing',
    'Other Expenses',
  ];

  final Map<String, List<String>> typeCategories = {
    'Office Expenses': ['Utilities', 'Office Supplies', 'Rent'],
    'Shop Expenses': ['Shop Utilities', 'Maintenance', 'Packaging'],
    'Employee Expenses': ['Salary', 'Food', 'Other'],
    'Transport': ['Fuel', 'Vehicle Repair', 'Travel'],
    'Marketing': ['Advertisement', 'Printing', 'Promotion'],
    'Other Expenses': ['General', 'Miscellaneous'],
  };

  final Map<String, List<String>> expenseTypes = {
    'Utilities': [
      'Electricity Bill',
      'Water Bill',
      'Gas Bill',
      'Internet Bill'
    ],
    'Office Supplies': ['Stationery', 'Printer Items', 'Computer Items'],
    'Rent': ['Shop Rent', 'Office Rent', 'Warehouse Rent'],
    'Shop Utilities': ['Electricity Bill', 'Water Bill', 'Gas Bill'],
    'Maintenance': ['Repair', 'Equipment Maintenance'],
    'Packaging': ['Shopping Bags', 'Cartons', 'Packing Material'],
    'Salary': ['Monthly Salary', 'Overtime', 'Bonus'],
    'Food': ['Staff Food', 'Refreshments'],
    'Other': ['Staff Expense', 'Other Employee Expense'],
    'Fuel': ['Petrol', 'Diesel', 'CNG'],
    'Vehicle Repair': ['Oil Change', 'Vehicle Repair'],
    'Travel': ['Local Travel', 'Outstation Travel'],
    'Advertisement': ['Online Ads', 'Print Ads'],
    'Printing': ['Banner', 'Business Cards'],
    'Promotion': ['Promotional Material'],
    'General': ['General Expense'],
    'Miscellaneous': ['Miscellaneous Expense'],
  };

  final List<Map<String, dynamic>> history = [];
  final historySearchController = TextEditingController();
  int? editingExpenseId;
  bool isLoadingHistory = false;

  double get amount => double.tryParse(amountController.text) ?? 0;
  double get paid => double.tryParse(paidController.text) ?? 0;
  double get remaining => (amount - paid).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    loadExpenseHistory();
  }

  Future<void> loadExpenseHistory({String query = ''}) async {
    if (mounted) setState(() => isLoadingHistory = true);
    try {
      final records = await AppDatabase.instance.getExpenses(query: query);
      if (!mounted) return;
      setState(() {
        history
          ..clear()
          ..addAll(records);
        isLoadingHistory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingHistory = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Expense history load failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    paidController.dispose();
    vendorController.dispose();
    descriptionController.dispose();
    historySearchController.dispose();
    super.dispose();
  }

  Future<void> chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => expenseDate = picked);
  }

  Future<void> addOption(String title, List<String> options,
      ValueChanged<String> onSelected) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter $title name',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        options.add(result);
        onSelected(result);
      });
    }
    controller.dispose();
  }

  Widget sectionButton(String title, IconData icon) {
    final selected = selectedSection == title;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedSection = title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF173F73) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? const Color(0xFF173F73) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : const Color(0xFF173F73)),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget fieldLabel(String label, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (required) const Text(' *', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget textField(
    String label,
    TextEditingController controller, {
    String? hint,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    bool required = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label, required: required),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: required
              ? (value) => value == null || value.trim().isEmpty
                  ? 'Required field'
                  : null
              : null,
          decoration: InputDecoration(
            hintText: hint ?? 'Enter $label',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          ),
        ),
      ],
    );
  }

  Widget dropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    VoidCallback? onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel(label, required: true),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: items.contains(value) ? value : items.first,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                items: items
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
            if (onAdd != null) ...[
              const SizedBox(width: 7),
              IconButton.filledTonal(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                tooltip: 'Add $label',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget formCard({required String title, required Widget child}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF173F73))),
            const SizedBox(height: 15),
            child,
          ],
        ),
      ),
    );
  }

  void resetForm() {
    _formKey.currentState?.reset();
    amountController.clear();
    paidController.clear();
    vendorController.clear();
    descriptionController.clear();
    setState(() {
      expenseDate = DateTime.now();
      mainCategory = mainCategories.first;
      typeCategory = typeCategories[mainCategory]!.first;
      expenseType = expenseTypes[typeCategory]!.first;
      paymentMethod = 'Cash';
      paymentStatus = 'Paid';
      frequency = 'One Time';
      editingExpenseId = null;
    });
  }

  Future<void> saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    if (paymentStatus == 'Partial' && (paid <= 0 || paid > amount)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid paid amount.')),
      );
      return;
    }

    final paidAmount = paymentStatus == 'Paid'
        ? amount
        : paymentStatus == 'Unpaid'
            ? 0.0
            : paid;

    final dateValue = DateFormat('yyyy-MM-dd').format(expenseDate);

    try {
      if (editingExpenseId == null) {
        await AppDatabase.instance.saveExpense(
          category: '$mainCategory / $typeCategory',
          title: expenseType,
          amount: amount,
          expenseDate: dateValue,
          description: descriptionController.text,
          paymentMethod: paymentMethod,
          paidTo: vendorController.text,
          mainCategory: mainCategory,
          expenseTypeCategory: typeCategory,
          expenseType: expenseType,
          paymentStatus: paymentStatus,
          paidAmount: paidAmount,
          frequency: frequency,
        );
      } else {
        await AppDatabase.instance.updateExpense(
          id: editingExpenseId!,
          category: '$mainCategory / $typeCategory',
          title: expenseType,
          amount: amount,
          expenseDate: dateValue,
          description: descriptionController.text,
          paymentMethod: paymentMethod,
          paidTo: vendorController.text,
          mainCategory: mainCategory,
          expenseTypeCategory: typeCategory,
          expenseType: expenseType,
          paymentStatus: paymentStatus,
          paidAmount: paidAmount,
          frequency: frequency,
        );
      }

      await loadExpenseHistory();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editingExpenseId == null
                ? 'Expense saved successfully.'
                : 'Expense updated successfully.',
          ),
        ),
      );
      resetForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save expense: $e')),
      );
    }
  }

  void editExpense(Map<String, dynamic> record) {
    final id = record['id'] as int?;
    if (id == null) return;

    final main = (record['main_category'] ?? 'Other Expenses').toString();
    final typeCat = (record['expense_type_category'] ?? 'General').toString();
    final type = (record['expense_type'] ?? record['title'] ?? 'Other Expense')
        .toString();

    setState(() {
      if (!mainCategories.contains(main)) {
        mainCategories.add(main);
        typeCategories[main] = [typeCat];
      }
      if (!(typeCategories[main] ?? []).contains(typeCat)) {
        typeCategories.putIfAbsent(main, () => []).add(typeCat);
      }
      if (!(expenseTypes[typeCat] ?? []).contains(type)) {
        expenseTypes.putIfAbsent(typeCat, () => []).add(type);
      }

      editingExpenseId = id;
      mainCategory = main;
      typeCategory = typeCat;
      expenseType = type;
      amountController.text = (record['amount'] ?? 0).toString();
      paidController.text = (record['paid_amount'] ?? 0).toString();
      vendorController.text = (record['paid_to'] ?? '').toString();
      descriptionController.text = (record['description'] ?? '').toString();
      paymentMethod = (record['payment_method'] ?? 'Cash').toString();
      paymentStatus = (record['payment_status'] ?? 'Unpaid').toString();
      frequency = (record['frequency'] ?? 'One Time').toString();

      final parsedDate = DateTime.tryParse(
        (record['expense_date'] ?? '').toString(),
      );
      expenseDate = parsedDate ?? DateTime.now();
      selectedSection = 'New Expense';
    });
  }

  @override
  Widget build(BuildContext context) {
    final typeCategoryOptions = typeCategories[mainCategory] ?? ['General'];
    final expenseTypeOptions = expenseTypes[typeCategory] ?? ['Other Expense'];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF173F73),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OmniBizCRM', style: TextStyle(fontSize: 17)),
            Text('Expense Management',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              sectionButton('New Expense', Icons.add_circle_outline),
              const SizedBox(width: 7),
              sectionButton('Expense Reports', Icons.bar_chart),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              sectionButton('Expense History', Icons.history),
              const SizedBox(width: 7),
              sectionButton('Manage Categories', Icons.category_outlined),
            ],
          ),
          const SizedBox(height: 15),
          if (selectedSection == 'New Expense') ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  formCard(
                    title: 'Add New Expense',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldLabel('Expense Date', required: true),
                        InkWell(
                          onTap: chooseDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              suffixIcon: const Icon(Icons.calendar_month),
                            ),
                            child: Text(
                                DateFormat('dd MMMM yyyy').format(expenseDate)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        dropdownField(
                          label: 'Main Expense Category',
                          value: mainCategory,
                          items: mainCategories,
                          onChanged: (v) {
                            setState(() {
                              mainCategory = v!;
                              typeCategory = typeCategories[v]!.first;
                              expenseType = expenseTypes[typeCategory]!.first;
                            });
                          },
                          onAdd: () => addOption(
                            'Main Category',
                            mainCategories,
                            (v) {
                              typeCategories[v] = ['General'];
                              expenseTypes['General'] = ['Other Expense'];
                              mainCategory = v;
                              typeCategory = 'General';
                              expenseType = 'Other Expense';
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                        dropdownField(
                          label: 'Expense Type Category',
                          value: typeCategory,
                          items: typeCategoryOptions,
                          onChanged: (v) {
                            setState(() {
                              typeCategory = v!;
                              expenseType =
                                  (expenseTypes[v] ?? ['Other Expense']).first;
                            });
                          },
                          onAdd: () => addOption(
                            'Type Category',
                            typeCategoryOptions,
                            (v) {
                              expenseTypes[v] = ['Other Expense'];
                              typeCategory = v;
                              expenseType = 'Other Expense';
                            },
                          ),
                        ),
                        const SizedBox(height: 15),
                        dropdownField(
                          label: 'Expense Type',
                          value: expenseType,
                          items: expenseTypeOptions,
                          onChanged: (v) => setState(() => expenseType = v!),
                          onAdd: () => addOption(
                            'Expense Type',
                            expenseTypeOptions,
                            (v) => expenseType = v,
                          ),
                        ),
                      ],
                    ),
                  ),
                  formCard(
                    title: 'Expense Details',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        textField(
                          'Amount (Rs.)',
                          amountController,
                          hint: 'Enter total expense amount',
                          keyboard: const TextInputType.numberWithOptions(
                              decimal: true),
                          required: true,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 15),
                        dropdownField(
                          label: 'Payment Method',
                          value: paymentMethod,
                          items: const ['Cash', 'Bank', 'Online'],
                          onChanged: (v) => setState(() => paymentMethod = v!),
                        ),
                        const SizedBox(height: 15),
                        dropdownField(
                          label: 'Payment Status',
                          value: paymentStatus,
                          items: const ['Paid', 'Unpaid', 'Partial'],
                          onChanged: (v) {
                            setState(() {
                              paymentStatus = v!;
                              if (v != 'Partial') paidController.clear();
                            });
                          },
                        ),
                        if (paymentStatus == 'Partial') ...[
                          const SizedBox(height: 15),
                          textField(
                            'Amount Paid (Rs.)',
                            paidController,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true),
                            required: true,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'Remaining Amount: Rs. ${remaining.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                        const SizedBox(height: 15),
                        textField('Paid To / Vendor', vendorController),
                        const SizedBox(height: 15),
                        dropdownField(
                          label: 'Expense Frequency',
                          value: frequency,
                          items: const [
                            'One Time',
                            'Daily',
                            'Weekly',
                            'Monthly',
                            'Yearly'
                          ],
                          onChanged: (v) => setState(() => frequency = v!),
                        ),
                        const SizedBox(height: 15),
                        textField(
                          'Description / Notes',
                          descriptionController,
                          hint: 'Enter expense details...',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 15),
                        fieldLabel('Upload Receipt / Invoice'),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Receipt attachment will be connected in the next step.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: const Text('Choose Photo / PDF'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: resetForm,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: ElevatedButton.icon(
                          onPressed: saveExpense,
                          icon: const Icon(Icons.save),
                          label: Text(editingExpenseId == null
                              ? 'Save Expense'
                              : 'Update Expense'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF173F73),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 50),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  historySection(),
                ],
              ),
            ),
          ] else if (selectedSection == 'Expense History') ...[
            historySection(),
          ] else if (selectedSection == 'Expense Reports') ...[
            formCard(
              title: 'Expense Reports',
              child: const Column(
                children: [
                  ListTile(
                      leading: Icon(Icons.today),
                      title: Text('Daily Expense Report'),
                      trailing: Icon(Icons.chevron_right)),
                  Divider(height: 1),
                  ListTile(
                      leading: Icon(Icons.calendar_month),
                      title: Text('Monthly Expense Report'),
                      trailing: Icon(Icons.chevron_right)),
                  Divider(height: 1),
                  ListTile(
                      leading: Icon(Icons.date_range),
                      title: Text('Yearly Expense Report'),
                      trailing: Icon(Icons.chevron_right)),
                  Divider(height: 1),
                  ListTile(
                      leading: Icon(Icons.category),
                      title: Text('Category Wise Report'),
                      trailing: Icon(Icons.chevron_right)),
                  Divider(height: 1),
                  ListTile(
                      leading: Icon(Icons.account_tree),
                      title: Text('Expense Type Wise Report'),
                      trailing: Icon(Icons.chevron_right)),
                  Divider(height: 1),
                  ListTile(
                      leading: Icon(Icons.store),
                      title: Text('Branch Wise Report'),
                      trailing: Icon(Icons.chevron_right)),
                  Divider(height: 1),
                  ListTile(
                      leading: Icon(Icons.payments),
                      title: Text('Paid / Unpaid / Partial Report'),
                      trailing: Icon(Icons.chevron_right)),
                  Divider(height: 1),
                  ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Vendor Wise Report'),
                      trailing: Icon(Icons.chevron_right)),
                  Divider(height: 1),
                  ListTile(
                      leading: Icon(Icons.account_balance),
                      title: Text('Cash & Bank Report'),
                      trailing: Icon(Icons.chevron_right)),
                ],
              ),
            ),
          ] else ...[
            formCard(
              title: 'Manage Categories',
              child: const Column(
                children: [
                  ListTile(
                      leading: Icon(Icons.category),
                      title: Text('Main Expense Categories'),
                      subtitle: Text('Search, add, edit and delete')),
                  Divider(height: 1),
                  ListTile(
                      leading: Icon(Icons.account_tree),
                      title: Text('Expense Type Categories'),
                      subtitle:
                          Text('Manage categories under main categories')),
                  Divider(height: 1),
                  ListTile(
                      leading: Icon(Icons.list_alt),
                      title: Text('Expense Types'),
                      subtitle: Text('Manage types under type categories')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget historySection() {
    return formCard(
      title: 'Expense History',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: historySearchController,
            onChanged: (value) => loadExpenseHistory(query: value),
            decoration: InputDecoration(
              hintText: 'Search expense history...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoadingHistory)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 25),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long, size: 42, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('No expense records found'),
                  ],
                ),
              ),
            )
          else
            ...history.map((record) {
              final date = DateTime.tryParse(
                (record['expense_date'] ?? '').toString(),
              );
              final dateText = date == null
                  ? (record['expense_date'] ?? '').toString()
                  : DateFormat('dd MMM yyyy').format(date);
              final categoryText =
                  '${record['main_category'] ?? record['category'] ?? ''}'
                  ' / ${record['expense_type_category'] ?? ''}';
              final title =
                  (record['expense_type'] ?? record['title'] ?? 'Expense')
                      .toString();
              final vendor = (record['paid_to'] ?? '').toString();
              final status = (record['payment_status'] ?? 'Unpaid').toString();
              final value = (record['amount'] as num?)?.toDouble() ?? 0;

              return Card(
                color: Colors.white,
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$dateText • $categoryText\n'
                    'Vendor: ${vendor.isEmpty ? '—' : vendor}',
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rs. ${value.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(status, style: const TextStyle(fontSize: 11)),
                      InkWell(
                        onTap: () => editExpense(record),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Color(0xFF173F73),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
