import 'package:file_saver/file_saver.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../database/app_database.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final db = AppDatabase.instance;
  late DateTime _pakistanNow;
  Timer? _clockTimer;
  final _customerSearch = TextEditingController();
  final _productSearch = TextEditingController();
  final _barcodeController = TextEditingController();
  final _barcodeFocus = FocusNode();
  bool _barcodeProcessing = false;
  final _discount = TextEditingController(text: '0');
  final _tax = TextEditingController(text: '0');
  final _paid = TextEditingController(text: '0');
  final _reference = TextEditingController();
  final _notes = TextEditingController();

  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> products = [];
  List<String> savedCategories = [];
  List<Map<String, dynamic>> measurementUnits = [];
  String selectedCategory = "All";
  final List<Map<String, dynamic>> cart = [];

  Map<String, dynamic>? selectedCustomer;
  String paymentMethod = 'Cash';
  String paymentType = 'Cash';
  bool loading = false;
  bool saving = false;
  Map<String, dynamic>? lastGeneratedSaleDetails;

  double get subtotal => cart.fold(
    0.0,
    (sum, item) => sum +
        (item['quantity'] as double) * (item['price'] as double),
  );

  double get discount =>
      double.tryParse(_discount.text.trim()) ?? 0;

  double get tax => double.tryParse(_tax.text.trim()) ?? 0;

  double get total => subtotal - discount + tax;

  double get paid {
    if (paymentType == 'Cash') return total;
    if (paymentType == 'Udhaar') return 0;
    return double.tryParse(_paid.text.trim()) ?? 0;
  }

  void _selectPaymentType(String value) {
    setState(() {
      paymentType = value;
      if (value == 'Cash') _paid.text = total.toStringAsFixed(2);
      if (value == 'Udhaar') _paid.text = '0';
      if (value == 'Partial') _paid.text = '0';
    });
  }

  double get remaining => total - paid;

  @override
  void initState() {
    super.initState();
    _pakistanNow = DateTime.now().toUtc().add(const Duration(hours: 5));
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _pakistanNow = DateTime.now().toUtc().add(const Duration(hours: 5));
      });
    });
    _loadCustomers('');
    _loadSaleData();
  }

  Future<void> _loadSaleData() async {
    final categoryRows = await db.getCategories();
    final productRows = await db.searchProducts('');
    final unitRows = await db.getMeasurementUnits();
    if (mounted == false) return;
    setState(() {
      savedCategories = categoryRows.map((e) => e['name'].toString()).toList();
      products = productRows;
      measurementUnits = unitRows;
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _customerSearch.dispose();
    _productSearch.dispose();
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    _discount.dispose();
    _tax.dispose();
    _paid.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers(String query) async {
    final result = await db.searchCustomers(query);
    if (!mounted) return;
    setState(() => customers = result);
  }

  List<String> get saleCategories {
    final values = <String>{
      ...savedCategories,
      ...products.map((p) => (p['category'] ?? '').toString().trim()).where((v) => v.isNotEmpty),
    }.toList()..sort();
    return ['All', ...values];
  }

  List<Map<String, dynamic>> get filteredSaleProducts {
    final q = _productSearch.text.trim().toLowerCase();
    return products.where((p) {
      final category = (p['category'] ?? '').toString().trim();
      final matchesCategory = selectedCategory == 'All' || category == selectedCategory;
      final matchesSearch = q.isEmpty ||
          (p['name'] ?? '').toString().toLowerCase().contains(q) ||
          (p['sku'] ?? '').toString().toLowerCase().contains(q) ||
          category.toLowerCase().contains(q);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _searchProducts(String query) {
    setState(() {});
  }

  Future<void> _handleBarcode(String value) async {
    final code = value.trim();
    if (code.isEmpty || _barcodeProcessing) return;

    _barcodeProcessing = true;
    try {
      final product = await db.getProductByBarcode(code);
      if (!mounted) return;

      if (product == null) {
        _message('Barcode not found: $code');
      } else {
        _addProduct(product);
        _message('${product['name']} added to Sale Cart.');
      }
    } catch (e) {
      if (mounted) _message('Barcode scan error: $e');
    } finally {
      _barcodeController.clear();
      _barcodeProcessing = false;
      if (mounted) _barcodeFocus.requestFocus();
    }
  }

  void _addProduct(Map<String, dynamic> product) {
    final id = product['id'] as int;
    final stock = (product['quantity'] as num).toDouble();
    final index = cart.indexWhere((e) => e['productId'] == id);

    if (stock <= 0) {
      _message('Is product ka stock available nahi hai.');
      return;
    }

    setState(() {
      if (index >= 0) {
        final current = cart[index]['quantity'] as double;
        if (current + 1 > stock) {
          _message('Available stock: $stock');
          return;
        }
        cart[index]['quantity'] = current + 1;
      } else {
        cart.add({
          'productId': id,
          'productName': product['name'],
          'category': product['category'],
          'unit': product['unit'] ?? 'pcs',
          'quantity': 1.0,
          'price': (product['sale_price'] as num).toDouble(),
          'stock': stock,
        });
      }
      _productSearch.clear();
    });
  }

  void _changeQuantity(int index, double change) {
    final item = cart[index];
    final next = (item['quantity'] as double) + change;
    final stock = item['stock'] as double? ?? double.infinity;

    if (next <= 0) {
      setState(() => cart.removeAt(index));
    } else if (next > stock) {
      _message('Available stock: $stock');
    } else {
      setState(() => item['quantity'] = next);
    }
  }

  Future<void> _addManualItem() async {
    final name = TextEditingController();
    final price = TextEditingController();
    final quantity = TextEditingController(text: '1');
    final unit = TextEditingController(text: 'pcs');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Manual Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Sale Price'),
              ),
              TextField(
                controller: quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              TextField(
                controller: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add Item'),
          ),
        ],
      ),
    );

    if (result == true) {
      final p = double.tryParse(price.text);
      final q = double.tryParse(quantity.text);
      if (name.text.trim().isEmpty ||
          p == null || !p.isFinite || p < 0 ||
          q == null || !q.isFinite || q <= 0) {
        _message('Item name, valid price aur quantity enter karein.');
      } else {
        setState(() {
          cart.add({
            'productId': null,
            'productName': name.text.trim(),
            'category': null,
            'unit': unit.text.trim().isEmpty ? 'pcs' : unit.text.trim(),
            'quantity': q,
            'price': p,
          });
        });
      }
    }

    name.dispose();
    price.dispose();
    quantity.dispose();
    unit.dispose();
  }

  Future<void> _addCustomer() async {
    final name = TextEditingController();
    final mobile = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Customer Name *'),
            ),
            TextField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );

    if (result == true && name.text.trim().isNotEmpty) {
      try {
        final id = await db.addCustomer(
          name: name.text.trim(),
          mobile: mobile.text.trim(),
        );
        final found = await db.searchCustomers(name.text.trim());
        if (!mounted) return;
        setState(() {
          selectedCustomer = found.firstWhere(
            (c) => c['id'] == id,
            orElse: () => {'id': id, 'name': name.text.trim()},
          );
          _customerSearch.text = selectedCustomer!['name'] as String;
          customers = [];
        });
        _message('Customer add ho gaya.');
      } catch (e) {
        _message('Customer save nahi hua: $e');
      }
    }

    name.dispose();
    mobile.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  bool _isValidAmount(TextEditingController controller) {
    final value = double.tryParse(controller.text.trim());
    return value != null && value.isFinite && value >= 0;
  }

  Future<void> _saveSale() async {
    if (cart.isEmpty) {
      _message('Pehle cart mein product add karein.');
      return;
    }

    if (!_isValidAmount(_discount) ||
        !_isValidAmount(_tax) ||
        !_isValidAmount(_paid)) {
      _message('Discount, Tax aur Paid mein valid numeric amount enter karein.');
      return;
    }

    if (!subtotal.isFinite ||
        !discount.isFinite || discount < 0 ||
        !tax.isFinite || tax < 0 ||
        !paid.isFinite || paid < 0 ||
        !total.isFinite || total < 0 ||
        discount > subtotal || paid > total) {
      _message('Discount, tax ya paid amount check karein.');
      return;
    }

    if (remaining > 0.000001 && selectedCustomer == null) {
      _message('Udhaar ya partial payment ke liye customer select karein.');
      return;
    }

    setState(() => saving = true);
    try {
      final saleId = await db.saveSale(
        customerId: selectedCustomer?['id'] as int?,
        items: cart.map((item) => {
          'productId': item['productId'],
          'productName': item['productName'],
          'category': item['category'],
          'unit': item['unit'],
          'quantity': item['quantity'],
          'price': item['price'],
        }).toList(),
        discount: discount,
        tax: tax,
        paid: paid,
        paymentMethod: paymentMethod,
        referenceNumber: _reference.text.trim(),
        notes: _notes.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        lastGeneratedSaleDetails = null;
        paymentType = 'Cash';
        paymentMethod = 'Cash';
        cart.clear();
        selectedCustomer = null;
        _customerSearch.clear();
        _discount.text = '0';
        _tax.text = '0';
        _paid.text = '0';
        _reference.clear();
        _notes.clear();
      });

      try {
        final saleDetails = await db.getSaleDetails(saleId);
        if (!mounted) return;
        setState(() => lastGeneratedSaleDetails = saleDetails);
        final invoice = saleDetails?['sale']?['bill_number'];
        _message(invoice == null
            ? 'Sale save ho gayi, lekin invoice details load nahi huin.'
            : 'Invoice $invoice successfully generated.');
      } catch (e) {
        _message('Sale save ho gayi, lekin invoice details load nahi huin: $e');
      }
    } catch (e) {
      _message('Sale save nahi hui: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }


  Widget _section(String title, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          )),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _moneyField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rs. ',
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
        ),
      ),
    );
  }

  String _rs(double value) => 'Rs. ${value.toStringAsFixed(2)}';

  Widget _fieldDecoration({
    required String label,
    String? hint,
    IconData? icon,
  }) {
    return const SizedBox.shrink();
  }

  Widget _amountRow(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF374151),
          )),
          Text(_rs(amount), style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: bold ? const Color(0xFF16A34A) : const Color(0xFF111827),
          )),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    final dateText =
        '${_pakistanNow.day.toString().padLeft(2, '0')} '
        '${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][_pakistanNow.month - 1]} '
        '${_pakistanNow.year}';

    final status = remaining <= 0.000001
        ? 'Paid'
        : paid > 0
            ? 'Partially Paid'
            : 'Unpaid';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        title: const Text('New Sale',
          style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Sale',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                    SizedBox(height: 3),
                    Text('OmniBizCRM • Point of Sale',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('New Invoice',
                  style: TextStyle(color: Color(0xFF15803D),
                    fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(child: _infoCard('Invoice Number',
                lastGeneratedSaleDetails == null
                    ? 'Generated on save'
                    : lastGeneratedSaleDetails!['sale']['bill_number'].toString())),
              const SizedBox(width: 10),
              Expanded(child: _infoCard('Sale Date', dateText)),
            ],
          ),
          const SizedBox(height: 16),

          _section('1. Customer Details', Column(
            children: [
              TextField(
                controller: _customerSearch,
                onChanged: _loadCustomers,
                decoration: InputDecoration(
                  labelText: 'Search customer by name or mobile',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (selectedCustomer != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(selectedCustomer!['name'].toString()),
                  subtitle: Text(selectedCustomer!['mobile']?.toString() ?? ''),
                  trailing: IconButton(
                    onPressed: () => setState(() {
                      selectedCustomer = null;
                      _customerSearch.clear();
                    }),
                    icon: const Icon(Icons.close),
                  ),
                )
              else
                ...customers.take(5).map((customer) => ListTile(
                  dense: true,
                  title: Text(customer['name'].toString()),
                  subtitle: Text(customer['mobile']?.toString() ?? ''),
                  onTap: () => setState(() {
                    selectedCustomer = customer;
                    _customerSearch.text = customer['name'].toString();
                    customers = [];
                  }),
                )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _addCustomer,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add New Customer'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: selectedCustomer == null
                        ? null
                        : () => _message('Customer Khata will open for the selected customer.'),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Customer Khata'),
                  )),
                ],
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Walk-in Customer can be used without selecting a customer.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ],
          )),

          _section('2. Product Selection', Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Barcode / SKU Scanner',
                style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(
                    controller: _barcodeController,
                    focusNode: _barcodeFocus,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    onSubmitted: _handleBarcode,
                    decoration: InputDecoration(
                      hintText: 'Scan or enter barcode',
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      if (_barcodeController.text.trim().isNotEmpty) {
                        _handleBarcode(_barcodeController.text.trim());
                      } else {
                        _barcodeFocus.requestFocus();
                      }
                    },
                    child: const Text('Scan'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _productSearch,
                onChanged: _searchProducts,
                decoration: InputDecoration(
                  labelText: 'Search Product',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 7,
                children: saleCategories.map((category) => ChoiceChip(
                  label: Text(category),
                  selected: selectedCategory == category,
                  selectedColor: const Color(0xFFDCFCE7),
                  onSelected: (_) => setState(() => selectedCategory = category),
                )).toList(),
              ),
              const SizedBox(height: 8),
              ...filteredSaleProducts.take(12).map((product) {
                final stock = (product['quantity'] as num).toDouble();
                return Card(
                  color: const Color(0xFFF9FAFB),
                  elevation: 0,
                  child: ListTile(
                    title: Text(product['name'].toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'SKU: ${product['sku'] ?? '-'} • Stock: $stock ${product['unit'] ?? 'pcs'}'),
                    trailing: Text(_rs((product['sale_price'] as num).toDouble()),
                      style: const TextStyle(color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold)),
                    onTap: () => _addProduct(product),
                  ),
                );
              }),
              const Text('Select a product above to add it to the cart.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )),

          _section('3. Product Cart (${cart.length} items)', cart.isEmpty
              ? const Text('Your cart is empty.')
              : Column(
                  children: cart.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final qty = item['quantity'] as double;
                    final price = item['price'] as double;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text(item['productName'].toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold))),
                            const Text('In Cart Preview',
                              style: TextStyle(color: Color(0xFF16A34A), fontSize: 11)),
                          ]),
                          const SizedBox(height: 5),
                          Text('SKU / Barcode: ${item['sku'] ?? '-'}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Row(children: [
                            IconButton(
                              onPressed: () => _changeQuantity(i, -1),
                              icon: const Icon(Icons.remove_circle_outline)),
                            Text('${qty.toString()} × ${_rs(price)}'),
                            IconButton(
                              onPressed: () => _changeQuantity(i, 1),
                              icon: const Icon(Icons.add_circle_outline)),
                            const Spacer(),
                            Text(_rs(price * qty),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                            IconButton(
                              onPressed: () => setState(() => cart.removeAt(i)),
                              icon: const Icon(Icons.delete_outline, color: Colors.red)),
                          ]),
                        ],
                      ),
                    );
                  }).toList(),
                )),

          _section('4. Discount & Tax', Column(
            children: [
              Row(children: [
                Expanded(child: _moneyField('Item / Bill Discount (Rs.)', _discount)),
                const SizedBox(width: 10),
                Expanded(child: _moneyField('Tax (Rs.)', _tax)),
              ]),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(children: [
                  _amountRow('Subtotal', subtotal),
                  _amountRow('Discount', -discount),
                  _amountRow('Tax', tax),
                  const Divider(),
                  _amountRow('Grand Total', total, bold: true),
                ]),
              ),
            ],
          )),

          _section('5. Payment Details', Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...['Cash', 'Bank Transfer', 'Raast', 'JazzCash', 'Easypaisa',
                'Credit / Khata (Udhar)', 'Partial Payment'].map((option) {
                final selected = option == 'Credit / Khata (Udhar)'
                    ? paymentType == 'Udhaar'
                    : option == 'Partial Payment'
                        ? paymentType == 'Partial'
                        : paymentType == 'Cash' && paymentMethod == option;
                return RadioListTile<String>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: option,
                  groupValue: paymentType == 'Udhaar'
                      ? 'Credit / Khata (Udhar)'
                      : paymentType == 'Partial'
                          ? 'Partial Payment'
                          : paymentMethod,
                  title: Text(option),
                  onChanged: (value) {
                    if (value == null) return;
                    if (value == 'Credit / Khata (Udhar)') {
                      _selectPaymentType('Udhaar');
                    } else if (value == 'Partial Payment') {
                      _selectPaymentType('Partial');
                    } else {
                      setState(() {
                        paymentType = 'Cash';
                        paymentMethod = value;
                        _paid.text = total.toStringAsFixed(2);
                      });
                    }
                  },
                );
              }),
              if (paymentType == 'Partial') ...[
                const SizedBox(height: 8),
                _moneyField('Amount Received (Rs.)', _paid),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _infoCard('Received', _rs(paid))),
                const SizedBox(width: 10),
                Expanded(child: _infoCard('Remaining Balance', _rs(remaining))),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Payment Status: '),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'Paid'
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: TextStyle(
                    color: status == 'Paid'
                        ? const Color(0xFF15803D)
                        : const Color(0xFFC2410C),
                    fontWeight: FontWeight.bold,
                  )),
                ),
              ]),
            ],
          )),

          _section('6. Additional Details', Column(
            children: [
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Sale Notes',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: 'None',
                decoration: InputDecoration(
                  labelText: 'Other Options',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'None', child: Text('None')),
                ],
                onChanged: (_) {},
              ),
            ],
          )),

          _section('7. Invoice Actions', Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: saving ? null : _saveSale,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(saving ? 'Saving Sale...' : 'Save Sale'),
                ),
              ),
              if (lastGeneratedSaleDetails != null) ...[
                const SizedBox(height: 10),
                Text('Invoice: ${lastGeneratedSaleDetails!['sale']['bill_number']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: lastGeneratedSaleDetails == null
                      ? null : () => _showSaleDocument(false),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Preview Invoice'),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: lastGeneratedSaleDetails == null ? null : _printInvoice,
                  icon: const Icon(Icons.print),
                  label: const Text('Print'),
                )),
              ]),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: lastGeneratedSaleDetails == null ? null : _downloadInvoicePdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Export PDF'),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: lastGeneratedSaleDetails == null ? null : _sendWhatsAppBill,
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                )),
              ]),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  cart.clear();
                  selectedCustomer = null;
                  _customerSearch.clear();
                  _productSearch.clear();
                  _barcodeController.clear();
                  _discount.text = '0';
                  _tax.text = '0';
                  _paid.text = '0';
                  _reference.clear();
                  _notes.clear();
                  paymentType = 'Cash';
                  paymentMethod = 'Cash';
                  lastGeneratedSaleDetails = null;
                }),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Form'),
              ),
            ],
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          )),
        ],
      ),
    );
  }

  Map<String, dynamic>? get _generatedSale =>
      lastGeneratedSaleDetails == null
          ? null
          : Map<String, dynamic>.from(lastGeneratedSaleDetails!['sale'] as Map);

  List<Map<String, dynamic>> get _generatedItems =>
      lastGeneratedSaleDetails == null
          ? []
          : List<Map<String, dynamic>>.from(lastGeneratedSaleDetails!['items']);

  String _invoiceMessage() {
    final sale = _generatedSale!;
    final lines = _generatedItems.map((item) =>
        "${item['product_name']} - ${item['quantity']} ${item['unit']} x Rs. ${item['price']} = Rs. ${item['total']}").join('\n');
    return "Invoice: ${sale['bill_number']}\n"
        "Date: ${sale['sale_date']}\n"
        "Customer: ${sale['customer_name'] ?? 'Walk-in Customer'}\n"
        "$lines\n"
        "Subtotal: Rs. ${sale['subtotal']}\n"
        "Discount: Rs. ${sale['discount']}\n"
        "Tax: Rs. ${sale['tax']}\n"
        "Grand Total: Rs. ${sale['total']}\n"
        "Paid: Rs. ${sale['paid']}\n"
        "Remaining: Rs. ${sale['remaining']}";
  }

  Future<Uint8List> _createInvoicePdf() async {
    final sale = _generatedSale;
    if (sale == null) throw StateError('Pehle bill generate karein.');

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) => [
        pw.Center(
          child: pw.Text('SALES INVOICE',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        ),
        pw.SizedBox(height: 12),
        pw.Text('Invoice: ${sale['bill_number']}'),
        pw.Text('Date: ${sale['sale_date']}'),
        pw.Text('Customer: ${sale['customer_name'] ?? 'Walk-in Customer'}'),
        pw.Divider(),
        ..._generatedItems.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 5),
          child: pw.Text(
            "${item['product_name']} | ${item['quantity']} ${item['unit']} x Rs. ${item['price']} = Rs. ${item['total']}",
          ),
        )),
        pw.Divider(),
        pw.Text('Subtotal: Rs. ${sale['subtotal']}'),
        pw.Text('Discount: Rs. ${sale['discount']}'),
        pw.Text('Tax: Rs. ${sale['tax']}'),
        pw.Text('Grand Total: Rs. ${sale['total']}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Paid: Rs. ${sale['paid']}'),
        pw.Text('Remaining: Rs. ${sale['remaining']}'),
        if (sale['reference_number'] != null)
          pw.Text('Reference: ${sale['reference_number']}'),
        if (sale['notes'] != null && sale['notes'].toString().isNotEmpty)
          pw.Text('Notes: ${sale['notes']}'),
      ],
    ));
    return pdf.save();
  }

  Future<void> _downloadInvoicePdf() async {
    try {
      final sale = _generatedSale;
      if (sale == null) return;
      final bytes = await _createInvoicePdf();
      await FileSaver.instance.saveFile(
        name: 'Invoice_${sale['bill_number']}',
        bytes: bytes,
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
      _message('PDF save process complete hua.');
    } catch (e) {
      _message('PDF save nahi hui: $e');
    }
  }

  Future<void> _printInvoice() async {
    try {
      final bytes = await _createInvoicePdf();
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      _message('Print nahi ho saka: $e');
    }
  }

  Future<void> _shareInvoicePdf() async {
    try {
      final sale = _generatedSale;
      if (sale == null) return;
      final bytes = await _createInvoicePdf();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/Invoice_${sale['bill_number']}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice ${sale['bill_number']}',
      );
    } catch (e) {
      _message('Bill share nahi ho saka: $e');
    }
  }

  Future<void> _sendWhatsAppBill() async {
    try {
      final sale = _generatedSale;
      if (sale == null) return;
      final mobile = (sale['customer_mobile'] ?? '')
          .toString().replaceAll(RegExp(r'[^0-9]'), '');
      if (mobile.isEmpty) {
        _message('Customer ka mobile number available nahi hai.');
        return;
      }
      var phone = mobile;
      if (phone.startsWith('0')) phone = '92${phone.substring(1)}';
      if (!phone.startsWith('92')) phone = '92$phone';

      final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent(_invoiceMessage())}',
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) _message('WhatsApp open nahi ho saka.');
    } catch (e) {
      _message('WhatsApp bill send nahi ho saka: $e');
    }
  }

  void _showSaleDocument(bool paymentSlip) {
    final details = lastGeneratedSaleDetails;
    if (details == null) return;
    final sale = Map<String, dynamic>.from(details['sale'] as Map);
    final items = List<Map<String, dynamic>>.from(details['items']);
    final payments = List<Map<String, dynamic>>.from(details['payments']);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(paymentSlip ? 'Payment Slip' : 'Sale Invoice'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Invoice: ${sale['bill_number']}'),
              Text('Date: ${sale['sale_date']}'),
              Text('Customer: ${sale['customer_name'] ?? 'Walk-in Customer'}'),
              const Divider(),
              if (!paymentSlip) ...[
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${item['product_name']}  |  ${item['quantity']} ${item['unit']}  x  Rs. ${item['price']}  =  Rs. ${item['total']}',
                  ),
                )),
                const Divider(),
                Text('Subtotal: Rs. ${sale['subtotal']}'),
                Text('Discount: Rs. ${sale['discount']}'),
                Text('Tax: Rs. ${sale['tax']}'),
                Text('Grand Total: Rs. ${sale['total']}'),
              ] else ...[
                Text('Receipt / Payment History'),
                if (payments.isEmpty)
                  const Text('No payment received yet. This invoice is on Udhaar.')
                else
                  ...payments.map((payment) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      'Receipt #${payment['id']}  |  ${payment['payment_date']}\n'
                      'Received: Rs. ${payment['amount']}\n'
                      'Method: ${payment['payment_method'] ?? '-'}',
                    ),
                  )),
                const Divider(),
                Text('Bill Total: Rs. ${sale['total']}'),
                Text('Total Received: Rs. ${sale['paid']}'),
              ],
              Text('Remaining: Rs. ${sale['remaining']}'),
              if (sale['reference_number'] != null)
                Text('Reference: ${sale['reference_number']}'),
              if (sale['notes'] != null && sale['notes'].toString().isNotEmpty)
                Text('Notes: ${sale['notes']}'),
            ],
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

  Widget _summaryRow(String label, double amount, {bool bold = false}) {
    final highlight = label == 'Grand Total' || label == 'Remaining';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: highlight ? 9 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? const Color(0xFF16A34A) : Colors.white70,
              fontSize: highlight ? 15 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            _rs(amount),
            style: TextStyle(
              color: highlight ? const Color(0xFF16A34A) : Colors.white,
              fontSize: highlight ? 17 : 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
