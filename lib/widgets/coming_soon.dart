import 'package:flutter/material.dart';

/// Shows the "OOPS!" coming-soon dialog (Image 3 left).
///
/// Light-cyan card with construction mascot, message, and a RETURN button.
void showComingSoonPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFFB8F0F7), // light cyan
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
                'OOPS!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SuperCartoon',
                  fontSize: 38,
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

              // Mascot image
              Image.asset(
                'assets/sisa_oyo/coming_soon.png',
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Image.asset(
                  'assets/sisa_oyo/oyo.png',
                  height: 140,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // Message
              const Text(
                'THAT FEATURE IS\nUNDER DEVELOPMENT.\nSTAY TUNED!',
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

              // Return button
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
                    'RETURN',
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
