import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/database_helper.dart';
import '../models/store_info.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _welcomeController = TextEditingController();

  StoreInfo? _storeInfo;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    final info = await _dbHelper.getStoreInfo();
    if (info != null) {
      setState(() {
        _storeInfo = info;
        _nameController.text = info.name;
        _phoneController.text = info.phone;
        _addressController.text = info.address;
        _welcomeController.text = info.welcomeMessage;
      });
    }
  }

  Future<void> _saveStoreInfo() async {
    if (_formKey.currentState!.validate()) {
      final info = StoreInfo(
        id: _storeInfo?.id,
        name: _nameController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        welcomeMessage: _welcomeController.text,
      );
      await _dbHelper.saveStoreInfo(info);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات المحل بنجاح!')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _welcomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('تفضيلات التطبيق', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          const Divider(),
          SwitchListTile(
            title: const Text('الوضع الداكن (Dark Mode)'),
            value: settings.isDarkMode,
            onChanged: (val) => settings.toggleDarkMode(val),
          ),
          SwitchListTile(
            title: const Text('قفل التطبيق بالبصمة'),
            value: settings.isBiometricEnabled,
            onChanged: (val) => settings.toggleBiometric(val),
          ),
          ListTile(
            title: const Text('العملة الافتراضية'),
            trailing: DropdownButton<String>(
              value: settings.currency,
              items: const [
                DropdownMenuItem(value: 'YER', child: Text('ريال يمني (YER)')),
                DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
                DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
              ],
              onChanged: (val) {
                if (val != null) settings.setCurrency(val);
              },
            ),
          ),

          const SizedBox(height: 24),
          const Text('بيانات المحل والترويسة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
          const Divider(),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم المحل'),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'العنوان'),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                TextFormField(
                  controller: _welcomeController,
                  decoration: const InputDecoration(labelText: 'الرسالة الترحيبية (أسفل الفاتورة)'),
                  validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _saveStoreInfo,
                  child: const Text('حفظ بيانات المحل'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
