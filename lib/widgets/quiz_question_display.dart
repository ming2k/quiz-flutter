import 'package:flutter/material.dart';
import '../models/models.dart';
import 'markdown_content.dart';
import 'dopamine_click_wrapper.dart';

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
      key: const Key('quiz_question_listview'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        // Parent Content (Passage) for Reading Comprehension
        if (question.parentContent != null) ...[
          Container(
            key: const Key('quiz_question_parent_container'),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor.withValues(alpha: 0.1)),
            ),
            child: MarkdownContent(
              key: const Key('quiz_question_parent_markdown'),
              content: question.parentContent!,
              imageBasePath: imageBasePath,
              fontSize: 16,
              textColor: textColor,
            ),
          ),
          const Divider(key: Key('quiz_question_parent_divider'), height: 32),
        ],

        // Question Content (Stem)
        Padding(
          key: const Key('quiz_question_stem_padding'),
          padding: const EdgeInsets.only(bottom: 16),
          child: MarkdownContent(
            key: const Key('quiz_question_stem_markdown'),
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
          const SizedBox(height: 20, key: Key('quiz_question_explanation_spacer_top')),
          _buildExplanationCard(context),
        ],
        const SizedBox(height: 32, key: Key('quiz_question_bottom_spacer')),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DopamineClickWrapper(
        key: Key('option_wrapper_${entry.key}'),
        isCorrect: showAnswer && isCorrect,
        child: Material(
          key: Key('option_material_${entry.key}'),
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('option_inkwell_${entry.key}'),
            onTap: () {
              if (!showAnswer && onOptionSelected != null) {
                onOptionSelected!(entry.key);
              }
            },
            child: Container(
              key: Key('option_container_${entry.key}'),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected || (showAnswer && isCorrect) 
                    ? Border.all(color: labelColor, width: 1)
                    : Border.all(color: textColor.withValues(alpha: 0.12), width: 1),
              ),
              child: Row(
                key: Key('option_row_${entry.key}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: Key('option_label_container_${entry.key}'),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: labelColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.key,
                      key: Key('option_label_text_${entry.key}'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: labelTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 14, key: Key('option_spacer_${entry.key}')),
                  Expanded(
                    key: Key('option_content_expanded_${entry.key}'),
                    child: Padding(
                      key: Key('option_content_padding_${entry.key}'),
                      padding: const EdgeInsets.only(top: 4),
                      child: MarkdownContent(
                        key: Key('option_content_markdown_${entry.key}'),
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
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationCard(BuildContext context) {
    return Container(
      key: const Key('quiz_explanation_container'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        key: const Key('quiz_explanation_column'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            key: const Key('quiz_explanation_header_row'),
            children: [
              const Icon(Icons.lightbulb_outline, key: Key('quiz_explanation_icon'), color: Colors.orange, size: 20),
              const SizedBox(width: 8, key: Key('quiz_explanation_header_spacer')),
              Text(
                '解析',
                key: const Key('quiz_explanation_title'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8, key: Key('quiz_explanation_content_spacer')),
          MarkdownContent(
            key: const Key('quiz_explanation_markdown'),
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