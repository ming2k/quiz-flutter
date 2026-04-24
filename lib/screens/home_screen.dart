import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

import 'book_detail_screen.dart';
import 'practice_screen.dart';
import 'test_screen.dart';
import 'preview_screen.dart';
import 'review_screen.dart';
import 'settings_screen.dart';

import '../services/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _StudyMode { review, preview, test, practice }

class _HomeScreenState extends State<HomeScreen> {
  Book? _lastOpenedBook;
  UserProgress? _lastProgress;
  final Map<int, _StudyMode> _selectedModes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadInitialData();
      }
    });
  }

  Future<void> _loadInitialData() async {
    final library = context.read<LibraryProvider>();
    final storage = StorageService();

    await library.loadBooks();
    if (!mounted) return;

    final lastBankFilename = await storage.loadLastOpenedBank();
    if (lastBankFilename != null) {
      final book = library.books.cast<Book?>().firstWhere(
            (b) => b?.filename == lastBankFilename,
            orElse: () => null,
          );

      if (book != null) {
        _lastOpenedBook = book;
        _lastProgress = await storage.loadProgress(book.filename);
        if (mounted) setState(() {});

        // Found last opened book, go straight to it
        _startPractice(book);
      }
    }
  }

  Future<void> _importPackage(BuildContext ctx) async {
    final navigator = Navigator.of(ctx, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(ctx);
    final libraryProvider = ctx.read<LibraryProvider>();

    String statusText = 'Starting...';
    double? progressValue;

    // Show progress dialog
    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            // Store the setState function so we can call it from the callback
            _dialogSetState = (String status, double? progress) {
              if (dialogContext.mounted) {
                setDialogState(() {
                  statusText = status;
                  progressValue = progress;
                });
              }
            };

            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (progressValue != null)
                    LinearProgressIndicator(value: progressValue)
                  else
                    const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(statusText),
                ],
              ),
            );
          },
        );
      },
    );

    // Perform import
    final result = await PackageService().importPackage(
      onProgress: (status, progress) {
        _dialogSetState?.call(status, progress);
      },
    );

    // Close progress dialog
    if (mounted) {
      navigator.pop();
    }

    // Handle result
    if (!mounted) return;

    if (result.success) {
      // Reload books and show success
      await libraryProvider.loadBooks();
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(l10n.importSuccess(result.packageName ?? '')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (!result.isCancelled && result.errorMessage != null) {
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (dlgCtx) {
            final l10n = AppLocalizations.of(dlgCtx);
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n.importFailed),
                ],
              ),
              content: Text(result.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx),
                  child: Text(l10n.ok),
                ),
              ],
            );
          },
        );
      }
    }
    // If cancelled, do nothing
  }

  // Callback to update dialog state from outside the dialog builder
  void Function(String status, double? progress)? _dialogSetState;

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _greeting(l10n),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('home_import_button'),
            icon: const Icon(Icons.upload_file_outlined),
            tooltip: l10n.importPackage,
            onPressed: () => _importPackage(context),
          ),
          IconButton(
            key: const Key('home_settings_button'),
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
      body: Consumer<LibraryProvider>(
        builder: (context, library, child) {
          if (library.isLoading && library.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (library.error != null && library.books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(library.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => library.loadBooks(),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          if (library.books.isEmpty) {
            return _buildEmptyState(context, l10n);
          }

          return ReorderableListView(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContinueSection(context, l10n, settings),
              ],
            ),
            padding: const EdgeInsets.only(bottom: 16),
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (ctx, c) {
                  final elevationValue = Tween<double>(begin: 1, end: 6)
                      .animate(animation)
                      .value;
                  return Material(
                    elevation: elevationValue,
                    borderRadius: BorderRadius.circular(16),
                    child: c,
                  );
                },
                child: child,
              );
            },
            onReorder: (oldIndex, newIndex) {
              context.read<LibraryProvider>().reorderBooks(oldIndex, newIndex);
            },
            children: [
              for (final book in library.books)
                _buildBookCard(book, l10n, settings),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined, size: 80, color: colorScheme.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 24),
            Text(
              l10n.noBooks,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noBooksDesc,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _importPackage(context),
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.importPackage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueSection(BuildContext context, AppLocalizations l10n, SettingsProvider settings) {
    final book = _lastOpenedBook;
    if (book == null) return const SizedBox.shrink();

    final progress = _lastProgress;
    final currentIndex = (progress?.currentQuestionIndex ?? 0) + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _startPractice(book),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continue learning', // TODO(l10n): add continueLearning
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.getDisplayName(l10n.localeName),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Question $currentIndex of ${book.totalQuestions}', // TODO(l10n)
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookCard(Book book, AppLocalizations l10n, SettingsProvider settings) {
    final locale = l10n.localeName;
    final bookColor = AppTheme.bookColor(book.id);

    return Dismissible(
      key: ValueKey('book_${book.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.confirm),
            content: Text(l10n.confirmDeleteBook(book.getDisplayName(locale))),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<LibraryProvider>().deleteBook(book.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card header: book info + explicit detail entry
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Leading color block with initial letter
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: bookColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        book.getDisplayName(locale).isNotEmpty
                            ? book.getDisplayName(locale)[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 24,
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
                          book.getDisplayName(locale),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${book.totalQuestions} ${l10n.questions}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        _BookProgressBar(bookId: book.id, totalQuestions: book.totalQuestions, color: bookColor),
                        _SrsBadge(bookId: book.id),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _openBookDetail(book),
                    tooltip: 'Details', // TODO(l10n)
                  ),
                ],
              ),
            ),

            const Divider(height: 1, indent: 16, endIndent: 16),

            // Bottom mode selector: all modes are visually equal.
            // SegmentedButton is the Material 3 canonical component for
            // selecting one value from a small set of mutually exclusive options.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: FutureBuilder<SrsStats>(
                future: DatabaseService().getSrsStats(book.id),
                builder: (context, snapshot) {
                  final stats = snapshot.data;
                  final hasDue = stats != null && stats.dueToday > 0;
                  final selectedMode = _selectedModes[book.id] ?? _StudyMode.practice;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final useLabels = constraints.maxWidth >= 360;
                      return SegmentedButton<_StudyMode>(
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 11)),
                        ),
                        segments: [
                          ButtonSegment(
                            value: _StudyMode.review,
                            icon: Icon(
                              Icons.psychology_outlined,
                              size: 18,
                              color: hasDue
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            label: useLabels
                                ? Text(
                                    hasDue ? 'Review ${stats.dueToday}' : 'Review',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: hasDue ? FontWeight.bold : FontWeight.normal,
                                      color: hasDue
                                          ? Theme.of(context).colorScheme.primary
                                          : null,
                                    ),
                                  )
                                : null,
                          ),
                          ButtonSegment(
                            value: _StudyMode.preview,
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            label: useLabels ? const Text('Preview', style: TextStyle(fontSize: 11)) : null,
                          ),
                          ButtonSegment(
                            value: _StudyMode.test,
                            icon: const Icon(Icons.timer_outlined, size: 18),
                            label: useLabels ? const Text('Test', style: TextStyle(fontSize: 11)) : null,
                          ),
                          ButtonSegment(
                            value: _StudyMode.practice,
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: useLabels ? const Text('Practice', style: TextStyle(fontSize: 11)) : null,
                          ),
                        ],
                        selected: {selectedMode},
                        onSelectionChanged: (selection) {
                          final mode = selection.first;
                          setState(() => _selectedModes[book.id] = mode);
                          switch (mode) {
                            case _StudyMode.review:
                              _startReview(book);
                              break;
                            case _StudyMode.preview:
                              _startPreview(book);
                              break;
                            case _StudyMode.test:
                              _startTest(book);
                              break;
                            case _StudyMode.practice:
                              _startPractice(book);
                              break;
                          }
                        },
                      );
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

  void _openBookDetail(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: book)),
    );
  }

  void _startPreview(Book book) async {
    final preview = context.read<PreviewProvider>();
    await preview.loadBook(book);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PreviewScreen()),
      );
    }
  }

  void _startPractice(Book book) async {
    final quiz = context.read<PracticeProvider>();
    await quiz.selectBook(book);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PracticeScreen()),
      );
    }
  }

  void _startTest(Book book) async {
    final test = context.read<TestProvider>();
    final settings = context.read<SettingsProvider>();
    await test.loadBook(book);
    test.startTest(settings.testQuestionCount);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TestScreen()),
      );
    }
  }

  void _startReview(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReviewScreen(book: book)),
    );
  }
}

