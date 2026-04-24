import 'dart:convert';
import 'dart:math';

import 'database_service.dart';

/// Evaluates smart collection configs to produce lists of question IDs.
///
/// Config format: {"filters": [{"type": "wrong"}|{"type": "marked"}|{"type": "unanswered"}|{"type": "srs_due"}]}
class SmartCollectionEngine {
  final DatabaseService _db;

  SmartCollectionEngine({DatabaseService? db}) : _db = db ?? DatabaseService();

  Future<List<int>> evaluate(int bookId, String? config) async {
    if (config == null || config.isEmpty) return [];

    final parsed = jsonDecode(config) as Map<String, dynamic>;

    // Exam blueprint evaluation
    if (parsed['sections'] != null) {
      return _evaluateBlueprint(bookId, parsed);
    }

    final filters = parsed['filters'] as List<dynamic>? ?? [];

    // Start with all answerable question IDs for this book
    var ids = await _db.getAnswerableQuestionIds(bookId);

    for (final filter in filters) {
      final type = filter['type'] as String?;
      switch (type) {
        case 'wrong':
          ids = await _filterWrong(bookId, ids);
        case 'marked':
          ids = await _filterMarked(bookId, ids);
        case 'unanswered':
          ids = await _filterUnanswered(bookId, ids);
        case 'srs_due':
          ids = await _filterSrsDue(bookId, ids);
        case 'tag':
          final tag = filter['tag'] as String?;
          if (tag != null) {
            ids = await _filterTag(bookId, tag, ids);
          }
      }
    }

    // Ordering
    final order = parsed['order'] as String?;
    if (order == 'random') {
      ids.shuffle();
    } else if (order == 'difficulty_asc') {
      ids = await _orderByDifficulty(bookId, ids, ascending: true);
    } else if (order == 'difficulty_desc') {
      ids = await _orderByDifficulty(bookId, ids, ascending: false);
    }

    final limit = parsed['limit'] as int?;
    if (limit != null && limit > 0 && ids.length > limit) {
      ids = ids.sublist(0, limit);
    }

    return ids;
  }

  Future<List<int>> _evaluateBlueprint(int bookId, Map<String, dynamic> parsed) async {
    final sections = parsed['sections'] as List<dynamic>? ?? [];
    final result = <int>[];
    final random = Random();

    for (final section in sections) {
      final collectionId = section['collectionId'] as int?;
      final count = section['count'] as int? ?? 0;
      if (collectionId == null || count <= 0) continue;

      final questions = await _db.getQuestionsByCollection(collectionId);
      final ids = questions.where((q) => q.isAnswerable).map((q) => q.id).toList();
      ids.shuffle(random);
      result.addAll(ids.take(count));
    }

    if (parsed['shuffle'] == true) {
      result.shuffle(random);
    }

    return result;
  }

  Future<List<int>> _filterWrong(int bookId, List<int> ids) async {
    if (ids.isEmpty) return ids;
    final wrong = await _db.getWrongQuestionIds(bookId);
    return ids.where((id) => wrong.contains(id)).toList();
  }

  Future<List<int>> _filterMarked(int bookId, List<int> ids) async {
    if (ids.isEmpty) return ids;
    final marked = await _db.getMarkedQuestions(bookId);
    return ids.where((id) => marked.contains(id)).toList();
  }

  Future<List<int>> _filterUnanswered(int bookId, List<int> ids) async {
    if (ids.isEmpty) return ids;
    final answered = await _db.getAnsweredQuestionIds(bookId);
    return ids.where((id) => !answered.contains(id)).toList();
  }

  Future<List<int>> _filterSrsDue(int bookId, List<int> ids) async {
    if (ids.isEmpty) return ids;
    final due = await _db.getSrsDueQuestionIds(bookId);
    return ids.where((id) => due.contains(id)).toList();
  }

  Future<List<int>> _filterTag(int bookId, String tag, List<int> ids) async {
    if (ids.isEmpty) return ids;
    final tagged = await _db.getQuestionIdsByTag(bookId, tag);
    return ids.where((id) => tagged.contains(id)).toList();
  }

  Future<List<int>> _orderByDifficulty(
    int bookId,
    List<int> ids, {
    required bool ascending,
  }) async {
    if (ids.isEmpty) return ids;
    final difficulties = await _db.getQuestionDifficulties(bookId);
    ids.sort((a, b) {
      final da = difficulties[a] ?? 2.5;
      final db = difficulties[b] ?? 2.5;
      return ascending ? da.compareTo(db) : db.compareTo(da);
    });
    return ids;
  }
}
