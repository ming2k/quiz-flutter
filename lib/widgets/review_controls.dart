import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/srs_state.dart';
import '../services/srs_service.dart';
import '../theme/app_theme.dart';

/// Bottom control bar for the Review Screen.
/// Shows "Show Answer" button when answer is hidden,
/// and SM-2 rating buttons (Again/Hard/Good/Easy) when revealed.
class ReviewControls extends StatelessWidget {
  final bool showAnswer;
  final VoidCallback onShowAnswer;
  final void Function(SrsRating) onRate;
  final SrsState? srsState;

  const ReviewControls({
    super.key,
    required this.showAnswer,
    required this.onShowAnswer,
    required this.onRate,
    this.srsState,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: showAnswer
              ? _buildRatingButtons(context)
              : _buildShowAnswerButton(context),
        ),
      ),
    );
  }

  Widget _buildShowAnswerButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: onShowAnswer,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          AppLocalizations.of(context).showAnswer,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRatingButtons(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratings = [
      (
        SrsRating.again,
        AppLocalizations.of(context).srsAgain,
        colorScheme.error,
        colorScheme.errorContainer,
      ),
      (
        SrsRating.hard,
        AppLocalizations.of(context).srsHard,
        AppTheme.warning,
        colorScheme.tertiaryContainer,
      ),
      (
        SrsRating.good,
        AppLocalizations.of(context).srsGood,
        colorScheme.primary,
        colorScheme.primaryContainer,
      ),
      (
        SrsRating.easy,
        AppLocalizations.of(context).srsEasy,
        AppTheme.success,
        colorScheme.secondaryContainer,
      ),
    ];

    return Row(
      children: ratings.map((rating) {
        final interval = srsState != null
            ? SrsService.intervalLabel(srsState!, rating.$1)
            : '';
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _RatingButton(
              label: rating.$2,
              sublabel: interval,
              foregroundColor: rating.$3,
              backgroundColor: rating.$4,
              onPressed: () => onRate(rating.$1),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final Color foregroundColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _RatingButton({
    required this.label,
    required this.sublabel,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (sublabel.isNotEmpty)
                Text(
                  sublabel,
                  style: TextStyle(
                    color: foregroundColor.withAlpha(180),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
