import 'package:flutter_test/flutter_test.dart';

import 'package:quiz_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const QuizApp());
    await tester.pump();

    expect(find.text('船员考试题库'), findsOneWidget);
  });
}
