import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/cargo_model.dart';

class WebCargoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebCargoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Cargo>(
      title: "Cargos",
      fetchEndpoint: ApiLinks.allCargos,
      createEndpoint: ApiLinks.createCargo,
      updateEndpoint: ApiLinks.updateCargo(":id"),
      deleteEndpoint: ApiLinks.deleteCargo(":id"),
      fromJson: (json) => Cargo.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Cargo.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'cargos'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
