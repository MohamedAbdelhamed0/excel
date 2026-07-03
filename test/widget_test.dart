import 'package:excel_ai_analyzer/core/DI/platform_factory.dart';
import 'package:excel_ai_analyzer/core/DI/platform_providers.dart';
import 'package:excel_ai_analyzer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test renders mobile and desktop layouts', (WidgetTester tester) async {
    final mobileFactory = MobileServiceFactory();

    // Test Mobile Layout (width < 600)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformFactoryProvider.overrideWithValue(mobileFactory),
        ],
        child: const ExcelAiApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Excel AI Analyzer'), findsOneWidget);

    // Test Desktop Layout (width >= 600)
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          platformFactoryProvider.overrideWithValue(DesktopServiceFactory()),
        ],
        child: const ExcelAiApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Spreadsheet Intelligence Dashboard'), findsOneWidget);

    // Reset test view size
    addTearDown(tester.view.resetPhysicalSize);
  });
}
