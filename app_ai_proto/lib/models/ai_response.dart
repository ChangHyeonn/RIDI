class AIResponse {
  final bool success;
  final AIAction? action;
  final TextResponse? textResponse; // voiceResponse를 textResponse로 변경
  final String timestamp;

  AIResponse({
    required this.success,
    this.action,
    this.textResponse,
    required this.timestamp,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      success: json['success'] ?? false,
      action: json['action'] != null ? AIAction.fromJson(json['action']) : null,
      textResponse: json['text_response'] != null
          ? TextResponse.fromJson(json['text_response'])
          : null,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class AIAction {
  final String type;
  final String priority;
  final Map<String, dynamic> data;
  final UIInstructions uiInstructions;

  AIAction({
    required this.type,
    required this.priority,
    required this.data,
    required this.uiInstructions,
  });

  factory AIAction.fromJson(Map<String, dynamic> json) {
    return AIAction(
      type: json['type'] ?? '',
      priority: json['priority'] ?? 'medium',
      data: json['data'] ?? {},
      uiInstructions: UIInstructions.fromJson(json['ui_instructions'] ?? {}),
    );
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
}
