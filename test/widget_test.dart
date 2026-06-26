import 'package:flutter_test/flutter_test.dart';

import 'package:smart_pos/main.dart';

void main() {
  testWidgets('App loads and shows Dashboard', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartPOSApp());

    // Verify that the Home Screen title is present.
    expect(find.text('لوحة التحكم الرئيسية'), findsOneWidget);

    // Verify that the navigation cards are present.
    expect(find.text('نقطة البيع'), findsOneWidget);
    expect(find.text('إدارة المخزون'), findsOneWidget);
  });
}
