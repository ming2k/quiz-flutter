import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ReviewScreen extends StatelessWidget {
  final Book book;

  const ReviewScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReviewProvider()..startReview(book),
      child: const _ReviewScreenBody(),
    );
  }
}

class _ReviewScreenBody extends StatefulWidget {
  const _ReviewScreenBody();

  @override
  State<_ReviewScreenBody> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreenBody> {
  // ReviewProvider is already initialized with startReview(book)
  // by the parent ReviewScreen via ChangeNotifierProvider.create.
  // No additional initState setup needed.

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final review = context.watch<ReviewProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              review.currentBook?.getDisplayName(Localizations.localeOf(context).languageCode) ?? l10n.memoryReview,
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              review.isComplete
                  ? l10n.complete
                  : '${review.currentIndex + 1} / ${review.total}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary.withAlpha(200),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: review.isLoading
          ? const Center(child: CircularProgressIndicator())
          : review.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(review.error!, style: TextStyle(color: colorScheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final book = context.read<PracticeProvider>().currentBook;
                          if (book != null) {
                            context.read<ReviewProvider>().startReview(book);
                          }
                        },
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : review.isComplete
                  ? _buildCompletionView(context, review)
                  : _buildReviewView(context, review),
    );
  }

  Widget _buildReviewView(BuildContext context, ReviewProvider review) {
    final l10n = AppLocalizations.of(context);
    final question = review.currentQuestion;
    if (question == null || question.id == -1) {
      return Center(child: Text(l10n.noReviewQuestions));
    }

    final colorScheme = Theme.of(context).colorScheme;
    final quiz = context.read<PracticeProvider>();

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: review.total > 0 ? review.currentIndex / review.total : 0,
          backgroundColor: colorScheme.surfaceContainerHighest,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question content
                QuestionDisplay(
                  question: question,
                  showAnswer: review.showAnswer,
                  hideOptions: !review.showAnswer,
                  showAnalysis: true,
                  imageBasePath: quiz.currentPackageImagePath,
                  onOptionSelected: null,
                  primaryColor: colorScheme.primary,
                  errorColor: colorScheme.error,
                  successColor: AppTheme.success,
                  surfaceColor: colorScheme.surfaceContainerHighest,
                  textColor: colorScheme.onSurface,
                ),

                // AI Explain button (only when answer is shown)
                if (review.showAnswer) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showAiPanel(context, question),
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      label: Text(AppLocalizations.of(context).aiExplain),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        ReviewControls(
          showAnswer: review.showAnswer,
          onShowAnswer: review.revealAnswer,
          onRate: review.rateCard,
          srsState: review.currentSrsState,
        ),
      ],
    );
  }

  Widget _buildCompletionView(BuildContext context, ReviewProvider review) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.reviewComplete,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.reviewedCount(review.total),
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: Text(l10n.backToHome),
            ),
          ],
        ),
      ),
    );
  }

  void _showAiPanel(BuildContext context, Question question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiChatPanel(question: question),
    );
  }
}
