import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../l10n/app_localizations.dart';
import '../widgets/widgets.dart';
import 'practice_screen.dart';
import 'test_result_screen.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late PageController _pageController;
  late TestProvider _test;
  final FocusNode _inputFocusNode = FocusNode(debugLabel: 'test_input');

  String? _selectedOption;
  int? _highlightedOptionIndex;
  bool _isAnimatingPage = false;

  @override
  void initState() {
    super.initState();
    _test = context.read<TestProvider>();
    _pageController = PageController(initialPage: _test.currentIndex);
    _test.addListener(_syncTestState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncHighlightedOptionFromTest();
      _requestInputFocus();
    });
  }

  void _syncTestState() {
    if (!mounted) return;

    if (_pageController.hasClients) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage != _test.currentIndex) {
        _isAnimatingPage = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _pageController.hasClients) {
            _pageController.jumpToPage(_test.currentIndex);
          }
        });
      }
    }

    _syncHighlightedOptionFromTest();
  }

  @override
  void dispose() {
    _test.removeListener(_syncTestState);
    _inputFocusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final test = context.watch<TestProvider>();

    return Focus(
      autofocus: true,
      focusNode: _inputFocusNode,
      onKeyEvent: _handleTestKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                test.currentBook?.getDisplayName(l10n.localeName) ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              Text(
                '${test.currentIndex + 1} / ${test.totalQuestions}',
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
            onPressed: _handleBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _TestOverviewSheet(
                    totalQuestions: test.totalQuestions,
                    currentIndex: test.currentIndex,
                    onQuestionSelected: (index) {
                      _goToPage(index);
                    },
                  ),
                ).whenComplete(_requestInputFocus);
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: LinearProgressIndicator(
                value: test.totalQuestions > 0
                    ? (test.currentIndex + 1) / test.totalQuestions
                    : 0.0,
              ),
            ),
            Expanded(
              child: test.totalQuestions > 0
                  ? PageView.builder(
                      controller: _pageController,
                      itemCount: test.totalQuestions,
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      onPageChanged: (index) {
                        if (_isAnimatingPage) return;
                        setState(() {
                          _selectedOption = null;
                          _highlightedOptionIndex = null;
                        });
                        if (index != _test.currentIndex) {
                          _test.goToQuestion(index);
                        }
                      },
                      itemBuilder: (context, index) {
                        final question = test.questions[index];
                        final isCurrent = index == test.currentIndex;
                        final answer = isCurrent
                            ? test.currentUserAnswer
                            : null;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: QuestionCard(
                            key: ValueKey('test_question_$index'),
                            question: question,
                            selectedOption: isCurrent
                                ? (_selectedOption ?? answer?.selected)
                                : null,
                            highlightedOption: isCurrent
                                    ? _currentHighlightedOptionKey(question, answer)
                                    : null,
                            showAnswer: false,
                            showAnalysis: false,
                            imageBasePath: test.currentPackageImagePath,
                            onOptionSelected: (isCurrent)
                                ? (option) => _handleAnswer(option, index)
                                : null,
                          ),
                        );
                      },
                    )
                  : _buildEmptyState(context, l10n),
            ),
            _buildActionBar(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
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
        child: Consumer<TestProvider>(
          builder: (context, test, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: test.currentIndex > 0
                      ? () => _goToPage(test.currentIndex - 1)
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: l10n.previous,
                ),
                ElevatedButton(
                  onPressed: _finishTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(l10n.finishTest),
                ),
                IconButton(
                  onPressed: test.currentIndex < test.totalQuestions - 1
                      ? () => _goToPage(test.currentIndex + 1)
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

    setState(() {
      _isAnimatingPage = true;
      _selectedOption = null;
      _highlightedOptionIndex = null;
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
          });

          final test = context.read<TestProvider>();
          if (test.currentIndex != page) {
            test.goToQuestion(page);
          }
        });
  }

  void _handleAnswer(String option, int questionIndex) {
    final test = context.read<TestProvider>();

    if (questionIndex != test.currentIndex) return;

    setState(() {
      _selectedOption = option;
      _highlightedOptionIndex = _findChoiceIndexByKey(
        test.currentQuestion,
        option,
      );
    });

    test.answerQuestion(option);
  }

  void _handleBack() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.finishTest),
        content: Text(l10n.confirmExitTest),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishTest();
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    ).then((_) => _requestInputFocus());
  }

  Future<void> _finishTest() async {
    final test = context.read<TestProvider>();
    final result = await test.finishTest();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TestResultScreen(
            result: result,
            onRetake: () async {
              final test = context.read<TestProvider>();
              final settings = context.read<SettingsProvider>();
              test.startTest(settings.testQuestionCount);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const TestScreen()),
                (route) => route.isFirst,
              );
            },
            onReviewMistakes: () {
              final quiz = context.read<PracticeProvider>();
              quiz.startMistakeReview(result);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const PracticeScreen()),
                (route) => route.isFirst,
              );
            },
          ),
        ),
      );
    }
  }

  void _requestInputFocus() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _inputFocusNode.requestFocus();
      }
    });
  }

  void _syncHighlightedOptionFromTest() {
    final nextIndex = _resolvedHighlightedOptionIndex(_test);
    if (!mounted || nextIndex == _highlightedOptionIndex) {
      return;
    }

    setState(() {
      _highlightedOptionIndex = nextIndex;
    });
  }

  int? _resolvedHighlightedOptionIndex(TestProvider test) {
    final question = test.currentQuestion;
    final choices = question?.choices ?? const <QuestionChoice>[];
    if (choices.isEmpty) return null;

    final selectedKey = _selectedOption ?? test.currentUserAnswer?.selected;
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

    final highlightedIndex = _resolvedHighlightedOptionIndex(_test);
    if (highlightedIndex == null ||
        highlightedIndex < 0 ||
        highlightedIndex >= question.choices.length) {
      return null;
    }

    return question.choices[highlightedIndex].key;
  }

  void _moveHighlightedOption(int delta) {
    final test = context.read<TestProvider>();
    final question = test.currentQuestion;
    if (question == null || question.choices.isEmpty) {
      return;
    }

    final baseIndex = _resolvedHighlightedOptionIndex(test) ?? 0;
    final nextIndex = (baseIndex + delta)
        .clamp(0, question.choices.length - 1)
        .toInt();
    if (nextIndex == _highlightedOptionIndex) return;

    setState(() {
      _highlightedOptionIndex = nextIndex;
    });
  }

  void _submitHighlightedOption() {
    final test = context.read<TestProvider>();
    final question = test.currentQuestion;
    if (question == null || question.choices.isEmpty) {
      return;
    }

    final optionIndex = _resolvedHighlightedOptionIndex(test);
    if (optionIndex == null ||
        optionIndex < 0 ||
        optionIndex >= question.choices.length) {
      return;
    }

    _handleAnswer(question.choices[optionIndex].key, test.currentIndex);
  }

  void _selectOptionByIndex(int optionIndex) {
    final test = context.read<TestProvider>();
    final question = test.currentQuestion;
    if (question == null ||
        optionIndex < 0 ||
        optionIndex >= question.choices.length) {
      return;
    }

    setState(() {
      _highlightedOptionIndex = optionIndex;
    });
    _handleAnswer(question.choices[optionIndex].key, test.currentIndex);
  }

  KeyEventResult _handleTestKeyEvent(FocusNode node, KeyEvent event) {
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
      final test = context.read<TestProvider>();
      if (test.currentIndex > 0) {
        _goToPage(test.currentIndex - 1);
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
      final test = context.read<TestProvider>();
      if (test.currentIndex < test.totalQuestions - 1) {
        _goToPage(test.currentIndex + 1);
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

    if (_matchesAny(key, const [
      LogicalKeyboardKey.gameButtonStart,
      LogicalKeyboardKey.f5,
    ])) {
      _finishTest();
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
}

class _TestOverviewSheet extends StatelessWidget {
  final int totalQuestions;
  final int currentIndex;
  final ValueChanged<int> onQuestionSelected;

  const _TestOverviewSheet({
    required this.totalQuestions,
    required this.currentIndex,
    required this.onQuestionSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BottomSheetHandle(),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                AppLocalizations.of(context).overview,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: totalQuestions,
                  itemBuilder: (context, i) {
                    final status = context.read<TestProvider>().getQuestionStatus(i);
                    final isAnswered = status != QuestionStatus.unanswered;
                    final isCurrent = i == currentIndex;

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        onQuestionSelected(i);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isAnswered
                              ? colorScheme.primary.withValues(alpha: 0.15)
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: isCurrent
                              ? Border.all(color: colorScheme.primary, width: 3)
                              : Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAnswered ? colorScheme.primary : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
