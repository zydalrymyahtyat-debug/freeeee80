import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'pos_screen.dart';
import 'customers_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';
import 'shortages_screen.dart';
import 'orders_screen.dart';
import '../services/database_helper.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../providers/settings_provider.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Product> _lowStockProducts = [];
  List<Customer> _debtCustomers = [];
  bool _hasNotifications = false;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    final products = await _dbHelper.getProducts();
    final customers = await _dbHelper.getCustomers();

    setState(() {
      _lowStockProducts = products.where((p) => p.quantity <= p.minQuantity).toList();
      _debtCustomers = customers.where((c) => c.debt > 0).toList();
      _hasNotifications = _lowStockProducts.isNotEmpty || _debtCustomers.isNotEmpty;
    });
  }

  void _showNotificationsSheet() {
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: const Text('مركز الإشعارات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const Divider(),
                if (!_hasNotifications)
                  const Expanded(child: Center(child: Text('لا توجد إشعارات حالياً.'))),
                if (_hasNotifications)
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        if (_lowStockProducts.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('تنبيهات المخزون', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ),
                          ..._lowStockProducts.map((p) => ListTile(
                                leading: const Icon(Icons.warning, color: Colors.red),
                                title: Text(p.name),
                                subtitle: Text('الكمية الحالية: ${p.quantity} (الحد الأدنى: ${p.minQuantity})'),
                              )),
                        ],
                        if (_debtCustomers.isNotEmpty) ...[
                          const Divider(),
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('تنبيهات المديونيات', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ),
                          ..._debtCustomers.map((c) => ListTile(
                                leading: const Icon(Icons.account_balance_wallet, color: Colors.orange),
                                title: Text(c.name),
                                subtitle: Text('المبلغ المستحق: ${settings.formatCurrency(c.debt)}'),
                              )),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Refresh stock check when building (e.g. returning from another screen)
    _checkNotifications();

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم الرئيسية'),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: _showNotificationsSheet,
              ),
              if (_hasNotifications)
                Positioned(
                  right: 11,
                  top: 11,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                  ),
                )
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.point_of_sale, size: 64, color: Colors.white),
                  SizedBox(height: 8),
                  Text('نقاط البيع الذكية', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('الإعدادات والأمان'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('النسخ الاحتياطي'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BackupScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('حول التطبيق'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'نقاط البيع الذكية',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.point_of_sale, size: 48, color: Colors.blue),
                  children: const [
                    Text('تطبيق شامل لإدارة المبيعات، المخزون، والعملاء بسهولة وبدون إنترنت.'),
                  ]
                );
              },
            ),
            _buildDashboardCard(
              context,
              title: 'تسجيل النواقص',
              icon: Icons.inventory_2_outlined,
              color: Colors.redAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ShortagesScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              title: 'طلبيات التجار والصيانة',
              icon: Icons.build_circle,
              color: Colors.teal,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrdersScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          children: [
            _buildDashboardCard(
              context,
              title: 'نقطة البيع',
              icon: Icons.point_of_sale,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const POSScreen()),
                );
              },
            ),
            _buildDashboardCard(
              context,
              title: 'إدارة المخزون',
              icon: Icons.inventory,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InventoryScreen()),
                ).then((_) => _checkNotifications());
              },
            ),
            _buildDashboardCard(
              context,
              title: 'إدارة العملاء',
              icon: Icons.people,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomersScreen()),
                ).then((_) => _checkNotifications());
              },
            ),
            _buildDashboardCard(
              context,
              title: 'التقارير والأرباح',
              icon: Icons.analytics,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ReportsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48.0, color: color),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
