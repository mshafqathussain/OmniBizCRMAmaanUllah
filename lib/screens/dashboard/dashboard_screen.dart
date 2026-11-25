import 'package:flutter/material.dart';
import '../products/product_management_screen.dart';
import '../../database/app_database.dart';

class NewDashboardScreen extends StatefulWidget {
  final List<dynamic> modules;
  final void Function(BuildContext, dynamic) onOpenModule;

  const NewDashboardScreen({
    super.key,
    required this.modules,
    required this.onOpenModule,
  });

  @override
  State<NewDashboardScreen> createState() => _NewDashboardScreenState();
}

class _NewDashboardScreenState extends State<NewDashboardScreen> {
  String period = 'Today';
  late Future<Map<String, dynamic>> dashboardData;

  static const bg = Color(0xFF0B1220);
  static const panel = Color(0xFF172337);
  static const muted = Color(0xFF94A3B8);
  static const accent = Color(0xFF41D6B5);

  @override
  void initState() {
    super.initState();
    dashboardData = loadData();
  }

  Future<Map<String, dynamic>> loadData() async {
    final db = await AppDatabase.instance.database;
    final today = await AppDatabase.instance.getDashboardSummary(
      period: 'Today',
    );
    final selected = await AppDatabase.instance.getDashboardSummary(
      period: period,
    );
    final all = await AppDatabase.instance.getDashboardSummary(
      period: 'All Time',
    );

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1)).toIso8601String();

    final collection = await db.rawQuery('''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM payments
      WHERE payment_date >= ? AND payment_date < ?
    ''', [start, end]);

    final suppliers = await db.rawQuery('''
      SELECT COUNT(*) AS total,
             COALESCE(SUM(balance), 0) AS balance
      FROM suppliers
    ''');

    final bills = await db.rawQuery('''
      SELECT sales.id, sales.bill_number, sales.sale_date,
             sales.total, sales.paid, sales.remaining,
             sales.payment_status,
             COALESCE(customers.name, 'Walk-in Customer') AS customer_name
      FROM sales
      LEFT JOIN customers ON customers.id = sales.customer_id
      ORDER BY sales.id DESC
      LIMIT 10
    ''');

    final credit = await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) AS total
      FROM sales WHERE remaining > 0
    ''');

    return {
      'today': today,
      'selected': selected,
      'all': all,
      'collection': (collection.first['total'] as num).toDouble(),
      'suppliers': suppliers.first['total'],
      'supplierBalance': (suppliers.first['balance'] as num).toDouble(),
      'bills': bills,
      'credit': (credit.first['total'] as num).toDouble(),
    };
  }

  String money(dynamic value) {
    if (value == null) return 'Rs. —';
    final n = (value as num).toDouble();
    return 'Rs. ${n.toStringAsFixed(0)}';
  }

  void refresh() {
    setState(() {
      dashboardData = loadData();
    });
  }

  void openNamedModule(String name) {
    final matches = widget.modules.where((m) => m.name == name);
    if (matches.isNotEmpty) {
      widget.onOpenModule(context, matches.first);
    }
  }

  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 5, bottom: 3),
    child: Text(text, style: const TextStyle(
      color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold,
    )),
  );

  Widget overviewCard(
    String title, String value, IconData icon, Color color,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => openNamedModule(title),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF26364C)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right, color: muted, size: 18),
            ]),
            const SizedBox(height: 13),
            Text(value, style: const TextStyle(
              color: Colors.white, fontSize: 17,
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(
              color: Color(0xFFCBD5E1), fontSize: 11,
            )),
          ],
        ),
      ),
    );
  }

  Widget quickAction(String title, IconData icon, String module) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () {
        if (title == 'Add Product') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProductFormScreen(),
            ),
          );
        } else {
          openNamedModule(module);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 25),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        title: const Text('OmniBizCRM',
          style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => openNamedModule('Customer Notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refresh,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: dashboardData,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Database error: ${snapshot.error}',
                style: const TextStyle(color: Colors.redAccent)),
            ));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final today = data['today'] as Map<String, dynamic>;
          final selected = data['selected'] as Map<String, dynamic>;
          final all = data['all'] as Map<String, dynamic>;

          final cards = <Map<String, dynamic>>[
            {'n':'Total Sale','v':money(selected['sales']),'i':Icons.trending_up,'c':Colors.blue},
            {'n':'Total Products','v':'${selected['products']}','i':Icons.inventory_2,'c':Colors.purple},
            {'n':'Total Stock Value','v':money(selected['stockValue']),'i':Icons.warehouse,'c':Colors.teal},
            {'n':'Total Baqaya Udhaar','v':money(all['remaining']),'i':Icons.account_balance_wallet,'c':Colors.red},
            {'n':'Total Jama Raqam','v':money(all['paid']),'i':Icons.payments,'c':Colors.green},
            {'n':"Today's Wasooli",'v':money(data['collection']),'i':Icons.handshake,'c':Colors.cyan},
            {'n':"Today's Udhaar",'v':money(today['remaining']),'i':Icons.menu_book,'c':Colors.orange},
            {'n':'Total Customers','v':'${selected['customers']}','i':Icons.people,'c':Colors.blueAccent},
            {'n':"Today's Expenses",'v':money(today['expenses']),'i':Icons.receipt_long,'c':Colors.deepOrange},
            {'n':"Today's Profit",'v':money(today['profit']),'i':Icons.show_chart,'c':Colors.lightGreen},
            {'n':'Total Purchases','v':'—','i':Icons.shopping_bag,'c':Colors.purpleAccent},
            {'n':'Cash in Hand','v':'—','i':Icons.wallet,'c':Colors.amber},
            {'n':'Bank Balance','v':'—','i':Icons.account_balance,'c':Colors.lightBlue},
            {'n':'Cash Sales','v':'—','i':Icons.money,'c':Colors.green},
            {'n':'Credit Sales','v':money(data['credit']),'i':Icons.book,'c':Colors.pink},
            {'n':'Total Suppliers','v':'${data['suppliers']}','i':Icons.local_shipping,'c':Colors.blueGrey},
            {'n':'Pending Payments','v':money(data['supplierBalance']),'i':Icons.pending_actions,'c':Colors.redAccent},
          ];

          final actions = <Map<String, dynamic>>[
            {'n':'New Sale','i':Icons.point_of_sale,'m':'New Sale'},
            {'n':'Add Customer','i':Icons.person_add,'m':'Customers'},
            {'n':'Add Product','i':Icons.add_box,'m':'Products'},
            {'n':'Add Expense','i':Icons.receipt,'m':'Expenses'},
            {'n':'Cash Book','i':Icons.menu_book,'m':'Accounting & Cashbook'},
            {'n':'Naya Khata','i':Icons.menu_book,'m':'Khata'},
            {'n':'Earning & Summary','i':Icons.bar_chart,'m':'Reports & Profit & Loss'},
            {'n':'Scan Barcode','i':Icons.qr_code_scanner,'m':'Barcode Generate & Labels'},
            {'n':'Reports','i':Icons.bar_chart,'m':'Reports & Profit & Loss'},
          ];

          return RefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF123B42),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WELCOME TO OMNIBIZCRM',
                        style: TextStyle(color: Color(0xFF7EEAD5), fontSize: 11)),
                      SizedBox(height: 7),
                      Text('Apna Hisab Apne Pas',
                        style: TextStyle(color: Colors.white,
                          fontSize: 19, fontWeight: FontWeight.bold)),
                      Text('Manage your complete business in one place',
                        style: TextStyle(color: Color(0xFFC1E7E1), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: panel, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Sale",
                        style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(money(selected['sales']),
                        style: const TextStyle(color: Colors.white,
                          fontSize: 23, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 5, children: [
                        for (final p in ['Today','Weekly','Monthly','Year','All Time'])
                          ChoiceChip(
                            label: Text(p, style: const TextStyle(fontSize: 11)),
                            selected: period == p,
                            onSelected: (_) {
                              setState(() {
                                period = p;
                                dashboardData = loadData();
                              });
                            },
                          ),
                      ]),
                    ],
                  ),
                ),
                heading('Business Overview'),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cards.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 9,
                    crossAxisSpacing: 9, childAspectRatio: 1.55,
                  ),
                  itemBuilder: (_, i) {
                    final c = cards[i];
                    return overviewCard(c['n'], c['v'], c['i'], c['c']);
                  },
                ),
                heading('Quick Actions'),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: actions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, mainAxisSpacing: 8,
                    crossAxisSpacing: 8, childAspectRatio: 1.15,
                  ),
                  itemBuilder: (_, i) {
                    final a = actions[i];
                    return quickAction(a['n'], a['i'], a['m']);
                  },
                ),
                Row(children: [
                  Expanded(child: heading('Main Menu')),
                  const Text('39 Modules',
                    style: TextStyle(color: accent, fontSize: 12)),
                ]),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.modules.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (_, i) {
                    final module = widget.modules[i];
                    return InkWell(
                      onTap: () => widget.onOpenModule(context, module),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: panel,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(module.icon, color: accent, size: 26),
                            const SizedBox(height: 6),
                            Text(
                              module.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                heading('Quick Summary'),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: panel, borderRadius: BorderRadius.circular(15)),
                  child: Column(children: [
                    summaryRow('Total Udhaar', money(all['sales'])),
                    summaryRow('Total Wasooli', money(all['paid'])),
                    summaryRow('Total Baqaya', money(all['remaining'])),
                  ]),
                ),
                heading('Complete Bill History'),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: panel, borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      Row(children: [
                        const Expanded(child: Text('Recent Bills',
                          style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold))),
                        TextButton(
                          onPressed: () => openNamedModule('Bills & Printers'),
                          child: const Text('View All'),
                        ),
                      ]),
                      if ((data['bills'] as List).isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(18),
                          child: Text('No bill records yet',
                            style: TextStyle(color: muted)),
                        ),
                      for (final bill in data['bills'])
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFF334155)))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text('${bill['bill_number']}',
                                  style: const TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                                Text(money(bill['total']),
                                  style: const TextStyle(color: Colors.white)),
                              ]),
                              const SizedBox(height: 4),
                              Text('${bill['customer_name']} • ${bill['sale_date']}',
                                style: const TextStyle(color: muted, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text('Paid: ${money(bill['paid'])}   Remaining: ${money(bill['remaining'])}   ${bill['payment_status']}',
                                style: const TextStyle(color: Color(0xFF7EEAD5), fontSize: 11)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Center(child: Text('OmniBizCRM • Business Management',
                  style: TextStyle(color: muted, fontSize: 11))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget summaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text(title,
          style: const TextStyle(color: Color(0xFFE2E8F0)))),
        Text(value, style: const TextStyle(color: Colors.white,
          fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
