import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/shortage_item.dart';
import '../services/database_helper.dart';

class ShortagesScreen extends StatefulWidget {
  const ShortagesScreen({super.key});

  @override
  State<ShortagesScreen> createState() => _ShortagesScreenState();
}

class _ShortagesScreenState extends State<ShortagesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<ShortageItem> _shortages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShortages();
  }

  Future<void> _loadShortages() async {
    setState(() => _isLoading = true);
    final shortages = await _dbHelper.getShortages();
    setState(() {
      _shortages = shortages;
      _isLoading = false;
    });
  }

  void _showAddShortageDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    String selectedType = 'لواصق';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إضافة نواقص'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'اسم الصنف'),
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedType,
                      items: ['لواصق', 'غلافات', 'إكسسوارات', 'أخرى']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val != null) selectedType = val;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: qtyController,
                      decoration: const InputDecoration(labelText: 'الكمية المطلوبة'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final item = ShortageItem(
                        name: nameController.text,
                        type: selectedType,
                        requestedQuantity: int.tryParse(qtyController.text) ?? 1,
                      );
                      await _dbHelper.insertShortage(item);
                      if (context.mounted) Navigator.pop(ctx);
                      _loadShortages();
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

  Future<pw.Document> _generatePdf(PdfPageFormat format) async {
    final doc = pw.Document();
    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf').catchError((_) => ByteData(0));
    final ttf = fontData.lengthInBytes > 0 ? pw.Font.ttf(fontData) : pw.Font.helvetica();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: ttf),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text('قائمة النواقص والطلبيات', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text('التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}'),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('الصنف', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('النوع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('الكمية المطلوبة', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ]
                  ),
                  ..._shortages.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.name)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item.type)),
                      pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item.requestedQuantity}')),
                    ]
                  )),
                ]
              )
            ],
          );
        }
      )
    );
    return doc;
  }

  void _printShortages() {
    if (_shortages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('القائمة فارغة!')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('طباعة النواقص')),
          body: PdfPreview(
            build: (format) => _generatePdf(format).then((doc) => doc.save()),
            allowPrinting: true,
            allowSharing: true,
            initialPageFormat: PdfPageFormat.a4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل النواقص'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printShortages,
            tooltip: 'طباعة النواقص',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () {
              if (_shortages.isEmpty) return;
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('مسح القائمة'),
                  content: const Text('هل أنت متأكد من تفريغ جميع النواقص؟'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                    TextButton(
                      onPressed: () async {
                        await _dbHelper.clearShortages();
                        if (context.mounted) Navigator.pop(ctx);
                        _loadShortages();
                      },
                      child: const Text('تفريغ', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'تفريغ القائمة',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shortages.isEmpty
              ? const Center(child: Text('لا توجد نواقص مسجلة.'))
              : ListView.builder(
                  itemCount: _shortages.length,
                  itemBuilder: (context, index) {
                    final item = _shortages[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.inventory_2, color: Colors.blue),
                      ),
                      title: Text(item.name),
                      subtitle: Text('النوع: ${item.type} | الكمية المطلوبة: ${item.requestedQuantity}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _dbHelper.deleteShortage(item.id!);
                          _loadShortages();
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddShortageDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
