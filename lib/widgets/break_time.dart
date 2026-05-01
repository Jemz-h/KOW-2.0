import 'dart:async';

import 'package:flutter/material.dart';

const Duration kBreakTimeDuration = Duration(minutes: 20);
const RadialGradient kBreakTimeCardGradient = RadialGradient(
  center: Alignment(0, -0.08),
  radius: 1.02,
  colors: [
    Color(0xFFF8FFF9),
    Color(0xFFE6F7EA),
    Color(0xFF8CB195),
  ],
  stops: [0.0, 0.52, 1.0],
);
const Color kBreakTimeTimerColor = Color(0xFF80BE99);
const Color kBreakTimeTimerBorderColor = Color(0xBFE8FFF0);
const Color kBreakTimeRestingButtonColor = Color(0xFF9CB9A1);
const Color kBreakTimeRestingTextColor = Color(0xFF5E7E68);
const Color kBreakTimeContinueButtonColor = Color(0xFFFFC86A);

Future<void> showBreakTimePopup(
  BuildContext context, {
  Duration duration = kBreakTimeDuration,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BreakTimeDialog(duration: duration),
  );
}

class _BreakTimeDialog extends StatefulWidget {
  const _BreakTimeDialog({required this.duration});

  final Duration duration;

  @override
  State<_BreakTimeDialog> createState() => _BreakTimeDialogState();
}

class _BreakTimeDialogState extends State<_BreakTimeDialog> {
  Timer? _timer;
  late Duration _remaining = widget.duration;

  bool get _finished => _remaining.inSeconds <= 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final next = _remaining - const Duration(seconds: 1);
        _remaining = next.isNegative ? Duration.zero : next;
      });
      if (_finished) {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final minutes = _remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 42, vertical: 80),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          gradient: kBreakTimeCardGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _finished ? 'BREAK DONE!' : 'BREAK TIME!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'SuperCartoon',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 3,
                    color: Colors.black45,
                    offset: Offset(1, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
              decoration: BoxDecoration(
                color: kBreakTimeTimerColor,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: kBreakTimeTimerBorderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                _timeLabel,
                style: const TextStyle(
                  fontFamily: 'SuperCartoon',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox.square(
              dimension: 178,
              child: Image.asset(
                'assets/sisa_oyo/sisabreaktime.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/sisa_oyo/sisa.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _finished
                  ? 'SISA IS READY.\nLET US CONTINUE!'
                  : 'REST YOUR EYES.\nLOOK FAR AWAY AND\nMOVE AROUND FOR A WHILE!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'SuperCartoon',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black45,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: 170,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _finished
                      ? kBreakTimeContinueButtonColor
                      : kBreakTimeRestingButtonColor,
                  disabledBackgroundColor: kBreakTimeRestingButtonColor,
                  disabledForegroundColor: kBreakTimeRestingTextColor,
                  foregroundColor: const Color(0xFF2D2D2D),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: _finished ? 4 : 0,
                ),
                onPressed: _finished ? () => Navigator.of(context).pop() : null,
                child: Text(
                  _finished ? 'CONTINUE' : 'RESTING',
                  style: const TextStyle(
                    fontFamily: 'SuperCartoon',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
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
