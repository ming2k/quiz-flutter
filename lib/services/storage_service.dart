import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Progress Storage
  Future<void> saveProgress(UserProgress progress) async {
    final p = await prefs;
    await p.setString(
      'progress_${progress.bankFilename}',
      progress.toJsonString(),
    );
  }

  Future<UserProgress?> loadProgress(String bankFilename) async {
    final p = await prefs;
    final jsonStr = p.getString('progress_$bankFilename');
    if (jsonStr == null) return null;
    try {
      return UserProgress.fromJsonString(jsonStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteProgress(String bankFilename) async {
    final p = await prefs;
    await p.remove('progress_$bankFilename');
  }

  // Test History Storage
  Future<void> addHistoryEntry(TestHistoryEntry entry) async {
    final p = await prefs;
    final historyKey = 'history_${entry.bankFilename}';
    final existing = p.getStringList(historyKey) ?? [];
    existing.add(entry.toJsonString());
    await p.setStringList(historyKey, existing);
  }

  Future<List<TestHistoryEntry>> getHistoryEntries(String? bankFilename) async {
    final p = await prefs;

    if (bankFilename != null) {
      final historyKey = 'history_$bankFilename';
      final entries = p.getStringList(historyKey) ?? [];
      return entries
          .map((e) {
            try {
              return TestHistoryEntry.fromJsonString(e);
            } catch (_) {
              return null;
            }
          })
          .whereType<TestHistoryEntry>()
          .toList();
    }

    final allEntries = <TestHistoryEntry>[];
    final keys = p.getKeys().where((k) => k.startsWith('history_'));

    for (final key in keys) {
      final entries = p.getStringList(key) ?? [];
      for (final e in entries) {
        try {
          allEntries.add(TestHistoryEntry.fromJsonString(e));
        } catch (_) {}
      }
    }

    allEntries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return allEntries;
  }

  Future<void> clearAllHistory() async {
    final p = await prefs;
    final keys = p.getKeys().where((k) => k.startsWith('history_')).toList();
    for (final key in keys) {
      await p.remove(key);
    }
  }

  // Settings Storage
  Future<void> saveSetting(String key, dynamic value) async {
    final p = await prefs;
    if (value is String) {
      await p.setString(key, value);
    } else if (value is int) {
      await p.setInt(key, value);
    } else if (value is double) {
      await p.setDouble(key, value);
    } else if (value is bool) {
      await p.setBool(key, value);
    } else if (value is List<String>) {
      await p.setStringList(key, value);
    } else {
      await p.setString(key, jsonEncode(value));
    }
  }

  Future<T?> loadSetting<T>(String key, {T? defaultValue}) async {
    final p = await prefs;
    final value = p.get(key);
    if (value == null) return defaultValue;
    return value as T?;
  }

  Future<void> removeSetting(String key) async {
    final p = await prefs;
    await p.remove(key);
  }

  // Last Opened Bank
  Future<void> saveLastOpenedBank(String bankFilename) async {
    final p = await prefs;
    await p.setString('last_opened_bank', bankFilename);
  }

  Future<String?> loadLastOpenedBank() async {
    final p = await prefs;
    return p.getString('last_opened_bank');
  }
}
