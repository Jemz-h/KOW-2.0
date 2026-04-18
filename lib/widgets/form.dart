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

/// Shared KOW text field with consistent fixed height and typography.
class KowTextField extends StatelessWidget {
  const KowTextField({
    super.key,
    required this.hintText,
    this.controller,
    this.keyboardType,
    this.prefixIcon,
    this.prefixIconWidget,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    this.validator,
    this.height = 56,
    this.fontSize = 24,
    this.borderRadius = 16,
    this.fillColor = const Color(0xFFE0E0E0),
  });

  final String hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? prefixIconWidget;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final double height;
  final double fontSize;
  final double borderRadius;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final inputTextStyle = TextStyle(
      fontFamily: 'SuperCartoon',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF2D2D2D),
      height: 1.0,
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: 1,
        style: inputTextStyle,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          hintText: hintText,
          hintStyle: inputTextStyle.copyWith(color: const Color(0xFF9B9B9B)),
          prefixIcon: prefixIconWidget ??
              (prefixIcon == null
                  ? null
                  : Icon(
                      prefixIcon,
                      size: fontSize + 8,
                      color: const Color(0xFF6B6B6B),
                    )),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: const BorderSide(color: Color(0xFF0C8CE9), width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.red.shade700, width: 1.4),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide(color: Colors.red.shade700, width: 1.6),
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: fontSize * 0.65,
            vertical: (height - fontSize) / 2.4,
          ),
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
    this.controller,
  });

  final String hintText;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return KowTextField(
      hintText: hintText,
      controller: controller,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      readOnly: readOnly,
      onTap: onTap,
      height: 62,
      fontSize: 30,
      borderRadius: 12,
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
    this.width = 132,
    this.height = 112,
    this.iconHeight = 84,
    this.onTap,
  });

  final String iconPath;
  final String label;
  final bool selected;
  final double width;
  final double height;
  final double iconHeight;
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
            width: width,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? const Color(0xFF2ECC71) : Colors.transparent,
                width: 2,
              ),
            ),
            child: SvgPicture.asset(iconPath, height: iconHeight),
          ),
        ),
      ),
    );
  }
}
