import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:smart_pos/main.dart';
import 'package:smart_pos/providers/cart_provider.dart';
import 'package:smart_pos/providers/settings_provider.dart';

void main() {
  // Initialize sqflite for desktop/test environment
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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

    // After updating to check biometric, we have to pump and wait
    await tester.pumpAndSettle();

    // Verify that either the Home Screen or Auth Screen is present.
    // By default SettingsProvider sets isBiometricEnabled to false, so HomeScreen should show up.
    expect(find.text('لوحة التحكم الرئيسية'), findsOneWidget);

    // Verify that the navigation cards are present.
    expect(find.text('نقطة البيع'), findsOneWidget);
    expect(find.text('إدارة المخزون'), findsOneWidget);
  });
}
