import 'package:flutter/material.dart';
import '../models/task.dart';
import '../constants/recurring_task_constants.dart';
import '../constants/categories.dart';

/// 반복 일정 관련 비즈니스 로직을 처리하는 서비스 클래스
class RecurringTaskService {
  /// 패턴 시그니처 생성: daysOfWeek(오름차순) + times(HH:MM 오름차순)
  static String buildPatternSignatureFromRecurrence(
    RecurrenceInfo? r,
    DateTime fallbackDate,
  ) {
    List<int> days = [];
    List<String> times = [];
    if (r != null) {
      // 요일 시그니처: 타입별 기본 집합 처리
      if (r.type == 'daily') {
        days = [0, 1, 2, 3, 4, 5, 6];
      } else if (r.type == 'weekdays') {
        days = [0, 1, 2, 3, 4];
      } else if (r.type == 'weekends') {
        days = [5, 6];
      } else if (r.daysOfWeek != null) {
        days = List<int>.from(r.daysOfWeek!)..sort();
      }
      if (r.times.isNotEmpty) {
        times = r.times.map((t) => t.time).toList()..sort();
      }
    }
    if (days.isEmpty) {
      days = [fallbackDate.weekday - 1];
    }
    if (times.isEmpty) {
      final hh = fallbackDate.hour.toString().padLeft(2, '0');
      final mm = fallbackDate.minute.toString().padLeft(2, '0');
      times = ['$hh:$mm'];
    }
    final dayStr = days.join(',');
    final timeStr = times.join(',');
    return 'd:$dayStr|t:$timeStr';
  }

  static String buildPatternSignatureForTask(Task task) {
    return buildPatternSignatureFromRecurrence(task.recurrence, task.date);
  }

  /// 반복 일정들을 그룹화하여 반환
  static Map<String, List<Task>> groupRecurringTasks(List<Task> allTasks) {
    final recurringTasks = allTasks.where((task) => task.isRecurring).toList();
    final Map<String, List<Task>> groupedTasks = {};

    for (final task in recurringTasks) {
      final signature = buildPatternSignatureForTask(task);
      final key = '${task.title}_${task.category}_$signature';
      if (!groupedTasks.containsKey(key)) {
        groupedTasks[key] = [];
      }
      groupedTasks[key]!.add(task);
    }

    return groupedTasks;
  }

  /// 특정 패턴의 반복 일정들을 찾아 반환
  static List<Task> findRecurringTasksByPattern(
    List<Task> allTasks,
    String title,
    String category, {
    String? signature,
  }) {
    return allTasks.where((t) {
      if (!(t.isRecurring && t.title == title && t.category == category)) {
        return false;
      }
      if (signature == null) return true;
      final sig = buildPatternSignatureForTask(t);
      return sig == signature;
    }).toList();
  }

  /// 반복 일정에서 요일 정보를 추출
  static List<bool> extractWeekdaysFromTasks(List<Task> tasks) {
    final List<bool> weekdayStatus = List.filled(7, false);

    if (tasks.isEmpty) return weekdayStatus;

    // 우선 Recurrence 타입(daily/weekdays/weekends)을 반영
    final RecurrenceInfo? r = tasks.first.recurrence;
    if (r != null) {
      switch (r.type) {
        case 'daily':
          for (int i = 0; i < 7; i++) {
            weekdayStatus[i] = true;
          }
          return weekdayStatus;
        case 'weekdays':
          for (int i = 0; i < 5; i++) {
            weekdayStatus[i] = true; // 월(0)~금(4)
          }
          return weekdayStatus;
        case 'weekends':
          weekdayStatus[5] = true; // 토(5)
          weekdayStatus[6] = true; // 일(6)
          return weekdayStatus;
        default:
          break; // custom_days 또는 기타 → 아래 로직으로 처리
      }
    }

    for (final task in tasks) {
      final rec = task.recurrence;
      if (rec != null) {
        if (rec.type == 'daily') {
          for (int i = 0; i < 7; i++) weekdayStatus[i] = true;
          continue;
        }
        if (rec.type == 'weekdays') {
          for (int i = 0; i < 5; i++) weekdayStatus[i] = true;
          continue;
        }
        if (rec.type == 'weekends') {
          weekdayStatus[5] = true;
          weekdayStatus[6] = true;
          continue;
        }
        if (rec.daysOfWeek != null) {
          for (final weekday in rec.daysOfWeek!) {
            if (weekday >= 0 && weekday < 7) weekdayStatus[weekday] = true;
          }
          continue;
        }
      }
      final weekday = task.date.weekday - 1; // 0=월요일, 6=일요일
      if (weekday >= 0 && weekday < 7) weekdayStatus[weekday] = true;
    }

    return weekdayStatus;
  }

  /// 반복 일정에서 시간 정보를 추출
  static Set<String> extractTimesFromTasks(List<Task> tasks) {
    final Set<String> uniqueTimes = {};

    if (tasks.isEmpty) return uniqueTimes;

    for (final task in tasks) {
      if (task.recurrence?.times != null && task.recurrence!.times.isNotEmpty) {
        for (final recurrenceTime in task.recurrence!.times) {
          // 음성 생성 경로는 label(예: "오후")만 주는 경우가 있어 시간 표시가 사라짐
          // 시간 문자열(HH:MM)을 파싱해 12시간제 표기로 통일하여 표시
          final parts = recurrenceTime.time.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            if (hour != null && minute != null) {
              final tod = TimeOfDay(hour: hour, minute: minute);
              uniqueTimes.add(RecurringTaskConstants.formatTime12Hour(tod));
              continue;
            }
          }
          // 파싱 실패 시 label을 폴백으로 사용
          uniqueTimes.add(recurrenceTime.label);
        }
      } else {
        uniqueTimes.add(RecurringTaskConstants.formatDateTime12Hour(task.date));
      }
    }

