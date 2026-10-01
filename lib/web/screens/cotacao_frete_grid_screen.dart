import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/cotacao_frete_model.dart';

class WebCotacaoFreteGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebCotacaoFreteGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<CotacaoFrete>(
      title: "Cotações de Frete",
      fetchEndpoint: ApiLinks.allCotacoesFrete,
      createEndpoint: ApiLinks.createCotacaoFrete,
      updateEndpoint: ApiLinks.updateCotacaoFrete(":id"),
      deleteEndpoint: ApiLinks.deleteCotacaoFrete(":id"),
      fromJson: (json) => CotacaoFrete.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: CotacaoFrete.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'cotacoes_frete'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
