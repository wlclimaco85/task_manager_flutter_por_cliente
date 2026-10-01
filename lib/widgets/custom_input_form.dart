import 'package:flutter/material.dart';
import '../../constants/custom_colors.dart';
import 'custom_input_form_consolidated.dart';
// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

/// DEPRECATED: Use CustomInputFormConsolidated instead.
/// This class is maintained for backwards compatibility.
/// Redirect to CustomInputFormConsolidated with compatible parameters.
class CustomInputForm extends StatelessWidget {
  String? Function(String?)? validator;
  late FocusNode focusNode;
  TextInputType? type;
  String keyField;
  TextEditingController controller = TextEditingController();
  Function(String?)? onPressed;

  CustomInputForm({
    super.key,
    required this.validator,
    required this.focusNode,
    this.type,
    required this.keyField,
    required this.controller,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Redirect to consolidated form with compatible parameters
    return CustomInputFormConsolidated(
      controller: controller,
      label: keyField,
      hint: keyField,
      validator: validator,
      onChanged: onPressed,
      inputType: type ?? TextInputType.text,
      focusNode: focusNode,
      fillColor: CustomColors().getLightGreenBackground(),
      borderColor: Colors.yellow,
      borderWidth: 3.0,
    );
  }
}
