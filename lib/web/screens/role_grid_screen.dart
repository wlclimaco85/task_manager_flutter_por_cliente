import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../utils/security_matrix.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show CustomAction;
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/role_model.dart';
import '../../web/screens/role_dialog.dart';

class WebRoleGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebRoleGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final int? loginId = ModalRoute.of(context)?.settings.arguments as int?;

    // Somente system/master pode criar e editar roles
    final bool isSystem = SecurityMatrix.current().isMaster;

    // Filtra roles pelo modulo contratado do parceiro logado (nao-MASTER)
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
      fieldOverrides: [
        DropdownHelpers.aplicativoField(),
      ],
      customActions: () => [
        CustomAction<Role>(
          icon: Icons.check_circle,
          label: 'Baixar',
          onPressed: (context, object) =>
              _showBaixaDialog(context, object, loginId),
          isVisible: (chamado) => true,
        ),
      ],
    );
  }

  void _showBaixaDialog(BuildContext context, Role conta, int? loginId) {
    if (loginId == null) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WebRoleDialog(loginId: loginId);
      },
    );
  }
}
