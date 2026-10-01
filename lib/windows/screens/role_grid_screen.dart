import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/security_matrix.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/role_model.dart';
import '../../windows/screens/role_dialog.dart';

class WindowsRoleGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsRoleGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final int? loginId =
        ModalRoute.of(context)?.settings.arguments as int?;

    final bool isSystem = SecurityMatrix.current().isMaster;
    final parceiroId = AuthUtility.userInfo?.login?.parceiro?.id;
    final Map<String, dynamic>? filtroModulo =
        (!isSystem && parceiroId != null) ? {'parceiroId': parceiroId} : null;

    return DynamicGridWindowsScreen<Role>(
      telaNome: 'role',
      hasPermission: (action) {
        if (action == 'create' || action == 'edit' || action == 'delete') {
          return isSystem;
        }
        return hasPermission(action);
      },
      extraParams: filtroModulo,
      fromJson: (json) => Role.fromJson(json),
      toJson: (a) => a.toJson(),
      customActions: () => [
        CustomAction<Role>(
          icon: Icons.check_circle,
          label: 'Baixar',
          onPressed: (context, object) =>
              _showBaixaDialog(context, object, loginId),
          isVisible: (_) => true,
        ),
      ],
    );
  }

  void _showBaixaDialog(BuildContext context, Role conta, int? loginId) {
    if (loginId == null) return;
    showDialog(
      context: context,
      builder: (_) => RoleDialog(loginId: loginId),
    );
  }
}
