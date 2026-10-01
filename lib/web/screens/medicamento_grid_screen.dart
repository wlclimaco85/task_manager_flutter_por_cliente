import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/medicamento_model.dart';

class WebMedicamentoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebMedicamentoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Medicamento>(
      title: "Medicamentos",
      fetchEndpoint: ApiLinks.allMedicamentos,
      createEndpoint: ApiLinks.createMedicamento,
      updateEndpoint: ApiLinks.updateMedicamento(":id"),
      deleteEndpoint: ApiLinks.deleteMedicamento(":id"),
      fromJson: (json) => Medicamento.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Medicamento.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'medicamentos',
      ),
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
