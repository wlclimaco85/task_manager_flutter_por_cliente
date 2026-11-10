import 'package:flutter/material.dart';
import '../../customization/generic_grid_card.dart';
import '../../utils/api_links.dart';

/// Cadastro de motoristas (condutores do MDF-e) no mobile. CRUD via
/// `/api/transporte/motoristas`; empresa e parceiro vem do tenant no backend.
class MobileTransporteMotoristaScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;

  const MobileTransporteMotoristaScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
  });

  static const List<FieldConfig> fieldConfigs = [
    FieldConfig(
        label: 'Nome',
        fieldName: 'nome',
        icon: Icons.badge,
        isRequired: true,
        isFilterable: false),
    FieldConfig(
        label: 'CPF',
        fieldName: 'cpf',
        fieldType: FieldType.cpf,
        isRequired: true,
        isFilterable: false),
    FieldConfig(
        label: 'Ativo',
        fieldName: 'ativo',
        fieldType: FieldType.boolean,
        defaultValue: true,
        isFilterable: false),
  ];

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<Map<String, dynamic>>(
      title: 'Motoristas',
      fetchEndpoint: ApiLinks.allTransporteMotoristas,
      createEndpoint: ApiLinks.allTransporteMotoristas,
      updateEndpoint: ApiLinks.transporteMotorista(':id'),
      deleteEndpoint: ApiLinks.transporteMotorista(':id'),
      fromJson: (json) => json,
      toJson: (item) => item,
      hasPermission: hasPermission,
      fieldConfigs: fieldConfigs,
      idFieldName: 'id',
      storageKey: 'mobile_transporte_motoristas',
      useUserBannerAppBar: true,
      onUserBannerTapped: onUserBannerTapped,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: false,
    );
  }
}
