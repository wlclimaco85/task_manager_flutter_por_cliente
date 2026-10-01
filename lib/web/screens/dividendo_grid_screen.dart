import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/dividendo_model.dart';

class WebDividendoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebDividendoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Dividendo>(
      title: "Dividendos",
      fetchEndpoint: ApiLinks.allDividendos,
      createEndpoint: ApiLinks.createDividendo,
      updateEndpoint: ApiLinks.updateDividendo(":id"),
      deleteEndpoint: ApiLinks.deleteDividendo(":id"),
      fromJson: (json) => Dividendo.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Dividendo.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'dividendos'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
