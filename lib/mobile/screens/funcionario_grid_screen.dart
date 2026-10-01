import 'package:flutter/material.dart';
import '../../../models/funcionario_model.dart';
import '../../../utils/api_links.dart';
import '../../customization/generic_grid_card.dart';

class FuncionarioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const FuncionarioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<FuncionarioModel>(
      title: "Funcionários",
      fetchEndpoint: ApiLinks.allFuncionarios,
      createEndpoint: ApiLinks.createFuncionario,
      updateEndpoint: ApiLinks.updateFuncionario(":id"),
      deleteEndpoint: ApiLinks.deleteFuncionario(":id"),
      fromJson: (json) => FuncionarioModel.fromJson(json),
      toJson: (f) => f.toJson(),
      hasPermission: hasPermission,
      fieldConfigs: FuncionarioModel.fieldConfigs,
      idFieldName: 'id',
      useUserBannerAppBar: true,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
    );
  }
}
