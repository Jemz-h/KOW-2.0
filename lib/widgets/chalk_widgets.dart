import 'package:flutter/material.dart';

/// Chalk-styled text input used on the welcome back screen.
///
/// Supply either [icon] (an [IconData]) or [prefixIconWidget] (any widget) for
/// the leading icon. When [prefixIconWidget] is provided it takes precedence.
class ChalkTextField extends StatelessWidget {
  const ChalkTextField({
    super.key,
    required this.hintText,
    this.icon,
    this.prefixIconWidget,
    this.keyboardType,
    this.controller,
    this.validator,
    this.textStyle,
    this.hintStyle,
    this.contentPadding,
    this.iconSize,
  }) : assert(icon != null || prefixIconWidget != null,
            'Provide either icon or prefixIconWidget');

  final String hintText;
  final IconData? icon;
  /// Optional custom widget used as the prefix icon instead of [icon].
  final Widget? prefixIconWidget;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final EdgeInsetsGeometry? contentPadding;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final Widget resolvedPrefixIcon = prefixIconWidget ??
        Icon(icon!, color: const Color(0xFF7B7B7B), size: iconSize);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: textStyle,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hintText,
        hintStyle: hintStyle,
        prefixIcon: resolvedPrefixIcon,
        contentPadding:
            contentPadding ?? const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Chalk-styled dropdown input.
class ChalkDropdown extends StatefulWidget {
  const ChalkDropdown({
    super.key,
    required this.hintText,
    required this.icon,
    required this.items,
    this.required = false,
    this.onChanged,
    this.validator,
  });

  final String hintText;
  final IconData icon;
  final List<String> items;
  final bool required;
  final ValueChanged<String?>? onChanged;
  final String? Function(String?)? validator;

  @override
  State<ChalkDropdown> createState() => _ChalkDropdownState();
}

class _ChalkDropdownState extends State<ChalkDropdown> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: _selected,
      icon: const Icon(Icons.arrow_drop_down),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: widget.hintText,
        prefixIcon: Icon(widget.icon, color: const Color(0xFF7B7B7B)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (widget.required && (value == null || value.isEmpty)) {
          return 'Required';
        }
        return widget.validator?.call(value);
      },
      items: widget.items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: (value) {
        setState(() {
          _selected = value;
        });
        widget.onChanged?.call(value);
      },
    );
  }
}

/// Primary chalk-styled action button.
class ChalkButton extends StatelessWidget {
  const ChalkButton({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(75),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(fontSize: 25, letterSpacing: 1),
        ),
      ),
    );
  }
}
