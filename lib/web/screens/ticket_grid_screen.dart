import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/ticket_model.dart';

class WebTicketGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebTicketGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<TicketItem>(
      title: "Tickets",
      fetchEndpoint: ApiLinks.allTickets,
      createEndpoint: ApiLinks.createTicket,
      updateEndpoint: ApiLinks.updateTicket(":id"),
      deleteEndpoint: ApiLinks.deleteTicket(":id"),
      fromJson: (json) => TicketItem.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: TicketItem.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'tickets'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
