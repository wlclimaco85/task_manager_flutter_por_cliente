import 'package:flutter/material.dart';
import '../../customization/generic_grid_card.dart';
import '../../utils/api_links.dart';
import '../../web/screens/transporte_veiculo_grid_screen.dart'
    show kTransporteTiposRodado, kTransporteTiposCarroceria, kTransporteUfs;

/// Cadastro de veiculos (MDF-e/CT-e) no mobile. CRUD via
/// `/api/transporte/veiculos`; empresa e parceiro vem do tenant no backend.
class MobileTransporteVeiculoScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;

  const MobileTransporteVeiculoScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
  });

  static final List<FieldConfig> fieldConfigs = [
    const FieldConfig(
        label: 'Placa',
        fieldName: 'placa',
        icon: Icons.local_shipping,
        isRequired: true,
        isFilterable: false),
    const FieldConfig(
        label: 'RENAVAM',
        fieldName: 'renavam',
        isFilterable: false,
        isVisibleByDefault: false),
    const FieldConfig(
        label: 'Tara (kg)',
        fieldName: 'taraKg',
        fieldType: FieldType.number,
        isRequired: true,
        isFilterable: false),
    const FieldConfig(
        label: 'Capacidade (kg)',
        fieldName: 'capacidadeKg',
        fieldType: FieldType.number,
        isFilterable: false),
    const FieldConfig(
        label: 'Tipo de rodado',
        fieldName: 'tipoRodado',
        fieldType: FieldType.dropdown,
        dropdownOptions: kTransporteTiposRodado,
        isRequired: true,
        isFilterable: false),
    const FieldConfig(
        label: 'Tipo de carroceria',
        fieldName: 'tipoCarroceria',
        fieldType: FieldType.dropdown,
        dropdownOptions: kTransporteTiposCarroceria,
        isRequired: true,
        isFilterable: false),
    FieldConfig(
        label: 'UF da placa',
        fieldName: 'ufPlaca',
        fieldType: FieldType.dropdown,
        dropdownOptions: [
          for (final uf in kTransporteUfs) {'value': uf, 'label': uf},
        ],
        isRequired: true,
        isFilterable: false),
    const FieldConfig(
        label: 'Ativo',
        fieldName: 'ativo',
        fieldType: FieldType.boolean,
        defaultValue: true,
        isFilterable: false),
  ];

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<Map<String, dynamic>>(
      title: 'Veículos',
      fetchEndpoint: ApiLinks.allTransporteVeiculos,
      createEndpoint: ApiLinks.allTransporteVeiculos,
      updateEndpoint: ApiLinks.transporteVeiculo(':id'),
      deleteEndpoint: ApiLinks.transporteVeiculo(':id'),
      fromJson: (json) => json,
      toJson: (item) => item,
      hasPermission: hasPermission,
      fieldConfigs: fieldConfigs,
      idFieldName: 'id',
      storageKey: 'mobile_transporte_veiculos',
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
