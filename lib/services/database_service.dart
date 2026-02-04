import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'quiz.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create books table
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        filename TEXT NOT NULL,
        subject_name_zh TEXT,
        subject_name_en TEXT,
        total_questions INTEGER DEFAULT 0,
        total_chapters INTEGER DEFAULT 0,
        total_sections INTEGER DEFAULT 0,
        sort_order INTEGER DEFAULT 0
      )
    ''');

    // Create chapters table
    await db.execute('''
      CREATE TABLE chapters (
        id TEXT PRIMARY KEY,
        book_id INTEGER NOT NULL,
        title TEXT,
        question_count INTEGER DEFAULT 0,
        FOREIGN KEY (book_id) REFERENCES books(id)
      )
    ''');

    // Create sections table
    await db.execute('''
      CREATE TABLE sections (
        id TEXT PRIMARY KEY,
        book_id INTEGER NOT NULL,
        chapter_id TEXT,
        title TEXT,
        question_count INTEGER DEFAULT 0,
        FOREIGN KEY (book_id) REFERENCES books(id),
        FOREIGN KEY (chapter_id) REFERENCES chapters(id)
      )
    ''');

    // Create questions table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        section_id TEXT,
        parent_id INTEGER,
        content TEXT,
        choices TEXT,
        answer TEXT,
        explanation TEXT,
        FOREIGN KEY (book_id) REFERENCES books(id),
        FOREIGN KEY (section_id) REFERENCES sections(id)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_questions_book_id ON questions(book_id)');
    await db.execute('CREATE INDEX idx_questions_section_id ON questions(section_id)');
    await db.execute('CREATE INDEX idx_sections_book_id ON sections(book_id)');
    await db.execute('CREATE INDEX idx_chapters_book_id ON chapters(book_id)');
  }

  Future<List<Book>> getBooks() async {
    final db = await database;
    try {
      final maps = await db.query('books', orderBy: 'sort_order ASC, id ASC');
      return maps.map((map) => Book.fromMap(map)).toList();
    } catch (e) {
      final maps = await db.query('books', orderBy: 'id');
      return maps.map((map) => Book.fromMap(map)).toList();
    }
  }

  Future<List<Section>> getSections(int bookId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT
        s.id,
        s.book_id,
        s.chapter_id,
        s.title,
        s.question_count,
        c.title as chapter_title
      FROM sections s
      LEFT JOIN chapters c ON s.chapter_id = c.id
      WHERE s.book_id = ?
      ORDER BY s.id
    ''', [bookId]);
    return maps.map((map) => Section.fromMap(map)).toList();
  }

  Future<List<Chapter>> getChapters(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'chapters',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'id',
    );
    return maps.map((map) => Chapter.fromMap(map)).toList();
  }

  Future<List<Question>> getQuestions(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'id',
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<List<Question>> getQuestionsBySection(String sectionId) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'section_id = ?',
      whereArgs: [sectionId],
      orderBy: 'id',
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<Question?> getQuestion(int questionId) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'id = ?',
      whereArgs: [questionId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Question.fromMap(maps.first);
  }

  Future<int> getQuestionCount(int bookId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM questions WHERE book_id = ?',
      [bookId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateBookOrder(List<int> bookIds) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < bookIds.length; i++) {
      batch.update('books', {'sort_order': i}, where: 'id = ?', whereArgs: [bookIds[i]]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteBook(int bookId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('questions', where: 'book_id = ?', whereArgs: [bookId]);
      await txn.delete('sections', where: 'book_id = ?', whereArgs: [bookId]);
      await txn.delete('chapters', where: 'book_id = ?', whereArgs: [bookId]);
      await txn.delete('books', where: 'id = ?', whereArgs: [bookId]);
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  Future<void> importData(Map<String, dynamic> data, String packageId) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Insert Book
      final bookId = await txn.insert('books', {
        'filename': packageId,
        'subject_name_zh': data['subject_name_zh'] ?? 'Imported',
        'subject_name_en': data['subject_name_en'] ?? packageId,
        'total_questions': 0,
        'total_chapters': 0,
        'total_sections': 0,
      });

      int totalQuestions = 0;
      int totalChapters = 0;
      int totalSections = 0;

      final chapters = data['chapters'] as List?;
      if (chapters != null) {
        for (var c in chapters) {
          totalChapters++;
          final chapterId = '${packageId}_c_$totalChapters';
          await txn.insert('chapters', {
            'id': chapterId,
            'book_id': bookId,
            'title': c['title'] ?? 'Chapter $totalChapters',
            'question_count': 0,
          });

          final sections = c['sections'] as List?;
          if (sections != null) {
            for (var s in sections) {
              totalSections++;
              final sectionId = '${chapterId}_s_$totalSections';
              await txn.insert('sections', {
                'id': sectionId,
                'book_id': bookId,
                'chapter_id': chapterId,
                'title': s['title'] ?? 'Section $totalSections',
                'question_count': 0,
              });

              final questions = s['questions'] as List?;
              if (questions != null) {
                for (var q in questions) {
                  totalQuestions++;
                  String choices = q['choices'] is String
                      ? q['choices']
                      : jsonEncode(q['choices']);

                  await txn.insert('questions', {
                    'book_id': bookId,
                    'section_id': sectionId,
                    'content': q['content'] ?? '',
                    'choices': choices,
                    'answer': q['answer'] ?? '',
                    'explanation': q['explanation'],
                  });
                }
                await txn.update('sections', {'question_count': questions.length},
                    where: 'id = ?', whereArgs: [sectionId]);
              }
            }
          }
        }
      }

      await txn.update('books', {
        'total_questions': totalQuestions,
        'total_chapters': totalChapters,
        'total_sections': totalSections,
      }, where: 'id = ?', whereArgs: [bookId]);
    });
  }

}
