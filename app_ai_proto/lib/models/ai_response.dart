class AIResponse {
  final bool success;
  final String? userText;
  final ProcessingResult? processingResult;
  final String? responseText;
  final double? processingTime;
  final String timestamp;

  // 구형 응답 구조 호환성을 위한 필드들
  final AIAction? action;
  final TextResponse? textResponse;

  AIResponse({
    required this.success,
    this.userText,
    this.processingResult,
    this.responseText,
    this.processingTime,
    required this.timestamp,
    this.action,
    this.textResponse,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 AIResponse.fromJson 파싱 시작');
    print('🔍 JSON 데이터: $json');

    final success = json['success'] ?? false;
    print('🔍 success 값: $success (타입: ${success.runtimeType})');

    final userText = json['user_text'];
    print('🔍 userText: $userText');

    final processingResult = json['processing_result'] != null
        ? ProcessingResult.fromJson(json['processing_result'])
        : null;
    print('🔍 processingResult 파싱 완료: ${processingResult?.action}');

    // response_text는 문자열 또는 객체로 올 수 있음
    String? responseText;
    final rt = json['response_text'];
    if (rt is String) {
      responseText = rt;
    } else if (rt is Map<String, dynamic>) {
      responseText = rt['text']?.toString();
    }
    print('🔍 responseText: $responseText');

    // processing_time은 number 또는 string으로 올 수 있음
    double? processingTime;
    final pt = json['processing_time'];
    if (pt is num) {
      processingTime = pt.toDouble();
    } else if (pt is String) {
      processingTime = double.tryParse(pt);
    }
    print('🔍 processingTime: $processingTime');

    final timestamp = json['timestamp'] ?? '';
    print('🔍 timestamp: $timestamp');

    // 구형 응답 구조 처리 (action + text_response)
    AIAction? action;
    TextResponse? textResponse;
    
    print('🔍 JSON 키들: ${json.keys.toList()}');
    print('🔍 action 필드 존재 여부: ${json.containsKey('action')}');
    print('🔍 text_response 필드 존재 여부: ${json.containsKey('text_response')}');

    if (json.containsKey('action')) {
      print('🔍 구형 action 발견');
      print('🔍 action 데이터: ${json['action']}');
      try {
        action = AIAction.fromJson(json['action']);
        print('🔍 AIAction 파싱 성공 - type: ${action?.type}');
      } catch (e) {
        print('❌ AIAction 파싱 실패: $e');
        action = null;
      }
    } else {
      print('⚠️ action 필드 없음');
    }

    if (json.containsKey('text_response')) {
      print('🔍 구형 text_response 발견');
      print('🔍 text_response 데이터: ${json['text_response']}');
      try {
        textResponse = TextResponse.fromJson(json['text_response']);
        print('🔍 TextResponse 파싱 성공 - text: ${textResponse?.text}');
      } catch (e) {
        print('❌ TextResponse 파싱 실패: $e');
        textResponse = null;
      }
    } else {
      print('⚠️ text_response 필드 없음');
    }

    final response = AIResponse(
      success: success,
      userText: userText,
      processingResult: processingResult,
      responseText: responseText,
      processingTime: processingTime,
      timestamp: timestamp,
      action: action,
      textResponse: textResponse,
    );

    print('🔍 AIResponse 생성 완료 - success: ${response.success}');
    return response;
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user_text': userText,
      'processing_result': processingResult?.toJson(),
      'response_text': responseText,
      'processing_time': processingTime,
      'timestamp': timestamp,
      'action': action?.toJson(),
      'text_response': textResponse?.toJson(),
    }..removeWhere((k, v) => v == null);
  }
}

class ProcessingResult {
  final String action;
  final Map<String, dynamic> result;

  ProcessingResult({required this.action, required this.result});

  factory ProcessingResult.fromJson(Map<String, dynamic> json) {
    print('🔍 ProcessingResult.fromJson 시작');
    print('🔍 JSON 데이터: $json');

    final action = json['action'] ?? '';
    final dynamic rawResult = json['result'];
    final Map<String, dynamic> result = rawResult is Map
        ? Map<String, dynamic>.from(rawResult)
        : <String, dynamic>{};

    print('🔍 action: $action');
    print('🔍 result: $result');
    print('🔍 result 타입: ${result.runtimeType}');

    if (result is Map<String, dynamic>) {
      print('🔍 result 키들: ${result.keys.toList()}');
      if (result.containsKey('schedule_data')) {
        print('🔍 schedule_data 발견: ${result['schedule_data']}');
      }
    }

    final processingResult = ProcessingResult(action: action, result: result);

    print('🔍 ProcessingResult 생성 완료 - action: ${processingResult.action}');
    return processingResult;
  }

