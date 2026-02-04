import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

import '../services/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppMode _selectedMode = AppMode.practice;
  int _testQuestionCount = 50;

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
    final quiz = context.read<QuizProvider>();
    final storage = StorageService();

    await quiz.loadBooks();
    if (!mounted) return;

    final lastBankFilename = await storage.loadLastOpenedBank();
    if (lastBankFilename != null) {
      final book = quiz.books.cast<Book?>().firstWhere(
            (b) => b?.filename == lastBankFilename,
            orElse: () => null,
          );

      if (book != null) {
        // Found last opened book, go straight to it
        _startPractice(book, autoStart: true);
      }
    }
  }

  Future<void> _importPackage(BuildContext ctx) async {
    final navigator = Navigator.of(ctx, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(ctx);
    final quizProvider = ctx.read<QuizProvider>();

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
      await quizProvider.loadBooks();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Successfully imported "${result.packageName}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (!result.isCancelled && result.errorMessage != null) {
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (dlgCtx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Import Failed'),
              ],
            ),
            content: Text(result.errorMessage!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dlgCtx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
    // If cancelled, do nothing
  }

  // Callback to update dialog state from outside the dialog builder
  void Function(String status, double? progress)? _dialogSetState;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            key: const Key('home_import_button'),
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import Package',
            onPressed: () => _importPackage(context),
          ),
          IconButton(
            key: const Key('home_settings_button'),
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quiz, child) {
          if (quiz.isLoading && quiz.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (quiz.error != null && quiz.books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(quiz.error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => quiz.loadBooks(),
                    child: Text(l10n.get('retry')),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView(
            header: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Text(
                l10n.selectQuestionBank,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            onReorder: (oldIndex, newIndex) {
              context.read<QuizProvider>().reorderBooks(oldIndex, newIndex);
            },
            children: [
              for (final book in quiz.books)
                _buildBookCard(book, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookCard(Book book, AppLocalizations l10n) {
    final locale = l10n.locale.languageCode;

    return Dismissible(
      key: ValueKey('book_${book.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.get('confirm')),
            content: Text('Are you sure you want to delete "${book.getDisplayName(locale)}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.get('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n.get('delete')),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<QuizProvider>().deleteBook(book.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _showModeSelectionSheet(book, l10n),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.book,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.getDisplayName(locale),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${book.totalQuestions} ${l10n.get('questions')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModeSelectionSheet(Book book, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24 + 16), // Extra padding for bottom safe area
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    book.getDisplayName(l10n.locale.languageCode),
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.selectMode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildModeSelector(l10n, setModalState),
                  const SizedBox(height: 24),

                  // Test Question Count (only for test mode)
                  if (_selectedMode == AppMode.test) ...[
                    _buildTestQuestionCountSelector(l10n, setModalState),
                    const SizedBox(height: 24),
                  ],

                  // Start Button
                  ElevatedButton(
                    key: const Key('home_start_button'),
                    onPressed: () {
                      Navigator.pop(context);
                      _startPractice(book);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _selectedMode == AppMode.test
                          ? l10n.get('startTest')
                          : l10n.startPractice,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModeSelector(AppLocalizations l10n, StateSetter setModalState) {
    final modes = [
      (AppMode.practice, l10n.practiceMode, l10n.get('practiceModeDesc'), Icons.edit_note),
      (AppMode.review, l10n.reviewMode, l10n.get('reviewModeDesc'), Icons.rate_review),
      (AppMode.memorize, l10n.memorizeMode, l10n.get('memorizeModeDesc'), Icons.psychology),
      (AppMode.test, l10n.testMode, l10n.get('testModeDesc'), Icons.timer),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: modes.map((mode) {
        final isSelected = _selectedMode == mode.$1;
        return ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 150),
          child: Card(
            key: ValueKey('mode_${mode.$1.name}'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {
                setModalState(() {
                  _selectedMode = mode.$1;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      mode.$4,
                      size: 32,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      mode.$2,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.$3,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTestQuestionCountSelector(AppLocalizations l10n, StateSetter setModalState) {
    return Card(
      key: const Key('home_test_count_selector'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              l10n.get('testQuestionCount'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            IconButton(
              key: const Key('home_test_count_decrease'),
              onPressed: _testQuestionCount > 10
                  ? () => setModalState(() => _testQuestionCount -= 10)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Text(
                '$_testQuestionCount',
                key: const Key('home_test_count_text'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              key: const Key('home_test_count_increase'),
              onPressed: _testQuestionCount < 100
                  ? () => setModalState(() => _testQuestionCount += 10)
                  : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  void _startPractice(Book book, {bool autoStart = false}) async {
    final quiz = context.read<QuizProvider>();
    await quiz.selectBook(book);

    // If auto-starting, use the mode from saved progress.
    // Otherwise, use the mode selected in the UI.
    final modeToSet = autoStart ? quiz.appMode : _selectedMode;

    if (modeToSet == AppMode.test) {
      quiz.startTest(_testQuestionCount);
    } else {
      quiz.setMode(modeToSet);
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuizScreen()),
      );
    }
  }
}