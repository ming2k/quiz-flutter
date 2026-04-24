import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'screens.dart';

class BookDetailScreen extends StatelessWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BookDetailProvider()..loadBook(book),
      child: const _BookDetailView(),
    );
  }
}

class _BookDetailView extends StatefulWidget {
  const _BookDetailView();

  @override
  State<_BookDetailView> createState() => _BookDetailViewState();
}

class _BookDetailViewState extends State<_BookDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookDetailProvider>();
    final book = provider.book;

    if (provider.isLoading || book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(provider.error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(book.subjectNameEn),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard_outlined)),
            Tab(text: 'Collections', icon: Icon(Icons.folder_copy_outlined)),
            Tab(text: 'Content', icon: Icon(Icons.menu_book_outlined)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              final book = provider.book;
              if (book != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SearchScreen(book: book)),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          return _tabController.index == 1
              ? FloatingActionButton.extended(
                  onPressed: () => _createCollection(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('New Set'), // TODO(l10n)
                )
              : const SizedBox.shrink();
        },
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, provider),
          _buildCollectionsTab(context, provider),
          _buildContentTab(context, provider),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, BookDetailProvider provider) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildHeader(context, provider),
        _buildQuickActions(context, provider),
        _buildSmartCollections(context, provider),
      ],
    );
  }

  Widget _buildCollectionsTab(BuildContext context, BookDetailProvider provider) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildTopics(context, provider),
        _buildUserCollections(context, provider),
        _buildExamBlueprints(context, provider),
      ],
    );
  }

  Widget _buildContentTab(BuildContext context, BookDetailProvider provider) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        _buildSourceOutline(context, provider),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, BookDetailProvider provider) {
    final book = provider.book!;
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final bookColor = AppTheme.bookColor(book.id);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: bookColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    book.subjectNameEn.isNotEmpty
                        ? book.subjectNameEn[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: bookColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.subjectNameEn,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${book.totalQuestions} ${l10n.questions}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.srsStats != null && provider.srsStats!.total > 0)
            _buildSrsChips(context, provider.srsStats!),
        ],
      ),
    );
  }

  Widget _buildSrsChips(BuildContext context, SrsStats stats) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final chips = <Widget>[];

    if (stats.newCards > 0) {
      chips.add(_SrsChip(label: '${l10n.srsNew} ${stats.newCards}', color: colorScheme.primary));
    }
    if (stats.learning > 0) {
      chips.add(_SrsChip(label: '${l10n.srsLearning} ${stats.learning}', color: AppTheme.warning));
    }
    if (stats.review > 0) {
      chips.add(_SrsChip(label: '${l10n.srsReview} ${stats.review}', color: AppTheme.success));
    }
    if (stats.dueToday > 0) {
      chips.add(_SrsChip(label: '${l10n.review} ${stats.dueToday}', color: AppTheme.seedColor));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildQuickActions(BuildContext context, BookDetailProvider provider) {
    final book = provider.book!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions', // TODO(l10n)
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Practice',
                  color: Theme.of(context).colorScheme.primary,
                  onTap: () => _startPractice(context, book),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.timer_outlined,
                  label: 'Test',
                  color: AppTheme.seedColor,
                  onTap: () => _startTest(context, book),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.psychology_outlined,
                  label: 'Review',
                  color: AppTheme.success,
                  onTap: () => _startReview(context, book),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'Preview',
                  color: AppTheme.warning,
                  onTap: () => _startPreview(context, book),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmartCollections(BuildContext context, BookDetailProvider provider) {
    final smart = provider.smartCollections;
    if (smart.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Smart Collections', // TODO(l10n)
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          ...smart.map((c) => _buildSmartCollectionTile(context, provider, c)),
        ],
      ),
    );
  }

  Widget _buildSmartCollectionTile(BuildContext context, BookDetailProvider provider, Collection collection) {
    final book = provider.book!;
    final count = provider.getSmartCollectionCount(collection.id);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            Icons.auto_awesome_outlined,
            color: Theme.of(context).colorScheme.secondary,
          ),
          title: Text(
            collection.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 8),
              _SectionActionChip(
                icon: Icons.play_arrow_rounded,
                label: 'Practice',
                onTap: () => _startPracticeSmart(context, book, collection),
              ),
              const SizedBox(width: 8),
              _SectionActionChip(
                icon: Icons.timer_outlined,
                label: 'Test',
                onTap: () => _startTestSmart(context, book, collection),
              ),
            ],
          ),
          onTap: () => _startPreviewSmart(context, book, collection),
        ),
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildTopics(BuildContext context, BookDetailProvider provider) {
    final topics = provider.topicCollections;
    if (topics.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Topics', // TODO(l10n)
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          ...topics.map((t) => _buildTopicTile(context, provider, t)),
        ],
      ),
    );
  }

  Widget _buildTopicTile(BuildContext context, BookDetailProvider provider, Collection topic) {
    final book = provider.book!;
    final questionCount = provider.getQuestionCount(topic.id);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            Icons.label_outlined,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          title: Text(
            topic.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$questionCount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: 8),
              _SectionActionChip(
                icon: Icons.play_arrow_rounded,
                label: 'Practice',
                onTap: () => _startPracticeCollection(context, book, topic.id),
              ),
              const SizedBox(width: 8),
              _SectionActionChip(
                icon: Icons.timer_outlined,
                label: 'Test',
                onTap: () => _startTestCollection(context, book, topic.id),
              ),
            ],
          ),
          onTap: () => _startPreviewCollection(context, book, topic.id),
        ),
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildUserCollections(BuildContext context, BookDetailProvider provider) {
    final userCollections = provider.userCollections;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'My Collections', // TODO(l10n)
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _createCollection(context, provider),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'), // TODO(l10n)
                ),
              ],
            ),
          ),
          if (userCollections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Create your own practice sets and playlists.', // TODO(l10n)
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ...userCollections.map((c) => _buildUserCollectionTile(context, provider, c)),
        ],
      ),
    );
  }

  Widget _buildUserCollectionTile(BuildContext context, BookDetailProvider provider, Collection collection) {
    final book = provider.book!;
    final questionCount = provider.getQuestionCount(collection.id);

    return Dismissible(
      key: ValueKey('user_collection_${collection.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Collection?'), // TODO(l10n)
            content: Text('"${collection.name}" will be permanently deleted.'), // TODO(l10n)
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
      onDismissed: (_) => provider.deleteCollection(collection.id),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            leading: Icon(
              collection.type == CollectionType.playlist
                  ? Icons.playlist_play_outlined
                  : Icons.folder_copy_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              collection.name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            subtitle: collection.description != null
                ? Text(
                    collection.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$questionCount',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 8),
                _SectionActionChip(
                  icon: Icons.play_arrow_rounded,
                  label: 'Practice',
                  onTap: () => _startPracticeCollection(context, book, collection.id),
                ),
              ],
            ),
            onTap: () => _openCollectionDetail(context, book, collection),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildExamBlueprints(BuildContext context, BookDetailProvider provider) {
    final blueprints = provider.blueprintCollections;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Exam Blueprints', // TODO(l10n)
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _createBlueprint(context, provider),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New'), // TODO(l10n)
                ),
              ],
            ),
          ),
          if (blueprints.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Create structured exams from multiple collections.', // TODO(l10n)
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ...blueprints.map((b) => _buildBlueprintTile(context, provider, b)),
        ],
      ),
    );
  }

  Widget _buildBlueprintTile(BuildContext context, BookDetailProvider provider, Collection blueprint) {
    final book = provider.book!;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            Icons.assignment_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            blueprint.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          subtitle: blueprint.description != null
              ? Text(
                  blueprint.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectionActionChip(
                icon: Icons.play_arrow_rounded,
                label: 'Practice',
                onTap: () => _startPracticeSmart(context, book, blueprint),
              ),
              const SizedBox(width: 8),
              _SectionActionChip(
                icon: Icons.timer_outlined,
                label: 'Test',
                onTap: () => _startTestSmart(context, book, blueprint),
              ),
            ],
          ),
          onTap: () => _startPreviewSmart(context, book, blueprint),
        ),
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildSourceOutline(BuildContext context, BookDetailProvider provider) {
    final topLevel = provider.topLevelCollections;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Source Outline', // TODO(l10n)
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          ...topLevel.map((chapter) => _buildChapterTile(context, provider, chapter)),
        ],
      ),
    );
  }

  Widget _buildChapterTile(BuildContext context, BookDetailProvider provider, Collection chapter) {
    final children = provider.getChildren(chapter.id);
    final isExpanded = provider.isExpanded(chapter.id);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            isExpanded ? Icons.folder_open_outlined : Icons.folder_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            chapter.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${children.length} sections', // TODO(l10n)
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          onTap: () => provider.toggleExpand(chapter.id),
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Column(
              children: children.map((section) => _buildSectionTile(context, provider, section)).toList(),
            ),
          ),
        Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ],
    );
  }

  Widget _buildSectionTile(BuildContext context, BookDetailProvider provider, Collection section) {
    final questionCount = provider.getQuestionCount(section.id);
    final answeredCount = provider.getAnsweredCount(section.id);
    final progress = questionCount > 0 ? answeredCount / questionCount : 0.0;
    final book = provider.book!;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _startPreviewCollection(context, book, section.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      section.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Text(
                    '$answeredCount / $questionCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              if (questionCount > 0) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SectionActionChip(
                      icon: Icons.play_arrow_rounded,
                      label: 'Practice',
                      onTap: () => _startPracticeCollection(context, book, section.id),
                    ),
                    const SizedBox(width: 8),
                    _SectionActionChip(
                      icon: Icons.timer_outlined,
                      label: 'Test',
                      onTap: () => _startTestCollection(context, book, section.id),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _startPractice(BuildContext context, Book book) async {
    final quiz = context.read<PracticeProvider>();
    await quiz.selectBook(book);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PracticeScreen()),
      );
    }
  }

  void _startTest(BuildContext context, Book book) async {
    final test = context.read<TestProvider>();
    final settings = context.read<SettingsProvider>();
    await test.loadBook(book);
    test.startTest(settings.testQuestionCount);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TestScreen()),
      );
    }
  }

  void _startReview(BuildContext context, Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(book: book)),
    );
  }

  void _startPreview(BuildContext context, Book book) async {
    final preview = context.read<PreviewProvider>();
    await preview.loadBook(book);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PreviewScreen()),
      );
    }
  }

  void _startPracticeCollection(BuildContext context, Book book, int collectionId) async {
    final quiz = context.read<PracticeProvider>();
    await quiz.loadCollection(book, collectionId);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PracticeScreen()),
      );
    }
  }

  void _startTestCollection(BuildContext context, Book book, int collectionId) async {
    final test = context.read<TestProvider>();
    final settings = context.read<SettingsProvider>();
    await test.loadCollection(book, collectionId);
    test.startTest(settings.testQuestionCount);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TestScreen()),
      );
    }
  }

  void _startPreviewCollection(BuildContext context, Book book, int collectionId) async {
    final preview = context.read<PreviewProvider>();
    await preview.loadCollection(book, collectionId);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PreviewScreen()),
      );
    }
  }

  void _startPracticeSmart(BuildContext context, Book book, Collection collection) async {
    final quiz = context.read<PracticeProvider>();
    await quiz.loadSmartCollection(book, collection);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PracticeScreen()),
      );
    }
  }

  void _startTestSmart(BuildContext context, Book book, Collection collection) async {
    final test = context.read<TestProvider>();
    final settings = context.read<SettingsProvider>();
    await test.loadSmartCollection(book, collection);
    test.startTest(settings.testQuestionCount);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TestScreen()),
      );
    }
  }

  void _startPreviewSmart(BuildContext context, Book book, Collection collection) async {
    final preview = context.read<PreviewProvider>();
    await preview.loadSmartCollection(book, collection);

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PreviewScreen()),
      );
    }
  }

  Future<void> _createCollection(BuildContext context, BookDetailProvider provider) async {
    final book = provider.book;
    if (book == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateCollectionScreen(bookId: book.id)),
    );

    if (result == true) {
      await provider.refreshCollections();
    }
  }

  Future<void> _createBlueprint(BuildContext context, BookDetailProvider provider) async {
    final book = provider.book;
    if (book == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateBlueprintScreen(book: book)),
    );

    if (result == true) {
      await provider.refreshCollections();
    }
  }

  Future<void> _openCollectionDetail(BuildContext context, Book book, Collection collection) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CollectionDetailScreen(book: book, collection: collection),
      ),
    );

    if (result == true && context.mounted) {
      context.read<BookDetailProvider>().refreshCollections();
    }
  }
}

class _SrsChip extends StatelessWidget {
  final String label;
  final Color color;

  const _SrsChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SectionActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
