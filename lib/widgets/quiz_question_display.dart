import 'package:flutter/material.dart';
import '../models/models.dart';
import 'markdown_content.dart';

class QuizQuestionDisplay extends StatelessWidget {
  final Question question;
  final String? selectedOption;
  final bool showAnswer;
  final bool showAnalysis;
  final String? imageBasePath;
  final void Function(String)? onOptionSelected;
  final Color primaryColor;
  final Color errorColor;
  final Color successColor;
  final Color surfaceColor;
  final Color textColor;

  const QuizQuestionDisplay({
    super.key,
    required this.question,
    this.selectedOption,
    this.showAnswer = false,
    this.showAnalysis = true,
    this.imageBasePath,
    this.onOptionSelected,
    required this.primaryColor,
    required this.errorColor,
    required this.successColor,
    required this.surfaceColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Parent Content (Passage) for Reading Comprehension
        if (question.parentContent != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor.withValues(alpha: 0.1)),
            ),
            child: MarkdownContent(
              content: question.parentContent!,
              imageBasePath: imageBasePath,
              fontSize: 16,
              textColor: textColor,
            ),
          ),
          const Divider(height: 32),
        ],

        // Question Content (Stem)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: MarkdownContent(
            content: question.content,
            imageBasePath: imageBasePath,
            fontSize: 18,
            textColor: textColor,
          ),
        ),

        // Options
        ...question.choiceEntries.map((entry) => _buildOptionCard(context, entry)),

        // Explanation
        if (showAnswer && question.explanation.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildExplanationCard(context),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOptionCard(BuildContext context, MapEntry<String, String> entry) {
    final bool isSelected = selectedOption == entry.key;
    final bool isCorrect = entry.key.toUpperCase() == question.answer.toUpperCase();
    
    Color cardColor = surfaceColor;
    Color labelColor = Theme.of(context).brightness == Brightness.dark 
        ? Colors.grey[800]! 
        : Colors.grey[200]!;
    Color labelTextColor = textColor;

    if (showAnswer) {
      if (isCorrect) {
        cardColor = successColor.withValues(alpha: 0.1);
        labelColor = successColor;
        labelTextColor = Colors.white;
      } else if (isSelected) {
        cardColor = errorColor.withValues(alpha: 0.1);
        labelColor = errorColor;
        labelTextColor = Colors.white;
      }
    } else if (isSelected) {
      cardColor = primaryColor.withValues(alpha: 0.1);
      labelColor = primaryColor;
      labelTextColor = Colors.white;
    }

    return GestureDetector(
      onTap: () {
        if (!showAnswer && onOptionSelected != null) {
          onOptionSelected!(entry.key);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected || (showAnswer && isCorrect) 
              ? Border.all(color: labelColor, width: 1)
              : Border.all(color: textColor.withValues(alpha: 0.12), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: labelColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                entry.key,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: labelTextColor,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: MarkdownContent(
                  content: entry.value,
                  imageBasePath: imageBasePath,
                  fontSize: 16,
                  textColor: textColor,
                  selectable: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                '解析',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          MarkdownContent(
            content: question.explanation,
            imageBasePath: imageBasePath,
            fontSize: 15,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}