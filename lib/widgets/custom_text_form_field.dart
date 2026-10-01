// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'custom_input_form_consolidated.dart';

/// DEPRECATED: Use CustomInputFormConsolidated instead.
/// This class is maintained for backwards compatibility.
/// Redirect to CustomInputFormConsolidated with compatible parameters.
class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.hintText,
    required this.controller,
    this.obscureText,
    this.maxLines,
    this.validator,
    this.readOnly,
    required this.textInputType,
    this.icon,
  });

  final String hintText;
  final TextEditingController controller;
  final bool? obscureText;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool? readOnly;
  final TextInputType textInputType;
  final Icons? icon;

  @override
  Widget build(BuildContext context) {
    // Redirect to consolidated form with compatible parameters
    return CustomInputFormConsolidated(
      controller: controller,
      label: hintText,
      hint: hintText,
      validator: validator,
      inputType: textInputType,
      isPassword: obscureText ?? false,
      maxLines: maxLines ?? 1,
      readOnly: readOnly ?? false,
      icon: icon as IconData?,
      fillColor: Colors.white,
      borderRadius: 0.0, // Flat border like original
      borderColor: Colors.transparent,
      borderWidth: 0.0,
    );
  }
}
