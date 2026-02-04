import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_display.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentIndex();
    });
  }

  void _scrollToCurrentIndex() {
    final quiz = context.read<QuizProvider>();
    final currentIndex = quiz.currentIndex;
    
    // Grid calculations
    const int crossAxisCount = 6;
    const double crossAxisSpacing = 8.0;
    const double mainAxisSpacing = 8.0;
    const double padding = 16.0;
    
    final double screenWidth = MediaQuery.of(context).size.width;
    final double availableWidth = screenWidth - (padding * 2) - ((crossAxisCount - 1) * crossAxisSpacing);
    final double itemWidth = availableWidth / crossAxisCount;
    // Aspect ratio 1.0 means height = width
    final double itemHeight = itemWidth;
    
    final int row = currentIndex ~/ crossAxisCount;
    final double offset = row * (itemHeight + mainAxisSpacing);
    
    // Scroll with a bit of offset to show context if possible
    final double targetOffset = (offset - 100).clamp(0.0, _scrollController.position.maxScrollExtent);
    
    _scrollController.jumpTo(targetOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.overview),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quiz, child) {
          return Column(
            children: [
              // Legend
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(
                      context,
                      color: Colors.grey.shade300,
                      label: l10n.get('unanswered'),
                    ),
                    _buildLegendItem(
                      context,
                      color: AppTheme.successLight,
                      label: l10n.get('correct'),
                    ),
                    _buildLegendItem(
                      context,
                      color: AppTheme.errorLight,
                      label: l10n.get('wrong'),
                    ),
                    _buildLegendItem(
                      context,
                      color: AppTheme.warningLight,
                      label: l10n.get('marked'),
                    ),
                  ],
                ),
              ),

              // Question Grid
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: quiz.totalQuestions,
                  itemBuilder: (context, index) {
                    final status = quiz.getQuestionStatus(index);
                    final isCurrentQuestion = index == quiz.currentIndex;

                    return GestureDetector(
                      onTap: () {
                        quiz.goToQuestion(index);
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrentQuestion
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == QuestionStatus.unanswered
                                  ? Colors.black54
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Stats Bar
              StatsDisplay(
                key: const Key('overview_stats_display'),
                currentIndex: quiz.currentIndex,
                totalQuestions: quiz.totalQuestions,
                correctCount: quiz.correctCount,
                wrongCount: quiz.wrongCount,
                accuracy: quiz.accuracy,
                isTestMode: quiz.isTestActive,
                testStartTime: quiz.testStartTime,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context, {
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Color _getStatusColor(QuestionStatus status) {
    switch (status) {
      case QuestionStatus.unanswered:
        return Colors.grey.shade300;
      case QuestionStatus.correct:
        return AppTheme.successLight;
      case QuestionStatus.wrong:
        return AppTheme.errorLight;
      case QuestionStatus.marked:
        return AppTheme.warningLight;
    }
  }
}
