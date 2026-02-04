import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final SharedPreferencesAsync _asyncPrefs = SharedPreferencesAsync();

  // Progress Storage
  Future<void> saveProgress(UserProgress progress) async {
    await _asyncPrefs.setString(
      'progress_${progress.bankFilename}',
      progress.toJsonString(),
    );
  }

  Future<UserProgress?> loadProgress(String bankFilename) async {
    final jsonStr = await _asyncPrefs.getString('progress_$bankFilename');
    if (jsonStr == null) return null;
    try {
      return UserProgress.fromJsonString(jsonStr);
    } catch (_) {
      return null;
    }
  }

  // Test History Storage
  Future<void> addHistoryEntry(TestHistoryEntry entry) async {
    final historyKey = 'history_${entry.bankFilename}';
    final existing = await _asyncPrefs.getStringList(historyKey) ?? [];
    existing.add(entry.toJsonString());
    await _asyncPrefs.setStringList(historyKey, existing);
  }

  Future<List<TestHistoryEntry>> getHistoryEntries(String? bankFilename) async {
    if (bankFilename != null) {
      final historyKey = 'history_$bankFilename';
      final entries = await _asyncPrefs.getStringList(historyKey) ?? [];
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
    final keys = (await _asyncPrefs.getKeys()).where((k) => k.startsWith('history_'));

    for (final key in keys) {
      final entries = await _asyncPrefs.getStringList(key) ?? [];
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
    final keys = (await _asyncPrefs.getKeys()).where((k) => k.startsWith('history_')).toList();
    for (final key in keys) {
      await _asyncPrefs.remove(key);
    }
  }

  // Settings Storage
  Future<void> saveSetting(String key, dynamic value) async {
    if (value is String) {
      await _asyncPrefs.setString(key, value);
    } else if (value is int) {
      await _asyncPrefs.setInt(key, value);
    } else if (value is double) {
      await _asyncPrefs.setDouble(key, value);
    } else if (value is bool) {
      await _asyncPrefs.setBool(key, value);
    } else if (value is List<String>) {
      await _asyncPrefs.setStringList(key, value);
    } else {
      await _asyncPrefs.setString(key, jsonEncode(value));
    }
  }

  Future<T?> loadSetting<T>(String key, {T? defaultValue}) async {
    // SharedPreferencesAsync requires explicit type getters
    Object? value;
    if (T == String) {
      value = await _asyncPrefs.getString(key);
    } else if (T == int) {
      value = await _asyncPrefs.getInt(key);
    } else if (T == double) {
      value = await _asyncPrefs.getDouble(key);
    } else if (T == bool) {
      value = await _asyncPrefs.getBool(key);
    } else if (T == List<String>) {
      value = await _asyncPrefs.getStringList(key);
    } else {
      // Fallback for complex types stored as JSON strings
      final jsonStr = await _asyncPrefs.getString(key);
      if (jsonStr != null && T != dynamic) {
        try {
          return jsonDecode(jsonStr) as T?;
        } catch (_) {
          return defaultValue;
        }
      }
      value = jsonStr;
    }

    if (value == null) return defaultValue;
    return value as T?;
  }

  // Last Opened Bank
  Future<void> saveLastOpenedBank(String bankFilename) async {
    await _asyncPrefs.setString('last_opened_bank', bankFilename);
  }

  Future<String?> loadLastOpenedBank() async {
    return await _asyncPrefs.getString('last_opened_bank');
  }
}