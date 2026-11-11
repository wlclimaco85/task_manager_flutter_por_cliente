import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../customization/generic_grid/grid_models.dart';
import '../../utils/dropdown_helpers.dart';
import '../../utils/tenant_context.dart';

/// Tela mobile de Roles — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileRoleGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileRoleGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final appLogado = TenantContext.aplicativoId;
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_role'),
      telaNome: 'role',
      // role nasce no app logado: Aplicativo ja selecionado e desabilitado
      fieldOverrides: appLogado == null
          ? null
          : [
              FieldConfig(
                label: 'Aplicativo',
                fieldName: 'aplicativo',
                displayFieldName: 'aplicativo.nome',
                fieldType: FieldType.dropdown,
                dropdownValueField: 'id',
                dropdownDisplayField: 'nome',
                dropdownFutureBuilder: DropdownHelpers.aplicativos,
                enabled: false,
                defaultValue: appLogado,
              ),
            ],
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_role',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}
