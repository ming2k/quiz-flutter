import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mnema/providers/settings_provider.dart';
import 'package:mnema/widgets/markdown_content.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('MarkdownContent renders exact provided string', (
    WidgetTester tester,
  ) async {
    const testContent =
        r"此题的依据为经验公式$S=0.101\Deltav_{0}^{2}/R_{0}$，$t=0.004\Deltav_{0}/R_{0}$，其中，$S$为船舶由静止状态进车达到相应稳定航速的前进距离，$t$为船舶由静止状态进车达到相应稳定航速时的时间，$\Delta$为排水量，$v_{0}$为相应稳定航速，$R_{0}$为相应稳定航速下的阻力（与推力相等）。$t_{0}=0.004\frac{\Deltav_{0}}{R_{0}} S_{0}=0.101\frac{\Deltav_{0}^{2}}{R_{0}}$";
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: const MaterialApp(
          home: Scaffold(body: MarkdownContent(content: testContent)),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(Math), findsAtLeastNWidgets(1));
  });
}
