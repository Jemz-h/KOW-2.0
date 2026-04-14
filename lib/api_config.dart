import 'package:flutter/foundation.dart';

/// Central API configuration.
/// Change [baseUrl] to match your backend host/port.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the KOW Node.js backend.
  /// Priority:
  /// 1) --dart-define=API_BASE_URL=...
  /// 2) Platform-aware local defaults on port 3010.
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      return 'http://localhost:3010';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://localhost:3010';
      default:
        return 'http://localhost:3010';
    }
  }
}