    return uniqueTimes;
  }

  /// TimeOfDay 리스트를 반복 일정에서 추출
  static List<TimeOfDay> extractTimeOfDayFromTasks(List<Task> tasks) {
    final Set<TimeOfDay> uniqueTimes = {};

    if (tasks.isEmpty) return [];

    for (final task in tasks) {
      if (task.recurrence?.times != null && task.recurrence!.times.isNotEmpty) {
        for (final recurrenceTime in task.recurrence!.times) {
          final timeParts = recurrenceTime.time.split(':');
          if (timeParts.length == 2) {
            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);
            if (hour != null && minute != null) {
              uniqueTimes.add(TimeOfDay(hour: hour, minute: minute));
            }
          }
        }
      } else {
        uniqueTimes.add(
          TimeOfDay(hour: task.date.hour, minute: task.date.minute),
        );
      }
    }

    final sortedTimes = uniqueTimes.toList()
      ..sort((a, b) => a.hour * 60 + a.minute - (b.hour * 60 + b.minute));

    return sortedTimes;
  }

  /// 반복 일정 생성
  static List<Task> generateRecurringTasks({
    required String title,
    required List<bool> selectedDays,
    required List<TimeOfDay> times,
    required DateTime endDate,
    String category = TaskCategories.general,
    bool isImportant = false,
  }) {
    final List<Task> generatedTasks = [];
    final now = DateTime.now();

    if (times.isEmpty || !selectedDays.contains(true)) {
      return generatedTasks;
    }

    // 종료일을 하루 뒤로 설정하여 당일 포함 (23:59:59까지)
    final effectiveEndDate = DateTime(
      endDate.year,
      endDate.month,
      endDate.day + 1,
    ).subtract(const Duration(seconds: 1));

    debugPrint('🗓️ 반복 일정 생성: $title');
    debugPrint('  - 종료일: $endDate -> 실제 검사: $effectiveEndDate');
    debugPrint('  - 현재 시간: $now');

    // 반복 정보 생성
    final recurrenceInfo = RecurrenceInfo(
      type: 'custom_days',
      times: times
          .map(
            (time) => RecurrenceTime(
              time:
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              label: RecurringTaskConstants.formatTime12Hour(time),
            ),
          )
          .toList(),
      endDate: endDate,
      daysOfWeek: selectedDays
          .asMap()
          .entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList(),
    );

    // 고유 ID 생성용 카운터
    int taskCounter = 0;

    // 반복 일정 생성 (최대 1년)
    for (int i = 0; i < RecurringTaskConstants.maxRecurrenceDays; i++) {
      final currentDate = now.add(Duration(days: i));
      final weekday = currentDate.weekday - 1; // 0=월요일, 6=일요일

      if (weekday >= 0 &&
          weekday < selectedDays.length &&
          selectedDays[weekday]) {
        for (final time in times) {
          final taskDateTime = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
            time.hour,
            time.minute,
          );

          // 개선된 날짜/시간 검증
          final isWithinEndDate =
              taskDateTime.isBefore(effectiveEndDate) ||
              taskDateTime.isAtSameMomentAs(effectiveEndDate);
          final isFutureTime = taskDateTime.isAfter(now);

          if (isWithinEndDate && isFutureTime) {
            // 안전한 ID 생성
            final uniqueId = RecurringTaskConstants.generateSafeTaskId(
              prefix: 'RT', // RecurringTask
              counter: taskCounter,
            );

            final task = Task(
              id: uniqueId,
              title: title,
              date: taskDateTime,
              isImportant: isImportant,
              category: category,
              isRecurring: true,
              recurrence: recurrenceInfo,
            );
            generatedTasks.add(task);
            taskCounter++;

            debugPrint('  ✅ 일정 생성: $taskDateTime (ID: $uniqueId)');
          } else {
            debugPrint(
              '  ❌ 일정 제외: $taskDateTime (종료일 초과: ${!isWithinEndDate}, 과거 시간: ${!isFutureTime})',
            );
          }
        }
      }
    }

    debugPrint('📅 총 생성된 일정: ${generatedTasks.length}개');
    return generatedTasks;
  }

  /// 종료일 추출
  static DateTime? extractEndDateFromTasks(List<Task> tasks) {
    if (tasks.isEmpty) return null;
    DateTime? maxEnd;
    for (final task in tasks) {
      final end = task.recurrence?.endDate;
      if (end != null) {
        if (maxEnd == null || end.isAfter(maxEnd)) {
          maxEnd = end;
        }
      }
    }
    return maxEnd ?? RecurringTaskConstants.defaultEndDate;
  }

  /// 날짜 유효성 검사
  static bool isValidEndDate(DateTime endDate) {
    return endDate.isAfter(DateTime.now());
  }

  /// 요일 선택 유효성 검사
  static bool isValidDaySelection(List<bool> selectedDays) {
    return selectedDays.contains(true);
  }

  /// 제목 유효성 검사
  static bool isValidTitle(String title) {
    return title.trim().isNotEmpty;
  }

  /// 안전한 날짜 파싱
  static DateTime? parseDate(String year, String month, String day) {
    try {
      final yearInt = int.parse(year);
      final monthInt = int.parse(month);
      final dayInt = int.parse(day);

      // 기본적인 범위 검사
      if (yearInt < 2020 || yearInt > 2100) return null;
      if (monthInt < 1 || monthInt > 12) return null;
      if (dayInt < 1 || dayInt > 31) return null;

      return DateTime(yearInt, monthInt, dayInt);
    } catch (e) {
      debugPrint('날짜 파싱 오류: $year-$month-$day');
      return null;
    }
  }
}
