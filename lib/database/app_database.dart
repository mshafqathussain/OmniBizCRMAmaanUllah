import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'omnibizcrm.db');

    _database = await openDatabase(
      path,
      version: 15,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        final batch = db.batch();

        batch.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            mobile TEXT,
            whatsapp TEXT,
            cnic TEXT,
            address TEXT,
            email TEXT,
            business_name TEXT,
            additional_contact TEXT,
            opening_balance REAL NOT NULL DEFAULT 0,
            notes TEXT,
            created_at TEXT NOT NULL
        )
        ''');

        batch.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            barcode TEXT,
            sku TEXT,
            category TEXT,
            brand TEXT,
            purchase_price REAL NOT NULL DEFAULT 0,
            sale_price REAL NOT NULL DEFAULT 0,
            tax_percent REAL NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'Active',
            description TEXT,
            quantity REAL NOT NULL DEFAULT 0,
            min_stock REAL NOT NULL DEFAULT 0,
            unit TEXT NOT NULL DEFAULT 'pcs',
            image_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        batch.execute('''
          CREATE TABLE product_categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL COLLATE NOCASE UNIQUE,
            created_at TEXT NOT NULL
          )
        ''');

        batch.execute('''
          CREATE TABLE measurement_units (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL COLLATE NOCASE UNIQUE,
            created_at TEXT NOT NULL
          )
        ''');

        for (final finalUnit in [
          'Kg',
          'Gram',
          'Litre',
          'ML',
          'Piece',
          'Packet',
          'Dozen',
          'Box',
          'Plate',
        ]) {
          batch.execute(
            'INSERT OR IGNORE INTO measurement_units (name, created_at) VALUES (?, ?)',
            [finalUnit, DateTime.now().toIso8601String()],
          );
        }

        batch.execute('''
          CREATE TABLE suppliers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            mobile TEXT,
            address TEXT,
            balance REAL NOT NULL DEFAULT 0,
            company_name TEXT,
            whatsapp TEXT,
            email TEXT,
            cnic_ntn TEXT,
            city TEXT,
            country TEXT,
            contact_person TEXT,
            supplier_category TEXT,
            credit_limit REAL NOT NULL DEFAULT 0,
            payment_terms TEXT,
            bank_name TEXT,
            bank_account TEXT,
            bank_iban TEXT,
            status TEXT NOT NULL DEFAULT 'Active',
            notes TEXT,
            photo_path TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        batch.execute('''
          CREATE TABLE sales (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            bill_number TEXT NOT NULL UNIQUE,
            customer_id INTEGER,
            sale_date TEXT NOT NULL,
            subtotal REAL NOT NULL DEFAULT 0,
            discount REAL NOT NULL DEFAULT 0,
            tax REAL NOT NULL DEFAULT 0,
            reference_number TEXT,
            notes TEXT,
            total REAL NOT NULL DEFAULT 0,
            paid REAL NOT NULL DEFAULT 0,
            remaining REAL NOT NULL DEFAULT 0,
            payment_status TEXT NOT NULL DEFAULT 'Unpaid',
            FOREIGN KEY (customer_id) REFERENCES customers(id)
          )
        ''');

        batch.execute('''
          CREATE TABLE sale_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sale_id INTEGER NOT NULL,
            product_id INTEGER,
            product_name TEXT NOT NULL,
            product_category TEXT,
            unit TEXT NOT NULL DEFAULT 'pcs',
            quantity REAL NOT NULL,
            price REAL NOT NULL,
            cost_price REAL NOT NULL DEFAULT 0,
            total REAL NOT NULL,
            FOREIGN KEY (sale_id) REFERENCES sales(id),
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        batch.execute('''
          CREATE TABLE payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER,
            sale_id INTEGER,
            amount REAL NOT NULL,
            payment_type TEXT NOT NULL,
            payment_method TEXT,
            payment_date TEXT NOT NULL,
            note TEXT,
            FOREIGN KEY (customer_id) REFERENCES customers(id),
            FOREIGN KEY (sale_id) REFERENCES sales(id)
          )
        ''');

        batch.execute('''
          CREATE TABLE expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            category TEXT NOT NULL,
            description TEXT,
            amount REAL NOT NULL,
            payment_method TEXT,
            expense_date TEXT NOT NULL,
            paid_to TEXT,
            reference_number TEXT
          )
        ''');

        batch.execute('''
          CREATE TABLE stock_movements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER NOT NULL,
            movement_type TEXT NOT NULL,
            quantity REAL NOT NULL,
            note TEXT,
            movement_date TEXT NOT NULL,
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        batch.execute('CREATE INDEX idx_sales_date ON sales(sale_date)');
        batch.execute(
          'CREATE INDEX idx_payments_customer ON payments(customer_id)',
        );
        batch.execute(
          'CREATE INDEX idx_expenses_date ON expenses(expense_date)',
        );

        batch.execute('''
          CREATE TABLE sale_returns (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            return_number TEXT NOT NULL UNIQUE,
            refund_id TEXT NOT NULL UNIQUE,
            sale_id INTEGER NOT NULL,
            customer_id INTEGER,
            return_date TEXT NOT NULL,
            total_amount REAL NOT NULL DEFAULT 0,
            refund_method TEXT NOT NULL,
            reason TEXT,
            status TEXT NOT NULL DEFAULT 'Pending',
            requester_id TEXT,
            processor_id TEXT,
            approver_id TEXT,
            FOREIGN KEY (sale_id) REFERENCES sales(id),
            FOREIGN KEY (customer_id) REFERENCES customers(id)
          )
        ''');

        batch.execute('''
          CREATE TABLE sale_return_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            return_id INTEGER NOT NULL,
            sale_item_id INTEGER NOT NULL,
            product_id INTEGER,
            product_name TEXT NOT NULL,
            sold_quantity REAL NOT NULL,
            previously_returned_quantity REAL NOT NULL DEFAULT 0,
            return_quantity REAL NOT NULL,
            unit_price REAL NOT NULL,
            item_condition TEXT NOT NULL,
            stock_restored INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (return_id) REFERENCES sale_returns(id),
            FOREIGN KEY (sale_item_id) REFERENCES sale_items(id),
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        batch.execute('''
          CREATE TABLE refund_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            refund_id TEXT NOT NULL UNIQUE,
            return_id INTEGER NOT NULL,
            sale_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            method TEXT NOT NULL,
            reason TEXT,
            status TEXT NOT NULL DEFAULT 'Pending',
            created_at TEXT NOT NULL,
            completed_at TEXT,
            verified_by TEXT,
            payment_reference TEXT,
            FOREIGN KEY (return_id) REFERENCES sale_returns(id),
            FOREIGN KEY (sale_id) REFERENCES sales(id)
          )
        ''');

        batch.execute('''
          CREATE TABLE refund_audit (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            return_id INTEGER NOT NULL,
            refund_id TEXT NOT NULL,
            action TEXT NOT NULL,
            amount REAL NOT NULL DEFAULT 0,
            method TEXT,
            actor_id TEXT,
            event_time TEXT NOT NULL,
            notes TEXT,
            FOREIGN KEY (return_id) REFERENCES sale_returns(id)
          )
        ''');

        batch.execute('''
          CREATE TABLE damaged_stock (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            return_id INTEGER NOT NULL,
            return_item_id INTEGER NOT NULL UNIQUE,
            product_id INTEGER,
            product_name TEXT NOT NULL,
            quantity REAL NOT NULL,
            recorded_at TEXT NOT NULL,
            notes TEXT,
            FOREIGN KEY (return_id) REFERENCES sale_returns(id),
            FOREIGN KEY (return_item_id) REFERENCES sale_return_items(id),
            FOREIGN KEY (product_id) REFERENCES products(id)
          )
        ''');

        batch.execute('''
          CREATE TABLE sale_return_drafts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            draft_number TEXT NOT NULL UNIQUE,
            invoice_number TEXT,
            form_data TEXT NOT NULL DEFAULT '{}',
            status TEXT NOT NULL DEFAULT 'Draft',
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        batch.execute(
          'CREATE INDEX idx_sale_returns_sale ON sale_returns(sale_id)',
        );
        batch.execute(
          'CREATE INDEX idx_refunds_status ON refund_transactions(status)',
        );

        batch.execute('''
          CREATE TABLE IF NOT EXISTS module_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            module_key TEXT NOT NULL,
            title TEXT NOT NULL,
            form_data TEXT NOT NULL DEFAULT '{}',
            amount REAL NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'Saved',
            record_date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT
          )
        ''');

        batch.execute('''
          CREATE INDEX IF NOT EXISTS idx_module_records_key_date
          ON module_records(module_key, record_date)
        ''');

        await batch.commit(noResult: true);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE sale_items ADD COLUMN product_category TEXT",
          );
          await db.execute(
            "ALTER TABLE sale_items ADD COLUMN unit TEXT NOT NULL DEFAULT 'pcs'",
          );
          await db.execute('''
            UPDATE sale_items
            SET
              product_category = (
                SELECT category FROM products
                WHERE products.id = sale_items.product_id
              ),
              unit = COALESCE((
                SELECT unit FROM products
                WHERE products.id = sale_items.product_id
              ), 'pcs')
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
        }

        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE product_categories (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL COLLATE NOCASE UNIQUE,
              created_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE measurement_units (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL COLLATE NOCASE UNIQUE,
              created_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            INSERT OR IGNORE INTO product_categories (name, created_at)
            SELECT DISTINCT TRIM(category), CURRENT_TIMESTAMP
            FROM products
            WHERE category IS NOT NULL AND TRIM(category) != ''
          ''');

          await db.execute('''
            INSERT OR IGNORE INTO measurement_units (name, created_at)
            SELECT DISTINCT TRIM(unit), CURRENT_TIMESTAMP
            FROM products
            WHERE unit IS NOT NULL AND TRIM(unit) != ''
          ''');

          for (final finalUnit in [
            'Kg',
            'Gram',
            'Litre',
            'ML',
            'Piece',
            'Packet',
            'Dozen',
            'Box',
            'Plate',
          ]) {
            await db.insert('measurement_units', {
              'name': finalUnit,
              'created_at': DateTime.now().toIso8601String(),
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE sales ADD COLUMN tax REAL NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE sales ADD COLUMN reference_number TEXT',
          );
          await db.execute('ALTER TABLE sales ADD COLUMN notes TEXT');
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE customers ADD COLUMN whatsapp TEXT');
          await db.execute('ALTER TABLE customers ADD COLUMN cnic TEXT');
          await db.execute('ALTER TABLE customers ADD COLUMN email TEXT');
          await db.execute(
            'ALTER TABLE customers ADD COLUMN business_name TEXT',
          );
          await db.execute(
            'ALTER TABLE customers ADD COLUMN additional_contact TEXT',
          );
          await db.execute('ALTER TABLE customers ADD COLUMN notes TEXT');
        }

        if (oldVersion < 7) {
          await db.execute('''
            CREATE TABLE sale_returns (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              return_number TEXT NOT NULL UNIQUE,
              refund_id TEXT NOT NULL UNIQUE,
              sale_id INTEGER NOT NULL,
              customer_id INTEGER,
              return_date TEXT NOT NULL,
              total_amount REAL NOT NULL DEFAULT 0,
              refund_method TEXT NOT NULL,
              reason TEXT,
              status TEXT NOT NULL DEFAULT 'Pending',
              requester_id TEXT,
              processor_id TEXT,
              approver_id TEXT,
              FOREIGN KEY (sale_id) REFERENCES sales(id),
              FOREIGN KEY (customer_id) REFERENCES customers(id)
            )
          ''');

          await db.execute('''
            CREATE TABLE sale_return_items (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              return_id INTEGER NOT NULL,
              sale_item_id INTEGER NOT NULL,
              product_id INTEGER,
              product_name TEXT NOT NULL,
              sold_quantity REAL NOT NULL,
              previously_returned_quantity REAL NOT NULL DEFAULT 0,
              return_quantity REAL NOT NULL,
              unit_price REAL NOT NULL,
              item_condition TEXT NOT NULL,
              stock_restored INTEGER NOT NULL DEFAULT 0,
              FOREIGN KEY (return_id) REFERENCES sale_returns(id),
              FOREIGN KEY (sale_item_id) REFERENCES sale_items(id),
              FOREIGN KEY (product_id) REFERENCES products(id)
            )
          ''');

          await db.execute('''
            CREATE TABLE refund_transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              refund_id TEXT NOT NULL UNIQUE,
              return_id INTEGER NOT NULL,
              sale_id INTEGER NOT NULL,
              amount REAL NOT NULL,
              method TEXT NOT NULL,
              reason TEXT,
              status TEXT NOT NULL DEFAULT 'Pending',
              created_at TEXT NOT NULL,
              completed_at TEXT,
              verified_by TEXT,
              payment_reference TEXT,
              FOREIGN KEY (return_id) REFERENCES sale_returns(id),
              FOREIGN KEY (sale_id) REFERENCES sales(id)
            )
          ''');

          await db.execute('''
            CREATE TABLE refund_audit (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              return_id INTEGER NOT NULL,
              refund_id TEXT NOT NULL,
              action TEXT NOT NULL,
              amount REAL NOT NULL DEFAULT 0,
              method TEXT,
              actor_id TEXT,
              event_time TEXT NOT NULL,
              notes TEXT,
              FOREIGN KEY (return_id) REFERENCES sale_returns(id)
            )
          ''');

          await db.execute(
            'CREATE INDEX idx_sale_returns_sale ON sale_returns(sale_id)',
          );
          await db.execute(
            'CREATE INDEX idx_refunds_status ON refund_transactions(status)',
          );
        }

        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE damaged_stock (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              return_id INTEGER NOT NULL,
              return_item_id INTEGER NOT NULL UNIQUE,
              product_id INTEGER,
              product_name TEXT NOT NULL,
              quantity REAL NOT NULL,
              recorded_at TEXT NOT NULL,
              notes TEXT,
              FOREIGN KEY (return_id) REFERENCES sale_returns(id),
              FOREIGN KEY (return_item_id) REFERENCES sale_return_items(id),
              FOREIGN KEY (product_id) REFERENCES products(id)
            )
          ''');
        }
        if (oldVersion < 9) {
          await db.execute('''
            CREATE TABLE sale_return_drafts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              draft_number TEXT NOT NULL UNIQUE,
              invoice_number TEXT,
              form_data TEXT NOT NULL DEFAULT '{}',
              status TEXT NOT NULL DEFAULT 'Draft',
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }

        if (oldVersion < 10) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS module_records (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              module_key TEXT NOT NULL,
              title TEXT NOT NULL,
              form_data TEXT NOT NULL DEFAULT '{}',
              amount REAL NOT NULL DEFAULT 0,
              status TEXT NOT NULL DEFAULT 'Saved',
              record_date TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT
            )
          ''');

          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_module_records_key_date
            ON module_records(module_key, record_date)
          ''');
        }

        if (oldVersion < 11) {
          final supplierColumns = [
            'company_name TEXT',
            'whatsapp TEXT',
            'email TEXT',
            'cnic_ntn TEXT',
            'city TEXT',
            'country TEXT',
            'contact_person TEXT',
            'supplier_category TEXT',
            'credit_limit REAL NOT NULL DEFAULT 0',
            'payment_terms TEXT',
            'bank_name TEXT',
            'bank_account TEXT',
            'bank_iban TEXT',
            "status TEXT NOT NULL DEFAULT 'Active'",
            'notes TEXT',
            'photo_path TEXT',
          ];

          for (final column in supplierColumns) {
            await db.execute('ALTER TABLE suppliers ADD COLUMN $column');
          }
        }

        if (oldVersion < 12) {
          await db.execute('ALTER TABLE expenses ADD COLUMN paid_to TEXT');
          await db.execute(
            'ALTER TABLE expenses ADD COLUMN reference_number TEXT',
          );
        }

        if (oldVersion < 13) {
          await db.execute('ALTER TABLE expenses ADD COLUMN title TEXT');
        }

        if (oldVersion < 14) {
          await db.execute('ALTER TABLE products ADD COLUMN brand TEXT');
          await db.execute(
            'ALTER TABLE products ADD COLUMN tax_percent REAL NOT NULL DEFAULT 0',
          );
          await db.execute(
            "ALTER TABLE products ADD COLUMN status TEXT NOT NULL DEFAULT 'Active'",
          );
          await db.execute('ALTER TABLE products ADD COLUMN description TEXT');
        }

        if (oldVersion < 15) {
          await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
        }
      },
    );

    return _database!;
  }

  Future<List<Map<String, dynamic>>> searchCustomers(String query) async {
    final db = await database;
    final q = query.trim();
    return db.query(
      'customers',
      where: q.isEmpty ? null : 'name LIKE ? OR mobile LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'name COLLATE NOCASE ASC',
      limit: 30,
    );
  }

  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final db = await database;
    final q = query.trim();
    return db.query(
      'products',
      where: q.isEmpty ? null : 'name LIKE ? OR sku LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%'],
      orderBy: 'name COLLATE NOCASE ASC',
      limit: 50,
    );
  }

  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await database;
    final code = barcode.trim();
    if (code.isEmpty) return null;

    final rows = await db.query(
      'products',
      where: 'LOWER(TRIM(barcode)) = LOWER(?) OR LOWER(TRIM(sku)) = LOWER(?)',
      whereArgs: [code, code],
      limit: 1,
    );

    return rows.isEmpty ? null : rows.first;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query('product_categories', orderBy: 'name COLLATE NOCASE ASC');
  }

  Future<List<Map<String, dynamic>>> getMeasurementUnits() async {
    final db = await database;
    return db.query('measurement_units', orderBy: 'name COLLATE NOCASE ASC');
  }

  Future<Map<String, dynamic>?> getCustomerById(int id) async {
    final databaseInstance = await database;
    final rows = await databaseInstance.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> addCustomer({
    required String name,
    String? mobile,
    String? whatsapp,
    String? cnic,
    String? address,
    String? email,
    String? businessName,
    String? additionalContact,
    double openingBalance = 0,
    String? notes,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Customer name is required');
    }
    if (!openingBalance.isFinite || openingBalance < 0) {
      throw ArgumentError('Invalid opening balance');
    }
    final db = await database;
    return db.insert('customers', {
      'name': cleanName,
      'mobile': mobile?.trim(),
      'whatsapp': whatsapp?.trim(),
      'cnic': cnic?.trim(),
      'address': address?.trim(),
      'email': email?.trim(),
      'business_name': businessName?.trim(),
      'additional_contact': additionalContact?.trim(),
      'opening_balance': openingBalance,
      'notes': notes?.trim(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getCustomers({String query = ''}) async {
    final db = await database;
    final q = query.trim();
    return db.query(
      'customers',
      where: q.isEmpty ? null : 'name LIKE ? OR mobile LIKE ? OR whatsapp LIKE ? OR email LIKE ? OR business_name LIKE ?',
      whereArgs: q.isEmpty ? null : List.filled(5, '%$q%'),
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  Future<int> updateCustomer({
    required int id,
    required String name,
    String? mobile,
    String? whatsapp,
    String? cnic,
    String? address,
    String? email,
    String? businessName,
    String? additionalContact,
    double openingBalance = 0,
    String? notes,
  }) async {
    final cleanName = name.trim();
    if (id <= 0 || cleanName.isEmpty) {
      throw ArgumentError('Valid customer ID and name are required');
    }
    if (!openingBalance.isFinite || openingBalance < 0) {
      throw ArgumentError('Invalid opening balance');
    }

    final db = await database;
    return db.update(
      'customers',
      {
        'name': cleanName,
        'mobile': mobile?.trim(),
        'whatsapp': whatsapp?.trim(),
        'cnic': cnic?.trim(),
        'address': address?.trim(),
        'email': email?.trim(),
        'business_name': businessName?.trim(),
        'additional_contact': additionalContact?.trim(),
        'opening_balance': openingBalance,
        'notes': notes?.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    if (id <= 0) {
      throw ArgumentError('Invalid customer ID');
    }

    final db = await database;
    return db.transaction((txn) async {
      final sales = await txn.rawQuery(
        'SELECT COUNT(*) AS total FROM sales WHERE customer_id = ?',
        [id],
      );
      final payments = await txn.rawQuery(
        'SELECT COUNT(*) AS total FROM payments WHERE customer_id = ?',
        [id],
      );

      final saleCount = (sales.first['total'] as num).toInt();
      final paymentCount = (payments.first['total'] as num).toInt();

      if (saleCount > 0 || paymentCount > 0) {
        throw StateError(
          'This customer has linked sales or payments and cannot be deleted.',
        );
      }

      return txn.delete('customers', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> saveSale({
    required List<Map<String, dynamic>> items,
    int? customerId,
    double discount = 0,
    double tax = 0,
    double paid = 0,
    String paymentMethod = 'Cash',
    String? referenceNumber,
    String? notes,
    DateTime? saleDate,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Sale must contain at least one item');
    }
    if (!discount.isFinite ||
        discount < 0 ||
        !tax.isFinite ||
        tax < 0 ||
        !paid.isFinite ||
        paid < 0) {
      throw ArgumentError('Invalid discount, tax or payment amount');
    }

    final db = await database;
    final now =
        (saleDate ?? DateTime.now().toUtc().add(const Duration(hours: 5)))
            .toIso8601String();

    return db.transaction((txn) async {
      if (customerId != null) {
        final customer = await txn.query(
          'customers',
          where: 'id = ?',
          whereArgs: [customerId],
          limit: 1,
        );
        if (customer.isEmpty) {
          throw StateError('Selected customer does not exist');
        }
      }

      final preparedItems = <Map<String, dynamic>>[];
      double subtotal = 0;

      for (final item in items) {
        final quantity = (item['quantity'] as num?)?.toDouble();
        final price = (item['price'] as num?)?.toDouble();
        final rawProductId = item['productId'];
        final productId = rawProductId == null
            ? null
            : (rawProductId as num).toInt();

        if (quantity == null ||
            !quantity.isFinite ||
            quantity <= 0 ||
            price == null ||
            !price.isFinite ||
            price < 0) {
          throw ArgumentError('Invalid item quantity or price');
        }

        String productName;
        String? category;
        String unit;
        double costPrice;

        if (productId != null) {
          final products = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [productId],
            limit: 1,
          );

          if (products.isEmpty) {
            throw StateError('A selected product no longer exists');
          }

          final product = products.first;
          final stock = (product['quantity'] as num).toDouble();

          if (stock < quantity) {
            throw StateError(
              'Insufficient stock for ${product['name']}. Available: $stock',
            );
          }

          productName = product['name'] as String;
          category = product['category'] as String?;
          unit = product['unit'] as String? ?? 'pcs';
          costPrice = (product['purchase_price'] as num).toDouble();
        } else {
          productName = (item['productName'] as String? ?? '').trim();
          if (productName.isEmpty) {
            throw ArgumentError('Manual item name is required');
          }
          category = item['category'] as String?;
          unit = (item['unit'] as String? ?? 'pcs').trim();
          costPrice = 0;
        }

        final lineTotal = quantity * price;
        if (!lineTotal.isFinite) {
          throw ArgumentError('Item total is too large');
        }

        subtotal += lineTotal;
        if (!subtotal.isFinite) {
          throw ArgumentError('Sale subtotal is too large');
        }

        preparedItems.add({
          'product_id': productId,
          'product_name': productName,
          'product_category': category,
          'unit': unit,
          'quantity': quantity,
          'price': price,
          'cost_price': costPrice,
          'total': lineTotal,
        });
      }

      if (discount > subtotal) {
        throw ArgumentError('Discount cannot exceed subtotal');
      }

      final total = subtotal - discount + tax;
      if (!total.isFinite || paid > total) {
        throw ArgumentError('Paid amount cannot exceed bill total');
      }

      final remaining = total - paid;

      if (remaining > 0.000001 && customerId == null) {
        throw ArgumentError(
          'A customer is required for unpaid or partially paid sales.',
        );
      }

      final status = remaining <= 0.000001
          ? 'Paid'
          : paid > 0
          ? 'Partial'
          : 'Unpaid';

      final temporaryBillNumber =
          'PENDING-${DateTime.now().microsecondsSinceEpoch}';

      final saleId = await txn.insert('sales', {
        'bill_number': temporaryBillNumber,
        'customer_id': customerId,
        'sale_date': now,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'reference_number': referenceNumber?.trim(),
        'notes': notes?.trim(),
        'total': total,
        'paid': paid,
        'remaining': remaining,
        'payment_status': status,
      });

      final billNumber = 'OB-${saleId.toString().padLeft(6, '0')}';
      await txn.update(
        'sales',
        {'bill_number': billNumber},
        where: 'id = ?',
        whereArgs: [saleId],
      );

      for (final item in preparedItems) {
        await txn.insert('sale_items', {'sale_id': saleId, ...item});

        final productId = item['product_id'] as int?;
        if (productId != null) {
          final quantity = item['quantity'] as double;

          final stockUpdated = await txn.rawUpdate(
            'UPDATE products SET quantity = quantity - ? '
            'WHERE id = ? AND quantity >= ?',
            [quantity, productId, quantity],
          );

          if (stockUpdated != 1) {
            throw StateError(
              'Insufficient stock or stock update failed for product ID $productId',
            );
          }

          await txn.insert('stock_movements', {
            'product_id': productId,
            'movement_type': 'Sale',
            'quantity': -quantity,
            'note': 'Sold in bill $billNumber',
            'movement_date': now,
          });
        }
      }

      if (paid > 0) {
        await txn.insert('payments', {
          'customer_id': customerId,
          'sale_id': saleId,
          'amount': paid,
          'payment_type': 'Sale Payment',
          'payment_method': paymentMethod,
          'payment_date': now,
          'note': 'Initial payment for $billNumber',
        });
      }

      return saleId;
    });
  }

  Future<int> receivePayment({
    required int saleId,
    required double amount,
    String paymentMethod = 'Cash',
    String? note,
    DateTime? paymentDate,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }

    return database.then((db) async {
      return db.transaction((txn) async {
        final rows = await txn.query(
          'sales',
          where: 'id = ?',
          whereArgs: [saleId],
          limit: 1,
        );

        if (rows.isEmpty) {
          throw StateError('Sale not found.');
        }

        final sale = rows.first;
        final total = (sale['total'] as num).toDouble();
        final oldPaid = (sale['paid'] as num).toDouble();
        final remaining = (sale['remaining'] as num).toDouble();

        if (remaining <= 0) {
          throw StateError('This sale is already fully paid.');
        }

        if (amount > remaining) {
          throw StateError('Payment cannot exceed the remaining balance.');
        }

        final newPaid = oldPaid + amount;
        final newRemaining = (remaining - amount).clamp(0.0, total).toDouble();
        final status = newRemaining == 0 ? 'Paid' : 'Partial';
        final date = (paymentDate ?? DateTime.now()).toIso8601String();

        final updated = await txn.update(
          'sales',
          {
            'paid': newPaid,
            'remaining': newRemaining,
            'payment_status': status,
          },
          where: 'id = ? AND remaining = ?',
          whereArgs: [saleId, remaining],
        );

        if (updated != 1) {
          throw StateError('Sale balance update failed.');
        }

        return txn.insert('payments', {
          'customer_id': sale['customer_id'],
          'sale_id': saleId,
          'amount': amount,
          'payment_type': 'Received Payment',
          'payment_method': paymentMethod,
          'payment_date': date,
          'note': note,
        });
      });
    });
  }

  Future<Map<String, dynamic>?> getSaleDetails(int saleId) async {
    final db = await database;
    final saleRows = await db.rawQuery(
      '''
      SELECT sales.*, customers.name AS customer_name,
             customers.mobile AS customer_mobile,
             customers.address AS customer_address
      FROM sales
      LEFT JOIN customers ON customers.id = sales.customer_id
      WHERE sales.id = ?
    ''',
      [saleId],
    );
    if (saleRows.isEmpty) return null;

    final items = await db.query(
      'sale_items',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'id ASC',
    );
    final payments = await db.query(
      'payments',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'id ASC',
    );

    return {'sale': saleRows.first, 'items': items, 'payments': payments};
  }

  Future<Map<String, dynamic>> saveSaleReturnDraft({
    int? draftId,
    String? invoiceNumber,
    required Map<String, dynamic> formData,
  }) async {
    final db = await database;
    final now = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 5))
        .toIso8601String();
    final encoded = jsonEncode(formData);
    final invoice = invoiceNumber?.trim();

    return db.transaction((txn) async {
      if (draftId != null) {
        final existing = await txn.query(
          'sale_return_drafts',
          where: 'id = ?',
          whereArgs: [draftId],
          limit: 1,
        );

        if (existing.isEmpty) {
          throw StateError('Draft not found.');
        }

        await txn.update(
          'sale_return_drafts',
          {
            'invoice_number': invoice?.isEmpty == true ? null : invoice,
            'form_data': encoded,
            'updated_at': now,
          },
          where: 'id = ?',
          whereArgs: [draftId],
        );

        return {
          'id': draftId,
          'draft_number': existing.first['draft_number'],
          'status': 'Draft',
        };
      }

      final stamp = DateTime.now().microsecondsSinceEpoch;
      final draftNumber = 'DRF-$stamp';

      final id = await txn.insert('sale_return_drafts', {
        'draft_number': draftNumber,
        'invoice_number': invoice?.isEmpty == true ? null : invoice,
        'form_data': encoded,
        'status': 'Draft',
        'created_at': now,
        'updated_at': now,
      });

      return {'id': id, 'draft_number': draftNumber, 'status': 'Draft'};
    });
  }

  Future<List<Map<String, dynamic>>> getSaleReturnDrafts() async {
    final db = await database;
    final rows = await db.query(
      'sale_return_drafts',
      where: "status = 'Draft'",
      orderBy: 'updated_at DESC',
    );

    return rows.map((row) {
      final result = Map<String, dynamic>.from(row);
      result['form_data'] = Map<String, dynamic>.from(
        jsonDecode(row['form_data'] as String) as Map,
      );
      return result;
    }).toList();
  }

  Future<Map<String, dynamic>?> getSaleReturnDraft(int draftId) async {
    final db = await database;
    final rows = await db.query(
      'sale_return_drafts',
      where: "id = ? AND status = 'Draft'",
      whereArgs: [draftId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final result = Map<String, dynamic>.from(rows.first);
    result['form_data'] = Map<String, dynamic>.from(
      jsonDecode(rows.first['form_data'] as String) as Map,
    );
    return result;
  }

  Future<int> deleteSaleReturnDraft(int draftId) async {
    final db = await database;
    return db.delete(
      'sale_return_drafts',
      where: "id = ? AND status = 'Draft'",
      whereArgs: [draftId],
    );
  }

  Future<Map<String, dynamic>?> getSaleForReturn(String invoiceNumber) async {
    final db = await database;
    final invoice = invoiceNumber.trim();
    if (invoice.isEmpty) return null;

    final sales = await db.rawQuery(
      '''
      SELECT sales.*,
             customers.name AS customer_name,
             customers.mobile AS customer_mobile
      FROM sales
      LEFT JOIN customers ON customers.id = sales.customer_id
      WHERE sales.bill_number = ? COLLATE NOCASE
      LIMIT 1
    ''',
      [invoice],
    );

    if (sales.isEmpty) return null;
    final sale = sales.first;
    final saleId = sale['id'] as int;

    final items = await db.rawQuery(
      '''
      SELECT sale_items.*,
        COALESCE((
          SELECT SUM(sri.return_quantity)
          FROM sale_return_items sri
          INNER JOIN sale_returns sr ON sr.id = sri.return_id
          WHERE sri.sale_item_id = sale_items.id
            AND sr.status NOT IN ('Rejected', 'Cancelled')
        ), 0) AS previously_returned_quantity
      FROM sale_items
      WHERE sale_items.sale_id = ?
      ORDER BY id ASC
    ''',
      [saleId],
    );

    final returnItems = items.map((item) {
      final sold = (item['quantity'] as num).toDouble();
      final returned = (item['previously_returned_quantity'] as num).toDouble();
      return {
        ...item,
        'available_return_quantity': (sold - returned).clamp(0.0, sold),
      };
    }).toList();

    return {'sale': sale, 'items': returnItems};
  }

  Future<Map<String, dynamic>> createSaleReturnRequest({
    required String invoiceNumber,
    required List<Map<String, dynamic>> items,
    required String refundMethod,
    String? reason,
    String? requesterId,
  }) async {
    final invoice = invoiceNumber.trim();
    final method = refundMethod.trim();

    if (invoice.isEmpty) {
      throw ArgumentError('Invoice number is required.');
    }
    if (items.isEmpty) {
      throw ArgumentError('At least one return item is required.');
    }
    if (method.isEmpty) {
      throw ArgumentError('Refund method is required.');
    }

    final db = await database;
    final now = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 5))
        .toIso8601String();

    return db.transaction((txn) async {
      final sales = await txn.query(
        'sales',
        where: 'bill_number = ? COLLATE NOCASE',
        whereArgs: [invoice],
        limit: 1,
      );

      if (sales.isEmpty) {
        throw StateError('Original sale invoice was not found.');
      }

      final sale = sales.first;
      final saleId = (sale['id'] as num).toInt();

      final soldItems = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );

      final soldById = <int, Map<String, dynamic>>{};
      for (final soldItem in soldItems) {
        soldById[(soldItem['id'] as num).toInt()] = soldItem;
      }

      final seenItemIds = <int>{};
      final preparedItems = <Map<String, dynamic>>[];
      double returnedGross = 0;

      final originalSubtotal = (sale['subtotal'] as num).toDouble();
      final originalDiscount = (sale['discount'] as num).toDouble();
      final originalTax = (sale['tax'] as num).toDouble();

      if (originalSubtotal <= 0 ||
          !originalSubtotal.isFinite ||
          !originalDiscount.isFinite ||
          !originalTax.isFinite) {
        throw StateError('Original sale totals are invalid.');
      }

      for (final entry in items) {
        final rawId = entry['sale_item_id'];
        final rawQuantity = entry['return_quantity'];

        if (rawId is! num || rawQuantity is! num) {
          throw ArgumentError('Invalid return item data.');
        }

        final saleItemId = rawId.toInt();
        final quantity = rawQuantity.toDouble();
        final condition = (entry['item_condition'] ?? '').toString().trim();

        if (!quantity.isFinite || quantity <= 0) {
          throw ArgumentError('Return quantity must be greater than zero.');
        }
        if (condition.isEmpty) {
          throw ArgumentError('Item condition is required.');
        }
        if (!seenItemIds.add(saleItemId)) {
          throw ArgumentError('Duplicate sale item in return request.');
        }

        final soldItem = soldById[saleItemId];
        if (soldItem == null) {
          throw ArgumentError('Return item does not belong to this invoice.');
        }

        final soldQuantity = (soldItem['quantity'] as num).toDouble();

        final previousRows = await txn.rawQuery(
          """
          SELECT COALESCE(SUM(sri.return_quantity), 0) AS returned
          FROM sale_return_items sri
          INNER JOIN sale_returns sr ON sr.id = sri.return_id
          WHERE sri.sale_item_id = ?
            AND sr.status NOT IN ('Rejected', 'Cancelled')
        """,
          [saleItemId],
        );

        final previouslyReturned = (previousRows.first['returned'] as num)
            .toDouble();

        final available = (soldQuantity - previouslyReturned).clamp(
          0.0,
          soldQuantity,
        );

        if (quantity > available + 0.000001) {
          throw StateError(
            'Return quantity exceeds available quantity for '
            '${soldItem['product_name']}. Available: $available',
          );
        }

        final unitPrice = (soldItem['price'] as num).toDouble();
        final lineTotal = quantity * unitPrice;

        if (!lineTotal.isFinite) {
          throw ArgumentError('Return amount is too large.');
        }

        returnedGross += lineTotal;
        if (!returnedGross.isFinite) {
          throw ArgumentError('Total return amount is too large.');
        }

        preparedItems.add({
          'sale_item_id': saleItemId,
          'product_id': soldItem['product_id'],
          'product_name': soldItem['product_name'],
          'sold_quantity': soldQuantity,
          'previously_returned_quantity': previouslyReturned,
          'return_quantity': quantity,
          'unit_price': unitPrice,
          'item_condition': condition,
        });
      }

      final returnRatio = returnedGross / originalSubtotal;
      final allocatedDiscount = originalDiscount * returnRatio;
      final allocatedTax = originalTax * returnRatio;
      final totalAmount = (returnedGross - allocatedDiscount + allocatedTax)
          .clamp(0.0, returnedGross + allocatedTax)
          .toDouble();

      if (!totalAmount.isFinite) {
        throw ArgumentError('Calculated refund amount is invalid.');
      }

      final previousRefundRows = await txn.rawQuery(
        "SELECT COALESCE(SUM(total_amount), 0) AS refunded "
        "FROM sale_returns WHERE sale_id = ? "
        "AND status NOT IN ('Rejected', 'Cancelled')",
        [saleId],
      );
      final previousRefunded = (previousRefundRows.first['refunded'] as num)
          .toDouble();
      final remainingRefund =
          ((sale['total'] as num).toDouble() - previousRefunded).clamp(
            0.0,
            double.infinity,
          );

      if (totalAmount > remainingRefund + 0.000001) {
        throw StateError(
          'Refund exceeds remaining refundable bill amount: $remainingRefund',
        );
      }

      final stamp = DateTime.now().microsecondsSinceEpoch;
      final returnNumber = 'RET-$stamp';
      final refundId = 'REF-$stamp';
      final cleanReason = reason?.trim();

      final returnId = await txn.insert('sale_returns', {
        'return_number': returnNumber,
        'refund_id': refundId,
        'sale_id': saleId,
        'customer_id': sale['customer_id'],
        'return_date': now,
        'total_amount': totalAmount,
        'refund_method': method,
        'reason': cleanReason,
        'status': 'Pending',
        'requester_id': requesterId,
      });

      for (final item in preparedItems) {
        await txn.insert('sale_return_items', {
          'return_id': returnId,
          ...item,
          'stock_restored': 0,
        });
      }

      await txn.insert('refund_transactions', {
        'refund_id': refundId,
        'return_id': returnId,
        'sale_id': saleId,
        'amount': totalAmount,
        'method': method,
        'reason': cleanReason,
        'status': 'Pending',
        'created_at': now,
      });

      await txn.insert('refund_audit', {
        'return_id': returnId,
        'refund_id': refundId,
        'action': 'REQUEST_CREATED',
        'amount': totalAmount,
        'method': method,
        'actor_id': requesterId,
        'event_time': now,
        'notes': cleanReason,
      });

      return {
        'return_id': returnId,
        'return_number': returnNumber,
        'refund_id': refundId,
        'sale_id': saleId,
        'invoice_number': sale['bill_number'],
        'total_amount': totalAmount,
        'status': 'Pending',
      };
    });
  }

  Future<List<Map<String, dynamic>>> getSaleReturnHistory() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        sr.id,
        sr.return_number,
        sr.refund_id,
        sr.sale_id,
        sr.return_date,
        sr.total_amount,
        sr.refund_method,
        sr.reason,
        sr.status,
        s.bill_number,
        COALESCE(c.name, 'Walk-in Customer') AS customer_name,
        rt.status AS refund_status
      FROM sale_returns sr
      INNER JOIN sales s ON s.id = sr.sale_id
      LEFT JOIN customers c ON c.id = sr.customer_id
      LEFT JOIN refund_transactions rt ON rt.refund_id = sr.refund_id
      ORDER BY sr.id DESC
    ''');
  }

  Future<Map<String, dynamic>> approveSaleReturn({
    required int returnId,
    String? approverId,
  }) async {
    final db = await database;
    final now = DateTime.now()
        .toUtc()
        .add(const Duration(hours: 5))
        .toIso8601String();

    return db.transaction((txn) async {
      final rows = await txn.query(
        'sale_returns',
        where: 'id = ?',
        whereArgs: [returnId],
        limit: 1,
      );
      if (rows.isEmpty) {
        throw StateError('Return request not found.');
      }

      final request = rows.first;
      if (request['status'] != 'Pending') {
        throw StateError('Only Pending returns can be approved.');
      }

      final refundId = request['refund_id'] as String;
      final refunds = await txn.query(
        'refund_transactions',
        where: 'refund_id = ? AND status = ?',
        whereArgs: [refundId, 'Pending'],
        limit: 1,
      );
      if (refunds.isEmpty) {
        throw StateError('Pending refund transaction not found.');
      }

      final returnItems = await txn.query(
        'sale_return_items',
        where: 'return_id = ?',
        whereArgs: [returnId],
      );
      if (returnItems.isEmpty) {
        throw StateError('Return request has no items.');
      }

      for (final item in returnItems) {
        if ((item['stock_restored'] as num).toInt() != 0) {
          throw StateError('Return item was already processed.');
        }

        final quantity = (item['return_quantity'] as num).toDouble();
        final productId = item['product_id'] as int?;
        final condition = (item['item_condition'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        if (quantity <= 0 || !quantity.isFinite) {
          throw StateError('Invalid return quantity.');
        }

        if (condition == 'good') {
          if (productId != null) {
            final changed = await txn.rawUpdate(
              'UPDATE products SET quantity = quantity + ? WHERE id = ?',
              [quantity, productId],
            );
            if (changed != 1) {
              throw StateError('Could not restore returned product stock.');
            }
            await txn.insert('stock_movements', {
              'product_id': productId,
              'movement_type': 'Sales Return',
              'quantity': quantity,
              'note': 'Approved return $refundId',
              'movement_date': now,
            });
          }
        } else if (condition == 'damaged') {
          await txn.insert('damaged_stock', {
            'return_id': returnId,
            'return_item_id': item['id'],
            'product_id': productId,
            'product_name': item['product_name'],
            'quantity': quantity,
            'recorded_at': now,
            'notes': 'Approved damaged return $refundId',
          });
        } else {
          throw StateError('Unknown item condition: $condition');
        }

        await txn.update(
          'sale_return_items',
          {'stock_restored': 1},
          where: 'id = ? AND stock_restored = 0',
          whereArgs: [item['id']],
        );
      }

      await txn.update(
        'sale_returns',
        {'status': 'Approved', 'approver_id': approverId},
        where: 'id = ? AND status = ?',
        whereArgs: [returnId, 'Pending'],
      );

      await txn.update(
        'refund_transactions',
        {'status': 'Completed', 'completed_at': now, 'verified_by': approverId},
        where: 'refund_id = ? AND status = ?',
        whereArgs: [refundId, 'Pending'],
      );

      await txn.insert('refund_audit', {
        'return_id': returnId,
        'refund_id': refundId,
        'action': 'APPROVED_AND_REFUNDED',
        'amount': request['total_amount'],
        'method': request['refund_method'],
        'actor_id': approverId,
        'event_time': now,
        'notes': 'Return approved; refund marked completed.',
      });

      return {
        'return_id': returnId,
        'refund_id': refundId,
        'status': 'Approved',
        'refund_status': 'Completed',
      };
    });
  }

  Future<Map<String, dynamic>> getDashboardSummary({
    String period = 'Today',
  }) async {
    final db = await database;
    final now = DateTime.now();

    final DateTime start;
    switch (period) {
      case 'Weekly':
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));
        break;
      case 'Monthly':
        start = DateTime(now.year, now.month);
        break;
      case 'Year':
        start = DateTime(now.year);
        break;
      case 'All Time':
        start = DateTime(2000);
        break;
      default:
        start = DateTime(now.year, now.month, now.day);
    }

    final from = start.toIso8601String();
    final to = now.add(const Duration(days: 1)).toIso8601String();

    final sales = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(total), 0) AS total,
        COALESCE(SUM(paid), 0) AS paid,
        COALESCE(SUM(remaining), 0) AS remaining
      FROM sales
      WHERE sale_date >= ? AND sale_date < ?
    ''',
      [from, to],
    );

    final expenses = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(amount), 0) AS total
      FROM expenses
      WHERE expense_date >= ? AND expense_date < ?
    ''',
      [from, to],
    );

    final customers =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM customers'),
        ) ??
        0;

    final products =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;

    final stock = await db.rawQuery('''
      SELECT
        COALESCE(SUM(quantity * purchase_price), 0) AS value,
        COALESCE(SUM(CASE WHEN quantity <= min_stock AND quantity > 0 THEN 1 ELSE 0 END), 0) AS low,
        COALESCE(SUM(CASE WHEN quantity <= 0 THEN 1 ELSE 0 END), 0) AS empty
      FROM products
    ''');

    final totalSales = (sales.first['total'] as num).toDouble();
    final paid = (sales.first['paid'] as num).toDouble();
    final remaining = (sales.first['remaining'] as num).toDouble();
    final expenseTotal = (expenses.first['total'] as num).toDouble();
    final costResult = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(quantity * cost_price), 0) AS total
      FROM sale_items
      WHERE sale_id IN (SELECT id FROM sales WHERE sale_date >= ? AND sale_date < ?)
    ''',
      [from, to],
    );
    final costTotal = (costResult.first['total'] as num).toDouble();

    return {
      'sales': totalSales,
      'paid': paid,
      'remaining': remaining,
      'expenses': expenseTotal,
      'profit': totalSales - costTotal - expenseTotal,
      'customers': customers,
      'products': products,
      'stockValue': (stock.first['value'] as num).toDouble(),
      'lowStock': stock.first['low'],
      'outOfStock': stock.first['empty'],
    };
  }

  // Save a record for any business module.
  Future<int> saveModuleRecord({
    required String moduleKey,
    required String title,
    Map<String, dynamic> formData = const {},
    num amount = 0,
    String status = 'Saved',
    String? recordDate,
  }) async {
    if (moduleKey.trim().isEmpty || title.trim().isEmpty) {
      throw ArgumentError('Module name aur title zaroori hain.');
    }
    if (!amount.isFinite) {
      throw ArgumentError('Amount valid number hona chahiye.');
    }

    final db = await database;
    final now = DateTime.now().toIso8601String();

    return db.insert('module_records', {
      'module_key': moduleKey.trim(),
      'title': title.trim(),
      'form_data': jsonEncode(formData),
      'amount': amount,
      'status': status,
      'record_date': recordDate ?? now,
      'created_at': now,
      'updated_at': now,
    });
  }

  // Update an existing module record.
  Future<int> updateModuleRecord({
    required int id,
    required String moduleKey,
    required String title,
    Map<String, dynamic> formData = const {},
    num amount = 0,
    String status = 'Saved',
    String? recordDate,
  }) async {
    if (moduleKey.trim().isEmpty || title.trim().isEmpty) {
      throw ArgumentError('Module name aur title zaroori hain.');
    }
    if (!amount.isFinite) {
      throw ArgumentError('Amount valid number hona chahiye.');
    }

    final db = await database;
    return db.update(
      'module_records',
      {
        'title': title.trim(),
        'form_data': jsonEncode(formData),
        'amount': amount,
        'status': status,
        'record_date': recordDate ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND module_key = ?',
      whereArgs: [id, moduleKey],
    );
  }

  // Get all records belonging to one module.
  Future<List<Map<String, dynamic>>> getModuleRecords(String moduleKey) async {
    final db = await database;
    return db.query(
      'module_records',
      where: 'module_key = ?',
      whereArgs: [moduleKey],
      orderBy: 'record_date DESC, id DESC',
    );
  }

  // Get one record by its ID.
  Future<Map<String, dynamic>?> getModuleRecord(int id) async {
    final db = await database;
    final rows = await db.query(
      'module_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  // Delete a module record.
  Future<int> deleteModuleRecord(int id) async {
    final db = await database;
    return db.delete('module_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> addSupplier({
    required String name,
    String? mobile,
    String? address,
    double balance = 0,
    String? companyName,
    String? whatsapp,
    String? email,
    String? cnicNtn,
    String? city,
    String? country,
    String? contactPerson,
    String? supplierCategory,
    double creditLimit = 0,
    String? paymentTerms,
    String? bankName,
    String? bankAccount,
    String? bankIban,
    String status = 'Active',
    String? notes,
    String? photoPath,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Supplier name is required.');
    }
    if (!balance.isFinite || balance < 0) {
      throw ArgumentError('Enter a valid opening balance.');
    }
    if (!creditLimit.isFinite || creditLimit < 0) {
      throw ArgumentError('Enter a valid credit limit.');
    }

    String? clean(String? value) => value?.trim();

    final db = await database;
    return db.insert('suppliers', {
      'name': cleanName,
      'mobile': clean(mobile),
      'address': clean(address),
      'balance': balance,
      'company_name': clean(companyName),
      'whatsapp': clean(whatsapp),
      'email': clean(email),
      'cnic_ntn': clean(cnicNtn),
      'city': clean(city),
      'country': clean(country),
      'contact_person': clean(contactPerson),
      'supplier_category': clean(supplierCategory),
      'credit_limit': creditLimit,
      'payment_terms': clean(paymentTerms),
      'bank_name': clean(bankName),
      'bank_account': clean(bankAccount),
      'bank_iban': clean(bankIban),
      'status': status.trim().isEmpty ? 'Active' : status.trim(),
      'notes': clean(notes),
      'photo_path': clean(photoPath),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getSuppliers({String query = ''}) async {
    final db = await database;
    final q = query.trim();
    return db.query(
      'suppliers',
      where: q.isEmpty ? null : 'name LIKE ? OR mobile LIKE ? OR company_name LIKE ? OR whatsapp LIKE ?',
      whereArgs: q.isEmpty ? null : ['%$q%', '%$q%', '%$q%', '%$q%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  Future<int> updateSupplier({
    required int id,
    required String name,
    String? mobile,
    String? address,
    double balance = 0,
    String? companyName,
    String? whatsapp,
    String? email,
    String? cnicNtn,
    String? city,
    String? country,
    String? contactPerson,
    String? supplierCategory,
    double creditLimit = 0,
    String? paymentTerms,
    String? bankName,
    String? bankAccount,
    String? bankIban,
    String status = 'Active',
    String? notes,
    String? photoPath,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Supplier name is required.');
    }
    if (!balance.isFinite || balance < 0) {
      throw ArgumentError('Enter a valid opening balance.');
    }
    if (!creditLimit.isFinite || creditLimit < 0) {
      throw ArgumentError('Enter a valid credit limit.');
    }

    String? clean(String? value) => value?.trim();

    final db = await database;
    return db.update(
      'suppliers',
      {
        'name': cleanName,
        'mobile': clean(mobile),
        'address': clean(address),
        'balance': balance,
        'company_name': clean(companyName),
        'whatsapp': clean(whatsapp),
        'email': clean(email),
        'cnic_ntn': clean(cnicNtn),
        'city': clean(city),
        'country': clean(country),
        'contact_person': clean(contactPerson),
        'supplier_category': clean(supplierCategory),
        'credit_limit': creditLimit,
        'payment_terms': clean(paymentTerms),
        'bank_name': clean(bankName),
        'bank_account': clean(bankAccount),
        'bank_iban': clean(bankIban),
        'status': status.trim().isEmpty ? 'Active' : status.trim(),
        'notes': clean(notes),
        'photo_path': clean(photoPath),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await database;
    return db.delete('suppliers', where: 'id = ?', whereArgs: [id]);
  }

  // Dedicated Expense database functions.
  Future<int> saveExpense({
    required String category,
    String? title,
    required double amount,
    required String expenseDate,
    String? description,
    String? paymentMethod,
    String? paidTo,
    String? referenceNumber,
  }) async {
    if (category.trim().isEmpty) {
      throw ArgumentError('Expense category zaroori hai.');
    }
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Expense amount valid hona chahiye.');
    }

    final db = await database;
    return db.insert('expenses', {
      'category': category.trim(),
      'title': title?.trim(),
      'description': description?.trim(),
      'amount': amount,
      'payment_method': paymentMethod?.trim(),
      'expense_date': expenseDate,
      'paid_to': paidTo?.trim(),
      'reference_number': referenceNumber?.trim(),
    });
  }

  Future<int> updateExpense({
    required int id,
    required String category,
    String? title,
    required double amount,
    required String expenseDate,
    String? description,
    String? paymentMethod,
    String? paidTo,
    String? referenceNumber,
  }) async {
    if (category.trim().isEmpty) {
      throw ArgumentError('Expense category zaroori hai.');
    }
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Expense amount valid hona chahiye.');
    }

    final db = await database;
    return db.update(
      'expenses',
      {
        'category': category.trim(),
        'title': title?.trim(),
        'description': description?.trim(),
        'amount': amount,
        'payment_method': paymentMethod?.trim(),
        'expense_date': expenseDate,
        'paid_to': paidTo?.trim(),
        'reference_number': referenceNumber?.trim(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getExpenses({
    String query = '',
    String? fromDate,
    String? toDate,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];
    final q = query.trim();

    if (q.isNotEmpty) {
      conditions.add(
        '(title LIKE ? OR category LIKE ? OR description LIKE ? OR paid_to LIKE ? OR reference_number LIKE ?)',
      );
      args.add('%$q%');
      args.add('%$q%');
      args.add('%$q%');
      args.add('%$q%');
      args.add('%$q%');
    }
    if (fromDate != null && fromDate.isNotEmpty) {
      conditions.add('expense_date >= ?');
      args.add(fromDate);
    }
    if (toDate != null && toDate.isNotEmpty) {
      conditions.add('expense_date <= ?');
      args.add(toDate);
    }

    return db.query(
      'expenses',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'expense_date DESC, id DESC',
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getCustomerLedger(int customerId) async {
    if (customerId <= 0) throw ArgumentError("Invalid customer ID");
    final db = await database;
    final customers = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [customerId],
      limit: 1,
    );
    if (customers.isEmpty) throw StateError("Customer not found");
    final customer = customers.first;
    final opening = (customer["opening_balance"] as num?)?.toDouble() ?? 0.0;
    final rows = await db.rawQuery(
      "SELECT * FROM (SELECT id, sale_date AS transaction_date, bill_number AS reference, 'Sale' AS transaction_type, 'Debit' AS entry_type, total AS amount, notes AS note FROM sales WHERE customer_id = ? UNION ALL SELECT p.id, p.payment_date AS transaction_date, COALESCE(s.bill_number, p.payment_type) AS reference, p.payment_type AS transaction_type, 'Credit' AS entry_type, p.amount AS amount, p.note AS note FROM payments p LEFT JOIN sales s ON s.id = p.sale_id WHERE p.customer_id = ?) AS ledger_entries ORDER BY transaction_date ASC, CASE WHEN entry_type = 'Debit' THEN 0 ELSE 1 END ASC, id ASC",
      [customerId, customerId],
    );
    final ledger = <Map<String, dynamic>>[];
    double balance = opening;
    if (opening > 0) {
      ledger.add({
        "id": 0,
        "transaction_date": customer["created_at"],
        "reference": "Opening Balance",
        "transaction_type": "Opening Balance",
        "entry_type": "Debit",
        "amount": opening,
        "note": "Customer opening balance",
        "running_balance": balance,
      });
    }
    for (final row in rows) {
      final amount = (row["amount"] as num?)?.toDouble() ?? 0.0;
      if (row["entry_type"] == "Debit") {
        balance += amount;
      } else {
        balance -= amount;
      }
      ledger.add({...row, "amount": amount, "running_balance": balance});
    }
    return ledger;
  }
}
