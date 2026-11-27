import 'package:flutter/material.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/expenses/expense_management_screen.dart';
import 'screens/products/product_management_screen.dart';
import 'screens/sales/new_sale_screen.dart';
import 'screens/sales/return_approval_screen.dart';
import 'screens/sales/sales_return_screen.dart';
import 'screens/modules/module_entry_screen.dart';
import 'screens/customers/customer_management_screen.dart';
import 'screens/suppliers/supplier_management_screen.dart';

void main() => runApp(const OmniBizCRM());

class OmniBizCRM extends StatelessWidget {
  const OmniBizCRM({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OmniBizCRM',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF087E70),
        useMaterial3: true,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        iconTheme: const IconThemeData(size: 20),
        appBarTheme: const AppBarTheme(
          toolbarHeight: 48,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
      home: NewDashboardScreen(
        modules: modules,
        onOpenModule: (context, module) => openModule(context, module),
      ),
    );
  }
}

class AppModule {
  final String name;
  final String category;
  final IconData icon;
  final List<String> options;

  const AppModule(this.name, this.category, this.icon, this.options);

  String get displayName =>
      const {
        'Khata': 'Ledger',
        'Baqaya Udhaar': 'Outstanding Credit',
        'Jama Raqam & Udhar Dein': 'Payment Collection & Credit',
      }[name] ??
      name;

  String get displayCategory => category;

