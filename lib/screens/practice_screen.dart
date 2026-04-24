import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../l10n/app_localizations.dart';
import '../widgets/widgets.dart';
import '../widgets/dopamine_click_wrapper.dart';
import 'settings_screen.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late PageController _pageController;
  late PracticeProvider _quiz;
  final FocusNode _inputFocusNode = FocusNode(debugLabel: 'study_input');
  final FeedbackService _feedbackService = FeedbackService();

  // Local state to track selection before confirmation/animation
  String? _selectedOption;
  int? _highlightedOptionIndex;

  // Track if we are currently animating the page
  bool _isAnimatingPage = false;

  // Track target progress for immediate progress bar animation
  double? _targetProgress;

  // Trigger for success visual effect
  bool _successTrigger = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _feedbackService.init();
    _feedbackService.configure(
      soundEnabled: settings.soundEffects,
      hapticEnabled: settings.hapticFeedback,
      continuousFeedback: settings.continuousFeedback,
    );

    _quiz = context.read<PracticeProvider>();
    _pageController = PageController(initialPage: _quiz.currentIndex);
    _quiz.addListener(_syncStudyState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncHighlightedOptionFromStudy();
      _requestInputFocus();
    });
  }

  void _syncStudyState() {
    if (!mounted) return;

    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage != _quiz.currentIndex) {
        _isAnimatingPage = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(_quiz.currentIndex);
          }
        });
      }
    }

    _syncHighlightedOptionFromStudy();
  }

  @override
  void dispose() {
    _quiz.removeListener(_syncStudyState);
    _inputFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quiz = context.watch<PracticeProvider>();

    return Focus(
      autofocus: true,
      focusNode: _inputFocusNode,
      onKeyEvent: _handleStudyKeyEvent,
      child: Scaffold(
        key: const Key('study_scaffold'),
        appBar: PreferredSize(
          key: const Key('study_app_bar_preferred_size'),
          preferredSize: const Size.fromHeight(56),
          child: _buildAppBar(context, l10n),
        ),
        body: SuccessFeedback(
          key: const Key('study_success_feedback'),
          trigger: _successTrigger,
          child: Stack(
            key: const Key('study_body_stack'),
            children: [
              Column(
                key: const Key('study_main_column'),
                children: [
                  Padding(
                    key: const Key('study_progress_bar_padding'),
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Consumer<PracticeProvider>(
                      key: const Key('study_progress_consumer'),
                      builder: (context, quiz, _) {
                        final progress =
                            _targetProgress ??
                            (quiz.totalQuestions > 0
                                ? (quiz.currentIndex + 1) / quiz.totalQuestions
                                : 0.0);
                        return DopamineProgressBar(
                          key: const Key('study_dopamine_progress_bar'),
                          progress: progress,
                        );
                      },
                    ),
                  ),
                  Expanded(
                    key: const Key('study_question_expanded'),
                    child: quiz.totalQuestions > 0
                        ? PageView.builder(
                            key: const Key('study_question_pageview'),
                            controller: _pageController,
                            itemCount: quiz.totalQuestions,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            onPageChanged: (index) {
                              if (_isAnimatingPage) return;
                              setState(() {
                                _selectedOption = null;
                                _highlightedOptionIndex = null;
                              });
                              if (index != _quiz.currentIndex) {
                                _quiz.goToQuestion(index);
                              }
                            },
                            itemBuilder: (context, index) {
                              final question = quiz.questions[index];
                              final isCurrent = index == quiz.currentIndex;
                              final answer = isCurrent
                                  ? quiz.currentUserAnswer
                                  : null;

                              return SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: QuestionCard(
                                  key: ValueKey('question_$index'),
                                  question: question,
                                  selectedOption: isCurrent
                                      ? (_selectedOption ?? answer?.selected)
                                      : null,
                                  highlightedOption: isCurrent
                                      ? _currentHighlightedOptionKey(
                                          question,
                                          answer,
                                        )
                                      : null,
                                  showAnswer: isCurrent && answer != null,
                                  imageBasePath: quiz.currentPackageImagePath,
                                  onOptionSelected: (isCurrent && answer != null)
                                      ? null
                                      : (option) => _handleAnswer(option, index),
                                ),
                              );
                            },
                          )
                        : _buildEmptyState(context, l10n),
                  ),
                  _buildActionBar(l10n),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations l10n) {
    final quiz = context.read<PracticeProvider>();
    return AppBar(
      key: const Key('study_app_bar'),
      title: Column(
        key: const Key('study_title_column'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Selector<PracticeProvider, String>(
            key: const Key('study_title_selector'),
            selector: (_, provider) =>
                provider.currentBook?.getDisplayName(l10n.localeName) ?? '',
            builder: (_, title, _) => Text(
              title,
              key: const Key('study_title_text'),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Selector<PracticeProvider, String>(
            key: const Key('study_order_selector'),
            selector: (_, provider) =>
                '${provider.currentIndex + 1} / ${provider.totalQuestions}',
            builder: (_, order, _) => Text(
              order,
              key: const Key('study_order_text'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
      leading: DopamineClickWrapper(
        key: const Key('study_back_wrapper'),
        child: IconButton(
          key: const Key('study_back_button'),
          icon: const Icon(Icons.arrow_back, key: Key('study_back_icon')),
          onPressed: _handleBack,
        ),
      ),
      actions: [
        DopamineClickWrapper(
          key: const Key('study_section_wrapper'),
          child: IconButton(
            key: const Key('study_section_button'),
            icon: const Icon(Icons.list_alt, key: Key('study_section_icon')),
            tooltip: l10n.section,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SectionSelector(
                  key: const Key('study_section_sheet'),
                  sections: quiz.sections,
                  currentPartitionId: quiz.currentPartitionId,
                  onSectionSelected: quiz.selectPartition,
                ),
              ).whenComplete(_requestInputFocus);
            },
          ),
        ),
        DopamineClickWrapper(
          key: const Key('study_overview_wrapper'),
          child: IconButton(
            key: const Key('study_overview_button'),
            icon: const Icon(Icons.grid_view, key: Key('study_overview_icon')),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    const OverviewSheet(key: Key('study_overview_sheet')),
              ).whenComplete(_requestInputFocus);
            },
          ),
        ),
        PopupMenuButton<String>(
          key: const Key('study_menu_button'),
          onSelected: (value) {
            if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const SettingsScreen(key: Key('study_settings_page')),
                ),
              ).then((_) => _requestInputFocus());
            } else if (value == 'reset') {
              _showResetDialog();
            } else if (value == 'add_to_collection') {
              _showAddToCollectionSheet();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              key: const Key('menu_history'),
              value: 'history',
              child: Row(
                key: const Key('menu_history_row'),
                children: [
                  const Icon(
                    Icons.history,
                    key: Key('menu_history_icon'),
                    size: 20,
                  ),
                  const SizedBox(width: 8, key: Key('menu_history_spacer')),
                  Text(l10n.history, key: const Key('menu_history_text')),
                ],
              ),
            ),
            PopupMenuItem(
              key: const Key('menu_settings'),
              value: 'settings',
              child: Row(
                key: const Key('menu_settings_row'),
                children: [
                  const Icon(
                    Icons.settings,
                    key: Key('menu_settings_icon'),
                    size: 20,
                  ),
                  const SizedBox(width: 8, key: Key('menu_settings_spacer')),
                  Text(l10n.settings, key: const Key('menu_settings_text')),
                ],
              ),
            ),
            PopupMenuItem(
              key: const Key('menu_add_to_collection'),
              value: 'add_to_collection',
              child: Row(
                key: const Key('menu_add_to_collection_row'),
                children: [
                  const Icon(
                    Icons.folder_copy_outlined,
                    key: Key('menu_add_to_collection_icon'),
                    size: 20,
                  ),
                  const SizedBox(width: 8, key: Key('menu_add_to_collection_spacer')),
                  Text('Add to Collection', key: const Key('menu_add_to_collection_text')), // TODO(l10n)
                ],
              ),
            ),
            PopupMenuItem(
              key: const Key('menu_reset'),
              value: 'reset',
              child: Row(
                key: const Key('menu_reset_row'),
                children: [
                  const Icon(
                    Icons.restart_alt,
                    key: Key('menu_reset_icon'),
                    size: 20,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8, key: Key('menu_reset_spacer')),
                  Text(
                    l10n.reset,
                    key: const Key('menu_reset_text'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            l10n.noQuestions,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(AppLocalizations l10n) {
    return Container(
      key: const Key('study_action_bar_container'),
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
        key: const Key('study_action_bar_safe_area'),
        child: Consumer<PracticeProvider>(
          key: const Key('study_action_bar_consumer'),
          builder: (context, quiz, _) {
            final question = quiz.currentQuestion;
            return Row(
              key: const Key('action_bar'),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DopamineClickWrapper(
                  key: const Key('action_prev_wrapper'),
                  child: IconButton(
                    key: const Key('action_prev_button'),
                    onPressed: quiz.currentIndex > 0
                        ? () => _goToPage(quiz.currentIndex - 1)
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: l10n.previous,
                  ),
                ),
                DopamineClickWrapper(
                  key: const Key('action_ai_wrapper'),
                  child: IconButton(
                    key: const Key('action_ai_button'),
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: question != null
                        ? () => _showAiPanel(question)
                        : null,
                    tooltip: l10n.aiExplain,
                  ),
                ),
                const SizedBox(width: 48),
                DopamineClickWrapper(
                  key: const Key('action_mark_wrapper'),
                  child: IconButton(
                    key: const Key('action_mark_button'),
                    icon: Icon(
                      quiz.isCurrentMarked
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      color: quiz.isCurrentMarked ? Colors.orange : null,
                    ),
                    onPressed: question != null
                        ? () => quiz.toggleMark(question.id)
                        : null,
                    tooltip: quiz.isCurrentMarked ? l10n.unmark : l10n.mark,
                  ),
                ),
                DopamineClickWrapper(
                  key: const Key('action_reset_wrapper'),
                  child: IconButton(
                    key: const Key('action_reset_button'),
                    icon: const Icon(Icons.undo),
                    onPressed: quiz.currentUserAnswer != null
                        ? _resetCurrentQuestion
                        : null,
                    tooltip: l10n.reset,
                  ),
                ),
                DopamineClickWrapper(
                  key: const Key('action_next_wrapper'),
                  child: IconButton(
                    key: const Key('action_next_button'),
                    onPressed: quiz.currentIndex < quiz.totalQuestions - 1
                        ? () => _goToPage(quiz.currentIndex + 1)
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: l10n.next,
                  ),
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

    final quiz = context.read<PracticeProvider>();
    setState(() {
      _isAnimatingPage = true;
      _selectedOption = null;
      _highlightedOptionIndex = null;
      _targetProgress = (page + 1) / quiz.totalQuestions;
    });

    _pageController
        .animateToPage(
          page,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (!mounted) return;

          setState(() {
            _isAnimatingPage = false;
            _targetProgress = null;
          });

          final quiz = context.read<PracticeProvider>();
          if (quiz.currentIndex != page) {
            quiz.goToQuestion(page);
          }
        });
  }

  void _showAiPanel(Question question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AiChatPanel(key: const Key('study_ai_panel'), question: question),
    ).whenComplete(_requestInputFocus);
  }

  void _handleAnswer(String option, int questionIndex) {
    final quiz = context.read<PracticeProvider>();
    final settings = context.read<SettingsProvider>();

    if (questionIndex != quiz.currentIndex) return;

    setState(() {
      _selectedOption = option;
      _highlightedOptionIndex = _findChoiceIndexByKey(
        quiz.currentQuestion,
        option,
      );
    });

    quiz.answerQuestion(option);

    final isCorrect =
        option.toUpperCase() == quiz.currentQuestion!.answer.toUpperCase();

    if (isCorrect) {
      _feedbackService.incrementStreak();
    } else {
      _feedbackService.resetStreak();
    }

    _feedbackService.configure(
      soundEnabled: settings.soundEffects,
      hapticEnabled: settings.hapticFeedback,
      continuousFeedback: settings.continuousFeedback,
    );

    if (isCorrect) {
      _feedbackService.playCorrect();
    } else {
      _feedbackService.playWrong();
    }

    if (isCorrect && settings.confettiEffect) {
      setState(() {
        _successTrigger = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _successTrigger = false;
          });
        }
      });
    }

    if (isCorrect && settings.autoAdvance) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          final currentQuiz = context.read<PracticeProvider>();
          if (currentQuiz.currentIndex == questionIndex &&
              currentQuiz.currentIndex < currentQuiz.totalQuestions - 1) {
            _goToPage(currentQuiz.currentIndex + 1);
          }
        }
      });
    }
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  void _showResetDialog() {
    final quiz = context.read<PracticeProvider>();
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('reset_progress_dialog'),
        title: Text(l10n.resetProgress, key: const Key('reset_progress_title')),
        content: Text(
          l10n.confirmResetProgress,
          key: const Key('reset_progress_content'),
        ),
        actions: [
          TextButton(
            key: const Key('reset_progress_cancel'),
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel,
              key: const Key('reset_progress_cancel_text'),
            ),
          ),
          ElevatedButton(
            key: const Key('reset_progress_confirm'),
            onPressed: () {
              quiz.resetAllProgress();
              _feedbackService.resetStreak();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              l10n.doReset,
              key: const Key('reset_progress_confirm_text'),
            ),
          ),
        ],
      ),
    ).then((_) => _requestInputFocus());
  }

  void _requestInputFocus() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  void _syncHighlightedOptionFromStudy() {
    final nextIndex = _resolvedHighlightedOptionIndex(_quiz);
    if (!mounted || nextIndex == _highlightedOptionIndex) {
      return;
    }

    setState(() {
      _highlightedOptionIndex = nextIndex;
    });
  }

  int? _resolvedHighlightedOptionIndex(PracticeProvider quiz) {
    final question = quiz.currentQuestion;
    final choices = question?.choices ?? const <QuestionChoice>[];
    if (choices.isEmpty) return null;

    final selectedKey = _selectedOption ?? quiz.currentUserAnswer?.selected;
    final selectedIndex = _findChoiceIndexByKey(question, selectedKey);
    if (selectedIndex != null) {
      return selectedIndex;
    }

    if (_highlightedOptionIndex == null) {
      return 0;
    }

    if (_highlightedOptionIndex! < 0) return 0;
    if (_highlightedOptionIndex! >= choices.length) return choices.length - 1;
    return _highlightedOptionIndex;
  }

  int? _findChoiceIndexByKey(Question? question, String? optionKey) {
    if (question == null || optionKey == null) return null;

    final index = question.choices.indexWhere(
      (choice) => choice.key.toUpperCase() == optionKey.toUpperCase(),
    );
    return index >= 0 ? index : null;
  }

  String? _currentHighlightedOptionKey(Question question, UserAnswer? answer) {
    final selectedKey = _selectedOption ?? answer?.selected;
    if (selectedKey != null) {
      return selectedKey;
    }

    final highlightedIndex = _resolvedHighlightedOptionIndex(_quiz);
    if (highlightedIndex == null ||
        highlightedIndex < 0 ||
        highlightedIndex >= question.choices.length) {
      return null;
    }

    return question.choices[highlightedIndex].key;
  }

  void _moveHighlightedOption(int delta) {
    final quiz = context.read<PracticeProvider>();
    final question = quiz.currentQuestion;
    if (question == null ||
        question.choices.isEmpty ||
        quiz.currentUserAnswer != null) {
      return;
    }

    final baseIndex = _resolvedHighlightedOptionIndex(quiz) ?? 0;
    final nextIndex = (baseIndex + delta)
        .clamp(0, question.choices.length - 1)
        .toInt();
    if (nextIndex == _highlightedOptionIndex) return;

    setState(() {
      _highlightedOptionIndex = nextIndex;
    });
  }

  void _submitHighlightedOption() {
    final quiz = context.read<PracticeProvider>();
    final question = quiz.currentQuestion;
    if (question == null ||
        question.choices.isEmpty ||
        quiz.currentUserAnswer != null) {
      return;
    }

    final optionIndex = _resolvedHighlightedOptionIndex(quiz);
    if (optionIndex == null ||
        optionIndex < 0 ||
        optionIndex >= question.choices.length) {
      return;
    }

    _handleAnswer(question.choices[optionIndex].key, quiz.currentIndex);
  }

  void _selectOptionByIndex(int optionIndex) {
    final quiz = context.read<PracticeProvider>();
    final question = quiz.currentQuestion;
    if (question == null ||
        quiz.currentUserAnswer != null ||
        optionIndex < 0 ||
        optionIndex >= question.choices.length) {
      return;
    }

    setState(() {
      _highlightedOptionIndex = optionIndex;
    });
    _handleAnswer(question.choices[optionIndex].key, quiz.currentIndex);
  }

  void _resetCurrentQuestion() {
    final quiz = context.read<PracticeProvider>();
    quiz.resetCurrentQuestion();
    setState(() {
      _selectedOption = null;
      _highlightedOptionIndex = 0;
    });
    _requestInputFocus();
  }

  KeyEventResult _handleStudyKeyEvent(FocusNode node, KeyEvent event) {
    if (ModalRoute.of(context)?.isCurrent != true) {
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final numericSelection = _optionIndexForNumberKey(key);
    if (numericSelection != null) {
      _selectOptionByIndex(numericSelection);
      return KeyEventResult.handled;
    }

    final letterSelection = _optionIndexForLetterKey(key);
    if (letterSelection != null) {
      _selectOptionByIndex(letterSelection);
      return KeyEventResult.handled;
    }

    if (_matchesAny(key, const [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.gameButton12,
    ])) {
      _moveHighlightedOption(-1);
      return KeyEventResult.handled;
    }

    if (_matchesAny(key, const [
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.gameButton13,
    ])) {
      _moveHighlightedOption(1);
      return KeyEventResult.handled;
    }

    if (_matchesAny(key, const [
      LogicalKeyboardKey.enter,
      LogicalKeyboardKey.numpadEnter,
      LogicalKeyboardKey.space,
      LogicalKeyboardKey.select,
      LogicalKeyboardKey.gameButtonA,
      LogicalKeyboardKey.gameButton1,
    ])) {
      _submitHighlightedOption();
      return KeyEventResult.handled;
    }

    if (_matchesAny(key, const [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.keyQ,
      LogicalKeyboardKey.pageUp,
      LogicalKeyboardKey.gameButtonLeft1,
      LogicalKeyboardKey.gameButtonLeft2,
    ])) {
      final quiz = context.read<PracticeProvider>();
      if (quiz.currentIndex > 0) {
        _goToPage(quiz.currentIndex - 1);
      }
      return KeyEventResult.handled;
    }

    if (_matchesAny(key, const [
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.keyE,
      LogicalKeyboardKey.pageDown,
      LogicalKeyboardKey.gameButtonRight1,
      LogicalKeyboardKey.gameButtonRight2,
    ])) {
      final quiz = context.read<PracticeProvider>();
      if (quiz.currentIndex < quiz.totalQuestions - 1) {
        _goToPage(quiz.currentIndex + 1);
      }
      return KeyEventResult.handled;
    }

    if (_matchesAny(key, const [
      LogicalKeyboardKey.keyY,
      LogicalKeyboardKey.gameButtonY,
      LogicalKeyboardKey.gameButton4,
    ])) {
      final quiz = context.read<PracticeProvider>();
      final question = quiz.currentQuestion;
      if (question != null) {
        quiz.toggleMark(question.id);
      }
      return KeyEventResult.handled;
    }

    if (_matchesAny(key, const [
      LogicalKeyboardKey.keyX,
      LogicalKeyboardKey.backspace,
      LogicalKeyboardKey.delete,
      LogicalKeyboardKey.gameButtonX,
      LogicalKeyboardKey.gameButton3,
    ])) {
      if (context.read<PracticeProvider>().currentUserAnswer != null) {
        _resetCurrentQuestion();
      }
      return KeyEventResult.handled;
    }

    if (_matchesAny(key, const [
      LogicalKeyboardKey.escape,
      LogicalKeyboardKey.gameButtonB,
      LogicalKeyboardKey.goBack,
    ])) {
      _handleBack();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _matchesAny(LogicalKeyboardKey key, List<LogicalKeyboardKey> keys) {
    return keys.contains(key);
  }

  int? _optionIndexForNumberKey(LogicalKeyboardKey key) {
    const numericKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];

    final index = numericKeys.indexOf(key);
    return index >= 0 ? index : null;
  }

  int? _optionIndexForLetterKey(LogicalKeyboardKey key) {
    const letterKeys = <LogicalKeyboardKey>[
      LogicalKeyboardKey.keyA,
      LogicalKeyboardKey.keyB,
      LogicalKeyboardKey.keyC,
      LogicalKeyboardKey.keyD,
      LogicalKeyboardKey.keyE,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyG,
      LogicalKeyboardKey.keyH,
    ];

    final index = letterKeys.indexOf(key);
    return index >= 0 ? index : null;
  }

  Future<void> _showAddToCollectionSheet() async {
    final quiz = context.read<PracticeProvider>();
    final book = quiz.currentBook;
    final question = quiz.currentQuestion;
    if (book == null || question == null) return;

    final collections = await DatabaseService().getCollectionsByType(
      book.id,
      CollectionType.practiceSet,
    );
    final playlists = await DatabaseService().getCollectionsByType(
      book.id,
      CollectionType.playlist,
    );
    final userCollections = [...collections, ...playlists];

    if (!mounted) return;

    if (userCollections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a collection first from the book detail screen.'), // TODO(l10n)
        ),
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
                'Add to Collection', // TODO(l10n)
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
                    subtitle: collection.description != null
                        ? Text(collection.description!)
                        : null,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final db = DatabaseService();
                      final added = await db.addQuestionToCollection(
                        collection.id,
                        question.id,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              added
                                  ? 'Added to "${collection.name}"'
                                  : 'Already in "${collection.name}"', // TODO(l10n)
                            ),
                          ),
                        );
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
}
