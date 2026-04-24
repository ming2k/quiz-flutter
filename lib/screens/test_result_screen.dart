import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/dopamine_click_wrapper.dart';
import 'practice_screen.dart';

class TestResultScreen extends StatelessWidget {
  final TestHistoryEntry result;
  final VoidCallback? onReviewMistakes;
  final VoidCallback? onRetake;

  const TestResultScreen({
    super.key,
    required this.result,
    this.onReviewMistakes,
    this.onRetake,
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
        title: Text(l10n.testResult),
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
              l10n.accuracy,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.format_list_numbered,
                    label: l10n.totalQuestions,
                    value: result.totalQuestions.toString(),
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.check,
                    label: l10n.correctCount,
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
                    label: l10n.wrongCount,
                    value: result.wrongCount.toString(),
                    color: failColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    icon: Icons.radio_button_unchecked,
                    label: l10n.unansweredCount,
                    value: result.unansweredCount.toString(),
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    Icon(Icons.timer, color: AppTheme.warning),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.timeTaken,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            if (result.wrongCount > 0)
              DopamineClickWrapper(
                child: ElevatedButton.icon(
                  onPressed: onReviewMistakes ?? () {},
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: colorScheme.errorContainer,
                    foregroundColor: colorScheme.error,
                  ),
                  icon: const Icon(Icons.error_outline),
                  label: Text(l10n.reviewMistakes),
                ),
              ),
            if (result.wrongCount > 0) const SizedBox(height: 12),
            DopamineClickWrapper(
              child: OutlinedButton.icon(
                onPressed: onRetake ?? () {},
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.replay),
                label: Text(l10n.retakeTest),
              ),
            ),
            const SizedBox(height: 12),
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
                child: Text(l10n.backToHome),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