  String displayOption(String option) =>
      const {
        'Naya Khata': 'New Ledger',
        'Khata List': 'Ledger List',
        'Customer Khata': 'Customer Ledger',
        'Supplier Khata': 'Supplier Ledger',
        'Jama Raqam': 'Amount Received',
        'Udhar Dein': 'Give Credit',
        'Khata Report': 'Ledger Report',
      }[option] ??
      option;
}

const modules = <AppModule>[
  AppModule('Dashboard', 'Home', Icons.dashboard,
      ['Business Overview', 'Today Summary', 'Quick Actions']),
  AppModule('New Sale', 'Sales', Icons.point_of_sale,
      ['Create New Sale', 'Sale History', 'Sale Details', 'Payment Received']),
  AppModule('Sales Return', 'Sales', Icons.assignment_return,
      ['New Sales Return', 'Return History', 'Refund Details']),
  AppModule('Orders & Quotations', 'Sales', Icons.request_quote,
      ['New Order', 'Order List', 'Create Quotation', 'Quotation History']),
  AppModule('Products', 'Stock', Icons.inventory_2, [
    'Add Product',
    'Product List',
    'Edit Product',
    'Product Categories',
    'Product Barcode'
  ]),
  AppModule('Customers', 'People', Icons.people,
      ['Add Customer', 'Customer List', 'Customer Details', 'Customer Ledger']),
  AppModule('Khata', 'Accounts', Icons.menu_book,
      ['Naya Khata', 'Khata List', 'Customer Khata', 'Supplier Khata']),
  AppModule('Baqaya Udhaar', 'Accounts', Icons.account_balance_wallet,
      ['Total Remaining Amount', 'Customer Wise Balance', 'Receive Payment']),
  AppModule('Jama Raqam & Udhar Dein', 'Accounts', Icons.currency_exchange,
      ['Jama Raqam', 'Udhar Dein', 'Payment History']),
  AppModule('Expenses', 'Accounts', Icons.wallet, [
    'Add Expense',
    'Expense Categories',
    'Expense History',
    'Expense Reports'
  ]),
  AppModule('Inventory & In Stock', 'Stock', Icons.warehouse,
      ['In Stock', 'Low Stock', 'Out of Stock', 'Stock History']),
  AppModule('Warehouse', 'Stock', Icons.store,
      ['Add Warehouse', 'Warehouse List', 'Warehouse Stock']),
  AppModule('Stock Transfer & Adjustment', 'Stock', Icons.swap_horiz,
      ['Transfer Stock', 'Stock Adjustment', 'Transfer History']),
  AppModule('Expiry & Damaged Stock', 'Stock', Icons.warning_amber,
      ['Expired Products', 'Near Expiry', 'Damaged Stock']),
  AppModule('Purchase & Purchase Return', 'Purchases', Icons.shopping_bag, [
    'New Purchase',
    'Purchase History',
    'Purchase Return',
    'Return History'
  ]),
  AppModule('Suppliers', 'People', Icons.local_shipping,
      ['Add Supplier', 'Supplier List', 'Supplier Details', 'Supplier Ledger']),
  AppModule('Reports & Profit & Loss', 'Reports', Icons.bar_chart, [
    'Sales Report',
    'Purchase Report',
    'Expense Report',
    'Profit & Loss',
    'Stock Report',
    'Khata Report'
  ]),
  AppModule('Barcode Generate & Labels', 'Tools', Icons.qr_code_scanner,
      ['Generate Barcode', 'Print Labels', 'Scan Barcode']),
  AppModule('Bills & Printers', 'Tools', Icons.print,
      ['Create Bill', 'Bill History', 'Printer Settings', 'Bill Design']),
  AppModule('WhatsApp', 'Tools', Icons.message, [
    'Send Bill',
    'Payment Reminder',
    'Customer Message',
    'WhatsApp Settings'
  ]),
  AppModule('Raast & Instant Pay', 'Payments', Icons.bolt,
      ['Raast Payment', 'Payment Request', 'Payment History']),
  AppModule('Payments', 'Payments', Icons.payment,
      ['Receive Payment', 'Make Payment', 'Payment Methods', 'Transactions']),
  AppModule('Business & Branches', 'Management', Icons.business,
      ['Business Profile', 'Add Branch', 'Branch List', 'Business Details']),
  AppModule('Admin & Staff Management', 'Management', Icons.groups,
      ['Add Staff', 'Staff List', 'Roles & Permissions', 'Staff Attendance']),
  AppModule('Discounts & Taxes', 'Management', Icons.percent,
      ['Create Discount', 'Discount List', 'Tax Settings']),
  AppModule('Appointments & Reminders', 'Management', Icons.event,
      ['Add Appointment', 'Appointment List', 'Set Reminder']),
  AppModule('Customer Loyalty', 'Management', Icons.loyalty,
      ['Loyalty Points', 'Rewards', 'Customer Offers']),
  AppModule('Accounting & Cashbook', 'Accounts', Icons.calculate,
      ['Cash In', 'Cash Out', 'Cashbook', 'Daily Closing']),
  AppModule('Bank & Cash Accounts', 'Accounts', Icons.account_balance,
      ['Add Bank Account', 'Cash Account', 'Account History']),
  AppModule('Online Store / Website', 'Online', Icons.language,
      ['Store Settings', 'Online Products', 'Online Orders']),
  AppModule('Settings', 'System', Icons.settings, [
    'Business Settings',
    'App Settings',
    'Invoice Settings',
    'Notification Settings'
  ]),
  AppModule('Security & Permissions', 'System', Icons.security,
      ['App Lock', 'Change PIN', 'User Permissions', 'Login Security']),
  AppModule('Languages', 'System', Icons.translate,
      ['Choose Language', 'Download Language Pack', 'Text Direction']),
  AppModule('Backup & Restore', 'System', Icons.backup,
      ['Create Backup', 'Restore Backup', 'Backup History']),
  AppModule('Packages & Subscription', 'System', Icons.workspace_premium, [
    'Current Package',
    'Upgrade Package',
    'Renew Subscription',
    'Payment History'
  ]),
  AppModule('Support', 'Help', Icons.support_agent,
      ['Contact Support', 'Submit Complaint', 'Help Center']),
  AppModule('History & Records', 'Records', Icons.history, [
    'Sales Records',
    'Purchase Records',
    'Customer Records',
    'Deleted Records'
  ]),
  AppModule('Activity History', 'Records', Icons.manage_history,
      ['User Activity', 'Login History', 'Changes History']),
  AppModule('Customer Notifications', 'Tools', Icons.notifications,
      ['Send Notification', 'Notification History', 'Message Settings']),
];

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String search = '';

