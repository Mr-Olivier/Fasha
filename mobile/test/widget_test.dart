import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kazilink_rwanda/main.dart';

void main() {
  testWidgets('App boots and shows the setup placeholder screen',
      (WidgetTester tester) async {
    // ProviderScope is required here too - the real app never runs without
    // it, so the test environment shouldn't either.
    await tester.pumpWidget(const ProviderScope(child: KaziLinkApp()));

    expect(find.text('KaziLink Rwanda'), findsOneWidget);
    expect(find.textContaining('Project setup complete'), findsOneWidget);
  });
}
