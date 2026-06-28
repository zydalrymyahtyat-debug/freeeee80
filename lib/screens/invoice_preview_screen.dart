import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import '../models/sale.dart';
import '../models/sale_item.dart';
import '../models/store_info.dart';
import '../services/database_helper.dart';
import '../providers/settings_provider.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final Sale sale;
  final List<SaleItem> items;

  const InvoicePreviewScreen({super.key, required this.sale, required this.items});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  StoreInfo? _storeInfo;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    final info = await _dbHelper.getStoreInfo();
    setState(() {
      _storeInfo = info;
    });
  }

  Future<pw.Document> _generatePdf(PdfPageFormat format, SettingsProvider settings) async {
    final doc = pw.Document();

    // Fallback to default font if loading fails, but PDF requires a valid ttf for arabic
    // Since we didn't add a TTF asset yet, we use a default built-in that might not support Arabic perfectly.
    // In a real production app, you should load an Arabic TTF font here.
    // For demonstration, we'll use the default font.

    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf').catchError((_) => ByteData(0));
    final ttf = fontData.lengthInBytes > 0 ? pw.Font.ttf(fontData) : pw.Font.helvetica();

    doc.addPage(
      pw.Page(
        pageFormat: format,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
          italic: ttf,
          boldItalic: ttf,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Store Header
              pw.Center(
                child: pw.Text(
                  _storeInfo?.name ?? 'فاتورة مبيعات',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
              ),
              if (_storeInfo != null) ...[
                pw.Center(child: pw.Text(_storeInfo!.address)),
                pw.Center(child: pw.Text(_storeInfo!.phone)),
              ],
              pw.SizedBox(height: 16),
              pw.Divider(),

              // Invoice Details
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('رقم الفاتورة: ${widget.sale.id}'),
                  pw.Text('التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(widget.sale.date))}'),
                ],
              ),
              pw.SizedBox(height: 16),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('الصنف', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('الكمية', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('الإجمالي', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                    ]
                  ),
                  ...widget.items.map((item) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(item.productName)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${item.quantity}', textAlign: pw.TextAlign.center)),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(settings.formatCurrency(item.price * item.quantity), textAlign: pw.TextAlign.center)),
                    ]
                  ))
                ]
              ),
              pw.SizedBox(height: 16),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الإجمالي الكلي:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(settings.formatCurrency(widget.sale.total), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ]
              ),

              pw.SizedBox(height: 32),
              if (_storeInfo != null && _storeInfo!.welcomeMessage.isNotEmpty)
                pw.Center(
                  child: pw.Text(_storeInfo!.welcomeMessage, style: const pw.TextStyle(color: PdfColors.grey700)),
                )
            ],
          );
        },
      ),
    );

    return doc;
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة وطباعة الفاتورة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة عبر واتساب',
            onPressed: () async {
              // Basic details to share via WhatsApp
              String itemsList = widget.items.map((i) => '${i.productName} x${i.quantity}').join('\n');
              String text = 'فاتورة مبيعات\nرقم الفاتورة: ${widget.sale.id}\n'
                  'الإجمالي: ${settings.formatCurrency(widget.sale.total)}\n'
                  'الأصناف:\n$itemsList\n\n'
                  'شكراً لتعاملكم معنا!';
              final Uri whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
              if (await canLaunchUrl(whatsappUri)) {
                await launchUrl(whatsappUri);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تطبيق واتساب غير مثبت على الجهاز.')));
                }
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format, settings).then((doc) => doc.save()),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.roll80, // Default receipt roll size
      ),
    );
  }
}
