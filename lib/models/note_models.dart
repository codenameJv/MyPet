class PetNote {
  final int? id;
  final int petId;
  final String content;
  final String createdAt;
  final bool isPinned;

  PetNote({
    this.id,
    required this.petId,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
  });

  PetNote copyWith({
    int? id,
    int? petId,
    String? content,
    String? createdAt,
    bool? isPinned,
  }) {
    return PetNote(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'content': content,
      'createdAt': createdAt,
      'isPinned': isPinned ? 1 : 0,
    };
  }

  factory PetNote.fromMap(Map<String, dynamic> map) {
    return PetNote(
      id: map['id'],
      petId: map['petId'],
      content: map['content'],
      createdAt: map['createdAt'],
      isPinned: map['isPinned'] == 1,
    );
  }
}
