import 'package:cashe/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots to the home route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CasheApp()));
    await tester.pumpAndSettle();

    expect(find.text('Cashe'), findsOneWidget);
  });
}
