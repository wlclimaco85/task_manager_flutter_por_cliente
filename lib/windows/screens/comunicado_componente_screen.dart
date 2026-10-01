import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart'
    show DynamicGridWindowsScreen, SecurityCheck;
import '../../../utils/tenant_context.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows, FieldType;
import './comunicado_detalhe_screen.dart';
import '../../web/screens/comunicado_componente_screen.dart'
    show WebComunicadoGridComponentesScreen;

/// Tela principal de Comunicados (versao Windows).
/// - Apenas botao "Visualizar comunicado" na coluna de acoes.
/// - Campo Empresa pre-selecionado com a empresa do usuario logado.
/// - Campo Aplicativo pre-selecionado e desabilitado.
/// - Campo ID oculto no INSERT (comportamento automatico do DynamicGridWindowsScreen).
class WindowsComunicadoGridComponentesScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsComunicadoGridComponentesScreen({
    super.key,
    required this.hasPermission,
  });

  List<FieldConfigWindows> get _fieldOverrides {
    final empresaId = TenantContext.empresaId;
    final aplicativoId = TenantContext.aplicativoId;

    return [
      FieldConfigWindows(
        label: 'Empresa',
        fieldName: 'empresa',
        displayFieldName: 'empresa.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        dropdownSelectedValue: empresaId?.toString(),
        dropdownFutureBuilder: DropdownHelpers.empresas,
        enabled: empresaId == null,
        isRequired: true,
        fieldOrder: 1,
      ),
      // Aplicativo: fixo pelo aplicativo da sessão — payload only (oculto do form).
      FieldConfigWindows(
        label: 'Aplicativo',
        fieldName: 'aplicativo',
        fieldType: FieldType.dropdown,
        dropdownSelectedValue: aplicativoId?.toString(),
        isInForm: false,
        isInGrid: false,
        fieldOrder: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'comunicado',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fieldOverrides: _fieldOverrides,
      transformFormData: WebComunicadoGridComponentesScreen.transformFormData,
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.visibility,
          label: 'Visualizar comunicado',
          onPressed: (context, comunicado) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => WindowsComunicadoDetalheScreen(
                  comunicado: comunicado,
                ),
              ),
            );
          },
          isVisible: (_) => true,
        ),
      ],
    );
  }
}
