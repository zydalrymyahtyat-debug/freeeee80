import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  String _currency = 'YER'; // Default currency
  bool _isDarkMode = false;
  bool _isBiometricEnabled = false;

  String get currency => _currency;
  bool get isDarkMode => _isDarkMode;
  bool get isBiometricEnabled => _isBiometricEnabled;

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('currency') ?? 'YER';
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setCurrency(String newCurrency) async {
    _currency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', newCurrency);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
    notifyListeners();
  }

  Future<void> toggleBiometric(bool value) async {
    _isBiometricEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBiometricEnabled', value);
    notifyListeners();
  }

  // Helper method to format currency
  String formatCurrency(double amount) {
    if (_currency == 'YER') {
      return '${amount.toStringAsFixed(0)} ريال';
    } else if (_currency == 'SAR') {
      return '${amount.toStringAsFixed(2)} ر.س';
    } else if (_currency == 'USD') {
      return '\$${amount.toStringAsFixed(2)}';
    }
    return '${amount.toStringAsFixed(2)} $_currency';
  }
}
