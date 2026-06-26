import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/database_helper.dart';
import '../providers/cart_provider.dart';
import 'scanner_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
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
      _filteredProducts = _allProducts.where((product) {
        final nameLower = product.name.toLowerCase();
        final searchLower = query.toLowerCase();
        final barcodeMatch = product.barcode != null && product.barcode == query;
        return nameLower.contains(searchLower) || barcodeMatch;
      }).toList();
    });
  }

  Future<void> _processCheckout(CartProvider cart) async {
    if (cart.items.isEmpty) return;

    final total = cart.totalAmount;
    final now = DateTime.now().toIso8601String();

    final sale = Sale(total: total, date: now);
    final saleId = await _dbHelper.saveSale(sale, cart.toSaleItems(0));

    // Reload products to get updated quantities
    await _loadProducts();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إتمام عملية البيع بنجاح! رقم الفاتورة: $saleId')),
      );
      cart.clear();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع'),
      ),
      body: Column(
        children: [
          // Search and Scanner Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'البحث عن منتج (الاسم أو الباركود)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _filterProducts,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 36, color: Colors.blue),
                  onPressed: () async {
                    final scannedCode = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ScannerScreen()),
                    );
                    if (scannedCode != null && scannedCode is String) {
                      _searchController.text = scannedCode;
                      _filterProducts(scannedCode);
                      // Auto-add if exact match found
                      if (_filteredProducts.length == 1 && _filteredProducts.first.barcode == scannedCode) {
                         if(_filteredProducts.first.quantity > 0) {
                            cart.addItem(_filteredProducts.first);
                            _searchController.clear();
                            _filterProducts('');
                         } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('الكمية غير متوفرة!')),
                              );
                            }
                         }
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          // Products Grid
          Expanded(
            flex: 2,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? const Center(child: Text('لا توجد منتجات مطابقة'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3 / 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final isOutOfStock = product.quantity <= 0;
                          return InkWell(
                            onTap: isOutOfStock ? null : () => cart.addItem(product),
                            child: Card(
                              elevation: 2,
                              color: isOutOfStock ? Colors.grey[300] : null,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text('\$${product.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'المتوفر: ${product.quantity}',
                                      style: TextStyle(color: isOutOfStock ? Colors.red : Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Cart Section
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.blue.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('سلة المشتريات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${cart.itemCount} عناصر', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep, color: Colors.red),
                        onPressed: cart.items.isEmpty ? null : () => cart.clear(),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: cart.items.isEmpty
                      ? const Center(child: Text('السلة فارغة'))
                      : ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder: (context, index) {
                            final cartItem = cart.items.values.toList()[index];
                            final productId = cart.items.keys.toList()[index];
                            return ListTile(
                              title: Text(cartItem.product.name),
                              subtitle: Text('\$${cartItem.product.price} x ${cartItem.quantity}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => cart.removeSingleItem(productId),
                                  ),
                                  Text('${cartItem.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                       // Check stock before adding more
                                       if (cartItem.quantity < cartItem.product.quantity) {
                                          cart.addItem(cartItem.product);
                                       } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('لا يوجد كمية كافية في المخزون!')),
                                          );
                                       }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'الإجمالي: \$${cart.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          backgroundColor: Colors.green,
                        ),
                        onPressed: cart.items.isEmpty ? null : () => _processCheckout(cart),
                        child: const Text('إتمام البيع', style: TextStyle(fontSize: 18, color: Colors.white)),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
