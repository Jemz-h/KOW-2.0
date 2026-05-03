import 'package:flutter_test/flutter_test.dart';
import 'package:kow/api_config.dart';

void main() {
  test('normalizes host and port into an http URL', () {
    expect(
      ApiConfig.normalizeBaseUrl('192.168.254.103:3000'),
      'http://192.168.254.103:3000',
    );
  });

  test('keeps fully qualified URLs unchanged', () {
    expect(
      ApiConfig.normalizeBaseUrl('https://kowapi-vgl.duckdns.org'),
      'https://kowapi-vgl.duckdns.org',
    );
  });
}