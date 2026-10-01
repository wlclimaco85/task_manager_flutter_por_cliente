import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/pedido_model.dart';

class WebPedidoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebPedidoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Pedido>(
      title: "Pedidos",
      fetchEndpoint: ApiLinks.allPedidos,
      createEndpoint: ApiLinks.createPedido,
      updateEndpoint: ApiLinks.updatePedido(":id"),
      deleteEndpoint: ApiLinks.deletePedido(":id"),
      fromJson: (json) => Pedido.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: Pedido.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'pedidos'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
