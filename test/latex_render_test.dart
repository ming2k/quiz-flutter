import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app/widgets/markdown_content.dart';
import 'package:flutter_math_fork/flutter_math.dart';

void main() {
  testWidgets('MarkdownContent renders exact provided string', (WidgetTester tester) async {
    // Exact string from user (with double backslashes which in JSON is a single backslash in memory)
    // If the user's data has "S=0.101\\Delta v", then in Dart string it's "S=0.101\Delta v"
    const testContent = r"此题的依据为经验公式$S=0.101\Deltav_{0}^{2}/R_{0}$，$t=0.004\Deltav_{0}/R_{0}$，其中，$S$为船舶由静止状态进车达到相应稳定航速的前进距离，$t$为船舶由静止状态进车达到相应稳定航速时的时间，$\Delta$为排水量，$v_{0}$为相应稳定航速，$R_{0}$为相应稳定航速下的阻力（与推力相等）。$t_{0}=0.004\frac{\Deltav_{0}}{R_{0}} S_{0}=0.101\frac{\Deltav_{0}^{2}}{R_{0}}$";

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarkdownContent(content: testContent),
        ),
      ),
    );

    // Verify that it doesn't crash and at least some Math widgets are found
    expect(find.byType(Math), findsAtLeastNWidgets(1));
  });
}