import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/departamento_model.dart';

class WebDepartamentoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebDepartamentoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Departamento>(
      title: "Departamentos",
      fetchEndpoint: ApiLinks.allDepartamentos,
      createEndpoint: ApiLinks.createDepartamento,
      updateEndpoint: ApiLinks.updateDepartamento(":id"),
      deleteEndpoint: ApiLinks.deleteDepartamento(":id"),
      fromJson: (json) => Departamento.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Departamento.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'departamentos'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
