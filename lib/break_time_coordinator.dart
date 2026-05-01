import 'dart:async';

import 'package:flutter/material.dart';

import 'widgets/break_time.dart';

const Duration kBreakTimeTriggerInterval = Duration(minutes: 30);

class BreakTimeCoordinator {
  BreakTimeCoordinator._();

  static final BreakTimeCoordinator instance = BreakTimeCoordinator._();

  GlobalKey<NavigatorState>? _navigatorKey;
  Timer? _ticker;
  DateTime? _sessionStartedAt;
  DateTime? _lastBreakShownAt;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  bool _dialogVisible = false;

  void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey ??= navigatorKey;
    _sessionStartedAt ??= DateTime.now();
    _ticker ??= Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(checkNow()),
    );
  }

  void onResumed() {
    _lifecycleState = AppLifecycleState.resumed;
    _sessionStartedAt ??= DateTime.now();
    unawaited(checkNow());
  }

  void onPaused() {
    _lifecycleState = AppLifecycleState.paused;
  }

  Future<void> triggerNow() async {
    await checkNow(force: true);
  }

  Future<bool> checkNow({bool force = false}) async {
    if (_dialogVisible || _lifecycleState == AppLifecycleState.paused) {
      return false;
    }

    final context = _navigatorKey?.currentContext;
    if (context == null || !context.mounted) {
      return false;
    }

    final now = DateTime.now();
    final anchor = _lastBreakShownAt ?? _sessionStartedAt ?? now;
    if (!force && now.difference(anchor) < kBreakTimeTriggerInterval) {
      return false;
    }

    _dialogVisible = true;
    _lastBreakShownAt = now;
    try {
      await showBreakTimePopup(context);
      return true;
    } finally {
      _dialogVisible = false;
    }
  }

  void dispose() {
    _ticker?.cancel();
    _ticker = null;
  }
}