  Map<String, dynamic> toJson() {
    return {'action': action, 'result': result};
  }
}

class AIAction {
  final String type;
  final String priority;
  final bool isImportant;
  final Map<String, dynamic> data;
  final UIInstructions uiInstructions;

  AIAction({
    required this.type,
    required this.priority,
    required this.isImportant,
    required this.data,
    required this.uiInstructions,
  });

  factory AIAction.fromJson(Map<String, dynamic> json) {
    print('🔍 AIAction.fromJson 시작');
    print('🔍 AIAction JSON 데이터: $json');
    
    final type = json['type'] ?? '';
    final priority = json['priority'] ?? 'medium';
    final isImportant = json['is_important'] == true;
    
    final dynamic rawData = json['data'];
    final Map<String, dynamic> data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    
    print('🔍 AIAction 파싱 결과:');
    print('  - type: $type');
    print('  - priority: $priority');
    print('  - isImportant: $isImportant');
    print('  - data 키들: ${data.keys.toList()}');
    
    final uiInstructions = UIInstructions.fromJson(json['ui_instructions'] ?? {});
    print('🔍 UIInstructions 파싱 완료');
    
    final result = AIAction(
      type: type,
      priority: priority,
      isImportant: isImportant,
      data: data,
      uiInstructions: uiInstructions,
    );
    
    print('🔍 AIAction 생성 완료 - type: ${result.type}');
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'priority': priority,
      'is_important': isImportant,
      'data': data,
      'ui_instructions': uiInstructions.toJson(),
    };
  }
}

class TextResponse {
  final String text;
  final bool
  displayAutomatically; // playAutomatically를 displayAutomatically로 변경

  TextResponse({required this.text, required this.displayAutomatically});

  factory TextResponse.fromJson(Map<String, dynamic> json) {
    return TextResponse(
      text: json['text'] ?? '',
      displayAutomatically: json['display_automatically'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'display_automatically': displayAutomatically};
  }
}

class UIInstructions {
  final String? screen;
  final bool? refreshData;
  final bool? showConfirmation;
  final bool? showVisualList;  // 시각적 목록 표시
  final bool? groupByDate;     // 날짜별 그룹핑
  final bool? highlightImportant; // 중요한 일정 강조
  final int? totalCount;       // 총 일정 개수
  final String? searchKeyword; // 검색 키워드
  final Map<String, dynamic>? dateRange; // 날짜 범위
  final NotificationInfo? notification;

  UIInstructions({
    this.screen,
    this.refreshData,
    this.showConfirmation,
    this.showVisualList,
    this.groupByDate,
    this.highlightImportant,
    this.totalCount,
    this.searchKeyword,
    this.dateRange,
    this.notification,
  });

  factory UIInstructions.fromJson(Map<String, dynamic> json) {
    print('🔍 UIInstructions.fromJson 시작');
    print('🔍 json 데이터: $json');
    
    final showVisualList = json['show_visual_list'];
    print('🔍 show_visual_list 원본값: $showVisualList (타입: ${showVisualList.runtimeType})');
    
    final result = UIInstructions(
      screen: json['screen'],
      refreshData: json['refresh_data'],
      showConfirmation: json['show_confirmation'],
      showVisualList: showVisualList,
      groupByDate: json['group_by_date'],
      highlightImportant: json['highlight_important'],
      totalCount: json['total_count'],
      searchKeyword: json['search_keyword'],
      dateRange: json['date_range'] != null 
          ? Map<String, dynamic>.from(json['date_range'])
          : null,
      notification: json['notification'] != null
          ? NotificationInfo.fromJson(json['notification'])
          : null,
    );
    
    print('🔍 UIInstructions 생성 완료 - showVisualList: ${result.showVisualList}');
    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'screen': screen,
      'refresh_data': refreshData,
      'show_confirmation': showConfirmation,
      'show_visual_list': showVisualList,
      'group_by_date': groupByDate,
      'highlight_important': highlightImportant,
      'total_count': totalCount,
      'search_keyword': searchKeyword,
      'date_range': dateRange,
      'notification': notification?.toJson(),
    }..removeWhere((k, v) => v == null);
  }
}

class NotificationInfo {
  final String type; // 'success', 'error', 'info'
  final String title;
  final String message;
  final int? duration;

  NotificationInfo({
    required this.type,
    required this.title,
    required this.message,
    this.duration,
  });

  factory NotificationInfo.fromJson(Map<String, dynamic> json) {
    return NotificationInfo(
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'message': message,
      'duration': duration,
    }..removeWhere((k, v) => v == null);
  }
}
