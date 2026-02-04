import 'package:flutter/material.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';

class SectionSelector extends StatelessWidget {
  final List<Section> sections;
  final String currentPartitionId;
  final ValueChanged<String> onSectionSelected;

  const SectionSelector({
    super.key,
    required this.sections,
    required this.currentPartitionId,
    required this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalQuestions =
        sections.fold<int>(0, (sum, s) => sum + s.questionCount);

    // Using a Column with Flexible to ensure the sheet size is based on content.
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Drag Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                l10n.get('section'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            // Scrollable list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildSectionTile(
                    context,
                    id: 'all',
                    title: l10n.get('allSections'),
                    questionCount: totalQuestions,
                    isSelected: currentPartitionId == 'all',
                  ),
                  ...sections.map(
                    (section) => _buildSectionTile(
                      context,
                      id: section.id.toString(),
                      title: section.displayTitle,
                      questionCount: section.questionCount,
                      isSelected: currentPartitionId == section.id.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildSectionTile(
    BuildContext context, {
    required String id,
    required String title,
    required int questionCount,
    required bool isSelected,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Text(
        '$questionCount 题',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withAlpha(25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        onSectionSelected(id);
        Navigator.pop(context);
      },
    );
  }
}