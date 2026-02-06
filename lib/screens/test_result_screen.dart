import 'package:flutter/material.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/dopamine_click_wrapper.dart';

class TestResultScreen extends StatelessWidget {
  final TestHistoryEntry result;

  const TestResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isPass = result.accuracy >= 0.6;
    final passColor = AppTheme.success;
    final failColor = colorScheme.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('testResult')),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Result Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isPass
                    ? passColor.withValues(alpha: 0.2)
                    : failColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPass ? Icons.check_circle : Icons.cancel,
                size: 80,
                color: isPass ? passColor : failColor,
              ),
            ),
            const SizedBox(height: 24),

            // Accuracy
            Text(
              result.accuracyPercent,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPass ? passColor : failColor,
                  ),
            ),
            Text(
              l10n.get('accuracy'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 32),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.help_outline,
                    label: l10n.get('totalQuestions'),
                    value: result.totalQuestions.toString(),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.check,
                    label: l10n.get('correctCount'),
                    value: result.correctCount.toString(),
                    color: passColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.close,
                    label: l10n.get('wrongCount'),
                    value: result.wrongCount.toString(),
                    color: failColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.remove_circle_outline,
                    label: l10n.get('unansweredCount'),
                    value: result.unansweredCount.toString(),
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Time Taken
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: Colors.orange),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.get('timeTaken'),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        Text(
                          result.formattedDuration,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      result.formattedDate,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            DopamineClickWrapper(
              key: const Key('result_home_wrapper'),
              child: ElevatedButton(
                key: const Key('result_home_button'),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(l10n.get('backToHome')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
