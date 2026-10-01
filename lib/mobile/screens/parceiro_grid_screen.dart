import 'package:flutter/material.dart';

import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../customization/generic_grid/grid_models.dart';
import '../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/parceiro_form_rules.dart';

class ParceiroGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;

  const ParceiroGridScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
  });

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'parceiro',
      tituloOverride: 'Contatos',
      hasPermission: hasPermission,
      createEndpointOverride: ApiLinks.createParceiro,
      updateEndpointOverride: ApiLinks.updateParceiro(':id'),
      deleteEndpointOverride: ApiLinks.deleteParceiro(':id'),
      onUserBannerTapped: onUserBannerTapped,
      fieldOverrides: [
        ...ParceiroFormRules.mobileModuleSuppression(),
        FieldConfig(
          label: 'CEP',
          fieldName: 'cep',
          icon: Icons.search,
          fieldType: FieldType.cep,
          isInForm: true,
        ),
        FieldConfig(
          label: 'Rua',
          fieldName: 'rua',
          icon: Icons.location_on,
          isInForm: true,
        ),
        FieldConfig(
          label: 'Bairro',
          fieldName: 'bairro',
          icon: Icons.map,
          isInForm: true,
        ),
        FieldConfig(
          label: 'Cidade',
          fieldName: 'cidade',
          icon: Icons.location_city,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () =>
              _loadDropdown('${ApiLinks.baseUrl}/api/cidade?tamanho=6000'),
          dropdownValueField: 'nome',
          dropdownDisplayField: 'nome',
          isInForm: true,
        ),
        FieldConfig(
          label: 'Estado',
          fieldName: 'estado',
          icon: Icons.map_outlined,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () =>
              _loadDropdown('${ApiLinks.baseUrl}/api/estado'),
          dropdownValueField: 'uf',
          dropdownDisplayField: 'nome',
          isInForm: true,
        ),
        FieldConfig(
          label: 'País',
          fieldName: 'pais',
          icon: Icons.public,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () => _loadDropdown(ApiLinks.buscarPaises),
          dropdownValueField: 'nomePt',
          dropdownDisplayField: 'nomePt',
          defaultValue: 'Brasil',
          isInForm: true,
        ),
        FieldConfig(
          label: 'Tipo Cliente',
          fieldName: 'tipoCliente',
          icon: Icons.category,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () => _loadDropdown(ApiLinks.allTipoParceiro),
          dropdownValueField: 'nome',
          dropdownDisplayField: 'nome',
          isInForm: true,
        ),
        FieldConfig(
          label: 'Regime',
          fieldName: 'regime',
          icon: Icons.business_center,
          fieldType: FieldType.dropdown,
          dropdownFutureBuilder: () =>
              _loadDropdown(ApiLinks.allRegimetributario),
          dropdownValueField: 'id',
          dropdownDisplayField: 'codigo',
          isInForm: true,
        ),
      ],
    );
  }

  static Future<List<Map<String, dynamic>>> _loadDropdown(
      String endpoint) async {
    final response = await NetworkCaller().getRequest(endpoint);
    return _extractList(response);
  }

  static List<Map<String, dynamic>> _extractList(NetworkResponse response) {
    if (!response.isSuccess || response.body == null) return [];
    return _extractFrom(response.body);
  }

  static List<Map<String, dynamic>> _extractFrom(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      for (final key in ['data', 'dados', 'items', 'content', 'account']) {
        final nested = map[key];
        if (nested != null) {
          final extracted = _extractFrom(nested);
          if (extracted.isNotEmpty) return extracted;
        }
      }
      return [map];
    }
    return [];
  }
}
