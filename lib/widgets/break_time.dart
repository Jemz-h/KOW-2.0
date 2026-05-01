import 'dart:async';

import 'package:flutter/material.dart';

const Duration kBreakTimeDuration = Duration(minutes: 20);
const RadialGradient kBreakTimeCardGradient = RadialGradient(
  center: Alignment(0, -0.06),
  radius: 0.88,
  colors: [Color(0xFFF5FAF2), Color(0xFFBDD8BB), Color(0xFF85AA82)],
  stops: [0.08, 0.56, 1.0],
);
const Color kBreakTimeTimerColor = Color(0xFF6FBE87);
const Color kBreakTimeTimerBorderColor = Color(0xD8B5E0C1);
const Color kBreakTimeContinueButtonColor = Color(0xFFF7C86D);

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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth < 420 ? 252.0 : 272.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 54),
      child: SizedBox(
        width: cardWidth,
        child: AspectRatio(
          aspectRatio: 0.79,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = constraints.maxWidth / 252;

              return Container(
                padding: EdgeInsets.fromLTRB(
                  16 * scale,
                  12 * scale,
                  16 * scale,
                  13 * scale,
                ),
                decoration: BoxDecoration(
                  gradient: kBreakTimeCardGradient,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _finished ? 'BREAK DONE!' : 'BREAK TIME!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SuperCartoon',
                        fontSize: 19 * scale,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            blurRadius: 3,
                            color: Colors.black45,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 5 * scale),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18 * scale,
                        vertical: 4 * scale,
                      ),
                      decoration: BoxDecoration(
                        color: kBreakTimeTimerColor,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: kBreakTimeTimerBorderColor),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x24000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _timeLabel,
                        style: TextStyle(
                          fontFamily: 'SuperCartoon',
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 8 * scale),
                    SizedBox.square(
                      dimension: 145 * scale,
                      child: Image.asset(
                        'assets/sisa_oyo/sisabreaktime.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/sisa_oyo/sisa.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 4 * scale),
                    Text(
                      _finished
                          ? 'SISA IS READY.\nLET US CONTINUE!'
                          : 'SISA IS TIRED. GO OUT AND\nHAVE FUN WITH YOUR FRIENDS\nFOR A WHILE!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'SuperCartoon',
                        fontSize: 12 * scale,
                        fontWeight: FontWeight.w800,
                        height: 1.16,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black45,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 101 * scale,
                      height: 34 * scale,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBreakTimeContinueButtonColor,
                          foregroundColor: const Color(0xFF2D2D2D),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          elevation: 4,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          _finished ? 'CONTINUE' : 'EXIT',
                          style: TextStyle(
                            fontFamily: 'SuperCartoon',
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
