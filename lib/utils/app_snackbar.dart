import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/custom_colors.dart';

class AppSnackbar {
  static void success(BuildContext context, String message) {
    _show(context, message, backgroundColor: GridColors.success);
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: GridColors.error,
      action: SnackBarAction(
        label: 'Copiar',
        textColor: Colors.white,
        onPressed: () => Clipboard.setData(ClipboardData(text: message)),
      ),
    );
  }

  static void warning(BuildContext context, String message) {
    _show(context, message, backgroundColor: GridColors.warning);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, backgroundColor: GridColors.info);
  }

  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: action,
      ),
    );
  }
}
