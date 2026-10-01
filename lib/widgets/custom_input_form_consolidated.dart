// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

/// CustomInputFormConsolidated consolidates:
/// - CustomInputForm (label, hint, validator, onChanged)
/// - CustomTextFormField (obscureText, maxLines, textInputType)
/// - sign_up_button styling (optional)
///
/// Reduced code duplication from 156 usages across Mobile + Web.
class CustomInputFormConsolidated extends StatelessWidget {
  const CustomInputFormConsolidated({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.inputType = TextInputType.text,
    this.multiline = false,
    this.isPassword = false,
    this.isDisabled = false,
    this.maxLines = 1,
    this.focusNode,
    this.readOnly = false,
    this.icon,
    this.fillColor,
    this.borderRadius = 8.0,
    this.borderColor = Colors.yellow,
    this.borderWidth = 3.0,
  });

  /// Text controller for the form field
  final TextEditingController controller;

  /// Label text displayed above the input
  final String label;

  /// Hint text displayed inside the input when empty
  final String? hint;

  /// Validator function called on form validation
  final String? Function(String?)? validator;

  /// Callback when text changes
  final ValueChanged<String>? onChanged;

  /// Keyboard input type (email, number, text, etc.)
  final TextInputType inputType;

  /// Whether the field supports multiline input (textarea)
  final bool multiline;

  /// Whether the input should be obscured (password field)
  final bool isPassword;

  /// Whether the input is disabled
  final bool isDisabled;

  /// Maximum number of lines for the input
  final int maxLines;

  /// Optional FocusNode for managing focus
  final FocusNode? focusNode;

  /// Whether the field is read-only
  final bool readOnly;

  /// Optional leading icon
  final IconData? icon;

  /// Fill color for the input field
  final Color? fillColor;

  /// Border radius for the input field
  final double borderRadius;

  /// Border color for the input field
  final Color borderColor;

  /// Border width for the input field
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        enabled: !isDisabled,
        readOnly: readOnly || isDisabled,
        keyboardType: multiline ? TextInputType.multiline : inputType,
        obscureText: isPassword,
        maxLines: multiline ? maxLines : 1,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: fillColor ?? Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(borderRadius),
            ),
            borderSide: BorderSide(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(borderRadius),
            ),
            borderSide: BorderSide(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(borderRadius),
            ),
            borderSide: BorderSide(
              color: Colors.grey,
              width: borderWidth,
            ),
          ),
          prefixIcon: icon != null ? Icon(icon) : null,
          labelStyle: TextStyle(
            color: isDisabled ? Colors.grey : borderColor,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }
}
