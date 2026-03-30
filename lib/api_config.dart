/// Central API configuration.
/// Change [baseUrl] to match your backend host/port.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the KOW Node.js backend.
  /// Default is Android emulator host (10.0.2.2).
  /// For physical devices, pass --dart-define=API_BASE_URL=http://LAN_IP:3000
  /// Example: flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
