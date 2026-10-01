import 'package:flutter/material.dart';
import '../../../utils/security_matrix.dart';
import '../../web/screens/mensalidade_grid_screen.dart';

/// Tela mobile de Mensalidades — reutiliza o widget Web/Windows.
class MobileMensalidadeScreen extends StatelessWidget {
  const MobileMensalidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sec = SecurityMatrix.current();
    return WebMensalidadeGridScreen(
      hasPermission: (action) {
        final lower = action.toLowerCase();
        if (lower.contains('insert') || lower.contains('create')) {
          return sec.canInsert(AppScreen.mensalidades);
        }
        if (lower.contains('update') || lower.contains('edit')) {
          return sec.canUpdate(AppScreen.mensalidades);
        }
        if (lower.contains('delete') || lower.contains('remove')) {
          return sec.canDelete(AppScreen.mensalidades);
        }
        return sec.canView(AppScreen.mensalidades);
      },
    );
  }
}
