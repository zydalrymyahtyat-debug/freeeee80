import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../services/database_helper.dart';
import '../providers/settings_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Sale> _sales = [];
  bool _isLoading = true;

  double _totalSales = 0.0;
  double _totalProfits = 0.0;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('sales', orderBy: 'date DESC');

    double tSales = 0.0;
    double tProfits = 0.0;

    final sales = List.generate(maps.length, (i) {
      final sale = Sale.fromMap(maps[i]);
      tSales += sale.total;
      tProfits += sale.profit;
      return sale;
    });

    setState(() {
      _sales = sales;
      _totalSales = tSales;
      _totalProfits = tProfits;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والأرباح'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.blue.shade100,
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('إجمالي المبيعات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(settings.formatCurrency(_totalSales), style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          color: Colors.green.shade100,
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text('إجمالي الأرباح', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text(settings.formatCurrency(_totalProfits), style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('سجل المبيعات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),

                // Sales List
                Expanded(
                  child: _sales.isEmpty
                      ? const Center(child: Text('لا يوجد سجل مبيعات'))
                      : ListView.builder(
                          itemCount: _sales.length,
                          itemBuilder: (context, index) {
                            final sale = _sales[index];
                            final dateFormatted = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(sale.date));
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.receipt)),
                              title: Text('فاتورة رقم: ${sale.id}'),
                              subtitle: Text(dateFormatted),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(settings.formatCurrency(sale.total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('ربح: ${settings.formatCurrency(sale.profit)}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                                ],
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
