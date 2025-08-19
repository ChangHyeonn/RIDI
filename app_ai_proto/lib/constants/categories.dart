class TaskCategories {
  static const String general = '일반';
  static const String event = '경조사';
  static const String health = '건강';

  static const List<String> allCategories = [general, event, health];

  // 카테고리별 아이콘 및 색상 정보
  static Map<String, Map<String, dynamic>> categoryInfo = {
    general: {
      'icon': '📅',
      'color': 0xFF2196F3, // 파란색
      'name': '일반',
    },
    event: {
      'icon': '🎉',
      'color': 0xFFFF9800, // 주황색
      'name': '경조사',
    },
    health: {
      'icon': '🏥',
      'color': 0xFF4CAF50, // 초록색
      'name': '건강',
    },
  };

  // 카테고리 이름으로 정보 가져오기
  static Map<String, dynamic>? getCategoryInfo(String category) {
    return categoryInfo[category];
  }

  // 카테고리 아이콘 가져오기
  static String getCategoryIcon(String category) {
    return categoryInfo[category]?['icon'] ?? '📅';
  }

  // 카테고리 색상 가져오기
  static int getCategoryColor(String category) {
    return categoryInfo[category]?['color'] ?? 0xFF2196F3;
  }
}
