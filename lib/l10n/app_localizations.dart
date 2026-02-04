import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'zh': {
      // App
      'appTitle': 'Quiz',
      'appSubtitle': '通用扩展题库练习系统',

      // Home
      'selectQuestionBank': '选择题库',
      'selectMode': '选择模式',
      'startPractice': '开始练习',
      'exit': '退出',

      // Modes
      'practiceMode': '练习模式',
      'practiceModeDesc': '逐题练习，即时反馈',
      'reviewMode': '复习模式',
      'reviewModeDesc': '复习错题和标记题目',
      'memorizeMode': '背题模式',
      'memorizeModeDesc': '直接显示答案和解析',
      'testMode': '模拟考试',
      'testModeDesc': '随机抽题，计时考试',

      // Quiz
      'question': '题目',
      'of': '/',
      'correct': '正确',
      'wrong': '错误',
      'accuracy': '正确率',
      'mark': '标记',
      'unmark': '取消标记',
      'previous': '上一题',
      'next': '下一题',
      'submit': '提交',
      'reset': '重置',
      'showAnalysis': '显示解析',
      'hideAnalysis': '隐藏解析',
      'analysis': '解析',
      'aiExplain': 'AI 解析',

      // Overview
      'overview': '题目概览',
      'unanswered': '未答',
      'answered': '已答',
      'marked': '已标记',

      // Test
      'testQuestionCount': '考试题数',
      'startTest': '开始考试',
      'finishTest': '交卷',
      'testResult': '考试结果',
      'totalQuestions': '总题数',
      'correctCount': '答对',
      'wrongCount': '答错',
      'unansweredCount': '未答',
      'timeTaken': '用时',
      'backToHome': '返回首页',
      'viewHistory': '查看历史',

      // Settings
      'settings': '设置',
      'appearance': '外观',
      'theme': '主题',
      'themeSystem': '跟随系统',
      'themeLight': '浅色',
      'themeDark': '深色',
      'language': '语言',
      'quizExperience': '练习体验',
      'autoAdvance': '自动下一题',
      'autoAdvanceDesc': '答对后自动跳转下一题',
      'showAnalysisOption': '显示解析',
      'showAnalysisOptionDesc': '答题后显示解析',
      'soundEffects': '音效',
      'soundEffectsDesc': '答题时播放音效',
      'hapticFeedback': '振动反馈',
      'hapticFeedbackDesc': '答题时振动提示',
      'confettiEffect': '彩带效果',
      'confettiEffectDesc': '答对时显示彩带动画',
      'aiSettings': 'AI 设置',
      'aiProvider': 'AI 服务商',
      'aiApiKey': 'API 密钥',
      'aiModel': '模型',

      // Sections
      'allSections': '全部章节',
      'section': '章节',
      'questions': '题',

      // History
      'history': '历史记录',
      'noHistory': '暂无历史记录',
      'clearHistory': '清除历史',

      // Common
      'loading': '加载中...',
      'error': '错误',
      'retry': '重试',
      'cancel': '取消',
      'confirm': '确认',
      'save': '保存',
      'delete': '删除',
    },
    'en': {
      // App
      'appTitle': 'Quiz',
      'appSubtitle': 'General Extensible Quiz Framework',

      // Home
      'selectQuestionBank': 'Select Question Bank',
      'selectMode': 'Select Mode',
      'startPractice': 'Start Practice',
      'exit': 'Exit',

      // Modes
      'practiceMode': 'Practice',
      'practiceModeDesc': 'Practice questions with instant feedback',
      'reviewMode': 'Review',
      'reviewModeDesc': 'Review wrong and marked questions',
      'memorizeMode': 'Memorize',
      'memorizeModeDesc': 'Show answers directly',
      'testMode': 'Mock Test',
      'testModeDesc': 'Timed test with random questions',

      // Quiz
      'question': 'Question',
      'of': '/',
      'correct': 'Correct',
      'wrong': 'Wrong',
      'accuracy': 'Accuracy',
      'mark': 'Mark',
      'unmark': 'Unmark',
      'previous': 'Previous',
      'next': 'Next',
      'submit': 'Submit',
      'reset': 'Reset',
      'showAnalysis': 'Show Analysis',
      'hideAnalysis': 'Hide Analysis',
      'analysis': 'Analysis',
      'aiExplain': 'AI Explain',

      // Overview
      'overview': 'Overview',
      'unanswered': 'Unanswered',
      'answered': 'Answered',
      'marked': 'Marked',

      // Test
      'testQuestionCount': 'Question Count',
      'startTest': 'Start Test',
      'finishTest': 'Finish',
      'testResult': 'Test Result',
      'totalQuestions': 'Total',
      'correctCount': 'Correct',
      'wrongCount': 'Wrong',
      'unansweredCount': 'Unanswered',
      'timeTaken': 'Time',
      'backToHome': 'Back to Home',
      'viewHistory': 'View History',

      // Settings
      'settings': 'Settings',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'themeSystem': 'System',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'language': 'Language',
      'quizExperience': 'Quiz Experience',
      'autoAdvance': 'Auto Advance',
      'autoAdvanceDesc': 'Auto advance after correct answer',
      'showAnalysisOption': 'Show Analysis',
      'showAnalysisOptionDesc': 'Show analysis after answering',
      'soundEffects': 'Sound Effects',
      'soundEffectsDesc': 'Play sounds on answer',
      'hapticFeedback': 'Haptic Feedback',
      'hapticFeedbackDesc': 'Vibrate on answer',
      'confettiEffect': 'Confetti Effect',
      'confettiEffectDesc': 'Show confetti on correct answer',
      'aiSettings': 'AI Settings',
      'aiProvider': 'AI Provider',
      'aiApiKey': 'API Key',
      'aiModel': 'Model',

      // Sections
      'allSections': 'All Sections',
      'section': 'Section',
      'questions': 'questions',

      // History
      'history': 'History',
      'noHistory': 'No history yet',
      'clearHistory': 'Clear History',

      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
    },
  };

  String get(String key) {
    final langCode = locale.languageCode;
    return _localizedValues[langCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }

  // Convenience getters for common strings
  String get appTitle => get('appTitle');
  String get appSubtitle => get('appSubtitle');
  String get selectQuestionBank => get('selectQuestionBank');
  String get selectMode => get('selectMode');
  String get startPractice => get('startPractice');
  String get practiceMode => get('practiceMode');
  String get reviewMode => get('reviewMode');
  String get memorizeMode => get('memorizeMode');
  String get testMode => get('testMode');
  String get settings => get('settings');
  String get overview => get('overview');
  String get history => get('history');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
