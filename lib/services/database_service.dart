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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // Create AI chat sessions table
    await db.execute('''
      CREATE TABLE ai_chat_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        title TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (question_id) REFERENCES questions(id)
      )
    ''');

    // Create AI chat history table
    await db.execute('''
      CREATE TABLE ai_chat_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES ai_chat_sessions(id) ON DELETE CASCADE
      )
    ''');

    // Create user answers table
    await db.execute('''
      CREATE TABLE user_answers (
        question_id INTEGER PRIMARY KEY,
        book_id INTEGER NOT NULL,
        selected TEXT,
        is_correct INTEGER,
        marked_wrong INTEGER DEFAULT 0,
        is_marked INTEGER DEFAULT 0,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (question_id) REFERENCES questions(id),
        FOREIGN KEY (book_id) REFERENCES books(id)
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_questions_book_id ON questions(book_id)');
    await db.execute('CREATE INDEX idx_questions_section_id ON questions(section_id)');
    await db.execute('CREATE INDEX idx_sections_book_id ON sections(book_id)');
    await db.execute('CREATE INDEX idx_chapters_book_id ON chapters(book_id)');
    await db.execute('CREATE INDEX idx_ai_chat_sessions_question_id ON ai_chat_sessions(question_id)');
    await db.execute('CREATE INDEX idx_ai_chat_history_session_id ON ai_chat_history(session_id)');
    await db.execute('CREATE INDEX idx_user_answers_book_id ON user_answers(book_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 1. Create sessions table
      await db.execute('''
        CREATE TABLE ai_chat_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          question_id INTEGER NOT NULL,
          title TEXT,
          created_at INTEGER NOT NULL,
          FOREIGN KEY (question_id) REFERENCES questions(id)
        )
      ''');

      // 2. Rename old history table
      await db.execute('ALTER TABLE ai_chat_history RENAME TO old_ai_chat_history');

      // 3. Create new history table with session_id
      await db.execute('''
        CREATE TABLE ai_chat_history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          session_id INTEGER NOT NULL,
          text TEXT NOT NULL,
          is_user INTEGER NOT NULL,
          timestamp INTEGER NOT NULL,
          FOREIGN KEY (session_id) REFERENCES ai_chat_sessions(id) ON DELETE CASCADE
        )
      ''');

      // 4. Migrate data (Optional: Create a default session for each question that has chat history)
      // This part is tricky in raw SQL without cursors. 
      // Simplified approach: For each unique question_id in old history, create a session and move messages.
      final List<Map<String, dynamic>> distinctQuestions = await db.rawQuery('SELECT DISTINCT question_id FROM old_ai_chat_history');
      
      for (final q in distinctQuestions) {
        final qId = q['question_id'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Create default session
        final sessionId = await db.insert('ai_chat_sessions', {
          'question_id': qId,
          'title': 'Original Chat',
          'created_at': now,
        });

        // Copy messages
        await db.execute('''
          INSERT INTO ai_chat_history (session_id, text, is_user, timestamp)
          SELECT ?, text, is_user, timestamp FROM old_ai_chat_history WHERE question_id = ?
        ''', [sessionId, qId]);
      }

      // 5. Drop old table
      await db.execute('DROP TABLE old_ai_chat_history');
      
      // 6. Create indexes
      await db.execute('CREATE INDEX idx_ai_chat_sessions_question_id ON ai_chat_sessions(question_id)');
      await db.execute('CREATE INDEX idx_ai_chat_history_session_id ON ai_chat_history(session_id)');
    }
  }

  Future<Map<int, UserAnswer>> getUserAnswers(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'user_answers',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    
    final result = <int, UserAnswer>{};
    for (final map in maps) {
      result[map['question_id'] as int] = UserAnswer(
        selected: map['selected'] as String?,
        isCorrect: map['is_correct'] != null ? (map['is_correct'] as int) == 1 : null,
        markedWrong: (map['marked_wrong'] as int) == 1,
      );
    }
    return result;
  }

  Future<Set<int>> getMarkedQuestions(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'user_answers',
      columns: ['question_id'],
      where: 'book_id = ? AND is_marked = 1',
      whereArgs: [bookId],
    );
    return maps.map((m) => m['question_id'] as int).toSet();
  }

  Future<void> saveUserAnswer(int bookId, int questionId, UserAnswer answer) async {
    final db = await database;
    await db.insert(
      'user_answers',
      {
        'question_id': questionId,
        'book_id': bookId,
        'selected': answer.selected,
        'is_correct': answer.isCorrect == null ? null : (answer.isCorrect! ? 1 : 0),
        'marked_wrong': answer.markedWrong ? 1 : 0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> setUserMark(int bookId, int questionId, bool isMarked) async {
    final db = await database;
    // Check if record exists
    final maps = await db.query(
      'user_answers',
      where: 'question_id = ?',
      whereArgs: [questionId],
    );

    if (maps.isEmpty) {
      await db.insert('user_answers', {
        'question_id': questionId,
        'book_id': bookId,
        'is_marked': isMarked ? 1 : 0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await db.update(
        'user_answers',
        {
          'is_marked': isMarked ? 1 : 0,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'question_id = ?',
        whereArgs: [questionId],
      );
    }
  }

  Future<void> deleteUserAnswer(int questionId) async {
    final db = await database;
    // We might want to just set fields to null or 0 instead of deleting
    // to preserve the is_marked status, or vice-versa.
    // For now, let's just update the answer-related fields.
    await db.update(
      'user_answers',
      {
        'selected': null,
        'is_correct': null,
        'marked_wrong': 0,
      },
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  Future<void> clearBookProgress(int bookId) async {
    final db = await database;
    await db.delete(
      'user_answers',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    
    // Also clear chat history for questions in this book?
    // This requires a join delete which SQLite doesn't strictly support in one statement usually.
    // For now, let's leave chat history as it's often valuable to keep even if progress resets.
  }

  Future<List<ChatSession>> getChatSessions(int questionId) async {
    final db = await database;
    final maps = await db.query(
      'ai_chat_sessions',
      where: 'question_id = ?',
      whereArgs: [questionId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => ChatSession.fromMap(map)).toList();
  }

  Future<ChatSession> createChatSession(int questionId, String title) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = await db.insert('ai_chat_sessions', {
      'question_id': questionId,
      'title': title,
      'created_at': now,
    });
    return ChatSession(id: id, questionId: questionId, title: title, createdAt: now);
  }

  Future<void> deleteChatSession(int sessionId) async {
    final db = await database;
    await db.delete(
      'ai_chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
    // Cascade delete handles history messages
  }

  Future<List<ChatMessage>> getChatHistory(int sessionId) async {
    final db = await database;
    final maps = await db.query(
      'ai_chat_history',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => ChatMessage(
      text: map['text'] as String,
      isUser: (map['is_user'] as int) == 1,
    )).toList();
  }

  Future<void> saveChatMessage(int sessionId, ChatMessage message) async {
    final db = await database;
    await db.insert('ai_chat_history', {
      'session_id': sessionId,
      'text': message.text,
      'is_user': message.isUser ? 1 : 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
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
    final questions = maps.map((map) => Question.fromMap(map)).toList();
    await _populateParentContent(questions);
    return questions;
  }

  Future<List<Question>> getQuestionsBySection(String sectionId) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'section_id = ?',
      whereArgs: [sectionId],
      orderBy: 'id',
    );
    final questions = maps.map((map) => Question.fromMap(map)).toList();
    await _populateParentContent(questions);
    return questions;
  }

  Future<void> _populateParentContent(List<Question> questions) async {
    final parentIds = questions.where((q) => q.parentId != null).map((q) => q.parentId!).toSet();
    if (parentIds.isEmpty) return;

    final db = await database;
    final parentMaps = await db.query(
      'questions',
      where: 'id IN (${parentIds.join(',')})',
    );

    final parentContentMap = {
      for (final map in parentMaps) map['id'] as int: map['content'] as String
    };

    for (final q in questions) {
      if (q.parentId != null) {
        q.parentContent = parentContentMap[q.parentId];
      }
    }
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
                int sectionQuestionCount = 0;
                for (var q in questions) {
                  int count = await _insertQuestion(txn, q, bookId, sectionId);
                  sectionQuestionCount += count;
                  totalQuestions += count;
                }
                await txn.update('sections', {'question_count': sectionQuestionCount},
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

  Future<int> _insertQuestion(Transaction txn, Map<String, dynamic> q, int bookId, String sectionId, {int? parentId}) async {
    int insertedCount = 0;
    
    // Ensure choices is a JSON string for storage
    Object? rawChoices = q['choices'];
    String choicesJson;
    if (rawChoices is String) {
      choicesJson = rawChoices;
    } else if (rawChoices != null) {
      choicesJson = jsonEncode(rawChoices);
    } else {
      choicesJson = '[]';
    }

    final id = await txn.insert('questions', {
      'book_id': bookId,
      'section_id': sectionId,
      'parent_id': parentId,
      'content': q['content'] ?? '',
      'choices': choicesJson,
      'answer': q['answer'] ?? '',
      'explanation': q['explanation'],
    });
    
    insertedCount++;

    final subQuestions = q['questions'] as List?;
    if (subQuestions != null) {
      for (var sq in subQuestions) {
        insertedCount += await _insertQuestion(txn, sq, bookId, sectionId, parentId: id);
      }
    }
    
    return insertedCount;
  }

}
