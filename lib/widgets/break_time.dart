import 'package:flutter/material.dart';

/// Shows the "BREAK TIME!" dialog.
Future<void> showBreakTimePopup(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFFBCEED5), // mint green
            borderRadius: BorderRadius.circular(24),
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
              // Title
              const Text(
                'BREAK TIME!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SuperCartoon',
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2D2D2D),
                  shadows: [
                    Shadow(
                      blurRadius: 3,
                      color: Colors.black26,
                      offset: Offset(1, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mascot image (sleepy Sisa)
              Image.asset(
                'assets/sisa_oyo/sisaGOD.png',
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/sisa_oyo/sisa.png',
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // Message
              const Text(
                "SISA'S TIRED. GO\nOUT AND HAVE FUN\nWITH YOUR FRIENDS\nFOR A WHILE!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SuperCartoon',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                  color: Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 22),

              // Exit button
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFCC44),
                    foregroundColor: const Color(0xFF2D2D2D),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'EXIT',
                    style: TextStyle(
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
    },
  );
}
