import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import '../providers/settings_provider.dart';
import 'add_product_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _dbHelper.getProducts();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
      _isLoading = false;
    });
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final nameLower = p.name.toLowerCase();
        final searchLower = query.toLowerCase();
        final barcodeMatch = p.barcode != null && p.barcode == query;
        return nameLower.contains(searchLower) || barcodeMatch;
      }).toList();
    });
  }

  Future<void> _deleteProduct(int id) async {
    await _dbHelper.deleteProduct(id);
    _loadProducts();
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
        title: const Text('إدارة المخزون'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'بحث بالاسم أو الباركود',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterProducts,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('لا توجد منتجات متاحة.'))
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final isLowStock = product.quantity <= product.minQuantity;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isLowStock ? Colors.red.shade100 : Colors.blue.shade100,
                              child: Icon(Icons.inventory_2, color: isLowStock ? Colors.red : Colors.blue),
                            ),
                            title: Text(product.name),
                            subtitle: Text('الكمية: ${product.quantity} | السعر: ${settings.formatCurrency(product.price)}'),
                            trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddProductScreen(product: product),
                                ),
                              );
                              if (result == true) {
                                _loadProducts();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('حذف المنتج'),
                                  content: const Text('هل أنت متأكد أنك تريد حذف هذا المنتج؟'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _deleteProduct(product.id!);
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
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
          if (result == true) {
            _loadProducts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
