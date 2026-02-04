import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/sound_service.dart';
import '../l10n/app_localizations.dart';
import '../widgets/question_card.dart';
import '../widgets/section_selector.dart';
import '../widgets/ai_chat_panel.dart';
import '../widgets/test_history_list.dart';
import '../widgets/overview_sheet.dart';
import 'test_result_screen.dart';
import 'settings_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late ConfettiController _confettiController;
  late PageController _pageController;
  final SoundService _soundService = SoundService();
  
  // Local state to track selection before confirmation/animation
  String? _selectedOption;
  
  // Track if we are currently animating the page
  bool _isAnimatingPage = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _soundService.init();
    
    final quiz = context.read<QuizProvider>();
    _pageController = PageController(initialPage: quiz.currentIndex);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quiz = context.watch<QuizProvider>();
    final settings = context.watch<SettingsProvider>();

    // Sync PageController with QuizProvider index if changed externally (e.g. Overview)
    if (_pageController.hasClients && !_isAnimatingPage) {
      final currentPage = _pageController.page?.round() ?? 0;
      if (currentPage != quiz.currentIndex) {
        _pageController.jumpToPage(quiz.currentIndex);
      }
    }

    return Scaffold(
      appBar: _buildAppBar(context, l10n),
      body: Stack(
        children: [
          Column(
            children: [
              // Question PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: quiz.totalQuestions,
                  // Disable user swiping to prevent conflict with vertical scrolling
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    if (!_isAnimatingPage) {
                      quiz.goToQuestion(index);
                      setState(() {
                        _selectedOption = null;
                      });
                    }
                  },
                  itemBuilder: (context, index) {
                    if (index >= quiz.totalQuestions) return const SizedBox.shrink();
                    
                    final question = quiz.questions[index];
                    
                    // Note: Adjacent pages might not have perfect answer state until they become current
                    // due to QuizProvider architecture, but pre-rendering the WebView content
                    // is the priority for performance.
                    final isCurrent = index == quiz.currentIndex;
                    final answer = isCurrent ? quiz.currentUserAnswer : null; 
                    
                    return QuestionCard(
                      question: question,
                      questionIndex: index,
                      totalQuestions: quiz.totalQuestions,
                      selectedOption: isCurrent ? (_selectedOption ?? answer?.selected) : null,
                      showAnswer: (isCurrent && answer != null) || quiz.appMode == AppMode.memorize,
                      isCorrect: isCurrent ? answer?.isCorrect : null,
                      isMarked: quiz.isMarked(question.id),
                      showAnalysis: settings.showAnalysis,
                      imageBasePath: quiz.currentPackageImagePath,
                      onAiExplain: () => _showAiPanel(question),
                      onOptionSelected: (isCurrent && answer != null)
                          ? null
                          : (option) => _handleAnswer(option, index),
                      onMarkToggle: () => quiz.toggleMark(question.id),
                      onReset: (isCurrent && answer != null)
                          ? () {
                              quiz.resetCurrentQuestion();
                              setState(() {
                                _selectedOption = null;
                              });
                            }
                          : null,
                    );
                  },
                ),
              ),

              // Navigation Bar
              _buildNavigationBar(l10n),
            ],
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AppLocalizations l10n) {
    final quiz = context.read<QuizProvider>();
    return AppBar(
      title: Selector<QuizProvider, String>(
        selector: (_, provider) =>
            provider.currentBook?.getDisplayName(l10n.locale.languageCode) ?? '',
        builder: (_, title, __) => Text(title),
      ),
      leading: IconButton(
        key: const Key('quiz_back_button'),
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _handleBack(),
      ),
      actions: [
        // Section selector
        Selector<QuizProvider, bool>(
          selector: (_, provider) => provider.isTestActive,
          builder: (context, isTestActive, _) {
            if (isTestActive) return const SizedBox.shrink();
            return IconButton(
              key: const Key('quiz_section_button'),
              icon: const Icon(Icons.list_alt),
              tooltip: l10n.get('section'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SectionSelector(
                    sections: quiz.sections,
                    currentPartitionId: quiz.currentPartitionId,
                    onSectionSelected: quiz.selectPartition,
                  ),
                );
              },
            );
          },
        ),
        // Overview
        IconButton(
          key: const Key('quiz_overview_button'),
          icon: const Icon(Icons.grid_view),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const OverviewSheet(),
            );
          },
        ),
        // Menu
        PopupMenuButton<String>(
          key: const Key('quiz_menu_button'),
          onSelected: (value) {
            if (value == 'history') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestHistoryList()),
              );
            } else if (value == 'settings') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
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
                children: [
                  const Icon(Icons.history, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.history),
                ],
              ),
            ),
            PopupMenuItem(
              key: const Key('menu_settings'),
              value: 'settings',
              child: Row(
                children: [
                  const Icon(Icons.settings, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n.settings),
                ],
              ),
            ),
            PopupMenuItem(
              key: const Key('menu_reset'),
              value: 'reset',
              child: Row(
                children: [
                  const Icon(Icons.restart_alt, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(l10n.get('reset'),
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        child: Consumer<QuizProvider>(
          builder: (context, quiz, _) => Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('quiz_prev_button'),
                  onPressed:
                      quiz.currentIndex > 0 ? () => _animateToPage(quiz.currentIndex - 1) : null,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l10n.get('previous')),
                ),
              ),
              const SizedBox(width: 16),
              if (quiz.isTestActive) ...[
                ElevatedButton(
                  key: const Key('quiz_finish_button'),
                  onPressed: () => _finishTest(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.get('finishTest')),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('quiz_next_button'),
                  onPressed: quiz.currentIndex < quiz.totalQuestions - 1
                      ? () => _animateToPage(quiz.currentIndex + 1)
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(l10n.get('next')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _animateToPage(int page) {
    if (_pageController.hasClients) {
      _isAnimatingPage = true;
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ).then((_) {
        _isAnimatingPage = false;
        // Ensure the provider is updated after animation if not already
        if (mounted) {
           // Reset transient selection state for the new page
           setState(() {
             _selectedOption = null;
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

    // Haptic feedback
    if (settings.hapticFeedback) {
      HapticFeedback.mediumImpact();
    }

    // Sound effects
    if (settings.soundEffects) {
      if (isCorrect) {
        _soundService.playCorrect();
      } else {
        _soundService.playWrong();
      }
    }

    // Confetti for correct answers
    if (isCorrect && settings.confettiEffect) {
      _confettiController.play();
    }

    // Auto advance
    if (isCorrect && settings.autoAdvance) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          final currentQuiz = context.read<QuizProvider>();
          if (currentQuiz.currentIndex == questionIndex && 
              currentQuiz.currentIndex < currentQuiz.totalQuestions - 1) {
            _animateToPage(currentQuiz.currentIndex + 1);
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
        title: Text(l10n.get('finishTest')),
        content: const Text('确定要结束考试吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishTest();
            },
            child: Text(l10n.get('confirm')),
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
        title: const Text('重置进度'),
        content: const Text('确定要重置当前题库的所有进度吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              quiz.resetAllProgress();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('重置'),
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
          builder: (_) => TestResultScreen(result: result),
        ),
      );
    }
  }
}