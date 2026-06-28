import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import '../services/database_helper.dart';
import '../providers/cart_provider.dart';
import '../providers/settings_provider.dart';
import 'scanner_screen.dart';
import 'invoice_preview_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final products = await _dbHelper.getProducts();
    final customers = await _dbHelper.getCustomers();
    setState(() {
      _allProducts = products;
      _filteredProducts = products;
      _customers = customers;
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

    // Calculate profit
    double totalProfit = 0.0;
    for (var cartItem in cart.items.values) {
      final profitPerItem = cartItem.product.price - cartItem.product.cost;
      totalProfit += profitPerItem * cartItem.quantity;
    }

    final now = DateTime.now().toIso8601String();

    final sale = Sale(
      total: total,
      profit: totalProfit,
      date: now,
      customerId: _selectedCustomer?.id,
    );

    final saleItems = cart.toSaleItems(0);
    final saleId = await _dbHelper.saveSale(sale, saleItems);

    // Reload products to get updated quantities
    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ الفاتورة بنجاح! رقم: $saleId')),
      );
      cart.clear();
      setState(() {
        _selectedCustomer = null;
      });

      // Navigate to Invoice Preview
      final finalSale = Sale(
        id: saleId,
        total: total,
        profit: totalProfit,
        date: now,
        customerId: _selectedCustomer?.id,
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicePreviewScreen(sale: finalSale, items: saleItems),
        ),
      );
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
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نقطة البيع'),
      ),
      body: Column(
        children: [
          // Customer Selection
          // Customer Selection (Autocomplete)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Autocomplete<Customer>(
              displayStringForOption: (Customer option) => option.name,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<Customer>.empty();
                }
                final query = textEditingValue.text.toLowerCase();
                return _customers.where((Customer option) {
                  return option.name.toLowerCase().contains(query) ||
                         option.phone.toLowerCase().contains(query);
                });
              },
              onSelected: (Customer selection) {
                setState(() {
                  _selectedCustomer = selection;
                });
              },
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'ابحث عن عميل (بالاسم أو الرقم)',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: _selectedCustomer != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              controller.clear();
                              setState(() {
                                _selectedCustomer = null;
                              });
                            },
                          )
                        : null,
                  ),
                );
              },
            ),
          ),

          // Search and Scanner Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                                    Text(settings.formatCurrency(product.price), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
                            return Dismissible(
                              key: ValueKey(productId),
                              background: Container(
                                color: Theme.of(context).colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                                child: const Icon(Icons.delete, color: Colors.white, size: 40),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                cart.removeItem(productId);
                              },
                              child: ListTile(
                                title: Text(cartItem.product.name),
                                subtitle: Text('${settings.formatCurrency(cartItem.product.price)} x ${cartItem.quantity}'),
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
                        'الإجمالي: ${settings.formatCurrency(cart.totalAmount)}',
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
