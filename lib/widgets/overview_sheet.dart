import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_display.dart';
import 'bottom_sheet_handle.dart';

class OverviewSheet extends StatefulWidget {
  const OverviewSheet({super.key});

  @override
  State<OverviewSheet> createState() => _OverviewSheetState();
}

class _OverviewSheetState extends State<OverviewSheet> {
  ScrollController? _scrollController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scrollController == null) {
      final quiz = context.read<QuizProvider>();
      final currentIndex = quiz.currentIndex;

      // Grid calculations
      const int crossAxisCount = 6;
      const double crossAxisSpacing = 8.0;
      const double mainAxisSpacing = 8.0;
      const double padding = 16.0;

      final double screenWidth = MediaQuery.of(context).size.width;
      final double availableWidth = screenWidth -
          (padding * 2) -
          ((crossAxisCount - 1) * crossAxisSpacing);
      final double itemWidth = availableWidth / crossAxisCount;
      // Aspect ratio 1.0 means height = width
      final double itemHeight = itemWidth;

      final int row = currentIndex ~/ crossAxisCount;
      final double offset = row * (itemHeight + mainAxisSpacing);

      // Scroll with a bit of offset to show context if possible
      // We can't clamp to maxScrollExtent here easily because we don't know the content size yet,
      // but ScrollController handles out of bounds reasonably well (or we can clamp to 0.0 minimum).
      final double targetOffset = (offset - 100).clamp(0.0, double.infinity);

      _scrollController = ScrollController(initialScrollOffset: targetOffset);
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Consumer<QuizProvider>(
          builder: (context, quiz, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                const BottomSheetHandle(),
                
                // Title
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    l10n.overview,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 16),

                // Question Grid
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: GridView.builder(
                      controller: _scrollController!,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: quiz.totalQuestions,
                      itemBuilder: (context, index) {
                        final status = quiz.getQuestionStatus(index);
                        final isCurrentQuestion = index == quiz.currentIndex;
                        final isDark = Theme.of(context).brightness == Brightness.dark;

                        return GestureDetector(
                          onTap: () {
                            quiz.goToQuestion(index);
                            Navigator.pop(context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: _getStatusColor(context, status),
                              borderRadius: BorderRadius.circular(8),
                              border: isCurrentQuestion
                                  ? Border.all(
                                      color: Theme.of(context).colorScheme.primary,
                                      width: 3,
                                    )
                                  : Border.all(
                                      color: isDark ? Colors.white10 : Colors.black12,
                                      width: 1,
                                    ),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: status == QuestionStatus.unanswered
                                      ? (isDark ? Colors.white70 : Colors.black54)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Stats Bar
                StatsDisplay(
                  key: const Key('overview_stats_display'),
                  currentIndex: quiz.currentIndex,
                  totalQuestions: quiz.totalQuestions,
                  correctCount: quiz.correctCount,
                  wrongCount: quiz.wrongCount,
                  markedCount: quiz.markedCount,
                  accuracy: quiz.accuracy,
                  isTestMode: quiz.isTestActive,
                  testStartTime: quiz.testStartTime,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, QuestionStatus status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (status) {
      case QuestionStatus.unanswered:
        return isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200;
      case QuestionStatus.correct:
        return AppTheme.success;
      case QuestionStatus.wrong:
        return Theme.of(context).colorScheme.error;
      case QuestionStatus.marked:
        return AppTheme.warning;
    }
  }
}
