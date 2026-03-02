import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        style: const TextStyle(fontSize: 12, color: Color(0xFF2D2D2D)),
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
      height: 62,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w300,
          height: 1.1,
          color: Color(0xFF2D2D2D),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w300,
            height: 1.1,
            color: Color(0xFF9B9B9B),
          ),
          border: InputBorder.none,
          isDense: true,
          constraints: const BoxConstraints(minHeight: 62),
          prefixIcon: prefixIcon == null
              ? null
              : Icon(prefixIcon, size: 24, color: const Color(0xFF6B6B6B)),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

/// Gender selection card used in the welcome student form.
class SexCard extends StatelessWidget {
  const SexCard({
    super.key,
    required this.iconPath,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String iconPath;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: selected ? 1.0 : 0.72,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 110,
            height: 94,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? const Color(0xFF2ECC71) : Colors.transparent,
                width: 2,
              ),
            ),
            child: SvgPicture.asset(iconPath, height: 72),
          ),
        ),
      ),
    );
  }
}
