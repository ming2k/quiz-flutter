import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'markdown_content.dart';
import 'dopamine_click_wrapper.dart';

class QuestionDisplay extends StatelessWidget {
  final Question question;
  final String? selectedOption;
  final bool showAnswer;
  final bool showAnalysis;
  final bool hideOptions;
  final String? imageBasePath;
  final void Function(String)? onOptionSelected;
  final String? highlightedOption;
  final Color primaryColor;
  final Color errorColor;
  final Color successColor;
  final Color surfaceColor;
  final Color textColor;

  const QuestionDisplay({
    super.key,
    required this.question,
    this.selectedOption,
    this.showAnswer = false,
    this.showAnalysis = true,
    this.hideOptions = false,
    this.imageBasePath,
    this.onOptionSelected,
    this.highlightedOption,
    required this.primaryColor,
    required this.errorColor,
    required this.successColor,
    required this.surfaceColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Using Column instead of ListView because QuestionDisplay is often
    // placed inside another scrollable (PageView, SingleChildScrollView,
    // or ListView). Nesting scrollables causes unbounded-height errors.
    return Column(
      key: const Key('question_question_column'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Parent Content (Passage) for Reading Comprehension
        if (question.parentContent != null) ...[
          Container(
            key: const Key('question_question_parent_container'),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: surfaceColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: textColor.withValues(alpha: 0.1)),
            ),
            child: MarkdownContent(
              key: const Key('question_question_parent_markdown'),
              content: question.parentContent!,
              imageBasePath: imageBasePath,
              fontSize: 16,
              textColor: textColor,
            ),
          ),
          const Divider(
            key: Key('question_question_parent_divider'),
            height: 32,
          ),
        ],

        // Question Content (Stem)
        Padding(
          key: const Key('question_question_stem_padding'),
          padding: const EdgeInsets.only(bottom: 16),
          child: MarkdownContent(
            key: const Key('question_question_stem_markdown'),
            content: question.displayFront,
            imageBasePath: imageBasePath,
            fontSize: 18,
            textColor: textColor,
          ),
        ),

        // Options
        if (!hideOptions)
          ...question.choiceEntries.map(
            (entry) => _buildOptionCard(context, entry),
          ),

        if (showAnswer && !hideOptions && question.needsAnswerReveal) ...[
          const SizedBox(height: 8, key: Key('question_answer_spacer_top')),
          _buildAnswerCard(context),
        ],

        // Explanation
        if (showAnswer &&
            !hideOptions &&
            !question.needsAnswerReveal &&
            question.explanation.isNotEmpty) ...[
          const SizedBox(
            height: 20,
            key: Key('question_question_explanation_spacer_top'),
          ),
          _buildExplanationCard(context),
        ],
        const SizedBox(height: 32, key: Key('question_question_bottom_spacer')),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    MapEntry<String, String> entry,
  ) {
    final bool isSelected = selectedOption == entry.key;
    final bool isCorrect =
        entry.key.toUpperCase() == question.answer.toUpperCase();
    final bool isHighlighted =
        !showAnswer && highlightedOption == entry.key && !isSelected;

    Color cardColor = surfaceColor;
    Color labelColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    Color labelTextColor = textColor;
    Color borderColor = textColor.withValues(alpha: 0.12);
    double borderWidth = 1;

    if (showAnswer) {
      if (isCorrect) {
        cardColor = successColor.withValues(alpha: 0.1);
        labelColor = successColor;
        labelTextColor = Colors.white;
        borderColor = labelColor;
      } else if (isSelected) {
        cardColor = errorColor.withValues(alpha: 0.1);
        labelColor = errorColor;
        labelTextColor = Colors.white;
        borderColor = labelColor;
      }
    } else if (isSelected) {
      cardColor = primaryColor.withValues(alpha: 0.1);
      labelColor = primaryColor;
      labelTextColor = Colors.white;
      borderColor = labelColor;
    } else if (isHighlighted) {
      cardColor = primaryColor.withValues(alpha: 0.06);
      labelColor = primaryColor.withValues(alpha: 0.18);
      labelTextColor = primaryColor;
      borderColor = primaryColor;
      borderWidth = 2;
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
                border: Border.all(color: borderColor, width: borderWidth),
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
      key: const Key('question_explanation_container'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        key: const Key('question_explanation_column'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            key: const Key('question_explanation_header_row'),
            children: [
              Icon(
                Icons.lightbulb_outline,
                key: const Key('question_explanation_icon'),
                color: AppTheme.warning,
                size: 20,
              ),
              const SizedBox(
                width: 8,
                key: Key('question_explanation_header_spacer'),
              ),
              Text(
                AppLocalizations.of(context).analysis,
                key: const Key('question_explanation_title'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 8,
            key: Key('question_explanation_content_spacer'),
          ),
          MarkdownContent(
            key: const Key('question_explanation_markdown'),
            content: question.explanation,
            imageBasePath: imageBasePath,
            fontSize: 15,
            textColor: textColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(BuildContext context) {
    return Container(
      key: const Key('question_answer_container'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: successColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        key: const Key('question_answer_column'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            key: const Key('question_answer_header_row'),
            children: [
              Icon(
                Icons.check_circle_outline,
                key: const Key('question_answer_icon'),
                color: successColor,
                size: 20,
              ),
              const SizedBox(width: 8, key: Key('question_answer_header_gap')),
              Text(
                AppLocalizations.of(context).answer,
                key: const Key('question_answer_title'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: successColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8, key: Key('question_answer_content_gap')),
          MarkdownContent(
            key: const Key('question_answer_markdown'),
            content: question.displayBack,
            imageBasePath: imageBasePath,
            fontSize: 15,
            textColor: textColor,
          ),
        ],
      ),
    );
  }
}
