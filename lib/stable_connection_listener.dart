import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Listens for stable WiFi/internet connection over a minimum duration.
/// Fires callback when stable connection is detected.
class StableConnectionListener {
  static const Duration _defaultStabilityDuration = Duration(seconds: 12);

  final Connectivity _connectivity = Connectivity();
  final Duration _stabilityDuration;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _stabilityTimer;

  bool _isOnline = false;
  bool _hasStableConnection = false;
  VoidCallback? _onStableConnection;

  /// Track if we've already triggered the callback in this session
  bool _alreadyTriggered = false;

  StableConnectionListener({
    Duration stabilityDuration = _defaultStabilityDuration,
  }) : _stabilityDuration = stabilityDuration;

  /// Start listening for stable connection
  /// Only calls [onStableConnection] once per session
  Future<void> startListening({
    required VoidCallback onStableConnection,
    bool triggerImmediatelyIfOnline = false,
  }) async {
    _subscription?.cancel();
    _stabilityTimer?.cancel();
    _onStableConnection = onStableConnection;
    _alreadyTriggered = false;
    _hasStableConnection = false;

    // Check current connectivity state
    final currentConnectivity = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(currentConnectivity);

    // If already online and flag set, fire immediately after brief delay
    if (_isOnline && triggerImmediatelyIfOnline && !_alreadyTriggered) {
      _triggerCallback();
      return;
    }

    // If online, start stability timer
    if (_isOnline) {
      _resetStabilityTimer();
    }

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
  }

  /// Stop listening and clean up
  void stopListening() {
    _subscription?.cancel();
    _stabilityTimer?.cancel();
  }

  /// Check if stable connection has been detected
  bool get hasDetectedStableConnection => _hasStableConnection;

  /// Check if currently online
  bool get isCurrentlyOnline => _isOnline;

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = _isConnected(results);

    if (_isOnline && !wasOnline) {
      // Came back online - start stability timer
      _resetStabilityTimer();
    } else if (!_isOnline && wasOnline) {
      // Went offline - cancel timer
      _stabilityTimer?.cancel();
      _hasStableConnection = false;
    }
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }

  void _resetStabilityTimer() {
    _stabilityTimer?.cancel();
    _stabilityTimer = Timer(_stabilityDuration, () {
      _hasStableConnection = true;
      if (!_alreadyTriggered) {
        _triggerCallback();
      }
    });
  }

  void _triggerCallback() {
    _alreadyTriggered = true;
    _onStableConnection?.call();
  }
}
