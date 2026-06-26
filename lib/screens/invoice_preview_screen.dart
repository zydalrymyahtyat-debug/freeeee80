import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
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

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _device;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
    _initBluetooth();
  }

  Future<void> _loadStoreInfo() async {
    final info = await _dbHelper.getStoreInfo();
    setState(() {
      _storeInfo = info;
    });
  }

  Future<void> _initBluetooth() async {
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      // Ignore
    }

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() => _connected = true);
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() => _connected = false);
          break;
        default:
          break;
      }
    });

    setState(() {
      _devices = devices;
      _connected = isConnected ?? false;
    });
  }

  void _connect() {
    if (_device != null) {
      bluetooth.connect(_device!).catchError((error) {
        setState(() => _connected = false);
      });
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _connected = false);
  }

  Future<void> _printInvoice(SettingsProvider settings) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected == true) {
      bluetooth.printNewLine();
      if (_storeInfo != null) {
        bluetooth.printCustom(_storeInfo!.name, 2, 1);
        bluetooth.printCustom(_storeInfo!.address, 1, 1);
        bluetooth.printCustom(_storeInfo!.phone, 1, 1);
        bluetooth.printNewLine();
      }

      final dateFormatted = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(widget.sale.date));
      bluetooth.printCustom('رقم الفاتورة: ${widget.sale.id}', 1, 1);
      bluetooth.printCustom('التاريخ: $dateFormatted', 1, 1);
      bluetooth.printNewLine();

      bluetooth.printCustom('--------------------------------', 1, 1);
      for (var item in widget.items) {
        bluetooth.printLeftRight(
          '${item.productName} (x${item.quantity})',
          settings.formatCurrency(item.price * item.quantity),
          1
        );
      }
      bluetooth.printCustom('--------------------------------', 1, 1);

      bluetooth.printLeftRight('الإجمالي:', settings.formatCurrency(widget.sale.total), 2);

      if (_storeInfo != null && _storeInfo!.welcomeMessage.isNotEmpty) {
        bluetooth.printNewLine();
        bluetooth.printCustom(_storeInfo!.welcomeMessage, 1, 1);
      }

      bluetooth.printNewLine();
      bluetooth.printNewLine();
      bluetooth.paperCut();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء الاتصال بالطابعة أولاً')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('معاينة وطباعة الفاتورة')),
      body: Column(
        children: [
          // Bluetooth connection section
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.print),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<BluetoothDevice>(
                    items: _devices.map((d) => DropdownMenuItem(value: d, child: Text(d.name ?? 'Unknown'))).toList(),
                    onChanged: (device) {
                      setState(() => _device = device);
                    },
                    value: _device,
                    hint: const Text('اختر الطابعة'),
                    isExpanded: true,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _connected ? _disconnect : _connect,
                  child: Text(_connected ? 'قطع' : 'اتصال'),
                ),
              ],
            ),
          ),

          // Invoice Preview
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_storeInfo != null) ...[
                      Text(_storeInfo!.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text(_storeInfo!.address, textAlign: TextAlign.center),
                      Text(_storeInfo!.phone, textAlign: TextAlign.center),
                      const Divider(),
                    ],
                    Text('رقم الفاتورة: ${widget.sale.id}', textAlign: TextAlign.center),
                    Text('التاريخ: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(widget.sale.date))}', textAlign: TextAlign.center),
                    const Divider(),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('الصنف', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('الكمية', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('السعر', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    ...widget.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item.productName)),
                          Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(settings.formatCurrency(item.price * item.quantity)),
                        ],
                      ),
                    )),
                    const Divider(thickness: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الإجمالي الكلي:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(settings.formatCurrency(widget.sale.total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (_storeInfo != null && _storeInfo!.welcomeMessage.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(_storeInfo!.welcomeMessage, textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic)),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _printInvoice(settings),
        icon: const Icon(Icons.print),
        label: const Text('طباعة'),
      ),
    );
  }
}
