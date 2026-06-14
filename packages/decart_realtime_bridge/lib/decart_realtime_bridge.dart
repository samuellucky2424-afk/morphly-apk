import 'dart:async';

import 'package:flutter/services.dart';

enum DecartConnectionState {
  idle,
  starting,
  connected,
  stopping,
  stopped,
  failed;

  static DecartConnectionState fromString(String? value) {
    return DecartConnectionState.values.firstWhere(
      (state) => state.name == value,
      orElse: () => DecartConnectionState.idle,
    );
  }
}

class DecartSessionConfig {
  const DecartSessionConfig({
    required this.sessionId,
    required this.clientToken,
    required this.model,
    required this.referenceImagePath,
    required this.prompt,
    required this.quality,
  });

  final String sessionId;
  final String clientToken;
  final String model;
  final String referenceImagePath;
  final String prompt;
  final String quality;

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'clientToken': clientToken,
      'model': model,
      'referenceImagePath': referenceImagePath,
      'prompt': prompt,
      'quality': quality,
    };
  }
}

class DecartBridgeEvent {
  const DecartBridgeEvent({
    required this.state,
    this.message,
    this.elapsedSeconds = 0,
  });

  final DecartConnectionState state;
  final String? message;
  final int elapsedSeconds;

  factory DecartBridgeEvent.fromMap(Map<dynamic, dynamic> map) {
    return DecartBridgeEvent(
      state: DecartConnectionState.fromString(map['state'] as String?),
      message: map['message'] as String?,
      elapsedSeconds: map['elapsedSeconds'] as int? ?? 0,
    );
  }
}

class DecartRealtimeBridge {
  DecartRealtimeBridge._();

  static const MethodChannel _methods =
      MethodChannel('morphly/decart_realtime/methods');
  static const EventChannel _events =
      EventChannel('morphly/decart_realtime/events');

  static Stream<DecartBridgeEvent>? _eventStream;

  static Stream<DecartBridgeEvent> get events {
    return _eventStream ??= _events.receiveBroadcastStream().map((event) {
      if (event is Map) return DecartBridgeEvent.fromMap(event);
      return const DecartBridgeEvent(
        state: DecartConnectionState.failed,
        message: 'Invalid Decart bridge event.',
      );
    });
  }

  static Future<void> startSession(DecartSessionConfig config) {
    return _methods.invokeMethod<void>('startSession', config.toMap());
  }

  static Future<void> setPrompt(String prompt) {
    return _methods.invokeMethod<void>('setPrompt', {'prompt': prompt});
  }

  static Future<void> stopSession() {
    return _methods.invokeMethod<void>('stopSession');
  }
}