  @override
  Widget build(BuildContext context) {
    const hiddenDashboardModules = <String>{
      'Barcode Generate & Labels',
      'Bills & Printers',
      'Discounts & Taxes',
      'Security & Permissions',
      'Languages',
      'Backup & Restore',
      'Packages & Subscription',
      'Support',
      'Customer Notifications',
    };

    final shown = modules
        .where((m) =>
            !hiddenDashboardModules.contains(m.name) &&
            (m.name.toLowerCase().contains(search.toLowerCase()) ||
                m.category.toLowerCase().contains(search.toLowerCase())))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('OmniBizCRM',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => openModule(context, modules.last),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Business, Your Control',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 6),
                Text('Complete Management for Your Business'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              decoration: InputDecoration(
                hintText: 'Search options...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Text('All Business Options',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${shown.length} options'),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.45,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: shown.length,
              itemBuilder: (context, index) {
                final module = shown[index];
                return Card(
                  elevation: 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => openModule(context, module),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(module.icon,
                              size: 30,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 9),
                          Text(module.displayName,
                              textAlign: TextAlign.center,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(module.category,
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const settingsModules = <AppModule>[
    AppModule('Business Settings', 'BUSINESS SETTINGS', Icons.business, [
      'Business Profile',
      'Business Information',
      'Business Logo',
      'Business Address',
      'Branch Settings',
    ]),
    AppModule(
        'Payment Settings', 'BUSINESS SETTINGS', Icons.account_balance_wallet, [
      'Payment Methods',
      'Bank Accounts',
      'Cash Settings',
      'Default Payment Method',
    ]),
    AppModule('Inventory Settings', 'BUSINESS SETTINGS', Icons.inventory_2, [
      'Product Categories',
      'Units Management',
      'Stock Alerts',
      'Low Stock Notifications',
    ]),
    AppModule('Discounts & Taxes', 'SALES & OPERATIONS', Icons.percent, [
      'Create Discount',
      'Discount List',
      'Percentage Discount',
      'Fixed Amount Discount',
      'Product-wise Discount',
      'Customer-wise Discount',
      'Tax Settings',
      'Tax Rates',
      'Tax Inclusive / Exclusive',
    ]),
    AppModule(
        'Customer Notifications', 'SALES & OPERATIONS', Icons.notifications, [
      'Send Notification',
      'Notification History',
      'Message Settings',
      'WhatsApp Notifications',
      'SMS Notifications',
      'Payment Reminders',
      'Message Templates',
    ]),
    AppModule('Bills & Printers', 'SALES & OPERATIONS', Icons.print, [
      'Create Bill',
      'Bill History',
      'Printer Settings',
      'Bill Design',
      'Invoice Settings',
      'Invoice Numbering',
      'Paper Size',
      'PDF Settings',
    ]),
    AppModule('Barcode Generate & Labels', 'SALES & OPERATIONS',
        Icons.qr_code_scanner, [
      'Generate Barcode',
      'Print Labels',
      'Scan Barcode',
      'Barcode Format',
      'Label Design',
      'Label Size',
    ]),
    AppModule('Security & Permissions', 'ACCESS & USERS', Icons.security, [
      'App Lock',
      'Change PIN',
      'User Permissions',
      'Login Security',
      'Access Control',
    ]),
    AppModule('User & Role Management', 'ACCESS & USERS', Icons.groups, [
      'User Management',
      'Role Management',
      'Admin Permissions',
      'Branch Access',
      'Staff Access',
    ]),
    AppModule('Languages', 'ACCESS & USERS', Icons.translate, [
      'Choose Language',
      'Download Language Pack',
      'Text Direction',
    ]),
    AppModule('Themes & Templates', 'APPEARANCE', Icons.palette_outlined, [
      'Choose Theme',
      'Create Your Own Theme',
      'Theme Colors',
      'App Templates',
    ]),
    AppModule('Backup & Restore', 'SUBSCRIPTION & SYSTEM', Icons.backup, [
      'Create Backup',
      'Restore Backup',
      'Backup History',
      'Google Drive Backup',
      'Manual Backup',
    ]),
    AppModule('Subscription & License', 'SUBSCRIPTION & SYSTEM',
        Icons.verified_user, [
      'Current Subscription',
      'License Information',
      'Renewal Details',
    ]),
    AppModule('Packages & Subscription', 'SUBSCRIPTION & SYSTEM',
        Icons.workspace_premium, [
      'Current Package',
      'Upgrade Package',
      'Renew Subscription',
      'Payment History',
      'Available Packages',
      'Package Details',
    ]),
    AppModule('General Settings', 'SUBSCRIPTION & SYSTEM', Icons.tune, [
      'Currency',
      'Date Format',
      'Time Format',
      'Notification Preferences',
      'Import & Export',
    ]),
    AppModule('Data Management', 'SUBSCRIPTION & SYSTEM', Icons.storage, [
      'Data Export',
      'Data Import',
    ]),
    AppModule(
        'System Information', 'SUBSCRIPTION & SYSTEM', Icons.info_outline, [
      'App Version',
      'System Status',
      'Database Information',
    ]),
    AppModule('Support', 'SUPPORT', Icons.support_agent, [
      'Contact Support',
      'Submit Complaint',
      'Help Center',
      'FAQs',
    ]),
    AppModule('Support OmniBizCRM', 'SUPPORT', Icons.volunteer_activism, [
      'Donate Now',
      'Payment Methods',
      'Donation History',
      'Donation Receipts',
      'About Donations',
      'Supporter Appreciation',
    ]),
    AppModule('Download App', 'APP & DOWNLOADS', Icons.download, [
      'Download OmniBizCRM',
    ]),
    AppModule('Rate Us on Google Play', 'APP & DOWNLOADS', Icons.star_rate, [
      'Rate OmniBizCRM',
    ]),
    AppModule('Share App', 'APP & DOWNLOADS', Icons.share, [
      'Share OmniBizCRM',
    ]),
    AppModule("What's New", 'APP & DOWNLOADS', Icons.new_releases, [
      'Latest Features',
      'Version History',
    ]),
    AppModule('Privacy Policy', 'APP & DOWNLOADS', Icons.privacy_tip, [
      'Privacy Policy',
    ]),
    AppModule('Terms & Conditions', 'APP & DOWNLOADS', Icons.description, [
      'Terms & Conditions',
    ]),
    AppModule('About OmniBizCRM', 'APP & DOWNLOADS', Icons.info, [
      'App Information',
      'Version Details',
    ]),
  ];

  static const categoryNames = [
    'BUSINESS SETTINGS',
    'SALES & OPERATIONS',
    'ACCESS & USERS',
    'APPEARANCE',
    'SUBSCRIPTION & SYSTEM',
    'SUPPORT',
    'APP & DOWNLOADS',
  ];

  String search = '';

  @override
  Widget build(BuildContext context) {
    final query = search.trim().toLowerCase();
    final shown = settingsModules.where((module) {
      return module.displayName.toLowerCase().contains(query) ||
          module.options.any((option) => option.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF183B32),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Manage your business preferences',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.settings_outlined,
                    color: Color(0xFF16866B),
                    size: 27,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                onChanged: (value) => setState(() => search = value),
                decoration: InputDecoration(
                  hintText: 'Search Settings...',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF16866B)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3EAE6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE3EAE6)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                children: [
                  for (final category in categoryNames)
                    Builder(builder: (context) {
                      final items = shown
                          .where((module) => module.category == category)
                          .toList();
                      if (items.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: Color(0xFF16866B),
                                ),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: const Color(0xFFE6ECE8),
                                ),
                              ),
                              child: Column(
                                children: [
                                  for (int i = 0; i < items.length; i++) ...[
                                    InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () =>
                                          openModule(context, items[i]),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              items[i].icon,
                                              size: 21,
                                              color: const Color(0xFF16866B),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                items[i].displayName,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF263B34),
                                                ),
                                              ),
                                            ),
                                            const Tooltip(
                                              message: 'Quick Settings',
                                              child: Icon(
                                                Icons.tune,
                                                size: 20,
                                                color: Color(0xFF16866B),
                                              ),
                                            ),
                                            const SizedBox(width: 13),
                                            const Tooltip(
                                              message: 'More Options',
                                              child: Icon(
                                                Icons.more_vert,
                                                size: 21,
                                                color: Color(0xFF65756E),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (i != items.length - 1)
                                      const Divider(
                                        height: 1,
                                        indent: 44,
                                        color: Color(0xFFEEF1EF),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 8),
                  Center(
                    child: Column(
                      children: [
                        CustomPaint(
                          size: const Size(34, 34),
                          painter: _GooglePlayLogoPainter(),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Google Play Store',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF35463F),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Get OmniBizCRM on Google Play',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GooglePlayLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()..color = const Color(0xFF4285F4);
    final green = Paint()..color = const Color(0xFF34A853);
    final yellow = Paint()..color = const Color(0xFFFBBC04);
    final red = Paint()..color = const Color(0xFFEA4335);

    final left = Path()
      ..moveTo(3, 2)
      ..lineTo(17, 16)
      ..lineTo(3, 32)
      ..close();
    canvas.drawPath(left, blue);

    final top = Path()
      ..moveTo(3, 2)
      ..lineTo(29, 15)
      ..lineTo(20, 19)
      ..lineTo(17, 16)
      ..close();
    canvas.drawPath(top, green);

    final bottom = Path()
      ..moveTo(3, 32)
      ..lineTo(17, 16)
      ..lineTo(20, 13)
      ..lineTo(29, 19)
      ..close();
    canvas.drawPath(bottom, yellow);

    final right = Path()
      ..moveTo(29, 15)
      ..lineTo(33, 17)
      ..quadraticBezierTo(35, 18, 33, 20)
      ..lineTo(29, 22)
      ..lineTo(20, 19)
      ..close();
    canvas.drawPath(right, red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void openModule(BuildContext context, AppModule module) {
  if (module.name == 'Dashboard') return;

  Widget screen;

  switch (module.name) {
    case 'Settings':
      screen = const SettingsScreen();
      break;
    case 'Customers':
      screen = const CustomerManagementScreen();
      break;

    case 'Suppliers':
      screen = const SupplierManagementScreen();
      break;

    case 'New Sale':
      screen = const NewSaleScreen();
      break;

    case 'Products':
      screen = const ProductManagementScreen();
      break;

    case 'Sales Return':
      screen = const SalesReturnScreen();
      break;

    case 'Expenses':
      screen = const ExpenseManagementScreen();
      break;

    default:
      screen = ModuleEntryScreen(
        moduleName: module.name,
        icon: module.icon,
      );
  }

  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => screen),
  );
}

class ModuleScreen extends StatelessWidget {
  final AppModule module;
  const ModuleScreen({super.key, required this.module});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(module.displayName)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: Icon(module.icon, size: 32),
              title: Text(module.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(module.category),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 18, 8, 8),
            child: Text('Sub Options',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...module.options.map((option) => Card(
                child: ListTile(
                  leading: const Icon(Icons.arrow_forward_ios, size: 18),
                  title: Text(module.displayOption(option)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) {
                      if (module.name == 'New Sale' &&
                          option == 'Create New Sale') {
                        return const NewSaleScreen();
                      }
                      if (module.name == 'Suppliers' &&
                          option != 'Supplier Ledger') {
                        return const SupplierManagementScreen();
                      }
                      if (module.name == 'Sales Return') {
                        if (option == 'New Sales Return') {
                          return const SalesReturnScreen();
                        }
                        if (option == 'Return History') {
                          return const ReturnApprovalScreen();
                        }
                        if (option == 'Refund Details') {
                          return const ReturnApprovalScreen(readOnly: true);
                        }
                      }
                      return OptionScreen(title: option);
                    },
                  )),
                ),
              )),
        ],
      ),
    );
  }
}

class OptionScreen extends StatelessWidget {
  final String title;
  const OptionScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 52),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'Is option ka actual form aur data system aglay development step mein banaya jayega.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OmniSplashScreen extends StatefulWidget {
  const OmniSplashScreen({super.key});

  @override
  State<OmniSplashScreen> createState() => _OmniSplashScreenState();
}

class _OmniSplashScreenState extends State<OmniSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: NewDashboardScreen(
              modules: modules,
              onOpenModule: (context, module) => openModule(context, module),
            ),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF071426);
    const blue = Color(0xFF168BFF);
    const cyan = Color(0xFF38D9FF);

    return Scaffold(
      backgroundColor: navy,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF102B50), navy, Color(0xFF030A16)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                ScaleTransition(
                  scale: _scale,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Container(
                      width: 126,
                      height: 126,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: const LinearGradient(
                          colors: [cyan, blue, Color(0xFF1747B8)],
                        ),
                        border: Border.all(color: Colors.white70, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: blue.withOpacity(0.65),
                            blurRadius: 35,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'OB',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'OmniBizCRM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'SMART BUSINESS MANAGEMENT',
                  style: TextStyle(
                    color: cyan,
                    fontSize: 11,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Business, Your Control',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 55),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 2700),
                    builder: (context, value, child) => Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 5,
                            backgroundColor: Colors.white12,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(cyan),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Loading... ${(value * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                const Text(
                  'GROW YOUR BUSINESS WITH OMNIBIZCRM',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 9,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
