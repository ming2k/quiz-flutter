import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late PageController _pageController;
  late PreviewProvider _preview;

  @override
  void initState() {
    super.initState();
    _preview = context.read<PreviewProvider>();
    _pageController = PageController(initialPage: _preview.currentIndex);
    _preview.addListener(_syncPreviewState);
  }

  void _syncPreviewState() {
    if (!mounted) return;
    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage != _preview.currentIndex) {
        _pageController.jumpToPage(_preview.currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _preview.removeListener(_syncPreviewState);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = context.watch<PreviewProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              preview.currentBook?.getDisplayName(l10n.localeName) ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${preview.currentIndex + 1} / ${preview.totalItems}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: l10n.section,
            onPressed: () => _showSectionSelector(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: LinearProgressIndicator(
              value: preview.totalItems > 0
                  ? (preview.currentIndex + 1) / preview.totalItems
                  : 0.0,
            ),
          ),
          Expanded(
            child: preview.totalItems > 0
                ? PageView.builder(
                    controller: _pageController,
                    itemCount: preview.totalItems,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    onPageChanged: (index) {
                      if (index != preview.currentIndex) {
                        preview.goToItem(index);
                      }
                    },
                    itemBuilder: (context, index) {
                      final item = preview.items[index];
                      return _PreviewItemCard(
                        key: ValueKey('preview_item_$index'),
                        item: item,
                        imageBasePath: preview.currentPackageImagePath,
                        subQuestions: item.isPassage
                            ? preview.getSubQuestions(item.id)
                            : null,
                      );
                    },
                  )
                : _buildEmptyState(context, l10n),
          ),
          _buildActionBar(l10n),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(l10n.noQuestions),
        ],
      ),
    );
  }

  Widget _buildActionBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Consumer<PreviewProvider>(
          builder: (context, preview, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: preview.currentIndex > 0
                      ? () => _goToPage(preview.currentIndex - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l10n.previous,
                ),
                Text(
                  '${preview.currentIndex + 1} / ${preview.totalItems}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  onPressed: preview.currentIndex < preview.totalItems - 1
                      ? () => _goToPage(preview.currentIndex + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: l10n.next,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _goToPage(int page) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showSectionSelector(BuildContext context) {
    final preview = context.read<PreviewProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SectionSelector(
        sections: preview.sections,
        currentPartitionId: preview.currentPartitionId,
        onSectionSelected: preview.selectPartition,
      ),
    );
  }
}

class _PreviewItemCard extends StatelessWidget {
  final Question item;
  final String? imageBasePath;
  final List<Question>? subQuestions;

  const _PreviewItemCard({
    super.key,
    required this.item,
    this.imageBasePath,
    this.subQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        // Metadata chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChip(
              context,
              item.questionType.name,
              colorScheme.primaryContainer,
              colorScheme.onPrimaryContainer,
            ),
            if (item.difficulty != null)
              _buildChip(
                context,
                'Difficulty ${item.difficulty}',
                colorScheme.secondaryContainer,
                colorScheme.onSecondaryContainer,
              ),
            ...item.tags.map(
              (tag) => _buildChip(
                context,
                tag,
                colorScheme.surfaceContainerHighest,
                colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Passage view
        if (item.isPassage && subQuestions != null) ...[
          MarkdownContent(
            content: item.content,
            imageBasePath: imageBasePath,
            fontSize: 18,
            textColor: colorScheme.onSurface,
          ),
          const SizedBox(height: 24),
          Text(
            'Sub-questions (${subQuestions!.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ...subQuestions!.map((sq) => _buildSubQuestionCard(context, sq)),
        ] else ...[
          // Answerable item view
          if (item.parentContent != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.onSurface.withValues(alpha: 0.1)),
              ),
              child: MarkdownContent(
                content: item.parentContent!,
                imageBasePath: imageBasePath,
                fontSize: 16,
                textColor: colorScheme.onSurface,
              ),
            ),
            const Divider(height: 32),
          ],
          QuestionDisplay(
            question: item,
            showAnswer: true,
            showAnalysis: true,
            imageBasePath: imageBasePath,
            onOptionSelected: null,
            primaryColor: colorScheme.primary,
            errorColor: colorScheme.error,
            successColor: AppTheme.success,
            surfaceColor: colorScheme.surface,
            textColor: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label,
    Color backgroundColor,
    Color foregroundColor,
  ) {
    return Chip(
      label: Text(label),
      backgroundColor: backgroundColor,
      labelStyle: TextStyle(color: foregroundColor, fontSize: 12),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSubQuestionCard(BuildContext context, Question sq) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownContent(
              content: sq.content,
              imageBasePath: imageBasePath,
              fontSize: 16,
              textColor: colorScheme.onSurface,
            ),
            const SizedBox(height: 12),
            if (sq.choices.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sq.choiceEntries.map((entry) {
                  final isCorrect =
                      entry.key.toUpperCase() == sq.answer.toUpperCase();
                  return Chip(
                    label: Text('${entry.key}: ${entry.value}'),
                    backgroundColor: isCorrect
                        ? AppTheme.success.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: isCorrect ? AppTheme.success : colorScheme.onSurfaceVariant,
                      fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Answer: ${sq.answer}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (sq.explanation.isNotEmpty) ...[
              const SizedBox(height: 12),
              MarkdownContent(
                content: sq.explanation,
                imageBasePath: imageBasePath,
                fontSize: 14,
                textColor: colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
