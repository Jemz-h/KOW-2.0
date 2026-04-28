import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'mock_background.dart';

enum BackendFeedbackTone { loading, success, warning, error }

class BackendFeedbackOverlay extends StatefulWidget {
  const BackendFeedbackOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.tone,
    this.showSpinner = false,
    this.buttonLabel = 'OK',
    this.secondaryButtonLabel,
    this.onButtonPressed,
    this.onSecondaryPressed,
    this.loadingMessages = const <String>[],
  });

  final String title;
  final String message;
  final BackendFeedbackTone tone;
  final bool showSpinner;
  final String buttonLabel;
  final String? secondaryButtonLabel;
  final VoidCallback? onButtonPressed;
  final VoidCallback? onSecondaryPressed;
  final List<String> loadingMessages;

  static Future<void> showMessage({
    required BuildContext context,
    required String title,
    required String message,
    BackendFeedbackTone tone = BackendFeedbackTone.warning,
    String buttonLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (dialogContext) => BackendFeedbackOverlay(
        title: title,
        message: message,
        tone: tone,
        buttonLabel: buttonLabel,
        onButtonPressed: () => Navigator.of(dialogContext).pop(),
      ),
    );
  }

  static Future<bool?> showChoice({
    required BuildContext context,
    required String title,
    required String message,
    BackendFeedbackTone tone = BackendFeedbackTone.success,
    String primaryLabel = 'OK',
    String secondaryLabel = 'Stay Here',
    bool barrierDismissible = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      builder: (dialogContext) => BackendFeedbackOverlay(
        title: title,
        message: message,
        tone: tone,
        buttonLabel: primaryLabel,
        secondaryButtonLabel: secondaryLabel,
        onButtonPressed: () => Navigator.of(dialogContext).pop(true),
        onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
      ),
    );
  }

  static Future<T> runWithLoading<T>({
    required BuildContext context,
    required Future<T> Function() task,
    String title = 'SYNCING',
    String message = 'Preparing your KOW adventure...',
    List<String> loadingMessages = const <String>[
      'Checking saved progress',
      'Syncing questions',
      'Updating learner records',
    ],
  }) async {
    var closed = false;
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.55),
        builder: (_) => BackendFeedbackOverlay(
          title: title,
          message: message,
          tone: BackendFeedbackTone.loading,
          showSpinner: true,
          loadingMessages: loadingMessages,
        ),
      ).whenComplete(() => closed = true),
    );

    try {
      return await task();
    } finally {
      if (context.mounted && !closed) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  State<BackendFeedbackOverlay> createState() => _BackendFeedbackOverlayState();
}

class _BackendFeedbackOverlayState extends State<BackendFeedbackOverlay> {
  Timer? _timer;
  int _messageIndex = 0;
  double _progress = 0.18;

  @override
  void initState() {
    super.initState();
    if (widget.showSpinner && widget.loadingMessages.isNotEmpty) {
      _timer = Timer.periodic(const Duration(milliseconds: 950), (_) {
        if (!mounted) return;
        setState(() {
          _messageIndex = (_messageIndex + 1) % widget.loadingMessages.length;
          _progress = (_progress + 0.17).clamp(0.18, 0.94);
          if (_progress >= 0.94) {
            _progress = 0.32;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _accentColor {
    return switch (widget.tone) {
      BackendFeedbackTone.loading => const Color(0xFF45D9FF),
      BackendFeedbackTone.success => const Color(0xFF48E088),
      BackendFeedbackTone.warning => const Color(0xFFFFD45A),
      BackendFeedbackTone.error => const Color(0xFFFF5A68),
    };
  }

  IconData get _icon {
    return switch (widget.tone) {
      BackendFeedbackTone.loading => Icons.sync_rounded,
      BackendFeedbackTone.success => Icons.check_circle_rounded,
      BackendFeedbackTone.warning => Icons.wifi_tethering_error_rounded,
      BackendFeedbackTone.error => Icons.error_rounded,
    };
  }

  String get _assetPath {
    final theme = selectedThemeNotifier.value.toLowerCase();
    if (theme.contains('classroom')) {
      return 'assets/misc/backend_feedback_classroom.svg';
    }
    if (theme.contains('sauyo')) {
      return 'assets/misc/backend_feedback_sauyo.svg';
    }
    return 'assets/misc/backend_feedback_space.svg';
  }

  Color get _cardColor {
    final theme = selectedThemeNotifier.value.toLowerCase();
    if (theme.contains('classroom')) {
      return const Color(0xFFFFF7D8);
    }
    if (theme.contains('sauyo')) {
      return const Color(0xFFFFF1E4);
    }
    return const Color(0xFFF2F7FF);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final scale = (media.size.width / 412).clamp(0.86, 1.16);
    final activeLoadingText = widget.loadingMessages.isEmpty
        ? widget.message
        : widget.loadingMessages[_messageIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.9, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0, 1), child: child),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _accentColor, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22 * scale,
                  18 * scale,
                  22 * scale,
                  22 * scale,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: -3, end: 3),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, widget.showSpinner ? value : 0),
                          child: child,
                        );
                      },
                      child: SvgPicture.asset(
                        _assetPath,
                        height: 116 * scale,
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * scale,
                        vertical: 7 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_icon, color: _accentColor, size: 20 * scale),
                          SizedBox(width: 7 * scale),
                          Text(
                            widget.title.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SuperCartoon',
                              fontSize: 16 * scale,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF17172E),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      child: Text(
                        widget.showSpinner ? activeLoadingText : widget.message,
                        key: ValueKey(
                          widget.showSpinner
                              ? activeLoadingText
                              : widget.message,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'SuperCartoon',
                          fontSize: 15 * scale,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                          color: const Color(0xFF2D2D2D),
                        ),
                      ),
                    ),
                    SizedBox(height: 18 * scale),
                    if (widget.showSpinner) ...[
                      SizedBox(
                        width: 34 * scale,
                        height: 34 * scale,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: _accentColor,
                          backgroundColor: const Color(
                            0xFF17172E,
                          ).withValues(alpha: 0.12),
                        ),
                      ),
                      SizedBox(height: 14 * scale),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 10 * scale,
                          color: _accentColor,
                          backgroundColor: const Color(
                            0xFF17172E,
                          ).withValues(alpha: 0.12),
                        ),
                      ),
                    ] else
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if (widget.secondaryButtonLabel != null)
                            _DialogButton(
                              label: widget.secondaryButtonLabel!,
                              scale: scale,
                              color: const Color(0xFFFFFFFF),
                              foreground: const Color(0xFF17172E),
                              onPressed: widget.onSecondaryPressed,
                            ),
                          _DialogButton(
                            label: widget.buttonLabel,
                            scale: scale,
                            color: _accentColor,
                            foreground: const Color(0xFF17172E),
                            onPressed: widget.onButtonPressed,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (!widget.showSpinner && widget.onButtonPressed != null)
              Positioned(
                top: -10,
                right: -10,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onButtonPressed,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: _accentColor, width: 3),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF17172E),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.scale,
    required this.color,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final double scale;
  final Color color;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140 * scale,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          padding: EdgeInsets.symmetric(vertical: 12 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 3,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SuperCartoon',
            fontSize: 15 * scale,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
