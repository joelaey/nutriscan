// NutriScan Widget Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:nutriscan/main.dart';

void main() {
  testWidgets('NutriScan app loads correctly', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const NutriScanApp());

    // Verify the app loads (splash screen shows NutriScan)
    await tester.pumpAndSettle(const Duration(seconds: 1));
    
    // Basic smoke test - app should build without errors
    expect(find.byType(NutriScanApp), findsOneWidget);
  });
}
