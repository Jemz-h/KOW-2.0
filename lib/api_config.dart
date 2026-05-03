/// Central API configuration.
/// Change [baseUrl] to match your backend host/port.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the KOW Node.js backend.
  /// Priority:
  /// 1) --dart-define=API_BASE_URL=...
  /// 2) Live KOW API used by production builds and installed APKs.
  static String get baseUrl {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) {
      return normalizeBaseUrl(configured);
    }

    return 'https://kowapi-vgl.duckdns.org';
  }

  static String normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return trimmed;
    }

    return 'http://$trimmed';
  }
}
