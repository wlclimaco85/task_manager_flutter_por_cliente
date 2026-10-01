import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/tipo_produto_model.dart';

class WebTipoProdutoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebTipoProdutoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<TipoProduto>(
      title: "Tipos de Produto",
      fetchEndpoint: ApiLinks.allTiposProduto,
      createEndpoint: ApiLinks.createTipoProduto,
      updateEndpoint: ApiLinks.updateTipoProduto(":id"),
      deleteEndpoint: ApiLinks.deleteTipoProduto(":id"),
      fromJson: (json) => TipoProduto.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: TipoProduto.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'tipos_produto'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
