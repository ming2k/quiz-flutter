import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  // Appearance
  ThemeMode _themeMode = ThemeMode.system;
  String _locale = '';

  // Quiz Experience
  AppMode _lastAppMode = AppMode.practice;
  bool _autoAdvance = true;
  bool _showAnalysis = true;
  bool _showNotes = true;
  bool _soundEffects = true;
  bool _hapticFeedback = true;
  bool _confettiEffect = true;

  // Test Settings
  int _testQuestionCount = 50;

  // AI Settings
  String _aiProvider = 'gemini';
  String _aiApiKey = '';
  String _aiBaseUrl = '';
  String _aiModel = 'gemini-1.5-flash';
  String _aiSystemPrompt =
      '你是一位专业的海事教育专家，擅长解释航海相关的考试题目。请用简洁明了的方式解释问题和答案。';
  List<String> _customAiPrompts = [
    '详细解析本题',
    '为什么其他选项是错误的？',
    '这道题考察的知识点是什么？',
  ];

  // Getters
  AppMode get lastAppMode => _lastAppMode;
  ThemeMode get themeMode => _themeMode;
  String get locale => _locale;
  bool get autoAdvance => _autoAdvance;
  bool get showAnalysis => _showAnalysis;
  bool get showNotes => _showNotes;
  bool get soundEffects => _soundEffects;
  bool get hapticFeedback => _hapticFeedback;
  bool get confettiEffect => _confettiEffect;
  int get testQuestionCount => _testQuestionCount;
  String get aiProvider => _aiProvider;
  String get aiApiKey => _aiApiKey;
  String get aiBaseUrl => _aiBaseUrl;
  String get aiModel => _aiModel;
  String get aiSystemPrompt => _aiSystemPrompt;
  List<String> get customAiPrompts => List.unmodifiable(_customAiPrompts);

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _themeMode = ThemeMode.values[
        await _storage.loadSetting<int>('themeMode', defaultValue: 0) ?? 0];
    
    final savedMode = await _storage.loadSetting<String>('lastAppMode');
    if (savedMode != null) {
      try {
        _lastAppMode = AppMode.values.firstWhere((e) => e.name == savedMode);
      } catch (_) {
        _lastAppMode = AppMode.practice;
      }
    }

    _locale =
        await _storage.loadSetting<String>('locale', defaultValue: '') ??
            '';
    _autoAdvance =
        await _storage.loadSetting<bool>('autoAdvance', defaultValue: true) ??
            true;
    _showAnalysis =
        await _storage.loadSetting<bool>('showAnalysis', defaultValue: true) ??
            true;
    _showNotes =
        await _storage.loadSetting<bool>('showNotes', defaultValue: true) ??
            true;
    _soundEffects =
        await _storage.loadSetting<bool>('soundEffects', defaultValue: true) ??
            true;
    _hapticFeedback =
        await _storage.loadSetting<bool>('hapticFeedback', defaultValue: true) ??
            true;
    _confettiEffect =
        await _storage.loadSetting<bool>('confettiEffect', defaultValue: true) ??
            true;
    _testQuestionCount =
        await _storage.loadSetting<int>('testQuestionCount', defaultValue: 50) ??
            50;
    _aiProvider =
        await _storage.loadSetting<String>('aiProvider', defaultValue: 'gemini') ??
            'gemini';
    _aiApiKey =
        await _storage.loadSetting<String>('aiApiKey', defaultValue: '') ?? '';
    _aiBaseUrl =
        await _storage.loadSetting<String>('aiBaseUrl', defaultValue: '') ?? '';
    _aiModel =
        await _storage.loadSetting<String>('aiModel', defaultValue: 'gemini-1.5-flash') ??
            'gemini-1.5-flash';
    _aiSystemPrompt = await _storage.loadSetting<String>('aiSystemPrompt',
            defaultValue:
                '你是一位专业的海事教育专家，擅长解释航海相关的考试题目。请用简洁明了的方式解释问题和答案。') ??
        '你是一位专业的海事教育专家，擅长解释航海相关的考试题目。请用简洁明了的方式解释问题和答案。';
    _customAiPrompts = await _storage.loadSetting<List<String>>(
            'customAiPrompts',
            defaultValue: [
              '详细解析本题',
              '为什么其他选项是错误的？',
              '这道题考察的知识点是什么？',
            ]) ??
        [
          '详细解析本题',
          '为什么其他选项是错误的？',
          '这道题考察的知识点是什么？',
        ];
    notifyListeners();
  }

  // Setters
  Future<void> setLastAppMode(AppMode mode) async {
    _lastAppMode = mode;
    await _storage.saveSetting('lastAppMode', mode.name);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveSetting('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    await _storage.saveSetting('locale', locale);
    notifyListeners();
  }

  Future<void> setAutoAdvance(bool value) async {
    _autoAdvance = value;
    await _storage.saveSetting('autoAdvance', value);
    notifyListeners();
  }

  Future<void> setShowAnalysis(bool value) async {
    _showAnalysis = value;
    await _storage.saveSetting('showAnalysis', value);
    notifyListeners();
  }

  Future<void> setShowNotes(bool value) async {
    _showNotes = value;
    await _storage.saveSetting('showNotes', value);
    notifyListeners();
  }

  Future<void> setSoundEffects(bool value) async {
    _soundEffects = value;
    await _storage.saveSetting('soundEffects', value);
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    await _storage.saveSetting('hapticFeedback', value);
    notifyListeners();
  }

  Future<void> setConfettiEffect(bool value) async {
    _confettiEffect = value;
    await _storage.saveSetting('confettiEffect', value);
    notifyListeners();
  }

  Future<void> setTestQuestionCount(int count) async {
    _testQuestionCount = count;
    await _storage.saveSetting('testQuestionCount', count);
    notifyListeners();
  }

  Future<void> setAiProvider(String provider) async {
    _aiProvider = provider;
    await _storage.saveSetting('aiProvider', provider);
    notifyListeners();
  }

  Future<void> setAiApiKey(String key) async {
    _aiApiKey = key;
    await _storage.saveSetting('aiApiKey', key);
    notifyListeners();
  }

  Future<void> setAiBaseUrl(String url) async {
    _aiBaseUrl = url;
    await _storage.saveSetting('aiBaseUrl', url);
    notifyListeners();
  }

  Future<void> setAiModel(String model) async {
    _aiModel = model;
    await _storage.saveSetting('aiModel', model);
    notifyListeners();
  }

  Future<void> setAiSystemPrompt(String prompt) async {
    _aiSystemPrompt = prompt;
    await _storage.saveSetting('aiSystemPrompt', prompt);
    notifyListeners();
  }

  Future<void> setCustomAiPrompts(List<String> prompts) async {
    _customAiPrompts = prompts;
    await _storage.saveSetting('customAiPrompts', prompts);
    notifyListeners();
  }
}
