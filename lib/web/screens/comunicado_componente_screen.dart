import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart'
    show DynamicGridWindowsScreen, SecurityCheck;
import '../../../utils/tenant_context.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show CustomAction, FieldConfigWindows, FieldType;
import './comunicado_detalhe_screen.dart';

/// Tela principal de Comunicados.
/// - Apenas botao "Visualizar comunicado" na coluna de acoes (sem botao de editar extra).
/// - Campo Empresa pre-selecionado com a empresa do usuario logado.
/// - Campo Aplicativo pre-selecionado e desabilitado.
/// - Campo ID oculto no INSERT (comportamento automatico do DynamicGridWindowsScreen).
class WebComunicadoGridComponentesScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebComunicadoGridComponentesScreen({
    super.key,
    required this.hasPermission,
  });

  /// Fix card #431: backend espera dataPublicacao como LocalDateTime
  /// (yyyy-MM-ddTHH:mm:ss), mas o form generico (field_factory.dart) so
  /// formata data pura (yyyy-MM-dd) no picker. Completa a hora no submit
  /// sem alterar o widget compartilhado (evita regressao em outras telas
  /// que usam LocalDate puro). Reutilizavel por qualquer tela/aba que
  /// monte o form de 'comunicado' (standalone ou RelatedGridTab).
  static Map<String, dynamic> transformFormData(Map<String, dynamic> formData) {
    final raw = formData['dataPublicacao'];
    if (raw is String && raw.isNotEmpty && !raw.contains('T')) {
      formData['dataPublicacao'] = '${raw}T00:00:00';
    }
    return formData;
  }

  List<FieldConfigWindows> get _fieldOverrides {
    final empresaId = TenantContext.empresaId;
    final aplicativoId = TenantContext.aplicativoId;

    return [
      // Empresa: pre-selecionada com a empresa do usuario logado, desabilitada se ja tiver empresa
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
      transformFormData: transformFormData,
      // Apenas a acao "Visualizar comunicado" — sem botao de editar duplicado
      customActions: () => [
        CustomAction<Map<String, dynamic>>(
          icon: Icons.visibility,
          label: 'Visualizar comunicado',
          onPressed: (context, comunicado) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ComunicadoDetalheScreen(comunicado: comunicado),
              ),
            );
          },
          isVisible: (_) => true,
        ),
      ],
    );
  }
}
