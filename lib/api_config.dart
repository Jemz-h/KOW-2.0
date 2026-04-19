import 'package:flutter/foundation.dart';

/// Central API configuration.
/// Change [baseUrl] to match your backend host/port.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the KOW Node.js backend.
  /// Priority:
  /// 1) --dart-define=API_BASE_URL=...
  /// 2) Platform-aware local defaults for the PM2 Oracle backend on port 3000.
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) {
      return configured;
    }

    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator reaches the Windows host through 10.0.2.2.
        return 'http://10.0.2.2:3000';
      default:
        return 'http://localhost:3000';
    }
  }
}
