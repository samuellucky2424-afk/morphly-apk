import 'package:flutter_test/flutter_test.dart';
import 'package:morphly/morphly_app.dart';

void main() {
  testWidgets('Morphly boots to the enhanced splash screen', (tester) async {
    await tester.pumpWidget(const MorphlyApp());

    expect(find.text('Morphly'), findsOneWidget);
    expect(find.text('AI Live Camera'), findsOneWidget);
  });
}
