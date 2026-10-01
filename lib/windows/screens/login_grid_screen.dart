import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows, FieldType, FileConfig, SecurityCheck;
import '../../../customization/dynamic_grid_windows_screen.dart'
    hide SecurityCheck;
import '../../../models/login_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/login_payload_defaults.dart';
import '../../../services/network_caller.dart';
import '../../web/screens/login_grid_screen.dart' show WebLoginGridScreen;
import 'details/login_detail_screen.dart';
import 'role_dialog.dart';

class WindowsLoginGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsLoginGridScreen({super.key, required this.hasPermission});

  static Future<List<Map<String, dynamic>>> loadRoles() async {
    final response = await NetworkCaller()
        .getRequest('${ApiLinks.baseUrl}/api/role/disponiveis');
    if (response.isSuccess && response.body != null) {
      final dynamic body = response.body;
      List lista = [];
      if (body is List) {
        lista = body;
      } else if (body is Map && body['data'] is List) {
        lista = body['data'] as List;
      }
      return lista.map((e) {
        final desc = e['description']?.toString();
        final key = e['key']?.toString() ?? e['name']?.toString();
        final label = (desc != null && desc.isNotEmpty)
            ? desc
            : (key != null && key.isNotEmpty)
                ? key
                : 'Role #${e['id']}';
        return {'value': e['id'].toString(), 'label': label};
      }).toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> loadEmpresas() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allEmpresas);
    if (response.isSuccess && response.body != null) {
      final lista = response.body!['data']['dados'] as List;
      return lista
          .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> loadParceiros() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allParceiros);
    if (response.isSuccess && response.body != null) {
      final lista = response.body!['data']['dados'] as List;
      return lista
          .map((e) => {'id': e['id'].toString(), 'label': e['nome'].toString()})
          .toList();
    }
    return [];
  }

  static Map<String, dynamic> get additionalFormData =>
      buildLoginAdditionalFormData();

  static const List<FieldConfigWindows> loginHiddenFields =
      WebLoginGridScreen.loginHiddenFields;

  static List<FieldConfigWindows> fieldOverrides() => [
        ...loginHiddenFields,
        const FieldConfigWindows(
          label: 'Foto',
          fieldName: 'foto',
          icon: Icons.photo_camera,
          fieldType: FieldType.file,
          fileConfig: FileConfig(
            allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
            maxFileSize: 2 * 1024 * 1024,
          ),
          isInForm: true,
          isInGrid: false,
          isFilterable: false,
        ),
        const FieldConfigWindows(
          label: 'Roles',
          fieldName: 'roles',
          icon: Icons.security,
          fieldType: FieldType.multiselect,
          dropdownFutureBuilder: WindowsLoginGridScreen.loadRoles,
          dropdownValueField: 'value',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: false,
        ),
        FieldConfigWindows(
          label: 'Empresa',
          fieldName: 'empresa',
          displayFieldName: 'empresa.nome',
          icon: Icons.business,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: loadEmpresas,
          dropdownValueField: 'id',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: true,
        ),
        FieldConfigWindows(
          label: 'Parceiro',
          fieldName: 'parceiro',
          displayFieldName: 'parceiro.nome',
          icon: Icons.person_outline,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: loadParceiros,
          dropdownValueField: 'id',
          dropdownDisplayField: 'label',
          isInForm: true,
          isFilterable: true,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Login>(
      telaNome: 'Login',
      hasPermission: hasPermission,
      fromJson: (json) => Login.fromJson(json),
      toJson: (a) => a.toJson(),
      extraParams: const {'skipTenantParceiro': 'true'},
      additionalFormData: additionalFormData,
      fieldOverrides: fieldOverrides(),
      customActions: () => [
        CustomAction<Login>(
          icon: Icons.admin_panel_settings,
          label: 'Permissões',
          onPressed: (context, object) => _showBaixaDialog(context, object),
          isVisible: (chamado) => true,
        ),
      ],
      detailScreenBuilder: (item) => WindowsLoginDetailScreen(
        item: item,
        hasPermission: hasPermission,
      ),
    );
  }

  void _showBaixaDialog(BuildContext context, Login conta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RoleDialog(
          loginId: conta.id ?? 0,
          empresaId: conta.empresa?.id,
          parceiroId: conta.parceiro?.id,
        );
      },
    );
  }
}
