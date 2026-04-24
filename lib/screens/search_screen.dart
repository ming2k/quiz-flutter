import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'screens.dart';

class SearchScreen extends StatefulWidget {
  final Book book;

  const SearchScreen({super.key, required this.book});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<Question> _results = [];
  bool _isSearching = false;
  String? _lastQuery;
  final Set<int> _selectedQuestionIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _lastQuery = null;
        _selectedQuestionIds.clear();
        _isSelectionMode = false;
      });
      return;
    }

    if (trimmed == _lastQuery) return;

    setState(() => _isSearching = true);

    final results = await DatabaseService().searchQuestions(widget.book.id, trimmed);

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
        _lastQuery = trimmed;
        _selectedQuestionIds.clear();
      });
    }
  }

  Future<void> _startPracticeAll() async {
    final quiz = context.read<PracticeProvider>();
    await quiz.loadQuestions(widget.book, _results, partitionId: 'search_$_lastQuery');

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PracticeScreen()),
      );
    }
  }

  void _toggleSelection(int questionId) {
    setState(() {
      if (_selectedQuestionIds.contains(questionId)) {
        _selectedQuestionIds.remove(questionId);
      } else {
        _selectedQuestionIds.add(questionId);
      }
      if (_selectedQuestionIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _startSelectionMode(int questionId) {
    setState(() {
      _isSelectionMode = true;
      _selectedQuestionIds.add(questionId);
    });
  }

  Future<void> _addSelectedToCollection() async {
    if (_selectedQuestionIds.isEmpty) return;

    final collections = await DatabaseService().getCollectionsByType(
      widget.book.id,
      CollectionType.practiceSet,
    );
    final playlists = await DatabaseService().getCollectionsByType(
      widget.book.id,
      CollectionType.playlist,
    );
    final userCollections = [...collections, ...playlists];

    if (!mounted) return;

    if (userCollections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a collection first from the book detail screen.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Add ${_selectedQuestionIds.length} questions to',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: userCollections.length,
                itemBuilder: (ctx, index) {
                  final collection = userCollections[index];
                  return ListTile(
                    leading: Icon(
                      collection.type == CollectionType.playlist
                          ? Icons.playlist_play_outlined
                          : Icons.folder_copy_outlined,
                    ),
                    title: Text(collection.name),
                    onTap: () async {
                      final db = DatabaseService();
                      final added = await db.addQuestionsToCollection(
                        collection.id,
                        _selectedQuestionIds.toList(),
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text('Added $added questions to "${collection.name}"'),
                          ),
                        );
                        setState(() {
                          _isSelectionMode = false;
                          _selectedQuestionIds.clear();
                        });
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search questions...',
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _search,
          onChanged: (value) {
            if (value.isEmpty) _search('');
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_controller.text),
          ),
        ],
      ),
      body: _buildBody(context),
      bottomNavigationBar: _isSelectionMode && _selectedQuestionIds.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedQuestionIds.clear();
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedQuestionIds.length} selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _addSelectedToCollection,
                      icon: const Icon(Icons.folder_copy_outlined, size: 18),
                      label: const Text('Add to Collection'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_lastQuery == null || _lastQuery!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Type to search questions',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results for "$_lastQuery"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_results.length} results',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              if (!_isSelectionMode)
                TextButton.icon(
                  onPressed: _startPracticeAll,
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Practice All'),
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _results.length,
            itemBuilder: (ctx, index) => _buildResultTile(ctx, index),
          ),
        ),
      ],
    );
  }

  Widget _buildResultTile(BuildContext context, int index) {
    final question = _results[index];
    final isSelected = _selectedQuestionIds.contains(question.id);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: _isSelectionMode
              ? Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleSelection(question.id),
                )
              : CircleAvatar(
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
          title: _highlightText(question.content, _lastQuery ?? ''),
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
          onTap: () {
            if (_isSelectionMode) {
              _toggleSelection(question.id);
            }
          },
          onLongPress: () {
            if (!_isSelectionMode) {
              _startSelectionMode(question.id);
            }
          },
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = index + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: spans,
      ),
    );
  }
}
