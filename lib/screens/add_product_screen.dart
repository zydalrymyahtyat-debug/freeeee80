import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import 'scanner_screen.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minQuantityController = TextEditingController();
  final _barcodeController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _costController.text = widget.product!.cost.toString();
      _quantityController.text = widget.product!.quantity.toString();
      _minQuantityController.text = widget.product!.minQuantity.toString();
      _barcodeController.text = widget.product!.barcode ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _quantityController.dispose();
    _minQuantityController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: widget.product?.id,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        cost: double.tryParse(_costController.text) ?? 0.0,
        quantity: int.tryParse(_quantityController.text) ?? 0,
        minQuantity: int.tryParse(_minQuantityController.text) ?? 0,
        barcode: _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
      );

      if (widget.product == null) {
        await _dbHelper.insertProduct(newProduct);
      } else {
        await _dbHelper.updateProduct(newProduct);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'إضافة منتج' : 'تعديل منتج'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'اسم المنتج', border: OutlineInputBorder()),
                validator: (value) => value == null || value.isEmpty ? 'يرجى إدخال اسم المنتج' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'سعر البيع', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _costController,
                      decoration: const InputDecoration(labelText: 'التكلفة', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'الكمية المتوفرة', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) => value == null || value.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minQuantityController,
                      decoration: const InputDecoration(labelText: 'الحد الأدنى للتنبيه', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(labelText: 'الباركود (اختياري)', border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, size: 36, color: Colors.blue),
                    onPressed: () async {
                      final scannedCode = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScannerScreen()),
                      );
                      if (scannedCode != null && scannedCode is String) {
                        setState(() {
                          _barcodeController.text = scannedCode;
                        });
                      }
                    },
                  )
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('حفظ المنتج', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
