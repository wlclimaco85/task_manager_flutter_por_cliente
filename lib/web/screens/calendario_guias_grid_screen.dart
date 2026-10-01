import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/calendario_guias_model.dart';

class WebCalendarioGuiasGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebCalendarioGuiasGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<CalendarioGuias>(
      title: "Calendário de Guias",
      fetchEndpoint: ApiLinks.allCalendariosGuias,
      createEndpoint: ApiLinks.createCalendarioGuias,
      updateEndpoint: ApiLinks.updateCalendarioGuias(":id"),
      deleteEndpoint: ApiLinks.deleteCalendarioGuias(":id"),
      fromJson: (json) => CalendarioGuias.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: CalendarioGuias.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'calendario_guias'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
