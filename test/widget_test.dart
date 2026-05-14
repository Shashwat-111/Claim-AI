// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:reimburse_ai/main.dart';
import 'package:reimburse_ai/provider/sheet_provider.dart';

void main() {
  testWidgets('App loads home title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SheetProvider(),
        child: const CopiousReimburseApp(),
      ),
    );

    expect(find.text('Copious ReimburseAI'), findsOneWidget);
  });
}
