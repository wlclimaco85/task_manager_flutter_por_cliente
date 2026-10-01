import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/centro_custo_model.dart';

class WebCentroCustoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebCentroCustoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<CentroCusto>(
      title: "Centros de Custo",
      fetchEndpoint: ApiLinks.allCentrosCusto,
      createEndpoint: ApiLinks.createCentroCusto,
      updateEndpoint: ApiLinks.updateCentroCusto(":id"),
      deleteEndpoint: ApiLinks.deleteCentroCusto(":id"),
      fromJson: (json) => CentroCusto.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: CentroCusto.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'centros_custo'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
