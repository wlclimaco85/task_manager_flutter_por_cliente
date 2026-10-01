import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/horario_func_model.dart';

class WebHorarioFuncGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebHorarioFuncGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<HorarioFunc>(
      title: "Horários de Funcionários",
      fetchEndpoint: ApiLinks.allHorariosFunc,
      createEndpoint: ApiLinks.createHorarioFunc,
      updateEndpoint: ApiLinks.updateHorarioFunc(":id"),
      deleteEndpoint: ApiLinks.deleteHorarioFunc(":id"),
      fromJson: (json) => HorarioFunc.fromJson(json),
      toJson: (item) => item.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: HorarioFunc.fieldConfigs,
      idFieldName: 'id',
      exportConfig: const ExportConfig(enableCsvExport: true, filenamePrefix: 'horarios_func'),
      paginationConfig: const PaginationConfig(defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: true,
      enableColumnReorder: true,
    );
  }
}
