// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Quiz';

  @override
  String get appSubtitle => 'General Extensible Quiz Framework';

  @override
  String get selectQuestionBank => 'Select Question Bank';

  @override
  String get selectMode => 'Select Mode';

  @override
  String get startPractice => 'Start Practice';

  @override
  String get exit => 'Exit';

  @override
  String get practiceMode => 'Practice';

  @override
  String get practiceModeDesc => 'Practice questions with instant feedback';

  @override
  String get reviewMode => 'Review';

  @override
  String get reviewModeDesc => 'Review wrong and marked questions';

  @override
  String get memorizeMode => 'Memorize';

  @override
  String get memorizeModeDesc => 'Show answers directly';

  @override
  String get testMode => 'Mock Test';

  @override
  String get testModeDesc => 'Timed test with random questions';

  @override
  String get question => 'Question';

  @override
  String get questionOf => '/';

  @override
  String get correct => 'Correct';

  @override
  String get wrong => 'Wrong';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get mark => 'Mark';

  @override
  String get unmark => 'Unmark';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String get submit => 'Submit';

  @override
  String get reset => 'Reset';

  @override
  String get showAnalysis => 'Show Analysis';

  @override
  String get hideAnalysis => 'Hide Analysis';

  @override
  String get analysis => 'Analysis';

  @override
  String get aiExplain => 'AI Explain';

  @override
  String get overview => 'Overview';

  @override
  String get all => 'All';

  @override
  String get unanswered => 'Unanswered';

  @override
  String get answered => 'Answered';

  @override
  String get marked => 'Marked';

  @override
  String get testQuestionCount => 'Question Count';

  @override
  String get startTest => 'Start Test';

  @override
  String get finishTest => 'Finish';

  @override
  String get testResult => 'Test Result';

  @override
  String get totalQuestions => 'Total';

  @override
  String get correctCount => 'Correct';

  @override
  String get wrongCount => 'Wrong';

  @override
  String get unansweredCount => 'Unanswered';

  @override
  String get timeTaken => 'Time';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get viewHistory => 'View History';

  @override
  String get settings => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get quizExperience => 'Quiz Experience';

  @override
  String get autoAdvance => 'Auto Advance';

  @override
  String get autoAdvanceDesc => 'Auto advance after correct answer';

  @override
  String get showAnalysisOption => 'Show Analysis';

  @override
  String get showAnalysisOptionDesc => 'Show analysis after answering';

  @override
  String get soundEffects => 'Sound Effects';

  @override
  String get soundEffectsDesc => 'Play sounds on answer';

  @override
  String get hapticFeedback => 'Haptic Feedback';

  @override
  String get hapticFeedbackDesc => 'Vibrate on answer';

  @override
  String get confettiEffect => 'Confetti Effect';

  @override
  String get confettiEffectDesc => 'Show confetti on correct answer';

  @override
  String get aiSettings => 'AI Settings';

  @override
  String get aiProvider => 'AI Provider';

  @override
  String get aiApiKey => 'API Key';

  @override
  String get aiModel => 'Model';

  @override
  String get aiChatScrollToBottom => 'Scroll to Bottom on Send';

  @override
  String get aiChatScrollToBottomDesc =>
      'Automatically scroll to latest content after sending a message';

  @override
  String get allSections => 'All Sections';

  @override
  String get section => 'Section';

  @override
  String get questions => 'questions';

  @override
  String get history => 'History';

  @override
  String get noHistory => 'No history yet';

  @override
  String get clearHistory => 'Clear History';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String get clear => 'Clear';

  @override
  String get importPackage => 'Import Package';

  @override
  String get importFailed => 'Import Failed';

  @override
  String importSuccess(String packageName) {
    return 'Successfully imported \"$packageName\"';
  }

  @override
  String confirmDeleteBook(String bookName) {
    return 'Are you sure you want to delete \"$bookName\"?';
  }

  @override
  String get aiKeyNotSet => 'Not set';

  @override
  String get aiBaseUrl => 'AI Base URL';

  @override
  String get aiBaseUrlDefault => 'Default';

  @override
  String get aiBaseUrlHint => 'https://generativelanguage.googleapis.com';

  @override
  String get aiBaseUrlHelper => 'Leave empty for default';

  @override
  String get enterApiKey => 'Enter your API key';

  @override
  String get textSelectionMenu => 'Text Selection Menu';

  @override
  String get menuItemOrder => 'Menu Item Order';

  @override
  String get reorderMenuItems => 'Reorder Menu Items';

  @override
  String get confirmExitTest => 'Are you sure you want to finish the test?';

  @override
  String get resetProgress => 'Reset Progress';

  @override
  String get confirmResetProgress =>
      'Are you sure you want to reset all progress? This cannot be undone.';

  @override
  String get doReset => 'Reset';

  @override
  String get aiChatTitle => 'AI Analysis';

  @override
  String get chatHistory => 'Chat History';

  @override
  String get newChat => 'New Chat';

  @override
  String get chatInputHint => 'Ask a question...';

  @override
  String get startConversation => 'Start a conversation with AI';

  @override
  String get noChatHistory => 'No records';

  @override
  String get deleteChat => 'Delete conversation?';

  @override
  String confirmDeleteChat(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get aiSuggestion1 => 'Explain this question in detail';

  @override
  String get aiSuggestion2 => 'Why are the other options wrong?';

  @override
  String get aiSuggestion3 => 'What knowledge does this question test?';

  @override
  String get aiSuggestion4 => 'Explain in simpler terms';

  @override
  String get aiSuggestion5 => 'Translate to Chinese';

  @override
  String get testHistory => 'Test History';

  @override
  String get noTestHistory => 'No test history';

  @override
  String get clearHistoryConfirm =>
      'Are you sure you want to clear all test history?';

  @override
  String get totalShort => 'Total';

  @override
  String get correctShort => 'Correct';

  @override
  String get wrongShort => 'Wrong';
}
