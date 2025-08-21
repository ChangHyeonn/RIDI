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

    if (json.containsKey('action')) {
      print('🔍 구형 action 발견');
      action = AIAction.fromJson(json['action']);
    }

    if (json.containsKey('text_response')) {
      print('🔍 구형 text_response 발견');
      textResponse = TextResponse.fromJson(json['text_response']);
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
    final dynamic rawData = json['data'];
    final Map<String, dynamic> data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};
    return AIAction(
      type: json['type'] ?? '',
      priority: json['priority'] ?? 'medium',
      isImportant: json['is_important'] == true,
      data: data,
      uiInstructions: UIInstructions.fromJson(json['ui_instructions'] ?? {}),
    );
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
  final NotificationInfo? notification;

  UIInstructions({
    this.screen,
    this.refreshData,
    this.showConfirmation,
    this.notification,
  });

  factory UIInstructions.fromJson(Map<String, dynamic> json) {
    return UIInstructions(
      screen: json['screen'],
      refreshData: json['refresh_data'],
      showConfirmation: json['show_confirmation'],
      notification: json['notification'] != null
          ? NotificationInfo.fromJson(json['notification'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'screen': screen,
      'refresh_data': refreshData,
      'show_confirmation': showConfirmation,
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
