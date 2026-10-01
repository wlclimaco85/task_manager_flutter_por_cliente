import 'package:flutter/material.dart';
import '../utils/security_matrix.dart';

/// Widget que aplica gating por AÇÃO definido na SecurityMatrix.
///
/// Regra:
/// - Ação SEM permissão → widget some (retorna SizedBox.shrink())
/// - Ação bloqueada por ESTADO do registro → desabilita + exibe tooltip
///
/// Uso:
/// ```dart
/// ActionGate(
///   screen: AppScreen.contasPagar,
///   action: AppAction.insert,
///   child: ElevatedButton(...),
/// )
/// ```
class ActionGate extends StatelessWidget {
  final AppScreen screen;
  final AppAction action;
  final Widget child;

  /// Quando true, o widget fica desabilitado em vez de some.
  /// Use para bloqueio por ESTADO do registro (ex: conta já baixada).
  final bool disabledByState;

  /// Tooltip exibido quando [disabledByState] é true.
  final String? disabledTooltip;

  const ActionGate({
    super.key,
    required this.screen,
    required this.action,
    required this.child,
    this.disabledByState = false,
    this.disabledTooltip,
  });

  bool _hasPermission(SecurityMatrix matrix) => switch (action) {
    AppAction.view   => matrix.canView(screen),
    AppAction.insert => matrix.canInsert(screen),
    AppAction.update => matrix.canUpdate(screen),
    AppAction.delete => matrix.canDelete(screen),
    AppAction.baixar => matrix.canBaixar(screen),
  };

  @override
  Widget build(BuildContext context) {
    final matrix = SecurityMatrix.current();

    if (!_hasPermission(matrix)) return const SizedBox.shrink();

    if (disabledByState) {
      return Tooltip(
        message: disabledTooltip ?? 'Ação não disponível neste estado',
        child: IgnorePointer(child: Opacity(opacity: 0.38, child: child)),
      );
    }

    return child;
  }
}
