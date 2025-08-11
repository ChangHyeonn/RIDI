class AIResponse {
  final bool success;
  final AIAction? action;
  final VoiceResponse? voiceResponse;
  final String timestamp;

  AIResponse({
    required this.success,
    this.action,
    this.voiceResponse,
    required this.timestamp,
  });

  factory AIResponse.fromJson(Map<String, dynamic> json) {
    return AIResponse(
      success: json['success'] ?? false,
      action: json['action'] != null ? AIAction.fromJson(json['action']) : null,
      voiceResponse: json['voice_response'] != null
          ? VoiceResponse.fromJson(json['voice_response'])
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

class VoiceResponse {
  final String text;
  final bool playAutomatically;
  final String? audioUrl;

  VoiceResponse({
    required this.text,
    required this.playAutomatically,
    this.audioUrl,
  });

  factory VoiceResponse.fromJson(Map<String, dynamic> json) {
    return VoiceResponse(
      text: json['text'] ?? '',
      playAutomatically: json['play_automatically'] ?? false,
      audioUrl: json['audio_url'],
    );
  }
}

class UIInstructions {
  final String? screen;
  final String? highlightDate;
  final bool? showConfirmation;
  final String? removeItem;
  final bool? refreshData;
  final bool? showInputPrompt;
  final bool? showVoiceIndicator;

  UIInstructions({
    this.screen,
    this.highlightDate,
    this.showConfirmation,
    this.removeItem,
    this.refreshData,
    this.showInputPrompt,
    this.showVoiceIndicator,
  });

  factory UIInstructions.fromJson(Map<String, dynamic> json) {
    return UIInstructions(
      screen: json['screen'],
      highlightDate: json['highlight_date'],
      showConfirmation: json['show_confirmation'],
      removeItem: json['remove_item'],
      refreshData: json['refresh_data'],
      showInputPrompt: json['show_input_prompt'],
      showVoiceIndicator: json['show_voice_indicator'],
    );
  }
}
