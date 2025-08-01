class Task {
  final String id;
  final String title;
  final DateTime date;
  final bool isCompleted;
  final bool isImportant;

  Task({
    required this.id,
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.isImportant = false,
  });

  Task copyWith({
    String? id,
    String? title,
    DateTime? date,
    bool? isCompleted,
    bool? isImportant,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
      'isImportant': isImportant,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      isCompleted: json['isCompleted'] ?? false,
      isImportant: json['isImportant'] ?? false,
    );
  }
}
