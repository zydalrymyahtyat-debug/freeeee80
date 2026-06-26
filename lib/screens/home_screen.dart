import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'pos_screen.dart';
import 'customers_screen.dart';
import 'reports_screen.dart'; // We will create this next
import 'settings_screen.dart';
import 'backup_screen.dart';
import '../services/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool _hasLowStock = false;

  @override
  void initState() {
    super.initState();
    _checkStock();
  }

  Future<void> _checkStock() async {
    final products = await _dbHelper.getProducts();
    setState(() {
      _hasLowStock = products.any((p) => p.quantity <= p.minQuantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم الرئيسية'),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InventoryScreen()),
                  ).then((_) => _checkStock());
                },
              ),
              if (_hasLowStock)
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
                ).then((_) => _checkStock());
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
                );
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
