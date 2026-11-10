import 'package:flutter/material.dart';
import '../../utils/api_links.dart';
import '../../widgets/generic_grid_windows_screen.dart';

/// Cadastro de motoristas (condutores do MDF-e). CRUD via
/// `/api/transporte/motoristas`; empresa e parceiro vem do tenant no backend.
/// Usada em Web e Windows.
class WebTransporteMotoristaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebTransporteMotoristaGridScreen(
      {super.key, required this.hasPermission});

  static final List<FieldConfigWindows> fieldConfigs = [
    FieldConfigWindows(
      label: 'Nome',
      fieldName: 'nome',
      icon: Icons.badge,
      isRequired: true,
      isFilterable: false,
    ),
    FieldConfigWindows(
      label: 'CPF',
      fieldName: 'cpf',
      fieldType: FieldType.cpf,
      isRequired: true,
      isFilterable: false,
    ),
    FieldConfigWindows(
      label: 'Ativo',
      fieldName: 'ativo',
      fieldType: FieldType.boolean,
      defaultValue: true,
      isFilterable: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Map<String, dynamic>>(
      title: 'Motoristas',
      fetchEndpoint: ApiLinks.allTransporteMotoristas,
      createEndpoint: ApiLinks.allTransporteMotoristas,
      updateEndpoint: ApiLinks.transporteMotorista(':id'),
      deleteEndpoint: ApiLinks.transporteMotorista(':id'),
      fromJson: (json) => json,
      toJson: (item) => item,
      hasPermission: hasPermission,
      FieldConfigWindowss: fieldConfigs,
      idFieldName: 'id',
      storageKey: 'transporte_motoristas_grid',
      exportConfig: const ExportConfig(
          enableCsvExport: true, filenamePrefix: 'transporte_motoristas'),
      paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: false,
    );
  }
}
