import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'General Extensible Quiz Framework'**
  String get appSubtitle;

  /// No description provided for @selectQuestionBank.
  ///
  /// In en, this message translates to:
  /// **'Select Question Bank'**
  String get selectQuestionBank;

  /// No description provided for @selectMode.
  ///
  /// In en, this message translates to:
  /// **'Select Mode'**
  String get selectMode;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start Practice'**
  String get startPractice;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @practiceMode.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceMode;

  /// No description provided for @practiceModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice questions with instant feedback'**
  String get practiceModeDesc;

  /// No description provided for @reviewMode.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewMode;

  /// No description provided for @reviewModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Review wrong and marked questions'**
  String get reviewModeDesc;

  /// No description provided for @memorizeMode.
  ///
  /// In en, this message translates to:
  /// **'Memorize'**
  String get memorizeMode;

  /// No description provided for @memorizeModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Show answers directly'**
  String get memorizeModeDesc;

  /// No description provided for @testMode.
  ///
  /// In en, this message translates to:
  /// **'Mock Test'**
  String get testMode;

  /// No description provided for @testModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Timed test with random questions'**
  String get testModeDesc;

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @questionOf.
  ///
  /// In en, this message translates to:
  /// **'/'**
  String get questionOf;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get wrong;

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get accuracy;

  /// No description provided for @mark.
  ///
  /// In en, this message translates to:
  /// **'Mark'**
  String get mark;

  /// No description provided for @unmark.
  ///
  /// In en, this message translates to:
  /// **'Unmark'**
  String get unmark;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @showAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Show Analysis'**
  String get showAnalysis;

  /// No description provided for @hideAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Hide Analysis'**
  String get hideAnalysis;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @aiExplain.
  ///
  /// In en, this message translates to:
  /// **'AI Explain'**
  String get aiExplain;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @unanswered.
  ///
  /// In en, this message translates to:
  /// **'Unanswered'**
  String get unanswered;

  /// No description provided for @answered.
  ///
  /// In en, this message translates to:
  /// **'Answered'**
  String get answered;

  /// No description provided for @marked.
  ///
  /// In en, this message translates to:
  /// **'Marked'**
  String get marked;

  /// No description provided for @testQuestionCount.
  ///
  /// In en, this message translates to:
  /// **'Question Count'**
  String get testQuestionCount;

  /// No description provided for @startTest.
  ///
  /// In en, this message translates to:
  /// **'Start Test'**
  String get startTest;

  /// No description provided for @finishTest.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishTest;

  /// No description provided for @testResult.
  ///
  /// In en, this message translates to:
  /// **'Test Result'**
  String get testResult;

  /// No description provided for @totalQuestions.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalQuestions;

  /// No description provided for @correctCount.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correctCount;

  /// No description provided for @wrongCount.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get wrongCount;

  /// No description provided for @unansweredCount.
  ///
  /// In en, this message translates to:
  /// **'Unanswered'**
  String get unansweredCount;

  /// No description provided for @timeTaken.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeTaken;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @quizExperience.
  ///
  /// In en, this message translates to:
  /// **'Quiz Experience'**
  String get quizExperience;

  /// No description provided for @autoAdvance.
  ///
  /// In en, this message translates to:
  /// **'Auto Advance'**
  String get autoAdvance;

  /// No description provided for @autoAdvanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto advance after correct answer'**
  String get autoAdvanceDesc;

  /// No description provided for @showAnalysisOption.
  ///
  /// In en, this message translates to:
  /// **'Show Analysis'**
  String get showAnalysisOption;

  /// No description provided for @showAnalysisOptionDesc.
  ///
  /// In en, this message translates to:
  /// **'Show analysis after answering'**
  String get showAnalysisOptionDesc;

  /// No description provided for @soundEffects.
  ///
  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffects;

  /// No description provided for @soundEffectsDesc.
  ///
  /// In en, this message translates to:
  /// **'Play sounds on answer'**
  String get soundEffectsDesc;

  /// No description provided for @hapticFeedback.
  ///
  /// In en, this message translates to:
  /// **'Haptic Feedback'**
  String get hapticFeedback;

  /// No description provided for @hapticFeedbackDesc.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on answer'**
  String get hapticFeedbackDesc;

  /// No description provided for @confettiEffect.
  ///
  /// In en, this message translates to:
  /// **'Confetti Effect'**
  String get confettiEffect;

  /// No description provided for @confettiEffectDesc.
  ///
  /// In en, this message translates to:
  /// **'Show confetti on correct answer'**
  String get confettiEffectDesc;

  /// No description provided for @aiSettings.
  ///
  /// In en, this message translates to:
  /// **'AI Settings'**
  String get aiSettings;

  /// No description provided for @aiProvider.
  ///
  /// In en, this message translates to:
  /// **'AI Provider'**
  String get aiProvider;

  /// No description provided for @aiApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get aiApiKey;

  /// No description provided for @aiModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get aiModel;

  /// No description provided for @aiChatScrollToBottom.
  ///
  /// In en, this message translates to:
  /// **'Scroll to Bottom on Send'**
  String get aiChatScrollToBottom;

  /// No description provided for @aiChatScrollToBottomDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically scroll to latest content after sending a message'**
  String get aiChatScrollToBottomDesc;

  /// No description provided for @allSections.
  ///
  /// In en, this message translates to:
  /// **'All Sections'**
  String get allSections;

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'questions'**
  String get questions;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noHistory.
  ///
  /// In en, this message translates to:
  /// **'No history yet'**
  String get noHistory;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get clearHistory;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @importPackage.
  ///
  /// In en, this message translates to:
  /// **'Import Package'**
  String get importPackage;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import Failed'**
  String get importFailed;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported \"{packageName}\"'**
  String importSuccess(String packageName);

  /// No description provided for @confirmDeleteBook.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{bookName}\"?'**
  String confirmDeleteBook(String bookName);

  /// No description provided for @aiKeyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get aiKeyNotSet;

  /// No description provided for @aiBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'AI Base URL'**
  String get aiBaseUrl;

  /// No description provided for @aiBaseUrlDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get aiBaseUrlDefault;

  /// No description provided for @aiBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://generativelanguage.googleapis.com'**
  String get aiBaseUrlHint;

  /// No description provided for @aiBaseUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for default'**
  String get aiBaseUrlHelper;

  /// No description provided for @enterApiKey.
  ///
  /// In en, this message translates to:
  /// **'Enter your API key'**
  String get enterApiKey;

  /// No description provided for @textSelectionMenu.
  ///
  /// In en, this message translates to:
  /// **'Text Selection Menu'**
  String get textSelectionMenu;

  /// No description provided for @menuItemOrder.
  ///
  /// In en, this message translates to:
  /// **'Menu Item Order'**
  String get menuItemOrder;

  /// No description provided for @reorderMenuItems.
  ///
  /// In en, this message translates to:
  /// **'Reorder Menu Items'**
  String get reorderMenuItems;

  /// No description provided for @confirmExitTest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finish the test?'**
  String get confirmExitTest;

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress'**
  String get resetProgress;

  /// No description provided for @confirmResetProgress.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all progress? This cannot be undone.'**
  String get confirmResetProgress;

  /// No description provided for @doReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get doReset;

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get aiChatTitle;

  /// No description provided for @chatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get chatHistory;

  /// No description provided for @newChat.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChat;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask a question...'**
  String get chatInputHint;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with AI'**
  String get startConversation;

  /// No description provided for @noChatHistory.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noChatHistory;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation?'**
  String get deleteChat;

  /// No description provided for @confirmDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String confirmDeleteChat(String title);

  /// No description provided for @aiSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Explain this question in detail'**
  String get aiSuggestion1;

  /// No description provided for @aiSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Why are the other options wrong?'**
  String get aiSuggestion2;

  /// No description provided for @aiSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'What knowledge does this question test?'**
  String get aiSuggestion3;

  /// No description provided for @aiSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'Explain in simpler terms'**
  String get aiSuggestion4;

  /// No description provided for @aiSuggestion5.
  ///
  /// In en, this message translates to:
  /// **'Translate to Chinese'**
  String get aiSuggestion5;

  /// No description provided for @testHistory.
  ///
  /// In en, this message translates to:
  /// **'Test History'**
  String get testHistory;

  /// No description provided for @noTestHistory.
  ///
  /// In en, this message translates to:
  /// **'No test history'**
  String get noTestHistory;

  /// No description provided for @clearHistoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear all test history?'**
  String get clearHistoryConfirm;

  /// No description provided for @totalShort.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalShort;

  /// No description provided for @correctShort.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correctShort;

  /// No description provided for @wrongShort.
  ///
  /// In en, this message translates to:
  /// **'Wrong'**
  String get wrongShort;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
