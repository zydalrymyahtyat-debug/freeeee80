import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/database_helper.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final customers = await _dbHelper.getCustomers();
    setState(() {
      _allCustomers = customers;
      _filteredCustomers = customers;
      _isLoading = false;
    });
  }

  void _filterCustomers(String query) {
    setState(() {
      _filteredCustomers = _allCustomers.where((c) {
        final nameLower = c.name.toLowerCase();
        final phoneLower = c.phone.toLowerCase();
        final searchLower = query.toLowerCase();
        return nameLower.contains(searchLower) || phoneLower.contains(searchLower);
      }).toList();
    });
  }

  void _showCustomerDialog({Customer? customer}) {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final debtController = TextEditingController(text: customer?.debt.toString() ?? '0.0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(customer == null ? 'إضافة عميل' : 'تعديل عميل'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'رقم الهاتف',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.contacts, color: Colors.blue),
                    onPressed: () async {
                      bool isGranted = await FlutterContacts.permissions.has(PermissionType.read);
                      if (!isGranted) {
                        final status = await FlutterContacts.permissions.request(PermissionType.read);
                        isGranted = status == PermissionStatus.granted || status == PermissionStatus.limited;
                      }

                      if (!isGranted) {
                        if (formKey.currentContext != null) {
                          ScaffoldMessenger.of(formKey.currentContext!).showSnackBar(const SnackBar(content: Text('الرجاء منح صلاحية الوصول لجهات الاتصال.')));
                        }
                        return;
                      }

                      final contact = await FlutterContacts.native.showPicker(properties: {ContactProperty.phone});
                      if (contact != null && contact.phones.isNotEmpty) {
                        phoneController.text = contact.phones.first.number;
                        if (nameController.text.isEmpty) {
                          nameController.text = contact.displayName ?? '';
                        }
                      }
                    },
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
              ),
              TextFormField(
                controller: debtController,
                decoration: const InputDecoration(labelText: 'المديونية الحالية'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newCustomer = Customer(
                  id: customer?.id,
                  name: nameController.text,
                  phone: phoneController.text,
                  debt: double.tryParse(debtController.text) ?? 0.0,
                );
                if (customer == null) {
                  await _dbHelper.insertCustomer(newCustomer);
                } else {
                  await _dbHelper.updateCustomer(newCustomer);
                }
                if (context.mounted) {
                  Navigator.pop(ctx);
                }
                _loadCustomers();
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCustomer(int id) async {
    await _dbHelper.deleteCustomer(id);
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العملاء'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'بحث برقم الهاتف أو الاسم',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterCustomers,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCustomers.isEmpty
                    ? const Center(child: Text('لا يوجد عملاء'))
                    : ListView.builder(
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(customer.name),
                            subtitle: Text('${customer.phone} | مديونية: ${settings.formatCurrency(customer.debt)}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showCustomerDialog(customer: customer),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('حذف العميل'),
                                        content: const Text('هل أنت متأكد من الحذف؟'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(ctx);
                                              _deleteCustomer(customer.id!);
                                            },
                                            child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCustomerDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
