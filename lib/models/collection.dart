enum CollectionType {
  source,
  topic,
  practiceSet,
  examBlueprint,
  smart,
  playlist,
}

class Collection {
  final int id;
  final int bookId;
  final CollectionType type;
  final String name;
  final String? description;
  final String? config;
  final int sortOrder;
  final int createdAt;
  final int? updatedAt;
  final int? parentId;

  const Collection({
    required this.id,
    required this.bookId,
    required this.type,
    required this.name,
    this.description,
    this.config,
    this.sortOrder = 0,
    required this.createdAt,
    this.updatedAt,
    this.parentId,
  });

  factory Collection.fromMap(Map<String, dynamic> map) {
    return Collection(
      id: map['id'] as int,
      bookId: map['book_id'] as int,
      type: _parseType(map['type'] as String?),
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      config: map['config'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int?,
      parentId: map['parent_id'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'type': type.name,
      'name': name,
      'description': description,
      'config': config,
      'sort_order': sortOrder,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'parent_id': parentId,
    };
  }

  static CollectionType _parseType(String? value) {
    return CollectionType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => CollectionType.source,
    );
  }

  bool get isSource => type == CollectionType.source;
  bool get isSmart => type == CollectionType.smart;
  bool get isBlueprint => type == CollectionType.examBlueprint;
}

class CollectionItem {
  final int id;
  final int collectionId;
  final int questionId;
  final int position;
  final String role;

  const CollectionItem({
    required this.id,
    required this.collectionId,
    required this.questionId,
    this.position = 0,
    this.role = 'item',
  });

  factory CollectionItem.fromMap(Map<String, dynamic> map) {
    return CollectionItem(
      id: map['id'] as int,
      collectionId: map['collection_id'] as int,
      questionId: map['question_id'] as int,
      position: map['position'] as int? ?? 0,
      role: map['role'] as String? ?? 'item',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection_id': collectionId,
      'question_id': questionId,
      'position': position,
      'role': role,
    };
  }
}
