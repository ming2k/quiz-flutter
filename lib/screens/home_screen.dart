import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../widgets/dopamine_click_wrapper.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

import '../services/services.dart';
import '../utils/toast_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            key: const Key('home_import_button'),
            icon: const Icon(Icons.upload_file),
            tooltip: l10n.importPackage,
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
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            );
          }

          return ReorderableListView(
            header: _buildModeSelector(context, l10n, settings),
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

  Widget _buildModeSelector(BuildContext context, AppLocalizations l10n, SettingsProvider settings) {
    final modes = [
      (AppMode.practice, l10n.practiceMode, Icons.edit_note),
      (AppMode.test, l10n.testMode, Icons.timer),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: modes.map((mode) {
          final isSelected = settings.lastAppMode == mode.$1;
          final color = isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant;

          return DopamineClickWrapper(
            key: Key('mode_wrapper_${mode.$1}'),
            child: IconButton(
              icon: Icon(mode.$3),
              iconSize: 32,
              color: color,
              tooltip: mode.$2,
              onPressed: () {
                if (settings.lastAppMode != mode.$1) {
                  settings.setLastAppMode(mode.$1);
                  ToastUtils.showToast(context, mode.$2);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookCard(Book book, AppLocalizations l10n) {
    final locale = l10n.localeName;

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
            title: Text(l10n.confirm),
            content: Text(l10n.confirmDeleteBook(book.getDisplayName(locale))),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<QuizProvider>().deleteBook(book.id);
      },
      child: DopamineClickWrapper(
        key: ValueKey('book_wrapper_${book.id}'),
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _startPractice(book),
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
                          '${book.totalQuestions} ${l10n.questions}',
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
      ),
    );
  }

  void _startPractice(Book book, {bool autoStart = false}) async {
    final quiz = context.read<QuizProvider>();
    final settings = context.read<SettingsProvider>();
    await quiz.selectBook(book);

    // If auto-starting, use the mode from saved progress.
    // Otherwise, use the mode from settings (global selection).
    final modeToSet = autoStart ? quiz.appMode : settings.lastAppMode;

    if (modeToSet == AppMode.test) {
      quiz.startTest(settings.testQuestionCount);
    } else {
      quiz.setMode(modeToSet, index: quiz.currentIndex);
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuizScreen()),
      );
    }
  }

}