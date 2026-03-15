/// Central API configuration.
/// Change [baseUrl] to match your backend host/port.
class ApiConfig {
  ApiConfig._();

  /// Base URL of the KOW Node.js backend.
  /// For Android emulator use http://10.0.2.2:3000
  /// For iOS simulator / physical device use your machine's LAN IP.
  static const String baseUrl = 'http://10.0.2.2:3000';
}
