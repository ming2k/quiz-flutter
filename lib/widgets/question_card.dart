import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'quiz_question_display.dart';
import 'dopamine_click_wrapper.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final String? selectedOption;
  final bool showAnswer;
  final bool? isCorrect;
  final bool showAnalysis;
  final void Function(String)? onOptionSelected;
  final String? imageBasePath;

  const QuestionCard({
    super.key,
    required this.question,
    this.selectedOption,
    this.showAnswer = false,
    this.isCorrect,
    this.showAnalysis = true,
    this.onOptionSelected,
    this.imageBasePath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return QuizQuestionDisplay(
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
    );
  }
}