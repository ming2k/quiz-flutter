import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'screens.dart';

class CollectionDetailScreen extends StatefulWidget {
  final Book book;
  final Collection collection;

  const CollectionDetailScreen({
    super.key,
    required this.book,
    required this.collection,
  });

  @override
  State<CollectionDetailScreen> createState() => _CollectionDetailScreenState();
}

class _CollectionDetailScreenState extends State<CollectionDetailScreen> {
  List<Question> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await DatabaseService().getQuestionsByCollection(
      widget.collection.id,
    );
    if (mounted) {
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeQuestion(int questionId) async {
    await DatabaseService().removeQuestionFromCollection(
      widget.collection.id,
      questionId,
    );
    await _loadQuestions();
  }

  Future<void> _deleteCollection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Collection?'), // TODO(l10n)
        content: Text('"${widget.collection.name}" will be permanently deleted.'), // TODO(l10n)
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService().deleteCollection(widget.collection.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _startPractice() async {
    final quiz = context.read<PracticeProvider>();
    await quiz.loadCollection(widget.book, widget.collection.id);
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticeScreen()));
    }
  }

  Future<void> _startTest() async {
    final test = context.read<TestProvider>();
    final settings = context.read<SettingsProvider>();
    await test.loadCollection(widget.book, widget.collection.id);
    test.startTest(settings.testQuestionCount);
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const TestScreen()));
    }
  }

  Future<void> _startPreview() async {
    final preview = context.read<PreviewProvider>();
    await preview.loadCollection(widget.book, widget.collection.id);
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PreviewScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUserCollection = widget.collection.type == CollectionType.practiceSet ||
        widget.collection.type == CollectionType.playlist;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.collection.name),
        actions: [
          if (isUserCollection)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteCollection,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(context),
                const Divider(height: 1),
                Expanded(
                  child: _questions.isEmpty
                      ? _buildEmptyState(context)
                      : widget.collection.type == CollectionType.playlist
                          ? ReorderableListView.builder(
                              buildDefaultDragHandles: true,
                              itemCount: _questions.length,
                              itemBuilder: (ctx, index) => _buildQuestionTile(ctx, index, isReorderable: true),
                              onReorder: _onReorder,
                            )
                          : ListView.builder(
                              itemCount: _questions.length,
                              itemBuilder: (ctx, index) => _buildQuestionTile(ctx, index),
                            ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.collection.description != null)
            Text(
              widget.collection.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _questions.isEmpty ? null : _startPractice,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(l10n.practiceMode),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _questions.isEmpty ? null : _startTest,
                  icon: const Icon(Icons.timer_outlined),
                  label: Text(l10n.testMode),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _questions.isEmpty ? null : _startPreview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview'), // TODO(l10n)
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'This collection is empty.', // TODO(l10n)
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add questions while practicing.', // TODO(l10n)
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTile(BuildContext context, int index, {bool isReorderable = false}) {
    final question = _questions[index];
    final isUserCollection = widget.collection.type == CollectionType.practiceSet ||
        widget.collection.type == CollectionType.playlist;

    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      title: Text(
        question.content,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: question.tags.isNotEmpty
          ? Wrap(
              spacing: 4,
              children: question.tags
                  .map((t) => Chip(
                        label: Text(t),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelStyle: const TextStyle(fontSize: 10),
                      ))
                  .toList(),
            )
          : null,
      trailing: isReorderable
          ? IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _removeQuestion(question.id),
            )
          : null,
    );

    final content = isReorderable
        ? tile
        : Dismissible(
            key: ValueKey('cd_q_${question.id}'),
            direction: isUserCollection ? DismissDirection.endToStart : DismissDirection.none,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: Theme.of(context).colorScheme.error,
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              if (!isUserCollection) return false;
              return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove Question?'), // TODO(l10n)
                  content: const Text('Remove this question from the collection?'), // TODO(l10n)
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: Text(AppLocalizations.of(context).delete),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) => _removeQuestion(question.id),
            child: Column(
              children: [
                tile,
                const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ),
          );

    // ReorderableListView requires a key on each item
    if (isReorderable) {
      return KeyedSubtree(
        key: ValueKey('cd_q_${question.id}'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            const Divider(height: 1, indent: 16, endIndent: 16),
          ],
        ),
      );
    }

    return content;
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _questions.removeAt(oldIndex);
    _questions.insert(newIndex, item);
    setState(() {});

    await DatabaseService().reorderCollectionItems(
      widget.collection.id,
      _questions.map((q) => q.id).toList(),
    );
  }
}
