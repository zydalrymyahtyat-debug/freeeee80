import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/database_helper.dart';
import '../providers/settings_provider.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<OrderItem> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await _dbHelper.getOrders();
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  void _showOrderDialog({OrderItem? order}) {
    final formKey = GlobalKey<FormState>();
    final supplierController = TextEditingController(text: order?.supplier ?? '');
    final detailsController = TextEditingController(text: order?.details ?? '');
    final costController = TextEditingController(text: order?.expectedCost.toString() ?? '');
    String selectedStatus = order?.status ?? 'تم الطلب';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(order == null ? 'إضافة طلبية' : 'تعديل الطلبية'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: supplierController,
                        decoration: const InputDecoration(labelText: 'التاجر / المورد'),
                        validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: detailsController,
                        decoration: const InputDecoration(labelText: 'تفاصيل الصيانة / البرمجة'),
                        maxLines: 3,
                        validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: costController,
                        decoration: const InputDecoration(labelText: 'التكلفة المتوقعة'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        isExpanded: true,
                        value: selectedStatus,
                        items: ['تم الطلب', 'قيد العمل', 'مكتمل', 'ملغي']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            if (val != null) selectedStatus = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final item = OrderItem(
                        id: order?.id,
                        supplier: supplierController.text,
                        details: detailsController.text,
                        expectedCost: double.tryParse(costController.text) ?? 0.0,
                        status: selectedStatus,
                      );
                      if (order == null) {
                        await _dbHelper.insertOrder(item);
                      } else {
                        await _dbHelper.updateOrder(item);
                      }
                      if (context.mounted) Navigator.pop(ctx);
                      _loadOrders();
                    }
                  },
                  child: const Text('حفظ'),
                ),
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبيات التجار والصيانة'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('لا توجد طلبيات حالياً.'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final item = _orders[index];
                    Color statusColor = Colors.blue;
                    if (item.status == 'مكتمل') statusColor = Colors.green;
                    if (item.status == 'ملغي') statusColor = Colors.red;
                    if (item.status == 'قيد العمل') statusColor = Colors.orange;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withValues(alpha: 0.2),
                          child: Icon(Icons.build, color: statusColor),
                        ),
                        title: Text('${item.supplier} - ${item.status}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.details),
                            const SizedBox(height: 4),
                            Text('التكلفة: ${settings.formatCurrency(item.expectedCost)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showOrderDialog(order: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _dbHelper.deleteOrder(item.id!);
                                _loadOrders();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showOrderDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
