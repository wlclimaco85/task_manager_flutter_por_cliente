import 'package:flutter/material.dart';

import '../../customization/generic_grid_card.dart';
import '../../models/alvara_model.dart';
import '../../utils/api_links.dart';

/// Tela mobile de Alvarás — usa GenericMobileGridScreen com header padrão.
class MobileAlvaraScreen extends StatelessWidget {
  const MobileAlvaraScreen({super.key});

  static Future<List<Map<String, dynamic>>> _tiposAlvara() async => const [
        {'id': 'Funcionamento', 'nome': 'Funcionamento'},
        {'id': 'Sanitário', 'nome': 'Sanitário'},
        {'id': 'Bombeiros', 'nome': 'Bombeiros'},
        {'id': 'Ambiental', 'nome': 'Ambiental'},
        {'id': 'Publicidade', 'nome': 'Publicidade'},
        {'id': 'Outros', 'nome': 'Outros'},
      ];

  static Future<List<Map<String, dynamic>>> _statusOptions() async => const [
        {'id': 'ATIVO', 'nome': 'Ativo'},
        {'id': 'VENCIDO', 'nome': 'Vencido'},
        {'id': 'EM_RENOVACAO', 'nome': 'Em Renovação'},
        {'id': 'CANCELADO', 'nome': 'Cancelado'},
      ];

  static const List<FieldConfig> _fieldConfigs = [
    FieldConfig(
      label: 'Descrição',
      fieldName: 'descricao',
      icon: Icons.description,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
      isRequired: true,
      fieldType: FieldType.text,
    ),
    FieldConfig(
      label: 'Número',
      fieldName: 'numero',
      icon: Icons.tag,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      fieldType: FieldType.text,
    ),
    FieldConfig(
      label: 'Data Emissão',
      fieldName: 'dataEmissao',
      icon: Icons.calendar_today,
      isInForm: true,
      isVisibleByDefault: true,
      fieldType: FieldType.date,
    ),
    FieldConfig(
      label: 'Data Vencimento',
      fieldName: 'dataVencimento',
      icon: Icons.event,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      fieldType: FieldType.date,
    ),
    FieldConfig(
      label: 'Órgão Emissor',
      fieldName: 'orgaoEmissor',
      icon: Icons.account_balance,
      isInForm: true,
      isVisibleByDefault: true,
      fieldType: FieldType.text,
    ),
    FieldConfig(
      label: 'Tipo de Alvará',
      fieldName: 'tipoAlvara',
      icon: Icons.category,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: _tiposAlvara,
      dropdownValueField: 'id',
      dropdownDisplayField: 'nome',
    ),
    FieldConfig(
      label: 'Status',
      fieldName: 'status',
      icon: Icons.info_outline,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: _statusOptions,
      dropdownValueField: 'id',
      dropdownDisplayField: 'nome',
    ),
    FieldConfig(
      label: 'Observação',
      fieldName: 'observacao',
      icon: Icons.notes,
      isInForm: true,
      isVisibleByDefault: false,
      fieldType: FieldType.multiline,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<AlvaraModel>(
      title: 'Alvarás',
      fetchEndpoint: '${ApiLinks.baseUrl}/api/alvara',
      createEndpoint: '${ApiLinks.baseUrl}/api/alvara',
      updateEndpoint: '${ApiLinks.baseUrl}/api/alvara/:id',
      deleteEndpoint: '${ApiLinks.baseUrl}/api/alvara/:id',
      fromJson: (json) => AlvaraModel.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: (_) => true,
      fieldConfigs: _fieldConfigs,
      idFieldName: 'id',
      useUserBannerAppBar: true,
      enableSearch: true,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      storageKey: 'alvara_mobile_grid',
    );
  }
}
