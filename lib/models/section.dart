class Section {
  final String id;
  final int bookId;
  final String chapterId;
  final String title;
  final int questionCount;
  final String? chapterTitle;

  Section({
    required this.id,
    required this.bookId,
    required this.chapterId,
    required this.title,
    required this.questionCount,
    this.chapterTitle,
  });

  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      id: map['id'] as String,
      bookId: map['book_id'] as int,
      chapterId: map['chapter_id'] as String,
      title: map['title'] as String? ?? '',
      questionCount: map['question_count'] as int? ?? 0,
      chapterTitle: map['chapter_title'] as String?,
    );
  }

  String get displayTitle {
    if (chapterTitle != null && chapterTitle!.isNotEmpty) {
      return '$chapterTitle - $title';
    }
    return title;
  }
}

class Chapter {
  final String id;
  final int bookId;
  final String title;
  final int questionCount;

  Chapter({
    required this.id,
    required this.bookId,
    required this.title,
    required this.questionCount,
  });

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] as String,
      bookId: map['book_id'] as int,
      title: map['title'] as String? ?? '',
      questionCount: map['question_count'] as int? ?? 0,
    );
  }
}
