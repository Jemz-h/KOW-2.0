import 'package:flutter/material.dart';

/// Simple label for form sections.
class FormLabel extends StatelessWidget {
  const FormLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF2D2D2D),
        ),
      ),
    );
  }
}

/// Editable field style for form inputs.
class LightField extends StatelessWidget {
  const LightField({
    super.key,
    required this.hintText,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
  });

  final String hintText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 12, color: Color(0xFF2D2D2D)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9B9B9B)),
          border: InputBorder.none,
          isDense: true,
          prefixIcon: prefixIcon == null
              ? null
              : Icon(prefixIcon, size: 18, color: const Color(0xFF6B6B6B)),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}

/// Gender selection card used in the welcome student form.
class SexCard extends StatelessWidget {
  const SexCard({
    super.key,
    required this.imagePath,
    required this.label,
    required this.backgroundColor,
    required this.selected,
    this.onTap,
  });

  final String imagePath;
  final String label;
  final Color backgroundColor;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? const Color(0xFF2ECC71) : Colors.transparent,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Image.asset(imagePath, height: 46),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          if (selected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xAA1B1B1B),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          if (selected)
            Positioned.fill(
              child: Center(
                child: Image.asset(
                  'assets/images/gender_check.png',
                  width: 44,
                  height: 44,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
