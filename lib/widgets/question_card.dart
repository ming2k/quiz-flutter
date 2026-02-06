import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'quiz_question_display.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final int? questionIndex;
  final int? totalQuestions;
  final String? selectedOption;
  final bool showAnswer;
  final bool? isCorrect;
  final bool isMarked;
  final bool showAnalysis;
  final void Function(String)? onOptionSelected;
  final VoidCallback? onMarkToggle;
  final VoidCallback? onReset;
  final VoidCallback? onAiExplain;
  final String? imageBasePath;

  const QuestionCard({
    super.key,
    required this.question,
    this.questionIndex,
    this.totalQuestions,
    this.selectedOption,
    this.showAnswer = false,
    this.isCorrect,
    this.isMarked = false,
    this.showAnalysis = true,
    this.onOptionSelected,
    this.onMarkToggle,
    this.onReset,
    this.onAiExplain,
    this.imageBasePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      key: const Key('question_card_column'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Row (Order, AI, Mark, Reset)
        Padding(
          key: const Key('question_card_header_padding'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            key: const Key('question_card_header_row'),
            children: [
              Text(
                key: const Key('question_card_index_text'),
                questionIndex != null && totalQuestions != null
                    ? '${questionIndex! + 1} / $totalQuestions'
                    : 'ID: ${question.id}',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(key: Key('question_card_header_spacer')),
              if (onAiExplain != null)
                IconButton(
                  key: const Key('question_ai_button'),
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: onAiExplain,
                  tooltip: 'AI Explain',
                ),
              if (onMarkToggle != null)
                IconButton(
                  key: const Key('question_mark_button'),
                  icon: Icon(
                    isMarked ? Icons.bookmark : Icons.bookmark_border,
                    color: isMarked ? AppTheme.warning : null,
                  ),
                  onPressed: onMarkToggle,
                  tooltip: isMarked ? 'Unmark' : 'Mark',
                ),
              IconButton(
                key: const Key('question_reset_button'),
                icon: const Icon(Icons.refresh),
                onPressed: onReset,
                tooltip: 'Reset',
              ),
            ],
          ),
        ),

        // WebView Content (Stem + Options + Explanation)
        Expanded(
          key: const Key('question_card_display_expanded'),
          child: QuizQuestionDisplay(
            key: const Key('question_card_display'),
            question: question,
            selectedOption: selectedOption,
            showAnswer: showAnswer,
            showAnalysis: showAnalysis,
            imageBasePath: imageBasePath,
            onOptionSelected: onOptionSelected,
            primaryColor: colorScheme.primary,
            errorColor: colorScheme.error,
            successColor: AppTheme.success,
            surfaceColor: colorScheme.surface,
            textColor: theme.textTheme.bodyLarge?.color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}