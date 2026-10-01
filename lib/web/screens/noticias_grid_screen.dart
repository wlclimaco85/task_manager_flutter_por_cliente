import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/noticias_model.dart';

class WebNoticiasGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebNoticiasGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Noticia>(
      title: "Notícias",
      fetchEndpoint: ApiLinks.allNoticias,
      createEndpoint: ApiLinks.createNoticia,
      updateEndpoint: ApiLinks.updateNoticia(":id"),
      deleteEndpoint: ApiLinks.deleteNoticia(":id"),
      fromJson: (json) => Noticia.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Noticia.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'noticias'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 25, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
