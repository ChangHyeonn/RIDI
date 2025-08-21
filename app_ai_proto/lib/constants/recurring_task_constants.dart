import 'package:flutter/material.dart';

/// 반복 일정 관련 상수들
class RecurringTaskConstants {
  // 기본값들
  static const TimeOfDay defaultTime = TimeOfDay(hour: 9, minute: 0);
  static const int maxRecurrenceDays = 365;
  static const int defaultEndDateDaysFromNow = 180;

  // UI 관련 상수
  static const double cardBorderRadius = 16.0;
  static const double inputBorderRadius = 12.0;
  static const double weekdayIconSize = 20.0;
  static const double categoryIconSize = 24.0;

  // 색상
  static const Color backgroundColor = Color(0xFFfafafa);
  static const Color cardColor = Colors.white;
  static const Color primaryColor = Color(0xFF6366f1);
  static const Color textPrimaryColor = Color(0xFF1f2937);
  static const Color textSecondaryColor = Color(0xFF6b7280);
  static const Color borderColor = Color(0xFFd1d5db);

  // 애니메이션
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // 요일 이름
  static const List<String> dayNames = ['월', '화', '수', '목', '금', '토', '일'];

  // 에러 메시지
  static const String errorInvalidDate = '올바른 날짜를 입력해주세요';
  static const String errorPastEndDate = '종료일은 오늘 이후로 설정해주세요';
  static const String errorNoDaySelected = '최소 하나의 요일을 선택해주세요';
  static const String errorEmptyTitle = '제목을 입력해주세요';

  // 성공 메시지
  static const String successRecurrenceCreated = '반복 일정이 생성되었습니다';
  static const String successRecurrenceUpdated = '반복 일정이 수정되었습니다';
  static const String successRecurrenceDeleted = '반복 일정이 삭제되었습니다';

  /// 기본 종료일 계산
  static DateTime get defaultEndDate =>
      DateTime.now().add(const Duration(days: defaultEndDateDaysFromNow));

  /// 시간을 12시간 형식으로 포맷
  static String formatTime12Hour(TimeOfDay time) {
    final period = time.hour < 12 ? '오전' : '오후';
    final displayHour = time.hour == 0
        ? 12
        : (time.hour > 12 ? time.hour - 12 : time.hour);
    return '$period ${displayHour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// DateTime을 12시간 형식으로 포맷
  static String formatDateTime12Hour(DateTime date) {
    final period = date.hour < 12 ? '오전' : '오후';
    final displayHour = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    return '$period ${displayHour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 안전한 Task ID 생성 (알림 시스템에서 파싱 가능한 형태)
  /// 알림 시스템에서 int.parse()가 가능하도록 숫자만 사용
  static String generateSafeTaskId({
    required String prefix,
    required int counter,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000; // 초 단위
    final shortTimestamp = timestamp.toString().substring(
      timestamp.toString().length - 6,
    ); // 마지막 6자리

    // 알림 ID는 숫자만 가능하므로 prefix 없이 숫자로만 구성
    // 형식: [6자리 타임스탬프][3자리 카운터] = 최대 9자리
    final numericId = '${shortTimestamp}${counter.toString().padLeft(3, '0')}';
    return numericId;
  }

  /// 현재 시간이 특정 시간 이후인지 확인 (같은 날 기준)
  static bool isTimeAfter(DateTime target, DateTime reference) {
    if (target.year == reference.year &&
        target.month == reference.month &&
        target.day == reference.day) {
      // 같은 날인 경우 시간만 비교
      return target.hour > reference.hour ||
          (target.hour == reference.hour && target.minute >= reference.minute);
    }
    return target.isAfter(reference);
  }
}
