import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/customer.dart';
import '../models/store_info.dart';
import '../models/shortage_item.dart';
import '../models/order.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smart_pos.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE store_info(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        logoPath TEXT,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        welcomeMessage TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        debt REAL NOT NULL DEFAULT 0.0
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        cost REAL NOT NULL,
        quantity INTEGER NOT NULL,
        minQuantity INTEGER NOT NULL DEFAULT 0,
        barcode TEXT
      )
    ''');

    // Create Indexes for performance
    await db.execute('CREATE INDEX idx_products_name ON products(name)');
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_customers_phone ON customers(phone)');

    await db.execute('''
      CREATE TABLE sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total REAL NOT NULL,
        profit REAL NOT NULL DEFAULT 0.0,
        date TEXT NOT NULL,
        customerId INTEGER,
        FOREIGN KEY(customerId) REFERENCES customers(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        saleId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY(saleId) REFERENCES sales(id),
        FOREIGN KEY(productId) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE shortages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        requestedQuantity INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier TEXT NOT NULL,
        details TEXT NOT NULL,
        expectedCost REAL NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 1 only had 'products' table (without minQuantity).
      await db.execute("ALTER TABLE products ADD COLUMN minQuantity INTEGER NOT NULL DEFAULT 0");

      // Create the missing tables that were introduced
      await db.execute('''
        CREATE TABLE store_info(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          logoPath TEXT,
          phone TEXT NOT NULL,
          address TEXT NOT NULL,
          welcomeMessage TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE customers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          debt REAL NOT NULL DEFAULT 0.0
        )
      ''');

      await db.execute('''
        CREATE TABLE sales(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          total REAL NOT NULL,
          profit REAL NOT NULL DEFAULT 0.0,
          date TEXT NOT NULL,
          customerId INTEGER,
          FOREIGN KEY(customerId) REFERENCES customers(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE sale_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          saleId INTEGER NOT NULL,
          productId INTEGER NOT NULL,
          productName TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          price REAL NOT NULL,
          FOREIGN KEY(saleId) REFERENCES sales(id),
          FOREIGN KEY(productId) REFERENCES products(id)
        )
      ''');

      // Create Indexes for performance on upgraded databases
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE shortages(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          requestedQuantity INTEGER NOT NULL
        )
      ''');
    }

    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE orders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          supplier TEXT NOT NULL,
          details TEXT NOT NULL,
          expectedCost REAL NOT NULL,
          status TEXT NOT NULL
        )
      ''');
    }
  }

  // CRUD Operations for Store Info
  Future<StoreInfo?> getStoreInfo() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('store_info', limit: 1);
    if (maps.isNotEmpty) {
      return StoreInfo.fromMap(maps.first);
    }
    return null;
  }

  Future<int> saveStoreInfo(StoreInfo info) async {
    final db = await database;
    if (info.id != null) {
      return await db.update('store_info', info.toMap(), where: 'id = ?', whereArgs: [info.id]);
    } else {
      await db.delete('store_info'); // Ensure only one record exists
      return await db.insert('store_info', info.toMap());
    }
  }

  // CRUD Operations for Customers
  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return await db.insert('customers', customer.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('customers');
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // CRUD Operations for Shortages
  Future<int> insertShortage(ShortageItem item) async {
    final db = await database;
    return await db.insert('shortages', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ShortageItem>> getShortages() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('shortages');
    return List.generate(maps.length, (i) {
      return ShortageItem.fromMap(maps[i]);
    });
  }

  Future<int> deleteShortage(int id) async {
    final db = await database;
    return await db.delete('shortages', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearShortages() async {
    final db = await database;
    return await db.delete('shortages');
  }

  // CRUD Operations for Orders
  Future<int> insertOrder(OrderItem order) async {
    final db = await database;
    return await db.insert('orders', order.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<OrderItem>> getOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('orders');
    return List.generate(maps.length, (i) {
      return OrderItem.fromMap(maps[i]);
    });
  }

  Future<int> updateOrder(OrderItem order) async {
    final db = await database;
    return await db.update('orders', order.toMap(), where: 'id = ?', whereArgs: [order.id]);
  }

  Future<int> deleteOrder(int id) async {
    final db = await database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD Operations for Products
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sales Operations
  Future<int> saveSale(Sale sale, List<SaleItem> items) async {
    final db = await database;
    int saleId = 0;

    await db.transaction((txn) async {
      // 1. Insert Sale
      saleId = await txn.insert('sales', sale.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      // Update customer debt if applicable
      if (sale.customerId != null) {
        await txn.rawUpdate(
          'UPDATE customers SET debt = debt + ? WHERE id = ?',
          [sale.total, sale.customerId]
        );
      }

      // 2. Insert Sale Items and Update Product Quantities
      for (var item in items) {
        final itemMap = item.toMap();
        itemMap['saleId'] = saleId; // Set the generated saleId
        await txn.insert('sale_items', itemMap, conflictAlgorithm: ConflictAlgorithm.replace);

        // Update product quantity
        await txn.rawUpdate(
          'UPDATE products SET quantity = quantity - ? WHERE id = ?',
          [item.quantity, item.productId]
        );
      }
    });

    return saleId;
  }
}
