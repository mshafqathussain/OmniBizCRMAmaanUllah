import 'package:flutter/material.dart';

class ExpenseCategoryScreen extends StatefulWidget {
  const ExpenseCategoryScreen({super.key});

  @override
  State<ExpenseCategoryScreen> createState() =>
      _ExpenseCategoryScreenState();
}

class _ExpenseCategoryScreenState
    extends State<ExpenseCategoryScreen> {
  final TextEditingController searchController =
      TextEditingController();

  final List<String> categories = [
    'Shop Rent',
    'Electricity Bill',
    'Water Bill',
    'Gas Bill',
    'Internet & Mobile',
    'Employee Salary',
    'Transport',
    'Food & Refreshments',
    'Repair & Maintenance',
    'Office Supplies',
    'Marketing & Advertisement',
    'Packaging',
    'Taxes',
    'Other Expenses',
  ];

  final List<String> customCategories = [];

  String? selected;

  List<String> get allCategories =>
      [...categories, ...customCategories];

  List<String> get filteredCategories {
    final query = searchController.text.toLowerCase();
    return allCategories
        .where((item) => item.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void addCategory({String? oldName}) {
    final controller =
        TextEditingController(text: oldName ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          oldName == null ? 'Add New Category' : 'Edit Category',
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();

              if (name.isEmpty) return;

              setState(() {
                if (oldName != null) {
                  final index = customCategories.indexOf(oldName);
                  if (index != -1) {
                    customCategories[index] = name;
                  }
                  if (selected == oldName) selected = name;
                } else if (!allCategories.contains(name)) {
                  customCategories.add(name);
                }
              });

              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void deleteCategory(String name) {
    setState(() {
      customCategories.remove(name);
      if (selected == name) selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = filteredCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search category...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => addCategory(),
                icon: const Icon(Icons.add),
                label: const Text('Add New Category'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: Text('No categories found'),
                    )
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final name = visible[index];
                        final isCustom =
                            customCategories.contains(name);

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.receipt_long),
                            ),
                            title: Text(name),
                            selected: selected == name,
                            onTap: () {
                              setState(() => selected = name);
                            },
                            trailing: isCustom
                                ? PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        addCategory(oldName: name);
                                      } else if (value == 'delete') {
                                        deleteCategory(name);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  )
                                : const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
            ),
            if (selected != null) ...[
              const SizedBox(height: 15),
              Text(
                'Selected: $selected',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.pop(context, selected),
                child: const Text('Confirm Category'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
