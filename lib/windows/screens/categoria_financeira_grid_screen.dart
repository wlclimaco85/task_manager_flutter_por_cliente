import 'package:flutter/material.dart';
import '../../../models/categoria_financeira_model.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';

class WindowsCategoriaFinanceiraGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsCategoriaFinanceiraGridScreen({
    super.key,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<CategoriaFinanceira>(
      title: 'Categorias Financeiras',
      fetchEndpoint: ApiLinks.allCategoriasFinanceiras,
      createEndpoint: ApiLinks.createCategoriaFinanceira,
      updateEndpoint: ApiLinks.updateCategoriaFinanceira(':id'),
      deleteEndpoint: ApiLinks.deleteCategoriaFinanceira(':id'),
      fromJson: (json) => CategoriaFinanceira.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: CategoriaFinanceira.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(
        enableCsvExport: true,
        filenamePrefix: 'categorias_financeiras',
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
