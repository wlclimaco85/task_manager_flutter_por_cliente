// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../../../utils/ensure_visible_when_focused.dart';
import '../../constants/custom_colors.dart';

class CustomInputHorarioForm extends StatelessWidget {
  String? Function(String?)? validator;
  late FocusNode focusNode;
  TextInputType? type;
  String keyField;
  TextEditingController controller = TextEditingController();

  CustomInputHorarioForm({
    super.key,
    required this.validator,
    required this.focusNode,
    this.type,
    required this.keyField,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: EnsureVisibleWhenFocused(
        focusNode: focusNode,
        child: TextFormField(
          controller: controller,
          key: Key(keyField),
          focusNode: focusNode,
          keyboardType: type ?? TextInputType.text,
          decoration: InputDecoration(
            fillColor: CustomColors().getLightGreenBackground(),
            filled: true,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              ),
              borderSide: BorderSide(
                color: Colors.yellow,
                width: 3.0,
              ),
            ),
            labelStyle: const TextStyle(color: Colors.red, fontSize: 16.0),
            hintText: keyField,
          ),
          validator: validator,
        ),
      ),
    );
  }
}
