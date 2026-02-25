import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_display.dart';
import 'bottom_sheet_handle.dart';

enum _OverviewFilter { all, correct, wrong, marked, unanswered }

class OverviewSheet extends StatefulWidget {
  const OverviewSheet({super.key});

  @override
  State<OverviewSheet> createState() => _OverviewSheetState();
}

class _OverviewSheetState extends State<OverviewSheet> {
  ScrollController? _scrollController;
  _OverviewFilter _filter = _OverviewFilter.all;

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
      final double itemHeight = itemWidth;

      final int row = currentIndex ~/ crossAxisCount;
      final double offset = row * (itemHeight + mainAxisSpacing);

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
            // Build filtered index list
            final filteredIndices = _buildFilteredIndices(quiz);

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

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(context, l10n.all, _OverviewFilter.all, quiz),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, l10n.correct, _OverviewFilter.correct, quiz),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, l10n.wrong, _OverviewFilter.wrong, quiz),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, l10n.marked, _OverviewFilter.marked, quiz),
                      const SizedBox(width: 8),
                      _buildFilterChip(context, l10n.unanswered, _OverviewFilter.unanswered, quiz),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Question Grid
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: filteredIndices.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              '-',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          )
                        : GridView.builder(
                            controller: _scrollController!,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: filteredIndices.length,
                            itemBuilder: (context, i) {
                              final index = filteredIndices[i];
                              final status = quiz.getQuestionStatus(index);
                              final isCurrentQuestion = index == quiz.currentIndex;
                              final colorScheme = Theme.of(context).colorScheme;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  quiz.goToQuestion(index);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(context, status),
                                    borderRadius: BorderRadius.circular(8),
                                    border: isCurrentQuestion
                                        ? Border.all(
                                            color: colorScheme.primary,
                                            width: 3,
                                          )
                                        : Border.all(
                                            color: colorScheme.outlineVariant,
                                            width: 1,
                                          ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: status == QuestionStatus.unanswered
                                            ? colorScheme.onSurfaceVariant
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

  List<int> _buildFilteredIndices(QuizProvider quiz) {
    final total = quiz.totalQuestions;
    final indices = <int>[];
    for (int i = 0; i < total; i++) {
      final status = quiz.getQuestionStatus(i);
      final include = switch (_filter) {
        _OverviewFilter.all => true,
        _OverviewFilter.correct => status == QuestionStatus.correct,
        _OverviewFilter.wrong => status == QuestionStatus.wrong,
        _OverviewFilter.marked => status == QuestionStatus.marked,
        _OverviewFilter.unanswered => status == QuestionStatus.unanswered,
      };
      if (include) indices.add(i);
    }
    return indices;
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    _OverviewFilter filter,
    QuizProvider quiz,
  ) {
    final isSelected = _filter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filter = filter;
        });
      },
      showCheckmark: false,
    );
  }

  Color _getStatusColor(BuildContext context, QuestionStatus status) {
    switch (status) {
      case QuestionStatus.unanswered:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
      case QuestionStatus.correct:
        return AppTheme.success;
      case QuestionStatus.wrong:
        return Theme.of(context).colorScheme.error;
      case QuestionStatus.marked:
        return AppTheme.warning;
    }
  }
}
