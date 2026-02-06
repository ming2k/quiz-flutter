import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../l10n/app_localizations.dart';
import '../widgets/widgets.dart';
import '../widgets/dopamine_click_wrapper.dart';
import 'test_result_screen.dart';
import 'settings_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late PageController _pageController;
  final SoundService _soundService = SoundService();
  final HapticService _hapticService = HapticService();
  
  // Local state to track selection before confirmation/animation
  String? _selectedOption;
  
  // Track if we are currently animating the page
  bool _isAnimatingPage = false;

  // Track target progress for immediate progress bar animation
  double? _targetProgress;

  // Trigger for success visual effect
  bool _successTrigger = false;

  @override
  void initState() {
    super.initState();
    _soundService.init();
    _hapticService.init();
    
    final quiz = context.read<QuizProvider>();
    _pageController = PageController(initialPage: quiz.currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quiz = context.watch<QuizProvider>();

    // Sync PageController with QuizProvider index if changed externally (e.g. Overview)
    if (_pageController.hasClients && !_isAnimatingPage) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage != quiz.currentIndex) {
        _pageController.jumpToPage(quiz.currentIndex);
      }
    }

    return Scaffold(
      key: const Key('quiz_scaffold'),
      appBar: PreferredSize(
        key: const Key('quiz_app_bar_preferred_size'),
        preferredSize: const Size.fromHeight(56),
        child: _buildAppBar(context, l10n),
      ),
      body: SuccessFeedback(
        key: const Key('quiz_success_feedback'),
        trigger: _successTrigger,
        child: Stack(
          key: const Key('quiz_body_stack'),
          children: [
            Column(
              key: const Key('quiz_main_column'),
              children: [
                // Progress Bar
                Padding(
                  key: const Key('quiz_progress_bar_padding'),
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Consumer<QuizProvider>(
                    key: const Key('quiz_progress_consumer'),
                    builder: (context, quiz, _) {
                      final progress = _targetProgress ?? 
                          (quiz.totalQuestions > 0 ? (quiz.currentIndex + 1) / quiz.totalQuestions : 0.0);
                      return DopamineProgressBar(
                        key: const Key('quiz_dopamine_progress_bar'),
                        progress: progress,
                      );
                    },
                  ),
                ),

                // Question Content
                Expanded(
                  key: const Key('quiz_question_expanded'),
                  child: quiz.totalQuestions > 0 
                    ? PageView.builder(
                        key: const Key('quiz_question_pageview'),
                        controller: _pageController,
                        itemCount: quiz.totalQuestions,
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        onPageChanged: (index) {
                          if (!_isAnimatingPage) {
                            quiz.goToQuestion(index);
                            setState(() {
                              _selectedOption = null;
                            });
                          }
                        },
                        itemBuilder: (context, index) {
                          final question = quiz.questions[index];
                          final isCurrent = index == quiz.currentIndex;
                          final answer = isCurrent ? quiz.currentUserAnswer : null;

                          return QuestionCard(
                            key: ValueKey('question_$index'),
                            question: question,
                            selectedOption: isCurrent ? (_selectedOption ?? answer?.selected) : null,
                            showAnswer: (isCurrent && answer != null) || quiz.appMode == AppMode.memorize,
                            imageBasePath: quiz.currentPackageImagePath,
                            onOptionSelected: (isCurrent && answer != null)
                                ? null
                                : (option) => _handleAnswer(option, index),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
                ),

                // Action Bar
                _buildActionBar(l10n),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations l10n) {
    final quiz = context.read<QuizProvider>();
    return AppBar(
      key: const Key('quiz_app_bar'),
      title: Column(
        key: const Key('quiz_title_column'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Selector<QuizProvider, String>(
            key: const Key('quiz_title_selector'),
            selector: (_, provider) =>
                provider.currentBook?.getDisplayName(l10n.locale.languageCode) ?? '',
            builder: (_, title, __) => Text(
              title, 
              key: const Key('quiz_title_text'),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Selector<QuizProvider, String>(
            key: const Key('quiz_order_selector'),
            selector: (_, provider) => '${provider.currentIndex + 1} / ${provider.totalQuestions}',
            builder: (_, order, __) => Text(
              order,
              key: const Key('quiz_order_text'),
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
      leading: DopamineClickWrapper(
        key: const Key('quiz_back_wrapper'),
        child: IconButton(
          key: const Key('quiz_back_button'),
          icon: const Icon(Icons.arrow_back, key: Key('quiz_back_icon')),
          onPressed: () => _handleBack(),
        ),
      ),
      actions: [
        // Section selector
        Selector<QuizProvider, bool>(
          key: const Key('quiz_section_selector'),
          selector: (_, provider) => provider.isTestActive,
          builder: (context, isTestActive, _) {
            if (isTestActive) return const SizedBox.shrink(key: Key('quiz_section_empty'));
            return DopamineClickWrapper(
              key: const Key('quiz_section_wrapper'),
              child: IconButton(
                key: const Key('quiz_section_button'),
                icon: const Icon(Icons.list_alt, key: Key('quiz_section_icon')),
                tooltip: l10n.get('section'),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => SectionSelector(
                      key: const Key('quiz_section_sheet'),
                      sections: quiz.sections,
                      currentPartitionId: quiz.currentPartitionId,
                      onSectionSelected: quiz.selectPartition,
                    ),
                  );
                },
              ),
            );
          },
        ),
        // Overview
        DopamineClickWrapper(
          key: const Key('quiz_overview_wrapper'),
          child: IconButton(
            key: const Key('quiz_overview_button'),
            icon: const Icon(Icons.grid_view, key: Key('quiz_overview_icon')),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const OverviewSheet(key: Key('quiz_overview_sheet')),
              );
            },
          ),
        ),
        // Menu
        PopupMenuButton<String>(
          key: const Key('quiz_menu_button'),
          onSelected: (value) {
            if (value == 'history') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestHistoryList(key: Key('quiz_history_page'))),
              );
            } else if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen(key: Key('quiz_settings_page'))),
              );
            } else if (value == 'reset') {
              _showResetDialog();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              key: const Key('menu_history'),
              value: 'history',
              child: Row(
                key: const Key('menu_history_row'),
                children: [
                  const Icon(Icons.history, key: Key('menu_history_icon'), size: 20),
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
                  const Icon(Icons.settings, key: Key('menu_settings_icon'), size: 20),
                  const SizedBox(width: 8, key: Key('menu_settings_spacer')),
                  Text(l10n.settings, key: const Key('menu_settings_text')),
                ],
              ),
            ),
            PopupMenuItem(
              key: const Key('menu_reset'),
              value: 'reset',
              child: Row(
                key: const Key('menu_reset_row'),
                children: [
                  const Icon(Icons.restart_alt, key: Key('menu_reset_icon'), size: 20, color: Colors.red),
                  const SizedBox(width: 8, key: Key('menu_reset_spacer')),
                  Text(l10n.get('reset'),
                      key: const Key('menu_reset_text'),
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionBar(AppLocalizations l10n) {
    return Container(
      key: const Key('quiz_action_bar_container'),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        key: const Key('quiz_action_bar_safe_area'),
        child: Consumer<QuizProvider>(
          key: const Key('quiz_action_bar_consumer'),
          builder: (context, quiz, _) {
            final question = quiz.currentQuestion;
            return Row(
              key: const Key('action_bar'),
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous
                DopamineClickWrapper(
                  key: const Key('action_prev_wrapper'),
                  child: IconButton(
                    key: const Key('action_prev_button'),
                    onPressed: quiz.currentIndex > 0 ? () => _goToPage(quiz.currentIndex - 1) : null,
                    icon: const Icon(Icons.arrow_back),
                    tooltip: l10n.get('previous'),
                  ),
                ),
                
                // AI Explain
                DopamineClickWrapper(
                  key: const Key('action_ai_wrapper'),
                  child: IconButton(
                    key: const Key('action_ai_button'),
                    icon: const Icon(Icons.auto_awesome),
                    onPressed: question != null ? () => _showAiPanel(question) : null,
                    tooltip: 'AI Explain',
                  ),
                ),

                // Finish Test (Special center button if active)
                if (quiz.isTestActive)
                  DopamineClickWrapper(
                    key: const Key('quiz_finish_wrapper'),
                    child: ElevatedButton(
                      key: const Key('quiz_finish_button'),
                      onPressed: () => _finishTest(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: Text(l10n.get('finishTest'), key: const Key('quiz_finish_text')),
                    ),
                  )
                else
                  const SizedBox(width: 48), // Placeholder to keep spacing if no finish button

                // Mark
                DopamineClickWrapper(
                  key: const Key('action_mark_wrapper'),
                  child: IconButton(
                    key: const Key('action_mark_button'),
                    icon: Icon(
                      quiz.isCurrentMarked ? Icons.bookmark : Icons.bookmark_border,
                      color: quiz.isCurrentMarked ? Colors.orange : null,
                    ),
                    onPressed: question != null ? () => quiz.toggleMark(question.id) : null,
                    tooltip: quiz.isCurrentMarked ? 'Unmark' : 'Mark',
                  ),
                ),

                // Reset
                DopamineClickWrapper(
                  key: const Key('action_reset_wrapper'),
                  child: IconButton(
                    key: const Key('action_reset_button'),
                    icon: const Icon(Icons.refresh),
                    onPressed: (quiz.currentUserAnswer != null) ? () {
                      quiz.resetCurrentQuestion();
                      setState(() {
                        _selectedOption = null;
                      });
                    } : null,
                    tooltip: 'Reset',
                  ),
                ),

                // Next
                DopamineClickWrapper(
                  key: const Key('action_next_wrapper'),
                  child: IconButton(
                    key: const Key('action_next_button'),
                    onPressed: quiz.currentIndex < quiz.totalQuestions - 1
                        ? () => _goToPage(quiz.currentIndex + 1)
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: l10n.get('next'),
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
    if (_pageController.hasClients) {
      final quiz = context.read<QuizProvider>();
      setState(() {
        _isAnimatingPage = true;
        _selectedOption = null;
        _targetProgress = (page + 1) / quiz.totalQuestions;
      });

      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        if (mounted) {
          setState(() {
            _isAnimatingPage = false;
            _targetProgress = null;
          });
          
          final quiz = context.read<QuizProvider>();
          if (quiz.currentIndex != page) {
            quiz.goToQuestion(page);
          }
        }
      });
    }
  }

  void _showAiPanel(Question question) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiChatPanel(
        key: const Key('quiz_ai_panel'),
        question: question,
      ),
    );
  }

  void _handleAnswer(String option, int questionIndex) {
    final quiz = context.read<QuizProvider>();
    final settings = context.read<SettingsProvider>();

    if (questionIndex != quiz.currentIndex) return;

    setState(() {
      _selectedOption = option;
    });

    quiz.answerQuestion(option);

    final isCorrect =
        option.toUpperCase() == quiz.currentQuestion!.answer.toUpperCase();

    // Update streak
    if (isCorrect) {
      _soundService.incrementStreak();
    } else {
      _soundService.resetStreak();
    }

    // Sound effects & Haptic feedback
    if (isCorrect) {
      if (settings.soundEffects) {
        _soundService.playCorrect();
      }
      if (settings.hapticFeedback) {
        _hapticService.playCorrect(_soundService.currentStreak);
      }
    } else {
      if (settings.soundEffects) {
        _soundService.playWrong();
      }
      if (settings.hapticFeedback) {
        _hapticService.playWrong();
      }
    }

    // Success feedback (Screen pulse)
    if (isCorrect && settings.confettiEffect) {
      setState(() {
        _successTrigger = true;
      });
      // Reset trigger shortly after
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _successTrigger = false;
          });
        }
      });
    }

    // Auto advance
    if (isCorrect && settings.autoAdvance) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          final currentQuiz = context.read<QuizProvider>();
          if (currentQuiz.currentIndex == questionIndex && 
              currentQuiz.currentIndex < currentQuiz.totalQuestions - 1) {
            _goToPage(currentQuiz.currentIndex + 1);
          }
        }
      });
    }
  }

  void _handleBack() {
    final quiz = context.read<QuizProvider>();
    if (quiz.isTestActive) {
      _showExitTestDialog();
    } else {
      Navigator.pop(context);
    }
  }

  void _showExitTestDialog() {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('exit_test_dialog'),
        title: Text(l10n.get('finishTest'), key: const Key('exit_test_title')),
        content: const Text('确定要结束考试吗？', key: Key('exit_test_content')),
        actions: [
          TextButton(
            key: const Key('exit_test_cancel'),
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel'), key: const Key('exit_test_cancel_text')),
          ),
          ElevatedButton(
            key: const Key('exit_test_confirm'),
            onPressed: () {
              Navigator.pop(context);
              _finishTest();
            },
            child: Text(l10n.get('confirm'), key: const Key('exit_test_confirm_text')),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    final quiz = context.read<QuizProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('reset_progress_dialog'),
        title: const Text('重置进度', key: Key('reset_progress_title')),
        content: const Text('确定要重置当前题库的所有进度吗？此操作不可撤销。', key: Key('reset_progress_content')),
        actions: [
          TextButton(
            key: const Key('reset_progress_cancel'),
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', key: Key('reset_progress_cancel_text')),
          ),
          ElevatedButton(
            key: const Key('reset_progress_confirm'),
            onPressed: () {
              quiz.resetAllProgress();
              _soundService.resetStreak();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('重置', key: Key('reset_progress_confirm_text')),
          ),
        ],
      ),
    );
  }

  void _finishTest() async {
    final quiz = context.read<QuizProvider>();
    final result = await quiz.finishTest();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TestResultScreen(key: const Key('test_result_page'), result: result),
        ),
      );
    }
  }
}