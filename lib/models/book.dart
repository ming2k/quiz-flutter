class Book {
  final int id;
  final String filename;
  final String subjectNameZh;
  final String subjectNameEn;
  final int totalQuestions;
  final int totalChapters;
  final int totalSections;

  Book({
    required this.id,
    required this.filename,
    required this.subjectNameZh,
    required this.subjectNameEn,
    required this.totalQuestions,
    required this.totalChapters,
    required this.totalSections,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int,
      filename: map['filename'] as String,
      subjectNameZh: map['subject_name_zh'] as String? ?? '',
      subjectNameEn: map['subject_name_en'] as String? ?? '',
      totalQuestions: map['total_questions'] as int? ?? 0,
      totalChapters: map['total_chapters'] as int? ?? 0,
      totalSections: map['total_sections'] as int? ?? 0,
    );
  }

  String get displayName => subjectNameZh;

  String getDisplayName(String locale) {
    return subjectNameZh;
  }
}
