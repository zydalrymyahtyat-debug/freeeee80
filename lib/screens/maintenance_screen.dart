import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../models/maintenance_ticket.dart';
import '../services/database_helper.dart';
import '../providers/settings_provider.dart';
import 'scanner_screen.dart';
import '../models/product.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<MaintenanceTicket> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    final tickets = await _dbHelper.getMaintenanceTickets();
    setState(() {
      _tickets = tickets;
      _isLoading = false;
    });
  }

  Future<void> _printTicketReceipt(MaintenanceTicket ticket) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري إنشاء إيصال الباركود...')),
    );

    final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('ورشة الصيانة', style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 10),
                  pw.Text('رقم التذكرة: ${ticket.id}', style: pw.TextStyle(font: ttf, fontSize: 14)),
                  pw.Text('العميل: ${ticket.customerName}', style: pw.TextStyle(font: ttf, fontSize: 14)),
                  pw.Text('الجهاز: ${ticket.deviceModel}', style: pw.TextStyle(font: ttf, fontSize: 14)),
                  pw.Text('IMEI: ${ticket.imei}', style: pw.TextStyle(font: ttf, fontSize: 12)),
                  pw.SizedBox(height: 10),
                  pw.BarcodeWidget(
                    data: ticket.id.toString(),
                    barcode: pw.Barcode.code128(),
                    width: 150,
                    height: 50,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('المطلوب: ${ticket.taskType}', style: pw.TextStyle(font: ttf, fontSize: 12)),
                  pw.Text('الملحقات: ${ticket.accessories}', style: pw.TextStyle(font: ttf, fontSize: 12)),
                  pw.SizedBox(height: 10),
                  pw.Text('تاريخ الاستلام: ${ticket.dateReceived}', style: pw.TextStyle(font: ttf, fontSize: 12)),
                  pw.SizedBox(height: 20),
                  pw.Text('شكرا لثقتكم بنا', style: pw.TextStyle(font: ttf, fontSize: 14, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Maintenance_Receipt_${ticket.id}',
    );
  }

  Future<void> _withdrawSpareParts(BuildContext context, MaintenanceTicket ticket) async {
    final products = await _dbHelper.getProducts();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('سحب قطع الغيار (المخزون)'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    title: Text(product.name),
                    subtitle: Text('الكمية المتاحة: ${product.quantity} | السعر: ${product.price}'),
                    trailing: ElevatedButton(
                      onPressed: product.quantity > 0 ? () async {
                        // Deduct 1 item
                        final updatedProduct = Product(
                          id: product.id,
                          name: product.name,
                          barcode: product.barcode,
                          cost: product.cost,
                          price: product.price,
                          quantity: product.quantity - 1,
                          minQuantity: product.minQuantity,
                        );
                        await _dbHelper.updateProduct(updatedProduct);

                        // Increase estimated cost
                        final updatedTicket = MaintenanceTicket(
                           id: ticket.id,
                           customerName: ticket.customerName,
                           customerPhone: ticket.customerPhone,
                           deviceModel: ticket.deviceModel,
                           imei: ticket.imei,
                           passcode: ticket.passcode,
                           taskType: ticket.taskType,
                           accessories: ticket.accessories,
                           estimatedCost: ticket.estimatedCost + product.price,
                           initialNotes: ticket.initialNotes,
                           status: ticket.status,
                           dateReceived: ticket.dateReceived,
                        );
                        await _dbHelper.updateMaintenanceTicket(updatedTicket);

                        if (context.mounted) {
                           Navigator.pop(ctx);
                           _loadTickets();
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('تم سحب قطعة: ${product.name}')),
                           );
                        }
                      } : null,
                      child: const Text('سحب (1)'),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
            ],
          );
        }
      );
    }
  }

  void _showTicketDialog({MaintenanceTicket? ticket}) {
    final nameController = TextEditingController(text: ticket?.customerName ?? '');
    final phoneController = TextEditingController(text: ticket?.customerPhone ?? '');
    final modelController = TextEditingController(text: ticket?.deviceModel ?? '');
    final imeiController = TextEditingController(text: ticket?.imei ?? '');
    final passcodeController = TextEditingController(text: ticket?.passcode ?? '');
    final costController = TextEditingController(text: ticket?.estimatedCost.toString() ?? '');
    final notesController = TextEditingController(text: ticket?.initialNotes ?? '');

    String taskType = ticket?.taskType ?? 'Hardware';
    String status = ticket?.status ?? 'مستلم';

    // Accessories state
    bool hasSim = ticket?.accessories.contains('SIM') ?? false;
    bool hasSdCard = ticket?.accessories.contains('SD') ?? false;
    bool hasCase = ticket?.accessories.contains('Case') ?? false;
    bool hasCharger = ticket?.accessories.contains('Charger') ?? false;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: Text(ticket == null ? 'استلام جهاز جديد' : 'تعديل حالة الصيانة'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Customer Info
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'اسم العميل'),
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
                              if (isGranted) {
                                final contact = await FlutterContacts.native.showPicker(properties: {ContactProperty.phone});
                                if (contact != null && contact.phones.isNotEmpty) {
                                  phoneController.text = contact.phones.first.number.replaceAll(RegExp(r'[\s\-]'), '');
                                  if (nameController.text.isEmpty) nameController.text = contact.displayName ?? '';
                                }
                              }
                            },
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                      ),
                      const Divider(),
                      // Device Info
                      TextFormField(
                        controller: modelController,
                        decoration: const InputDecoration(labelText: 'نوع الجهاز وموديله'),
                        validator: (val) => val == null || val.isEmpty ? 'مطلوب' : null,
                      ),
                      TextFormField(
                        controller: imeiController,
                        decoration: InputDecoration(
                          labelText: 'رقم الـ IMEI',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () async {
                              final scanned = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ScannerScreen()),
                              );
                              if (scanned != null && scanned is String) {
                                imeiController.text = scanned;
                              }
                            },
                          )
                        ),
                      ),
                      TextFormField(
                        controller: passcodeController,
                        decoration: const InputDecoration(labelText: 'رمز القفل (أو النمط)'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: taskType,
                        decoration: const InputDecoration(labelText: 'نوع الصيانة'),
                        items: const [
                          DropdownMenuItem(value: 'Hardware', child: Text('هاردوير (تغيير شاشة، بطارية، إلخ)')),
                          DropdownMenuItem(value: 'Software', child: Text('سوفتوير (تفليش، برمجة، تخطي)')),
                        ],
                        onChanged: (val) {
                          if(val != null) setStateSB(() => taskType = val);
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text('المرفقات المستلمة:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 10,
                        children: [
                          FilterChip(label: const Text('شريحة SIM'), selected: hasSim, onSelected: (v) => setStateSB(() => hasSim = v)),
                          FilterChip(label: const Text('بطاقة ذاكرة'), selected: hasSdCard, onSelected: (v) => setStateSB(() => hasSdCard = v)),
                          FilterChip(label: const Text('جراب'), selected: hasCase, onSelected: (v) => setStateSB(() => hasCase = v)),
                          FilterChip(label: const Text('شاحن'), selected: hasCharger, onSelected: (v) => setStateSB(() => hasCharger = v)),
                        ],
                      ),
                      const Divider(),
                      TextFormField(
                        controller: costController,
                        decoration: const InputDecoration(labelText: 'التكلفة التقديرية'),
                        keyboardType: TextInputType.number,
                      ),
                      TextFormField(
                        controller: notesController,
                        decoration: const InputDecoration(labelText: 'ملاحظات (خدوش، كسور مسبقة)'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 10),
                      if (ticket != null)
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(labelText: 'حالة الجهاز (Kanban)'),
                          items: const [
                            DropdownMenuItem(value: 'مستلم', child: Text('مستلم (في الدرج بانتظار الفحص)')),
                            DropdownMenuItem(value: 'قيد العمل', child: Text('قيد العمل')),
                            DropdownMenuItem(value: 'بانتظار موافقة', child: Text('بانتظار موافقة العميل')),
                            DropdownMenuItem(value: 'جاهز', child: Text('جاهز للتسليم')),
                            DropdownMenuItem(value: 'مرفوض/لا يصلح', child: Text('مرفوض/لا يمكن إصلاحه')),
                            DropdownMenuItem(value: 'تم التسليم', child: Text('تم التسليم (مكتمل)')),
                          ],
                          onChanged: (val) {
                            if(val != null) setStateSB(() => status = val);
                          },
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (ticket != null)
                  TextButton(
                    onPressed: () {
                      _withdrawSpareParts(context, ticket);
                    },
                    child: const Text('سحب قطع الغيار (المخزون)'),
                  ),
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      List<String> accList = [];
                      if (hasSim) accList.add('SIM');
                      if (hasSdCard) accList.add('SD');
                      if (hasCase) accList.add('Case');
                      if (hasCharger) accList.add('Charger');

                      final newTicket = MaintenanceTicket(
                        id: ticket?.id,
                        customerName: nameController.text,
                        customerPhone: phoneController.text,
                        deviceModel: modelController.text,
                        imei: imeiController.text,
                        passcode: passcodeController.text,
                        taskType: taskType,
                        accessories: accList.join(', '),
                        estimatedCost: double.tryParse(costController.text) ?? 0.0,
                        initialNotes: notesController.text,
                        status: status,
                        dateReceived: ticket?.dateReceived ?? DateTime.now().toIso8601String(),
                      );

                      if (ticket == null) {
                        await _dbHelper.insertMaintenanceTicket(newTicket);
                      } else {
                        await _dbHelper.updateMaintenanceTicket(newTicket);
                      }

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        _loadTickets();
                      }
                    }
                  },
                  child: const Text('حفظ الإيصال'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مستلم': return Colors.grey;
      case 'قيد العمل': return Colors.blue;
      case 'بانتظار موافقة': return Colors.orange;
      case 'جاهز': return Colors.green;
      case 'مرفوض/لا يصلح': return Colors.red;
      case 'تم التسليم': return Colors.purple;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الصيانة والبرمجة')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTicketDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tickets.isEmpty
              ? const Center(child: Text('لا توجد أجهزة في الصيانة حالياً.'))
              : ListView.builder(
                  itemCount: _tickets.length,
                  itemBuilder: (context, index) {
                    final ticket = _tickets[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(ticket.status),
                          child: Icon(
                            ticket.taskType == 'Hardware' ? Icons.hardware : Icons.computer,
                            color: Colors.white,
                          ),
                        ),
                        title: Text('${ticket.deviceModel} - ${ticket.customerName}'),
                        subtitle: Text(
                          'الحالة: ${ticket.status}\nالتكلفة التقديرية: ${settings.formatCurrency(ticket.estimatedCost)}',
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.print, color: Colors.blue),
                          onPressed: () {
                            _printTicketReceipt(ticket);
                          },
                        ),
                        onTap: () => _showTicketDialog(ticket: ticket),
                        onLongPress: () async {
                           final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: const Text('هل تريد حذف هذه التذكرة؟'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف')),
                              ],
                            ),
                          );
                          if (confirm == true && ticket.id != null) {
                            await _dbHelper.deleteMaintenanceTicket(ticket.id!);
                            _loadTickets();
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
