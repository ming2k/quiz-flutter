import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'question_display.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final String? selectedOption;
  final bool showAnswer;
  final bool? isCorrect;
  final bool showAnalysis;
  final void Function(String)? onOptionSelected;
  final String? imageBasePath;
  final String? highlightedOption;

  const QuestionCard({
    super.key,
    required this.question,
    this.selectedOption,
    this.showAnswer = false,
    this.isCorrect,
    this.showAnalysis = true,
    this.onOptionSelected,
    this.imageBasePath,
    this.highlightedOption,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return QuestionDisplay(
      key: const Key('question_card_display'),
      question: question,
      selectedOption: selectedOption,
      showAnswer: showAnswer,
      showAnalysis: showAnalysis,
      imageBasePath: imageBasePath,
      onOptionSelected: onOptionSelected,
      highlightedOption: highlightedOption,
      primaryColor: colorScheme.primary,
      errorColor: colorScheme.error,
      successColor: AppTheme.success,
      surfaceColor: colorScheme.surface,
      textColor: theme.textTheme.bodyLarge?.color ?? Colors.black87,
    );
  }
}
