import 'package:flutter_test/flutter_test.dart';

import 'package:babas_app/main.dart';

void main() {
  testWidgets('app launches and shows splash screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Babas'), findsWidgets);
  });
}
