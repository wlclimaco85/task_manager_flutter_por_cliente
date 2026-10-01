import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/auth_utility.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType;
import 'details/funcionario_detail_screen.dart';

class WebFuncionarioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebFuncionarioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    final login = AuthUtility.userInfo?.login;
    final empresa  = login?.empresa;
    final parceiro = login?.parceiro;

    final hasEmpresa  = empresa?.id != null;
    final hasParceiro = parceiro?.id != null;

    final empresaIdStr  = empresa?.id?.toString() ?? '';
    final empresaNome   = empresa?.nome ?? '';
    final parceiroIdStr = parceiro?.id?.toString() ?? '';
    final parceiroNome  = parceiro?.nome ?? 'Parceiro Contratante';

    // H9: pre-preencher e desabilitar empresa e parceiroContratante conforme TenantContext
    final fieldOverrides = <FieldConfigWindows>[
      if (hasEmpresa)
        FieldConfigWindows(
          label: 'Empresa',
          fieldName: 'empresa',
          displayFieldName: 'empresa.nome',
          icon: Icons.business,
          isFilterable: true,
          isInForm: true,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () async => [
            {'id': empresaIdStr, 'nome': empresaNome},
          ],
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownSelectedValue: empresaIdStr,
          enabled: false,
        ),
      if (hasParceiro)
        FieldConfigWindows(
          label: parceiroNome,
          fieldName: 'parceiroContratante',
          displayFieldName: 'parceiroContratante.nome',
          icon: Icons.person_outline,
          isFilterable: true,
          isInForm: true,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () async => [
            {'id': parceiroIdStr, 'nome': parceiroNome},
          ],
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          dropdownSelectedValue: parceiroIdStr,
          enabled: false,
        ),
    ];

    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'funcionario',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (f) => f,
      fieldOverrides: fieldOverrides.isNotEmpty ? fieldOverrides : null,
      detailScreenBuilder: (item) => WebFuncionarioDetailScreen(item: item, hasPermission: hasPermission),
    );
  }
}
