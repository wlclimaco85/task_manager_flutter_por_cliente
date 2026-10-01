import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/modalidade_model.dart';

class WebModalidadeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebModalidadeGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Modalidade>(
      title: "Modalidades",
      fetchEndpoint: ApiLinks.allModalidades,
      createEndpoint: ApiLinks.createModalidade,
      updateEndpoint: ApiLinks.updateModalidade(":id"),
      deleteEndpoint: ApiLinks.deleteModalidade(":id"),
      fromJson: (json) => Modalidade.fromJson(json),
      toJson: (m) => m.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Modalidade.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'createdAt',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'modalidades',
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
