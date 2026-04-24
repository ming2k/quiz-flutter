import 'dart:io' show Platform;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static bool _databaseFactoryConfigured = false;
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    _configureDatabaseFactory();

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'quiz.db');

    return await openDatabase(
      path,
      version: 6,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  void _configureDatabaseFactory() {
    if (_databaseFactoryConfigured || kIsWeb) {
      return;
    }

    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _databaseFactoryConfigured = true;
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
        question_type TEXT DEFAULT 'multiple_choice',
        tags TEXT,
        difficulty REAL DEFAULT 2.5,
        note TEXT,
        front_template TEXT,
        back_template TEXT,
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
    await db.execute(
      'CREATE INDEX idx_questions_book_id ON questions(book_id)',
    );
    await db.execute(
      'CREATE INDEX idx_questions_section_id ON questions(section_id)',
    );
    await db.execute('CREATE INDEX idx_sections_book_id ON sections(book_id)');
    await db.execute('CREATE INDEX idx_chapters_book_id ON chapters(book_id)');
    await db.execute(
      'CREATE INDEX idx_ai_chat_sessions_question_id ON ai_chat_sessions(question_id)',
    );
    await db.execute(
      'CREATE INDEX idx_ai_chat_history_session_id ON ai_chat_history(session_id)',
    );
    await db.execute(
      'CREATE INDEX idx_user_answers_book_id ON user_answers(book_id)',
    );

    // Create SRS reviews table
    await db.execute('''
      CREATE TABLE srs_reviews (
        question_id INTEGER PRIMARY KEY,
        book_id INTEGER NOT NULL,
        interval_days INTEGER DEFAULT 0,
        ease_factor REAL DEFAULT 2.5,
        repetitions INTEGER DEFAULT 0,
        lapses INTEGER DEFAULT 0,
        due_date INTEGER,
        last_reviewed INTEGER,
        review_state INTEGER DEFAULT 0,
        FOREIGN KEY (question_id) REFERENCES questions(id),
        FOREIGN KEY (book_id) REFERENCES books(id)
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_srs_reviews_book_id ON srs_reviews(book_id)',
    );
    await db.execute(
      'CREATE INDEX idx_srs_reviews_due_date ON srs_reviews(due_date)',
    );

    // Create collections table
    await db.execute('''
      CREATE TABLE collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        config TEXT,
        sort_order INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER,
        parent_id INTEGER,
        FOREIGN KEY (book_id) REFERENCES books(id),
        FOREIGN KEY (parent_id) REFERENCES collections(id)
      )
    ''');

    // Create collection_items table
    await db.execute('''
      CREATE TABLE collection_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        position INTEGER DEFAULT 0,
        role TEXT DEFAULT 'item',
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
        FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_collections_book_id ON collections(book_id)',
    );
    await db.execute(
      'CREATE INDEX idx_collections_type ON collections(type)',
    );
    await db.execute(
      'CREATE INDEX idx_collection_items_collection_id ON collection_items(collection_id)',
    );
    await db.execute(
      'CREATE INDEX idx_collection_items_question_id ON collection_items(question_id)',
    );
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
      await db.execute(
        'ALTER TABLE ai_chat_history RENAME TO old_ai_chat_history',
      );

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
      final List<Map<String, dynamic>> distinctQuestions = await db.rawQuery(
        'SELECT DISTINCT question_id FROM old_ai_chat_history',
      );

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
        await db.execute(
          '''
          INSERT INTO ai_chat_history (session_id, text, is_user, timestamp)
          SELECT ?, text, is_user, timestamp FROM old_ai_chat_history WHERE question_id = ?
        ''',
          [sessionId, qId],
        );
      }

      // 5. Drop old table
      await db.execute('DROP TABLE old_ai_chat_history');

      // 6. Create indexes
      await db.execute(
        'CREATE INDEX idx_ai_chat_sessions_question_id ON ai_chat_sessions(question_id)',
      );
      await db.execute(
        'CREATE INDEX idx_ai_chat_history_session_id ON ai_chat_history(session_id)',
      );
    }

    if (oldVersion < 3) {
      // Create SRS reviews table
      await db.execute('''
        CREATE TABLE srs_reviews (
          question_id INTEGER PRIMARY KEY,
          book_id INTEGER NOT NULL,
          interval_days INTEGER DEFAULT 0,
          ease_factor REAL DEFAULT 2.5,
          repetitions INTEGER DEFAULT 0,
          lapses INTEGER DEFAULT 0,
          due_date INTEGER,
          last_reviewed INTEGER,
          review_state INTEGER DEFAULT 0,
          FOREIGN KEY (question_id) REFERENCES questions(id),
          FOREIGN KEY (book_id) REFERENCES books(id)
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_srs_reviews_book_id ON srs_reviews(book_id)',
      );
      await db.execute(
        'CREATE INDEX idx_srs_reviews_due_date ON srs_reviews(due_date)',
      );
    }

    if (oldVersion < 4) {
      // Add v2 protocol fields to questions table
      await db.execute('ALTER TABLE questions ADD COLUMN tags TEXT');
      await db.execute(
        'ALTER TABLE questions ADD COLUMN difficulty REAL DEFAULT 2.5',
      );
      await db.execute('ALTER TABLE questions ADD COLUMN note TEXT');
    }

    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE questions ADD COLUMN question_type TEXT DEFAULT 'multiple_choice'",
      );
      await db.execute('ALTER TABLE questions ADD COLUMN front_template TEXT');
      await db.execute('ALTER TABLE questions ADD COLUMN back_template TEXT');
    }

    if (oldVersion < 6) {
      // Create collections table
      await db.execute('''
        CREATE TABLE collections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          book_id INTEGER NOT NULL,
          type TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          config TEXT,
          sort_order INTEGER DEFAULT 0,
          created_at INTEGER NOT NULL,
          updated_at INTEGER,
          parent_id INTEGER,
          FOREIGN KEY (book_id) REFERENCES books(id),
          FOREIGN KEY (parent_id) REFERENCES collections(id)
        )
      ''');

      // Create collection_items table
      await db.execute('''
        CREATE TABLE collection_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          collection_id INTEGER NOT NULL,
          question_id INTEGER NOT NULL,
          position INTEGER DEFAULT 0,
          role TEXT DEFAULT 'item',
          FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE,
          FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
        )
      ''');

      await db.execute(
        'CREATE INDEX idx_collections_book_id ON collections(book_id)',
      );
      await db.execute(
        'CREATE INDEX idx_collections_type ON collections(type)',
      );
      await db.execute(
        'CREATE INDEX idx_collection_items_collection_id ON collection_items(collection_id)',
      );
      await db.execute(
        'CREATE INDEX idx_collection_items_question_id ON collection_items(question_id)',
      );

      // Migrate existing chapters and sections to implicit source collections
      final now = DateTime.now().millisecondsSinceEpoch;

      // Migrate chapters
      final chapters = await db.query('chapters');
      final chapterIdMap = <String, int>{};
      for (final ch in chapters) {
        final bookId = ch['book_id'] as int;
        final chapterIdStr = ch['id'] as String;
        final title = ch['title'] as String? ?? '';

        final collectionId = await db.insert('collections', {
          'book_id': bookId,
          'type': 'source',
          'name': title,
          'description': null,
          'config': null,
          'sort_order': 0,
          'created_at': now,
          'updated_at': now,
          'parent_id': null,
        });
        chapterIdMap[chapterIdStr] = collectionId;
      }

      // Migrate sections
      final sections = await db.query('sections');
      final sectionIdMap = <String, int>{};
      for (final sec in sections) {
        final bookId = sec['book_id'] as int;
        final sectionIdStr = sec['id'] as String;
        final title = sec['title'] as String? ?? '';
        final chapterIdStr = sec['chapter_id'] as String?;

        final parentCollectionId = chapterIdStr != null
            ? chapterIdMap[chapterIdStr]
            : null;

        final collectionId = await db.insert('collections', {
          'book_id': bookId,
          'type': 'source',
          'name': title,
          'description': null,
          'config': null,
          'sort_order': 0,
          'created_at': now,
          'updated_at': now,
          'parent_id': parentCollectionId,
        });
        sectionIdMap[sectionIdStr] = collectionId;
      }

      // Migrate question-section associations to collection_items
      final questions = await db.query(
        'questions',
        columns: ['id', 'section_id'],
      );
      var position = 0;
      String? lastSectionId;
      for (final q in questions) {
        final qId = q['id'] as int;
        final sectionIdStr = q['section_id'] as String?;
        if (sectionIdStr == null || !sectionIdMap.containsKey(sectionIdStr)) {
          continue;
        }

        if (lastSectionId != sectionIdStr) {
          position = 0;
          lastSectionId = sectionIdStr;
        }

        await db.insert('collection_items', {
          'collection_id': sectionIdMap[sectionIdStr],
          'question_id': qId,
          'position': position,
          'role': 'item',
        });
        position++;
      }
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
        isCorrect: map['is_correct'] != null
            ? (map['is_correct'] as int) == 1
            : null,
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

  Future<void> saveUserAnswer(
    int bookId,
    int questionId,
    UserAnswer answer,
  ) async {
    final db = await database;
    await db.insert('user_answers', {
      'question_id': questionId,
      'book_id': bookId,
      'selected': answer.selected,
      'is_correct': answer.isCorrect == null
          ? null
          : (answer.isCorrect! ? 1 : 0),

      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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
      {'selected': null, 'is_correct': null},
      where: 'question_id = ?',
      whereArgs: [questionId],
    );
  }

  Future<void> clearBookProgress(int bookId) async {
    final db = await database;
    await db.delete('user_answers', where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('srs_reviews', where: 'book_id = ?', whereArgs: [bookId]);

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
    return ChatSession(
      id: id,
      questionId: questionId,
      title: title,
      createdAt: now,
    );
  }

  Future<void> updateChatSessionTitle(int sessionId, String title) async {
    final db = await database;
    await db.update(
      'ai_chat_sessions',
      {'title': title},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
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
    return maps
        .map(
          (map) => ChatMessage(
            text: map['text'] as String,
            isUser: (map['is_user'] as int) == 1,
          ),
        )
        .toList();
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
    final maps = await db.rawQuery(
      '''
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
    ''',
      [bookId],
    );
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
    final parentIds = questions
        .where((q) => q.parentId != null)
        .map((q) => q.parentId!)
        .toSet();
    if (parentIds.isEmpty) return;

    final db = await database;
    // Use parameterized query to avoid SQL injection
    final placeholders = List.filled(parentIds.length, '?').join(',');
    final parentMaps = await db.query(
      'questions',
      where: 'id IN ($placeholders)',
      whereArgs: parentIds.toList(),
    );

    final parentContentMap = {
      for (final map in parentMaps) map['id'] as int: map['content'] as String,
    };

    for (final q in questions) {
      if (q.parentId != null) {
        q.parentContent = parentContentMap[q.parentId];
      }
    }
  }

  // --- Collection Methods ---

  Future<List<Collection>> getCollections(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'collections',
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map((map) => Collection.fromMap(map)).toList();
  }

  Future<List<Collection>> getCollectionsByType(
    int bookId,
    CollectionType type,
  ) async {
    final db = await database;
    final maps = await db.query(
      'collections',
      where: 'book_id = ? AND type = ?',
      whereArgs: [bookId, type.name],
      orderBy: 'sort_order ASC, id ASC',
    );
    return maps.map((map) => Collection.fromMap(map)).toList();
  }

  Future<void> ensureBuiltinSmartCollections(int bookId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final existing = await getCollectionsByType(bookId, CollectionType.smart);
    final existingNames = existing.map((c) => c.name).toSet();

    final builtins = <Map<String, dynamic>>[
      {
        'name': 'Wrong Answers',
        'config': jsonEncode({'filters': [{'type': 'wrong'}]}),
        'sort_order': 0,
      },
      {
        'name': 'Marked',
        'config': jsonEncode({'filters': [{'type': 'marked'}]}),
        'sort_order': 1,
      },
      {
        'name': 'Unanswered',
        'config': jsonEncode({'filters': [{'type': 'unanswered'}]}),
        'sort_order': 2,
      },
      {
        'name': 'Due for Review',
        'config': jsonEncode({'filters': [{'type': 'srs_due'}]}),
        'sort_order': 3,
      },
    ];

    for (final spec in builtins) {
      if (existingNames.contains(spec['name'])) continue;

      await db.insert('collections', {
        'book_id': bookId,
        'type': CollectionType.smart.name,
        'name': spec['name'],
        'description': null,
        'config': spec['config'],
        'sort_order': spec['sort_order'],
        'created_at': now,
        'updated_at': now,
        'parent_id': null,
      });
    }
  }

  Future<void> generateTopicCollections(int bookId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Get all questions with tags for this book
    final questionMaps = await db.rawQuery(
      "SELECT id, tags FROM questions WHERE book_id = ? AND tags IS NOT NULL AND tags != ''",
      [bookId],
    );

    final tagQuestions = <String, List<int>>{};
    for (final m in questionMaps) {
      final qId = m['id'] as int;
      final tagsJson = m['tags'] as String?;
      if (tagsJson == null || tagsJson.isEmpty) continue;
      try {
        final decoded = jsonDecode(tagsJson) as List<dynamic>;
        for (final tag in decoded) {
          final tagStr = tag.toString();
          tagQuestions.putIfAbsent(tagStr, () => []).add(qId);
        }
      } catch (_) {}
    }

    if (tagQuestions.isEmpty) return;

    // Get existing topic collections
    final existing = await getCollectionsByType(bookId, CollectionType.topic);
    final existingByName = {for (final c in existing) c.name: c.id};

    for (final entry in tagQuestions.entries) {
      final tag = entry.key;
      final questionIds = entry.value;

      int collectionId;
      if (existingByName.containsKey(tag)) {
        collectionId = existingByName[tag]!;
        // Remove old items to avoid duplicates
        await db.delete(
          'collection_items',
          where: 'collection_id = ?',
          whereArgs: [collectionId],
        );
      } else {
        collectionId = await db.insert('collections', {
          'book_id': bookId,
          'type': CollectionType.topic.name,
          'name': tag,
          'description': null,
          'config': null,
          'sort_order': 0,
          'created_at': now,
          'updated_at': now,
          'parent_id': null,
        });
      }

      for (int i = 0; i < questionIds.length; i++) {
        await db.insert('collection_items', {
          'collection_id': collectionId,
          'question_id': questionIds[i],
          'position': i,
          'role': 'item',
        });
      }
    }
  }

  Future<List<CollectionItem>> getCollectionItems(int collectionId) async {
    final db = await database;
    final maps = await db.query(
      'collection_items',
      where: 'collection_id = ?',
      whereArgs: [collectionId],
      orderBy: 'position ASC, id ASC',
    );
    return maps.map((map) => CollectionItem.fromMap(map)).toList();
  }

  Future<List<Question>> getQuestionsByCollection(int collectionId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT q.* FROM questions q
      INNER JOIN collection_items ci ON ci.question_id = q.id
      WHERE ci.collection_id = ?
      ORDER BY ci.position ASC, q.id ASC
      ''',
      [collectionId],
    );
    final questions = maps.map((map) => Question.fromMap(map)).toList();
    await _populateParentContent(questions);
    return questions;
  }

  Future<Map<int, int>> getCollectionQuestionCounts(int bookId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT ci.collection_id, COUNT(*) as count
      FROM collection_items ci
      INNER JOIN collections c ON c.id = ci.collection_id
      WHERE c.book_id = ?
      GROUP BY ci.collection_id
      ''',
      [bookId],
    );
    return {
      for (final m in maps) m['collection_id'] as int: m['count'] as int,
    };
  }

  Future<Map<int, int>> getCollectionAnsweredCounts(int bookId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT ci.collection_id, COUNT(DISTINCT ua.question_id) as count
      FROM user_answers ua
      INNER JOIN collection_items ci ON ci.question_id = ua.question_id
      INNER JOIN collections c ON c.id = ci.collection_id
      WHERE ua.book_id = ?
      GROUP BY ci.collection_id
      ''',
      [bookId],
    );
    return {
      for (final m in maps) m['collection_id'] as int: m['count'] as int,
    };
  }

  Future<List<int>> getAnswerableQuestionIds(int bookId) async {
    final db = await database;
    final maps = await db.rawQuery(
      "SELECT id FROM questions WHERE book_id = ? AND question_type <> 'passage' ORDER BY id ASC",
      [bookId],
    );
    return maps.map((m) => m['id'] as int).toList();
  }

  Future<List<int>> getWrongQuestionIds(int bookId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT question_id FROM user_answers
      WHERE book_id = ? AND is_correct = 0
      ''',
      [bookId],
    );
    return maps.map((m) => m['question_id'] as int).toList();
  }

  Future<List<int>> getAnsweredQuestionIds(int bookId) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT question_id FROM user_answers WHERE book_id = ?',
      [bookId],
    );
    return maps.map((m) => m['question_id'] as int).toList();
  }

  Future<List<int>> getSrsDueQuestionIds(int bookId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.rawQuery(
      'SELECT question_id FROM srs_reviews WHERE book_id = ? AND due_date <= ?',
      [bookId, now],
    );
    return maps.map((m) => m['question_id'] as int).toList();
  }

  Future<List<int>> getQuestionIdsByTag(int bookId, String tag) async {
    final db = await database;
    final maps = await db.rawQuery(
      "SELECT id, tags FROM questions WHERE book_id = ? AND tags IS NOT NULL",
      [bookId],
    );
    final result = <int>[];
    for (final m in maps) {
      final tagsJson = m['tags'] as String?;
      if (tagsJson == null) continue;
      try {
        final decoded = jsonDecode(tagsJson) as List<dynamic>;
        if (decoded.any((t) => t.toString() == tag)) {
          result.add(m['id'] as int);
        }
      } catch (_) {}
    }
    return result;
  }

  Future<Map<int, double>> getQuestionDifficulties(int bookId) async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT id, difficulty FROM questions WHERE book_id = ? AND difficulty IS NOT NULL',
      [bookId],
    );
    return {
      for (final m in maps) m['id'] as int: (m['difficulty'] as num).toDouble(),
    };
  }

  Future<List<Question>> getQuestionsByIds(List<int> ids) async {
    if (ids.isEmpty) return [];
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final maps = await db.rawQuery(
      'SELECT * FROM questions WHERE id IN ($placeholders) ORDER BY id ASC',
      ids,
    );
    final questions = maps.map((m) => Question.fromMap(m)).toList();
    await _populateParentContent(questions);
    return questions;
  }

  Future<int> createUserCollection({
    required int bookId,
    required String name,
    required CollectionType type,
    String? description,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.insert('collections', {
      'book_id': bookId,
      'type': type.name,
      'name': name,
      'description': description,
      'config': null,
      'sort_order': 0,
      'created_at': now,
      'updated_at': now,
      'parent_id': null,
    });
  }

  Future<void> deleteCollection(int collectionId) async {
    final db = await database;
    await db.delete(
      'collections',
      where: 'id = ?',
      whereArgs: [collectionId],
    );
  }

  Future<void> updateCollectionConfig(int collectionId, String config) async {
    final db = await database;
    await db.update(
      'collections',
      {'config': config},
      where: 'id = ?',
      whereArgs: [collectionId],
    );
  }

  Future<bool> addQuestionToCollection(int collectionId, int questionId) async {
    final added = await addQuestionsToCollection(collectionId, [questionId]);
    return added > 0;
  }

  Future<int> addQuestionsToCollection(int collectionId, List<int> questionIds) async {
    final db = await database;

    // Get existing question IDs in this collection
    final existingMaps = await db.query(
      'collection_items',
      columns: ['question_id'],
      where: 'collection_id = ?',
      whereArgs: [collectionId],
    );
    final existingIds = existingMaps.map((m) => m['question_id'] as int).toSet();

    // Get max position
    final maxPosResult = await db.rawQuery(
      'SELECT MAX(position) as max_pos FROM collection_items WHERE collection_id = ?',
      [collectionId],
    );
    int nextPosition = ((maxPosResult.first['max_pos'] as int?) ?? -1) + 1;

    int addedCount = 0;
    final batch = db.batch();
    for (final questionId in questionIds) {
      if (existingIds.contains(questionId)) continue;
      batch.insert('collection_items', {
        'collection_id': collectionId,
        'question_id': questionId,
        'position': nextPosition,
        'role': 'item',
      });
      nextPosition++;
      addedCount++;
    }
    await batch.commit(noResult: true);
    return addedCount;
  }

  Future<void> removeQuestionFromCollection(int collectionId, int questionId) async {
    final db = await database;
    await db.delete(
      'collection_items',
      where: 'collection_id = ? AND question_id = ?',
      whereArgs: [collectionId, questionId],
    );
  }

  Future<void> reorderCollectionItems(int collectionId, List<int> questionIds) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < questionIds.length; i++) {
      batch.update(
        'collection_items',
        {'position': i},
        where: 'collection_id = ? AND question_id = ?',
        whereArgs: [collectionId, questionIds[i]],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Question>> searchQuestions(int bookId, String query) async {
    final db = await database;
    final pattern = '%$query%';
    final maps = await db.rawQuery(
      '''
      SELECT * FROM questions
      WHERE book_id = ?
        AND question_type <> 'passage'
        AND (
          content LIKE ?
          OR explanation LIKE ?
          OR tags LIKE ?
          OR note LIKE ?
        )
      ORDER BY id ASC
      ''',
      [bookId, pattern, pattern, pattern, pattern],
    );
    final questions = maps.map((m) => Question.fromMap(m)).toList();
    await _populateParentContent(questions);
    return questions;
  }

  Future<void> insertCollectionItem(CollectionItem item) async {
    final db = await database;
    await db.insert('collection_items', item.toMap());
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
      "SELECT COUNT(*) as count FROM questions WHERE book_id = ? AND question_type <> 'passage'",
      [bookId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> updateBookOrder(List<int> bookIds) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < bookIds.length; i++) {
      batch.update(
        'books',
        {'sort_order': i},
        where: 'id = ?',
        whereArgs: [bookIds[i]],
      );
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
      await txn.delete(
        'srs_reviews',
        where: 'book_id = ?',
        whereArgs: [bookId],
      );
    });
  }

  // --- SRS Methods ---

  Future<SrsState?> getSrsState(int questionId) async {
    final db = await database;
    final maps = await db.query(
      'srs_reviews',
      where: 'question_id = ?',
      whereArgs: [questionId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return SrsState.fromMap(maps.first);
  }

  Future<Map<int, SrsState>> getSrsStates(int bookId) async {
    final db = await database;
    final maps = await db.query(
      'srs_reviews',
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
    return {
      for (final map in maps) map['question_id'] as int: SrsState.fromMap(map),
    };
  }

  Future<List<int>> getDueQuestionIds(int bookId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final maps = await db.rawQuery(
      '''
      SELECT s.question_id
      FROM srs_reviews s
      INNER JOIN questions q ON q.id = s.question_id
      WHERE s.book_id = ?
        AND s.due_date <= ?
        AND q.question_type <> 'passage'
        AND TRIM(COALESCE(q.answer, '')) <> ''
      ORDER BY s.due_date ASC
    ''',
      [bookId, now],
    );
    return maps.map((m) => m['question_id'] as int).toList();
  }

  Future<List<int>> getNewQuestionIds(int bookId) async {
    final db = await database;
    final maps = await db.rawQuery(
      '''
      SELECT q.id 
      FROM questions q
      LEFT JOIN srs_reviews s ON q.id = s.question_id
      WHERE q.book_id = ?
        AND s.question_id IS NULL
        AND q.question_type <> 'passage'
        AND TRIM(COALESCE(q.answer, '')) <> ''
      ORDER BY q.id
    ''',
      [bookId],
    );
    return maps.map((m) => m['id'] as int).toList();
  }

  Future<void> saveSrsState(SrsState state) async {
    final db = await database;
    await db.insert(
      'srs_reviews',
      state.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SrsStats> getSrsStats(int bookId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    final newCardsResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count 
      FROM questions q
      LEFT JOIN srs_reviews s ON q.id = s.question_id
      WHERE q.book_id = ?
        AND s.question_id IS NULL
        AND q.question_type <> 'passage'
        AND TRIM(COALESCE(q.answer, '')) <> ''
    ''',
      [bookId],
    );

    final learningResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM srs_reviews s
      INNER JOIN questions q ON q.id = s.question_id
      WHERE s.book_id = ?
        AND s.review_state IN (1, 3)
        AND s.due_date <= ?
        AND q.question_type <> 'passage'
        AND TRIM(COALESCE(q.answer, '')) <> ''
    ''',
      [bookId, now],
    );

    final reviewResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM srs_reviews s
      INNER JOIN questions q ON q.id = s.question_id
      WHERE s.book_id = ?
        AND s.review_state = 2
        AND s.due_date <= ?
        AND q.question_type <> 'passage'
        AND TRIM(COALESCE(q.answer, '')) <> ''
    ''',
      [bookId, now],
    );

    final totalResult = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM questions
      WHERE book_id = ?
        AND question_type <> 'passage'
        AND TRIM(COALESCE(answer, '')) <> ''
    ''',
      [bookId],
    );

    return SrsStats(
      newCards: Sqflite.firstIntValue(newCardsResult) ?? 0,
      learning: Sqflite.firstIntValue(learningResult) ?? 0,
      review: Sqflite.firstIntValue(reviewResult) ?? 0,
      total: Sqflite.firstIntValue(totalResult) ?? 0,
    );
  }

  Future<void> initializeSrsForBook(int bookId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.execute(
      '''
      INSERT OR IGNORE INTO srs_reviews 
      (question_id, book_id, interval_days, ease_factor, repetitions, lapses, due_date, last_reviewed, review_state)
      SELECT id, book_id, 0, 2.5, 0, 0, ?, NULL, 0
      FROM questions
      WHERE book_id = ?
        AND question_type <> 'passage'
        AND TRIM(COALESCE(answer, '')) <> ''
    ''',
      [now, bookId],
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Validates package data before import. Returns a list of error messages.
  /// An empty list means the package is valid.
  List<String> validatePackageData(Map<String, dynamic> data) {
    final errors = <String>[];

    if (data['subject_name_zh'] == null ||
        (data['subject_name_zh'] as String?).toString().isEmpty) {
      errors.add('Missing or empty subject_name_zh');
    }
    if (data['subject_name_en'] == null ||
        (data['subject_name_en'] as String?).toString().isEmpty) {
      errors.add('Missing or empty subject_name_en');
    }

    final chapters = data['chapters'] as List?;
    if (chapters == null || chapters.isEmpty) {
      errors.add('Missing or empty chapters array');
      return errors;
    }

    void validateQuestion(Map<String, dynamic> q, String path) {
      final content = q['content'] as String?;
      if (content == null || content.isEmpty) {
        errors.add('$path: Missing or empty content');
      }

      final subQuestions = q['questions'] as List?;
      final isParentQuestion = subQuestions != null && subQuestions.isNotEmpty;

      final qType =
          q['question_type'] as String? ??
          (isParentQuestion ? 'passage' : 'multiple_choice');
      const supportedTypes = {
        'multiple_choice',
        'true_false',
        'fill_blank',
        'cloze',
        'flashcard',
        'passage',
      };
      if (!supportedTypes.contains(qType)) {
        errors.add('$path: Unsupported question_type "$qType"');
      }

      final requiresChoices =
          qType == 'multiple_choice' || qType == 'true_false';
      final requiresAnswer = qType != 'passage' && !isParentQuestion;

      if (requiresChoices && !isParentQuestion) {
        final choices = q['choices'] as List?;
        if (choices == null || choices.isEmpty) {
          errors.add('$path: $qType question missing choices');
        } else {
          final answer = q['answer'] as String?;
          if (answer == null || answer.isEmpty) {
            errors.add('$path: $qType question missing answer');
          } else {
            final choiceKeys = choices.map((c) {
              if (c is Map) {
                return (c['key'] ?? '').toString().toUpperCase();
              }
              return '';
            }).toSet();
            if (!choiceKeys.contains(answer.toUpperCase())) {
              errors.add(
                '$path: Answer "$answer" does not match any choice key',
              );
            }
          }
        }
      } else if (requiresAnswer) {
        final answer = q['answer'] as String?;
        if (answer == null || answer.isEmpty) {
          errors.add('$path: $qType question missing answer');
        }
      }

      final difficulty = q['difficulty'] as num?;
      if (difficulty != null && (difficulty < 1.0 || difficulty > 5.0)) {
        errors.add('$path: difficulty must be between 1.0 and 5.0');
      }

      if (subQuestions != null) {
        for (var i = 0; i < subQuestions.length; i++) {
          validateQuestion(
            subQuestions[i] as Map<String, dynamic>,
            '$path.subQ$i',
          );
        }
      }
    }

    for (var ci = 0; ci < chapters.length; ci++) {
      final chapter = chapters[ci] as Map<String, dynamic>;
      final chapterTitle = chapter['title'] as String?;
      if (chapterTitle == null || chapterTitle.isEmpty) {
        errors.add('Chapter $ci: Missing title');
      }

      final sections = chapter['sections'] as List?;
      if (sections == null || sections.isEmpty) {
        errors.add('Chapter $ci ($chapterTitle): Missing or empty sections');
        continue;
      }

      for (var si = 0; si < sections.length; si++) {
        final section = sections[si] as Map<String, dynamic>;
        final sectionTitle = section['title'] as String?;
        if (sectionTitle == null || sectionTitle.isEmpty) {
          errors.add('Chapter $ci Section $si: Missing title');
        }

        final questions = section['questions'] as List?;
        if (questions == null) continue;

        for (var qi = 0; qi < questions.length; qi++) {
          validateQuestion(
            questions[qi] as Map<String, dynamic>,
            'C$ci.S$si.Q$qi',
          );
        }
      }
    }

    return errors;
  }

  Future<void> importData(Map<String, dynamic> data, String packageId) async {
    final validationErrors = validatePackageData(data);
    if (validationErrors.isNotEmpty) {
      throw Exception(
        'Package validation failed:\n${validationErrors.join('\n')}',
      );
    }

    final db = await database;
    int bookId = -1;
    await db.transaction((txn) async {
      // 1. Insert Book
      bookId = await txn.insert('books', {
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
      final now = DateTime.now().millisecondsSinceEpoch;

      final chapterCollectionMap = <String, int>{};
      final sectionCollectionMap = <String, int>{};

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

          // Create source collection for chapter
          final chapterCollectionId = await txn.insert('collections', {
            'book_id': bookId,
            'type': 'source',
            'name': c['title'] ?? 'Chapter $totalChapters',
            'sort_order': totalChapters,
            'created_at': now,
            'parent_id': null,
          });
          chapterCollectionMap[chapterId] = chapterCollectionId;

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

              // Create source collection for section
              final sectionCollectionId = await txn.insert('collections', {
                'book_id': bookId,
                'type': 'source',
                'name': s['title'] ?? 'Section $totalSections',
                'sort_order': totalSections,
                'created_at': now,
                'parent_id': chapterCollectionId,
              });
              sectionCollectionMap[sectionId] = sectionCollectionId;

              final questions = s['questions'] as List?;
              if (questions != null) {
                int sectionQuestionCount = 0;
                int position = 0;
                for (var q in questions) {
                  int count = await _insertQuestion(
                    txn,
                    q,
                    bookId,
                    sectionId,
                    collectionId: sectionCollectionId,
                    position: position,
                  );
                  sectionQuestionCount += count;
                  totalQuestions += count;
                  position += count;
                }
                await txn.update(
                  'sections',
                  {'question_count': sectionQuestionCount},
                  where: 'id = ?',
                  whereArgs: [sectionId],
                );
              }
            }
          }
        }
      }

      await txn.update(
        'books',
        {
          'total_questions': totalQuestions,
          'total_chapters': totalChapters,
          'total_sections': totalSections,
        },
        where: 'id = ?',
        whereArgs: [bookId],
      );
    });

    await ensureBuiltinSmartCollections(bookId);
    await generateTopicCollections(bookId);
  }

  Future<int> _insertQuestion(
    Transaction txn,
    Map<String, dynamic> q,
    int bookId,
    String sectionId, {
    int? parentId,
    int? collectionId,
    int position = 0,
  }) async {
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

    // Extract v2 optional fields
    final tags = q['tags'];
    final tagsJson = tags is List
        ? jsonEncode(tags)
        : (tags is String ? tags : null);
    final difficulty = (q['difficulty'] as num?)?.toDouble();
    final subQuestions = q['questions'] as List?;
    final hasSubQuestions = subQuestions != null && subQuestions.isNotEmpty;
    final questionType =
        q['question_type'] as String? ??
        (hasSubQuestions ? 'passage' : 'multiple_choice');

    final isPassage = questionType == 'passage';

    final id = await txn.insert('questions', {
      'book_id': bookId,
      'section_id': sectionId,
      'parent_id': parentId,
      'content': q['content'] ?? '',
      'choices': choicesJson,
      'answer': q['answer'] ?? '',
      'explanation': q['explanation'],
      'question_type': questionType,
      'tags': tagsJson,
      'difficulty': difficulty,
      'note': q['note'],
      'front_template': q['front_template'],
      'back_template': q['back_template'],
    });

    int currentPosition = position;

    if (hasSubQuestions) {
      for (var sq in subQuestions) {
        final childCount = await _insertQuestion(
          txn,
          sq,
          bookId,
          sectionId,
          parentId: id,
          collectionId: collectionId,
          position: currentPosition,
        );
        insertedCount += childCount;
        currentPosition += childCount;
      }
    }

    if (!isPassage) {
      insertedCount++;
      if (collectionId != null) {
        await txn.insert('collection_items', {
          'collection_id': collectionId,
          'question_id': id,
          'position': currentPosition,
          'role': 'item',
        });
      }
      currentPosition++;
    }

    return insertedCount;
  }
}
