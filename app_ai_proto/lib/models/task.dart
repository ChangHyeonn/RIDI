class RecurrenceInfo {
  final String type; // daily, weekdays, weekends, custom_days
  final List<RecurrenceTime> times; // 반복 시간들
  final DateTime? endDate; // 종료 날짜 (null이면 무기한)
  final List<int>? daysOfWeek; // 요일들 (0=월요일, 6=일요일)

  RecurrenceInfo({
    required this.type,
    required this.times,
    this.endDate,
    this.daysOfWeek,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'times': times.map((time) => time.toJson()).toList(),
      'endDate': endDate?.toIso8601String(),
      'daysOfWeek': daysOfWeek,
    };
  }

  factory RecurrenceInfo.fromJson(Map<String, dynamic> json) {
    return RecurrenceInfo(
      type: json['type'],
      times: (json['times'] as List)
          .map((time) => RecurrenceTime.fromJson(time))
          .toList(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'])
          : null,
    );
  }
}

class RecurrenceTime {
  final String time; // "07:00" 형식
  final String label; // "아침", "저녁" 등

  RecurrenceTime({required this.time, required this.label});

  Map<String, dynamic> toJson() {
    return {'time': time, 'label': label};
  }

  factory RecurrenceTime.fromJson(Map<String, dynamic> json) {
    return RecurrenceTime(time: json['time'], label: json['label']);
  }
}

class Task {
  final String id;
  final String title;
  final DateTime date;
  final bool isCompleted;
  final bool isImportant;
  final String category; // 카테고리 필드 추가
  final bool isRecurring; // 반복 일정 여부
  final RecurrenceInfo? recurrence; // 반복 정보

  Task({
    required this.id,
    required this.title,
    required this.date,
    this.isCompleted = false,
    this.isImportant = false,
    this.category = '일반', // 기본값은 '일반'
    this.isRecurring = false,
    this.recurrence,
  });

  Task copyWith({
    String? id,
    String? title,
    DateTime? date,
    bool? isCompleted,
    bool? isImportant,
    String? category,
    bool? isRecurring,
    RecurrenceInfo? recurrence,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      isImportant: isImportant ?? this.isImportant,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrence: recurrence ?? this.recurrence,
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
      'isRecurring': isRecurring,
      'recurrence': recurrence?.toJson(),
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
      isRecurring: json['isRecurring'] ?? false,
      recurrence: json['recurrence'] != null
          ? RecurrenceInfo.fromJson(json['recurrence'])
          : null,
    );
  }
}
