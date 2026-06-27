import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smart_pos/main.dart';
import 'package:smart_pos/providers/cart_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_pos/providers/settings_provider.dart';

void main() {
  // Initialize sqflite for desktop/test environment
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads and shows Dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: const SmartPOSApp(),
      ),
    );

    // Wait for the SettingsProvider to load and animations to complete
    for(int i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    // Verify that the Home Screen title is present.
    // By default SettingsProvider sets isBiometricEnabled to false, so HomeScreen should show up.
    expect(find.text('لوحة التحكم الرئيسية'), findsOneWidget);

    // Verify that the navigation cards are present.
    expect(find.text('نقطة البيع'), findsOneWidget);
    expect(find.text('إدارة المخزون'), findsOneWidget);
  });
}