/// Displays a small progress bar for a book based on answered questions.
class _BookProgressBar extends StatelessWidget {
  final int bookId;
  final int totalQuestions;
  final Color color;

  const _BookProgressBar({
    required this.bookId,
    required this.totalQuestions,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (totalQuestions <= 0) return const SizedBox.shrink();

    return FutureBuilder<Map<int, UserAnswer>>(
      future: DatabaseService().getUserAnswers(bookId),
      builder: (context, snapshot) {
        final answeredCount = snapshot.data?.length ?? 0;
        final progress = answeredCount / totalQuestions;

        if (answeredCount <= 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$answeredCount/$totalQuestions',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Small SRS stats badge displayed under each book card.
class _SrsBadge extends StatelessWidget {
  final int bookId;

  const _SrsBadge({required this.bookId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SrsStats>(
      future: DatabaseService().getSrsStats(bookId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final stats = snapshot.data!;
        if (stats.total == 0) return const SizedBox.shrink();

        final List<Widget> chips = [];

        final l10n = AppLocalizations.of(context);
        final colorScheme = Theme.of(context).colorScheme;
        if (stats.newCards > 0) {
          chips.add(_buildChip('${l10n.srsNew} ${stats.newCards}', colorScheme.primary));
        }
        if (stats.learning > 0) {
          chips.add(_buildChip('${l10n.srsLearning} ${stats.learning}', AppTheme.warning));
        }
        if (stats.review > 0) {
          chips.add(_buildChip('${l10n.srsReview} ${stats.review}', AppTheme.success));
        }

        if (chips.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            children: chips,
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
