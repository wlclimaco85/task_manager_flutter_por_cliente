import 'package:flutter/material.dart';

import '../../../models/obrigacao_fiscal_model.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show FieldConfigWindows, FieldType;
import '../../../utils/api_links.dart';
import '../../../services/network_caller.dart';

class WindowsObrigacaoFiscalGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsObrigacaoFiscalGridScreen({super.key, required this.hasPermission});

  static Future<List<Map<String, dynamic>>> _loadRegimes() async {
    try {
      final r = await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/regime_tributario');
      if (!r.isSuccess || r.body == null) return [];
      final d = r.body!['data'];
      List lista = d is List ? d : (d is Map ? d['dados'] ?? d['content'] ?? [] : []);
      return lista.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }

  static Future<List<Map<String, dynamic>>> _loadSetores() async {
    try {
      final r = await NetworkCaller().getRequest('${ApiLinks.baseUrl}/api/setor');
      if (!r.isSuccess || r.body == null) return [];
      final d = r.body!['data'];
      List lista = d is List ? d : (d is Map ? d['dados'] ?? d['content'] ?? [] : []);
      return lista.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) { return []; }
  }

  static List<Map<String, dynamic>> _periodicidadeFallback() => [
    {'id': 'MENSAL',     'nome': 'Mensal'},
    {'id': 'TRIMESTRAL', 'nome': 'Trimestral'},
    {'id': 'SEMESTRAL',  'nome': 'Semestral'},
    {'id': 'ANUAL',      'nome': 'Anual'},
  ];

  static Future<List<Map<String, dynamic>>> _loadPeriodicidade() async {
    return _periodicidadeFallback();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<ObrigacaoFiscal>(
      telaNome: 'obrigacao_fiscal',
      hasPermission: hasPermission,
      fromJson: (json) => ObrigacaoFiscal.fromJson(json),
      toJson: (a) => a.toJson(),
      fieldOverrides: const [
        // Suprime campos brutos de FK gerados pelo banco
        FieldConfigWindows(fieldName: 'regime_tributario_id', label: '', isInForm: false, isVisibleByDefault: false, enabled: false),
        FieldConfigWindows(fieldName: 'setor_id',             label: '', isInForm: false, isVisibleByDefault: false, enabled: false),
        FieldConfigWindows(fieldName: 'regime_tributario',    label: '', isInForm: false, isVisibleByDefault: false, enabled: false),

        // Periodicidade → dropdown local
        FieldConfigWindows(
          label: 'Periodicidade',
          fieldName: 'periodicidade',
          fieldType: FieldType.dropdown,
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          enabled: true,
          isInForm: true,
          isFilterable: true,
          dropdownFutureBuilder: _loadPeriodicidade,
        ),

        // Regime Tributário → dropdown
        FieldConfigWindows(
          label: 'Regime Tributário',
          fieldName: 'regime',
          displayFieldName: 'regime.codigo',
          fieldType: FieldType.dropdown,
          dropdownValueField: 'id',
          dropdownDisplayField: 'codigo',
          enabled: true,
          isInForm: true,
          isFilterable: true,
          dropdownFutureBuilder: _loadRegimes,
        ),

        // Setor → dropdown
        FieldConfigWindows(
          label: 'Setor',
          fieldName: 'setor',
          displayFieldName: 'setor.descricao',
          fieldType: FieldType.dropdown,
          dropdownValueField: 'id',
          dropdownDisplayField: 'descricao',
          enabled: true,
          isInForm: true,
          dropdownFutureBuilder: _loadSetores,
        ),

        // Checkboxes
        FieldConfigWindows(
          label: 'Ativo',
          fieldName: 'ativo',
          fieldType: FieldType.boolean,
          enabled: true,
          isInForm: true,
          isFilterable: true,
        ),
        FieldConfigWindows(
          label: 'Gerar Chamado',
          fieldName: 'gerChamado',
          fieldType: FieldType.boolean,
          enabled: true,
          isInForm: true,
          isFilterable: true,
        ),
      ],
    );
  }
}
