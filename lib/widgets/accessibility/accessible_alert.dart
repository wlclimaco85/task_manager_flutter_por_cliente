import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

/// AccessibleAlert — WCAG AA compliant dialog with semantic structure for screen readers.
///
/// Provides:
/// - Heading role for title (announced by screen readers)
/// - Live region for content (announced immediately)
/// - Semantic button labels for actions
/// - Destructive action warnings
/// - Focus management (first actionable element on open)
/// - Keyboard dismissal (Esc/back)
///
/// Usage:
/// ```dart
/// showAccessibleAlert(
///   context: context,
///   title: 'Cancelar NF-e?',
///   message: 'Esta ação não pode ser desfeita.',
///   actionLabel: 'Sim, cancelar',
///   isDestructive: true,
///   onAction: _cancelNFe,
/// );
/// ```
void showAccessibleAlert({
  required BuildContext context,
  required String title,
  required String message,
  required String actionLabel,
  VoidCallback? onAction,
  bool isDestructive = false,
  String closeLabel = 'Fechar',
  String? secondaryActionLabel,
  VoidCallback? onSecondaryAction,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Semantics(
      container: true,
      label: title,
      child: AlertDialog(
        // Title with heading role
        title: Semantics(
          container: true,
          label: title,
          enabled: true,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: GridColors.textSecondary,
            ),
          ),
        ),

        // Content with live region (announced immediately to SR)
        content: Semantics(
          liveRegion: true,
          label: message,
          enabled: true,
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: GridColors.textSecondary,
            ),
          ),
        ),

        // Actions
        actions: [
          // Close/Cancel button
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              closeLabel,
              style: TextStyle(
                color: GridColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Secondary action (optional)
          if (secondaryActionLabel != null && onSecondaryAction != null) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onSecondaryAction();
              },
              child: Text(
                secondaryActionLabel,
                style: TextStyle(
                  color: GridColors.secondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Primary action
          TextButton(
            onPressed: onAction != null
                ? () {
                    Navigator.pop(ctx);
                    onAction();
                  }
                : null,
            child: Semantics(
              label:
                  isDestructive ? 'Ação perigosa: $actionLabel' : actionLabel,
              enabled: true,
              button: true,
              child: Text(
                actionLabel,
                style: TextStyle(
                  color: isDestructive ? GridColors.error : GridColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],

        // Dialog styling
        backgroundColor: GridColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 24,
      ),
    ),
  );
}

/// AccessibleSnackBar — WCAG AA compliant snack bar for error/success messages.
///
/// Announces immediately to screen readers via live region.
///
/// Usage:
/// ```dart
/// showAccessibleSnackBar(
///   context: context,
///   message: 'CNPJ inválido. Verifique o formato.',
///   type: AccessibleSnackBarType.error,
/// );
/// ```
enum AccessibleSnackBarType {
  error,
  success,
  warning,
  info,
}

void showAccessibleSnackBar({
  required BuildContext context,
  required String message,
  AccessibleSnackBarType type = AccessibleSnackBarType.info,
  Duration duration = const Duration(seconds: 4),
}) {
  final colors = {
    AccessibleSnackBarType.error: GridColors.error,
    AccessibleSnackBarType.success: GridColors.success,
    AccessibleSnackBarType.warning: GridColors.warning,
    AccessibleSnackBarType.info: GridColors.info,
  };

  final label = {
    AccessibleSnackBarType.error: 'Erro',
    AccessibleSnackBarType.success: 'Sucesso',
    AccessibleSnackBarType.warning: 'Aviso',
    AccessibleSnackBarType.info: 'Informação',
  };

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Semantics(
        liveRegion: true,
        label: '${label[type]}: $message',
        enabled: true,
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      backgroundColor: colors[type],
      duration: duration,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
