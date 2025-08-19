class Task {
  final String id;
  final String title;
  final DateTime date;
  final bool isCompleted;
  final bool isImportant;
  final String category; // 카테고리 필드 추가

  Task({
    required this.id,
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.isImportant = false,
    this.category = '일반', // 기본값은 '일반'
  });

  Task copyWith({
    String? id,
    String? title,
    DateTime? date,
    bool? isCompleted,
    bool? isImportant,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
      'isImportant': isImportant,
      'category': category,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      isCompleted: json['isCompleted'] ?? false,
      isImportant: json['isImportant'] ?? false,
      category: json['category'] ?? '일반',
    );
  }
}
