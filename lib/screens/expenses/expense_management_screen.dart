import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
  String? attachmentPath;

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

  Future<void> deleteOption({
    required String label,
    required List<String> options,
    required String selected,
    required VoidCallback onDelete,
  }) async {
    if (options.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one option must remain.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete $label?'),
        content: Text('Delete "$selected"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(onDelete);
    }
  }

  Widget sectionButton(String title, IconData icon) {
    final selected = selectedSection == title;
    return InkWell(
      onTap: () => setState(() => selectedSection = title),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF173F73) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF173F73) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 21,
                color: selected ? Colors.white : const Color(0xFF173F73)),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                )),
          ],
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
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
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
    VoidCallback? onDelete,
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
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  minimumSize: const Size(0, 34),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
            if (onDelete != null) ...[
              IconButton(
                tooltip: 'Delete selected option',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                    size: 19, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 34,
                ),
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
      margin: const EdgeInsets.only(bottom: 9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF173F73),
                )),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> pickExpenseAttachment() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose Photo'),
            onTap: () => Navigator.pop(context, 'photo'),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Choose PDF'),
            onTap: () => Navigator.pop(context, 'pdf'),
          ),
        ]),
      ),
    );

    if (choice == null || !mounted) return;

    try {
      String? path;
      if (choice == 'photo') {
        final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 90,
        );
        path = image?.path;
      } else {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        path = result?.files.single.path;
      }

      if (path != null && mounted) {
        setState(() => attachmentPath = path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attachment select nahi hui: $e')),
      );
    }
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
      attachmentPath = null;
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
          attachmentPath: attachmentPath,
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
          attachmentPath: attachmentPath,
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
      attachmentPath = record['attachment_path']?.toString();
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
        toolbarHeight: 55,
        backgroundColor: const Color(0xFF173F73),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OmniBizCRM', style: TextStyle(fontSize: 15)),
            Text('Expense Management',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 24) / 4;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                      width: tileWidth,
                      child: sectionButton(
                          'New Expense', Icons.add_circle_outline)),
                  SizedBox(
                      width: tileWidth,
                      child: sectionButton('Expense Reports', Icons.bar_chart)),
                  SizedBox(
                      width: tileWidth,
                      child: sectionButton('Expense History', Icons.history)),
                  SizedBox(
                      width: tileWidth,
                      child: sectionButton(
                          'Manage Categories', Icons.category_outlined)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (selectedSection == 'New Expense') ...[
            Form(
              key: _formKey,
              child: Column(
                children: [
                  formCard(
                    title: 'New Expense',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          onAdd: () =>
                              addOption('Main Category', mainCategories, (v) {
                            typeCategories[v] = ['General'];
                            expenseTypes['General'] = ['Other Expense'];
                            mainCategory = v;
                            typeCategory = 'General';
                            expenseType = 'Other Expense';
                          }),
                          onDelete: () => deleteOption(
                            label: 'Main Category',
                            options: mainCategories,
                            selected: mainCategory,
                            onDelete: () {
                              mainCategories.remove(mainCategory);
                              typeCategories.remove(mainCategory);
                              mainCategory = mainCategories.first;
                              typeCategory =
                                  (typeCategories[mainCategory] ?? ['General'])
                                      .first;
                              expenseType = (expenseTypes[typeCategory] ??
                                      ['Other Expense'])
                                  .first;
                            },
                          ),
                        ),
                        const SizedBox(height: 9),
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
                              'Type Category', typeCategoryOptions, (v) {
                            expenseTypes[v] = ['Other Expense'];
                            typeCategory = v;
                            expenseType = 'Other Expense';
                          }),
                          onDelete: () => deleteOption(
                            label: 'Type Category',
                            options: typeCategoryOptions,
                            selected: typeCategory,
                            onDelete: () {
                              typeCategoryOptions.remove(typeCategory);
                              expenseTypes.remove(typeCategory);
                              typeCategory = typeCategoryOptions.first;
                              expenseType = (expenseTypes[typeCategory] ??
                                      ['Other Expense'])
                                  .first;
                            },
                          ),
                        ),
                        const SizedBox(height: 9),
                        dropdownField(
                          label: 'Expense Type',
                          value: expenseType,
                          items: expenseTypeOptions,
                          onChanged: (v) => setState(() => expenseType = v!),
                          onAdd: () => addOption(
                              'Expense Type', expenseTypeOptions, (v) {
                            expenseType = v;
                          }),
                          onDelete: () => deleteOption(
                            label: 'Expense Type',
                            options: expenseTypeOptions,
                            selected: expenseType,
                            onDelete: () {
                              expenseTypeOptions.remove(expenseType);
                              expenseType = expenseTypeOptions.first;
                            },
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
                        const SizedBox(height: 9),
                        fieldLabel('Expense Date', required: true),
                        InkWell(
                          onTap: chooseDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9)),
                              suffixIcon:
                                  const Icon(Icons.calendar_month, size: 20),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 10),
                            ),
                            child: Text(
                                DateFormat('dd MMM yyyy').format(expenseDate)),
                          ),
                        ),
                        const SizedBox(height: 9),
                        dropdownField(
                          label: 'Payment Method',
                          value: paymentMethod,
                          items: const ['Cash', 'Bank', 'Online'],
                          onChanged: (v) => setState(() => paymentMethod = v!),
                        ),
                        const SizedBox(height: 9),
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
                          const SizedBox(height: 9),
                          textField(
                            'Amount Paid (Rs.)',
                            paidController,
                            keyboard: const TextInputType.numberWithOptions(
                                decimal: true),
                            required: true,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Remaining Amount: Rs. ${remaining.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                        const SizedBox(height: 9),
                        textField('Paid To / Vendor', vendorController),
                        const SizedBox(height: 9),
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
                        const SizedBox(height: 9),
                        textField(
                          'Description / Notes',
                          descriptionController,
                          hint: 'Enter expense details...',
                          maxLines: 2,
                        ),
                        const SizedBox(height: 9),
                        fieldLabel('Upload Receipt / Invoice'),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: pickExpenseAttachment,
                            icon: const Icon(Icons.cloud_upload_outlined,
                                size: 18),
                            label: const Text('Choose Photo / PDF'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 40),
                            ),
                          ),
                        ),
                        if (attachmentPath != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF1F8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.attach_file,
                                    color: Color(0xFF173F73), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    attachmentPath!.split('/').last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove attachment',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () =>
                                      setState(() => attachmentPath = null),
                                  icon: const Icon(Icons.close,
                                      color: Colors.red, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
                    dense: true,
                    leading: Icon(Icons.today),
                    title: Text('Daily Expense Report'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.calendar_month),
                    title: Text('Monthly Expense Report'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.date_range),
                    title: Text('Yearly Expense Report'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.category),
                    title: Text('Category Wise Report'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.account_tree),
                    title: Text('Expense Type Wise Report'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.store),
                    title: Text('Branch Wise Report'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.payments),
                    title: Text('Paid / Unpaid / Partial Report'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.person),
                    title: Text('Vendor Wise Report'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.account_balance),
                    title: Text('Cash & Bank Report'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
          ] else ...[
            formCard(
              title: 'Manage Categories',
              child: const Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.category),
                    title: Text('Main Expense Categories'),
                    subtitle: Text('Search, add, edit and delete'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.account_tree),
                    title: Text('Expense Type Categories'),
                    subtitle: Text('Manage categories under main categories'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.list_alt),
                    title: Text('Expense Types'),
                    subtitle: Text('Manage types under type categories'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void viewExpense(Map<String, dynamic> record) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Expense Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: record.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text(
                    '${entry.key.replaceAll('_', ' ')}: ${entry.value ?? '—'}'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteExpenseRecord(Map<String, dynamic> record) async {
    final id = record['id'] as int?;
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This expense record will be deleted. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await AppDatabase.instance.deleteExpense(id);
      await loadExpenseHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete expense: $e')),
      );
    }
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'View',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 30,
                            ),
                            onPressed: () => viewExpense(record),
                            icon:
                                const Icon(Icons.visibility_outlined, size: 17),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 30,
                            ),
                            onPressed: () => editExpense(record),
                            icon: const Icon(Icons.edit,
                                size: 17, color: Color(0xFF218838)),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 30,
                            ),
                            onPressed: () => deleteExpenseRecord(record),
                            icon: const Icon(Icons.delete_outline,
                                size: 17, color: Colors.red),
                          ),
                        ],
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
