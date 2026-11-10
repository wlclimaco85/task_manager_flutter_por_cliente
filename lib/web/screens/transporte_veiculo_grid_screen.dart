import 'package:flutter/material.dart';
import '../../utils/api_links.dart';
import '../../widgets/generic_grid_windows_screen.dart';

/// Opcoes fixas do esquema do MDF-e (tpRod / tpCar) e UFs, compartilhadas
/// pelas telas Web/Windows e Mobile de veiculos do modulo Transporte.
const List<Map<String, dynamic>> kTransporteTiposRodado = [
  {'value': '01', 'label': '01 - Truck'},
  {'value': '02', 'label': '02 - Toco'},
  {'value': '03', 'label': '03 - Cavalo mecânico'},
  {'value': '04', 'label': '04 - VAN'},
  {'value': '05', 'label': '05 - Utilitário'},
  {'value': '06', 'label': '06 - Outros'},
];

const List<Map<String, dynamic>> kTransporteTiposCarroceria = [
  {'value': '00', 'label': '00 - Não aplicável'},
  {'value': '01', 'label': '01 - Aberta'},
  {'value': '02', 'label': '02 - Fechada/Baú'},
  {'value': '03', 'label': '03 - Graneleira'},
  {'value': '04', 'label': '04 - Porta container'},
  {'value': '05', 'label': '05 - Sider'},
];

const List<String> kTransporteUfs = [
  'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MG', 'MS',
  'MT', 'PA', 'PB', 'PE', 'PI', 'PR', 'RJ', 'RN', 'RO', 'RR', 'RS', 'SC',
  'SE', 'SP', 'TO',
];

/// Cadastro de veiculos (MDF-e/CT-e). CRUD via `/api/transporte/veiculos`;
/// empresa e parceiro vem do tenant no backend. Usada em Web e Windows.
class WebTransporteVeiculoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebTransporteVeiculoGridScreen({super.key, required this.hasPermission});

  static final List<FieldConfigWindows> fieldConfigs = [
    FieldConfigWindows(
      label: 'Placa',
      fieldName: 'placa',
      icon: Icons.local_shipping,
      isRequired: true,
      isFilterable: false,
    ),
    FieldConfigWindows(
      label: 'RENAVAM',
      fieldName: 'renavam',
      isFilterable: false,
      isVisibleByDefault: false,
    ),
    FieldConfigWindows(
      label: 'Tara (kg)',
      fieldName: 'taraKg',
      fieldType: FieldType.number,
      isRequired: true,
      isFilterable: false,
    ),
    FieldConfigWindows(
      label: 'Capacidade (kg)',
      fieldName: 'capacidadeKg',
      fieldType: FieldType.number,
      isFilterable: false,
    ),
    FieldConfigWindows(
      label: 'Tipo de rodado',
      fieldName: 'tipoRodado',
      fieldType: FieldType.dropdown,
      dropdownOptions: kTransporteTiposRodado,
      isRequired: true,
      isFilterable: false,
    ),
    FieldConfigWindows(
      label: 'Tipo de carroceria',
      fieldName: 'tipoCarroceria',
      fieldType: FieldType.dropdown,
      dropdownOptions: kTransporteTiposCarroceria,
      isRequired: true,
      isFilterable: false,
    ),
    FieldConfigWindows(
      label: 'UF da placa',
      fieldName: 'ufPlaca',
      fieldType: FieldType.dropdown,
      dropdownOptions: [
        for (final uf in kTransporteUfs) {'value': uf, 'label': uf},
      ],
      isRequired: true,
      isFilterable: false,
    ),
    FieldConfigWindows(
      label: 'Ativo',
      fieldName: 'ativo',
      fieldType: FieldType.boolean,
      defaultValue: true,
      isFilterable: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GenericGridScreen<Map<String, dynamic>>(
      title: 'Veículos',
      fetchEndpoint: ApiLinks.allTransporteVeiculos,
      createEndpoint: ApiLinks.allTransporteVeiculos,
      updateEndpoint: ApiLinks.transporteVeiculo(':id'),
      deleteEndpoint: ApiLinks.transporteVeiculo(':id'),
      fromJson: (json) => json,
      toJson: (item) => item,
      hasPermission: hasPermission,
      FieldConfigWindowss: fieldConfigs,
      idFieldName: 'id',
      storageKey: 'transporte_veiculos_grid',
      exportConfig: const ExportConfig(
          enableCsvExport: true, filenamePrefix: 'transporte_veiculos'),
      paginationConfig: const PaginationConfig(
          defaultRowsPerPage: 10, availableRowsPerPage: [10, 25, 50]),
      enableSearch: false,
    );
  }
}
