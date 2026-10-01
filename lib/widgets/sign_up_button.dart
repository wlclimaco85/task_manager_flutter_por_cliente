import 'package:flutter/material.dart';

/// DEPRECATED: This widget is a simple static button with no interaction.
/// Consider using CustomInputFormConsolidated for form inputs or
/// a configurable button widget with onPressed callback.
class SignUpButton extends StatelessWidget {
  const SignUpButton({
    super.key,
    this.onPressed,
    this.text = "Não possui uma conta? Cadastre-se!",
    this.topPadding = 160,
  });

  /// Optional callback when button is pressed
  final VoidCallback? onPressed;

  /// Text to display
  final String text;

  /// Top padding
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed ?? () {},
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w300,
            color: Colors.white,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
