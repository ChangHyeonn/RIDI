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
    // 필수 필드 검증
    final type = json['type']?.toString();
    if (type == null) {
      throw FormatException('RecurrenceInfo.fromJson: type은 필수 필드입니다. JSON: $json');
    }
    
    // times 필드 안전하게 파싱
    List<RecurrenceTime> times = [];
    if (json['times'] != null && json['times'] is List) {
      try {
        times = (json['times'] as List)
            .map((time) => RecurrenceTime.fromJson(time))
            .toList();
      } catch (e) {
        // RecurrenceTime 파싱 실패는 무시 (빈 리스트 사용)
        times = [];
      }
    }
    
    // endDate 필드 안전하게 파싱
    DateTime? endDate;
    if (json['endDate'] != null) {
      try {
        endDate = DateTime.parse(json['endDate']);
      } catch (e) {
        // endDate 파싱 실패는 무시 (null 사용)
        endDate = null;
      }
    }
    
    // daysOfWeek 필드 안전하게 파싱
    List<int>? daysOfWeek;
    if (json['daysOfWeek'] != null && json['daysOfWeek'] is List) {
      try {
        daysOfWeek = List<int>.from(json['daysOfWeek']);
      } catch (e) {
        // daysOfWeek 파싱 실패는 무시 (null 사용)
        daysOfWeek = null;
      }
    }
    
    return RecurrenceInfo(
      type: type,
      times: times,
      endDate: endDate,
      daysOfWeek: daysOfWeek,
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
    final time = json['time']?.toString();
    final label = json['label']?.toString();
    
    if (time == null || label == null) {
      throw FormatException('RecurrenceTime.fromJson: time과 label은 필수 필드입니다. JSON: $json');
    }
    
    return RecurrenceTime(time: time, label: label);
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
    // 디버깅 모드 (개발 시에만 활성화)
    const bool debugMode = false;
    
    // 필수 필드 검증
    final id = json['id']?.toString();
    final title = json['title']?.toString();
    
    if (id == null || title == null) {
      throw FormatException('Task.fromJson: id와 title은 필수 필드입니다. JSON: $json');
    }
    
    // datetime 필드 처리 (AI 서버 응답용)
    DateTime? dateTime;
    String? dateTimeSource; // 디버깅용
    
    // 1. datetime 필드 우선 시도
    if (json['datetime'] != null) {
      try {
        dateTime = DateTime.parse(json['datetime']);
        dateTimeSource = 'datetime';
        if (debugMode) print('📅 Task.fromJson: datetime 파싱 성공 - $dateTime');
      } catch (e) {
        if (debugMode) print('⚠️ Task.fromJson: datetime 파싱 실패 - ${json['datetime']}');
        // 파싱 실패 시 로그만 남기고 계속 진행
      }
    }
    
    // 2. date 필드 시도 (datetime이 없거나 실패한 경우)
    if (dateTime == null && json['date'] != null) {
      try {
        dateTime = DateTime.parse(json['date']);
        dateTimeSource = 'date';
        if (debugMode) print('📅 Task.fromJson: date 파싱 성공 - $dateTime');
      } catch (e) {
        if (debugMode) print('⚠️ Task.fromJson: date 파싱 실패 - ${json['date']}');
        // 파싱 실패 시 로그만 남기고 계속 진행
      }
    }
    
    // 3. 스마트 기본값 결정
    if (dateTime == null) {
      // 삭제 화면에서는 시간 정보가 없어도 괜찮음
      // 현재 시간 대신 오늘 날짜의 기본 시간 사용
      final now = DateTime.now();
      dateTime = DateTime(now.year, now.month, now.day, 12, 0); // 오늘 정오
      dateTimeSource = 'default_noon';
      if (debugMode) print('📅 Task.fromJson: 기본값 사용 - $dateTime');
    }
    
    // RecurrenceInfo 안전하게 파싱
    RecurrenceInfo? recurrence;
    if (json['recurrence'] != null) {
      try {
        recurrence = RecurrenceInfo.fromJson(json['recurrence']);
        if (debugMode) print('🔄 Task.fromJson: RecurrenceInfo 파싱 성공');
      } catch (e) {
        if (debugMode) print('⚠️ Task.fromJson: RecurrenceInfo 파싱 실패 - $e');
        // RecurrenceInfo 파싱 실패는 무시 (선택적 필드)
        recurrence = null;
      }
    }
    
    if (debugMode) print('✅ Task.fromJson: 완료 - $title ($dateTimeSource)');
    
    return Task(
      id: id,
      title: title,
      date: dateTime,
      isCompleted: json['isCompleted'] ?? false,
      isImportant: json['isImportant'] ?? false,
      category: json['category'] ?? '일반',
      isRecurring: json['isRecurring'] ?? false,
      recurrence: recurrence,
    );
  }
}
