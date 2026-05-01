import 'dart:async';

import 'package:flutter/material.dart';

const Duration kBreakTimeDuration = Duration(minutes: 20);

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
          color: const Color(0xFF9BC7A4),
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF70B78C),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
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
            Image.asset(
              'assets/sisa_oyo/sisaGOD.png',
              height: 130,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/sisa_oyo/sisa.png',
                height: 130,
                fit: BoxFit.contain,
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
                      ? const Color(0xFFFFCC44)
                      : const Color(0xFFE8E8E8),
                  foregroundColor: const Color(0xFF2D2D2D),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
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
