import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/order_model.dart';

class WebOrderGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebOrderGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<OrderItem>(
      title: "Ordens",
      fetchEndpoint: ApiLinks.allOrders,
      createEndpoint: ApiLinks.createOrder,
      updateEndpoint: ApiLinks.updateOrder(":id"),
      deleteEndpoint: ApiLinks.deleteOrder(":id"),
      fromJson: (json) => OrderItem.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: OrderItem.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'ordens'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
