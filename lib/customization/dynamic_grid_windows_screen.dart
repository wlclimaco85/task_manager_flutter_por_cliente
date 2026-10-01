// lib/data/customization/dynamic_grid_windows_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/financial_account_form_rules.dart';

import '../../services/network_caller.dart';
import '../../services/tela_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/tenant_context.dart';

import '../../../widgets/generic_grid_windows_screen.dart'
    show
        FieldConfigWindows,
        FileConfig,
        FieldType,
        GenericGridScreen,
        GenericGridScreenState,
        ExportConfig,
        PaginationConfig,
        CustomAction,
        BulkAction;

import '../models/telas_model.dart';
import '../config/screen_field_overrides.dart';

typedef SecurityCheck = bool Function(String permission);
typedef CustomActionsBuilder<T> = List<CustomAction<T>> Function();

class DynamicGridWindowsScreen<T> extends StatefulWidget {
  final String telaNome;
  final SecurityCheck hasPermission;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final Widget Function(T item)? detailScreenBuilder;
  final Map<String, dynamic>? extraParams;
  final Map<String, dynamic>? additionalFormData;
  /// Ver GenericGridScreen.transformFormData — repassado como está.
  final Map<String, dynamic> Function(Map<String, dynamic> formData)?
      transformFormData;
  final CustomActionsBuilder<T>? customActions;

  /// Ver GenericGridScreen.bulkActions — repassado como está (lista direta,
  /// e não builder, pois não depende de estado reconstruído a cada abertura
  /// de menu como customActions).
  final List<BulkAction<T>>? bulkActions;
  final List<FieldConfigWindows>? fieldOverrides;
  final bool showAppBar;
  // Overrides de endpoint — quando informados substituem os valores que viriam da config da tela
  final String? fetchEndpointOverride;
  final String? createEndpointOverride;
  final String? updateEndpointOverride;
  final String? deleteEndpointOverride;
  final List<Widget>? headerActions;
  // Fix card #470: permite exibir um titulo diferente do gerado
  // automaticamente a partir de telaNome (ex.: "conta_receber" -> "Conta
  // Receber"), sem duplicar toda a config de tela. Usado pela tela
  // Mensalidades, que reaproveita telaNome='conta_receber' filtrado por
  // categoria financeira mas precisa exibir "Mensalidades" no cabeçalho.
  final String? tituloOverride;
  final void Function()? onAfterCreate;
  final Future<void> Function(Map<String, dynamic> formData, T? item)?
      onAfterSave;
  final void Function(Set<String> ids, List<Map<String, dynamic>> selectedData)?
      onSelectedRowsChanged;

  /// Ver GenericGridScreen.prefetchExtraFields/onAfterSave — repassados como
  /// estão, sem lógica própria neste nível (só plumbing).
  final Future<Map<String, dynamic>> Function(T item)? prefetchExtraFields;

  const DynamicGridWindowsScreen({
    super.key,
    required this.telaNome,
    required this.hasPermission,
    required this.fromJson,
    required this.toJson,
    this.detailScreenBuilder,
    this.extraParams,
    this.additionalFormData,
    this.transformFormData,
    this.customActions,
    this.bulkActions,
    this.fieldOverrides,
    this.showAppBar = true,
    this.fetchEndpointOverride,
    this.createEndpointOverride,
    this.updateEndpointOverride,
    this.deleteEndpointOverride,
    this.headerActions,
    this.tituloOverride,
    this.onAfterCreate,
    this.onAfterSave,
    this.onSelectedRowsChanged,
    this.prefetchExtraFields,
  });

  @override
  State<DynamicGridWindowsScreen<T>> createState() =>
      DynamicGridWindowsScreenState<T>();
}

class DynamicGridWindowsScreenState<T>
    extends State<DynamicGridWindowsScreen<T>> {
  late Future<TelaConfig> _telaFuture;
  final GlobalKey<GenericGridScreenState<T>> _gridKey = GlobalKey();

  void showColumnSettings() => _gridKey.currentState?.showColumnSettings();
  void exportCsv() => _gridKey.currentState?.exportCsv();
  void showHelp() => _gridKey.currentState?.showHelp();
  void reload() => _gridKey.currentState?.reload();

  @override
  void initState() {
    super.initState();
    _telaFuture = _loadTela();
  }

  Future<TelaConfig> _loadTela() async {
    // Tenta até 5 vezes com delay crescente antes de desistir
    const maxTentativas = 5;
    for (int i = 1; i <= maxTentativas; i++) {
      final tela =
          await TelaService(networkCaller: NetworkCaller()).getTelaFromCache(
        widget.telaNome,
        empId: TenantContext.empresaId,
        clienteId: TenantContext.parceiroId,
      );
      if (tela != null) return tela;
      if (i < maxTentativas) {
        await Future.delayed(Duration(seconds: i * 2)); // 2s, 4s, 6s, 8s
      }
    }
    throw Exception("Tela '${widget.telaNome}' não encontrada.");
  }

  // ─────────────────────────────────────────────────────────────────────────
  List<FieldConfigWindows> _convert(List<TelaField> fields) {
    final overrides =
        widget.fieldOverrides ?? kScreenFieldOverrides[widget.telaNome] ?? [];

    // Overrides de SUPRESSÃO: isInForm=false — apenas ocultam o campo bruto
    final suppressMap = <String, FieldConfigWindows>{
      for (final o in overrides.where((o) => !o.isInForm))
        o.fieldName.toLowerCase(): o,
    };
    // Índice normalizado (sem underscore) para match snake_case ↔ camelCase
    // Ex: override 'parceiroRec' → chave 'parceirorec' captura campo 'parceiro_rec' do DB
    final suppressMapNorm = <String, FieldConfigWindows>{
      for (final o in overrides.where((o) => !o.isInForm))
        o.fieldName.toLowerCase().replaceAll('_', ''): o,
    };

    // Overrides de SUBSTITUIÇÃO: isInForm=true — substituem por dropdown/etc
    final replaceMap = <String, FieldConfigWindows>{
      for (final o in overrides.where((o) => o.isInForm)) o.fieldName: o,
    };
    final replaceMapLower = <String, FieldConfigWindows>{
      for (final o in overrides.where((o) => o.isInForm))
        o.fieldName.toLowerCase(): o,
    };
    final dropdownReplaceNames = overrides
        .where((o) =>
            o.isInForm &&
            (o.fieldType == FieldType.dropdown ||
                o.fieldType == FieldType.multiselect))
        .map((o) => o.fieldName.toLowerCase())
        .toSet();

    // Pré-computa todos os nomes de dropdown (replace + backend)
    final allDropdownNames = <String>{...dropdownReplaceNames};
    for (final f in fields) {
      if ((f.dropdownEndpoint?.isNotEmpty ?? false)) {
        allDropdownNames.add(f.fieldName.toLowerCase());
      }
    }

    final insertedReplace = <String>{};
    final backendFieldNames = <String>{};
    final converted = <FieldConfigWindows>[];

    for (final f in fields) {
      backendFieldNames.add(f.fieldName);
      final fn = f.fieldName;
      final fnLower = fn.toLowerCase();
      final fnNorm = fnLower.replaceAll('_', '');

      // ── 1. Campo suprimido explicitamente ─────────────────────────────
      // Match exacto (toLowerCase) OU normalizado sem underscores (camelCase ↔ snake_case)
      final suppressEntry = suppressMap[fnLower] ?? suppressMapNorm[fnNorm];
      if (suppressEntry != null) {
        // Adiciona como oculto (para grid mas não form)
        converted.add(suppressEntry);
        // Verifica se existe um replace override correspondente para adicionar
        // Ex: app_id suprimido → adiciona dropdown "aplicativo"
        final base = _extractBase(fnLower);
        if (base != null &&
            dropdownReplaceNames.contains(base) &&
            !insertedReplace.contains(base)) {
          insertedReplace.add(base);
          final fieldConfig = replaceMapLower[base];
          if (fieldConfig != null) {
            converted.add(fieldConfig);
          }
        }
        continue;
      }

      // ── 2. Override de substituição exato ─────────────────────────────
      final fnNormKey = fnNorm;
      final matchedReplace = replaceMap[fn] ??
          replaceMapLower[fnLower] ??
          replaceMapLower.entries
              .where((e) => e.key.replaceAll('_', '') == fnNormKey)
              .map((e) => e.value)
              .firstOrNull;
      if (matchedReplace != null) {
        final key = matchedReplace.fieldName.toLowerCase();
        if (!insertedReplace.contains(key)) {
          insertedReplace.add(key);
          converted.add(matchedReplace);
        }
        continue;
      }

      // ── 3. Campo FK de um replace override ────────────────────────────
      // Ex: "cidade_id" → base "cidade" → replace "cidade" existe → usa replace
      final base = _extractBase(fnLower);
      if (base != null && dropdownReplaceNames.contains(base)) {
        backendFieldNames.add(base);
        if (!insertedReplace.contains(base)) {
          insertedReplace.add(base);
          final fieldConfig = replaceMapLower[base];
          if (fieldConfig != null) {
            converted.add(fieldConfig);
          }
        }
        continue;
      }
      // Também tenta match normalizado (ex: "appId" → "app" → "aplicativo")
      if (base != null) {
        final baseNorm = base.replaceAll('_', '');
        final matchName = dropdownReplaceNames.firstWhere(
            (n) =>
                n.replaceAll('_', '') == baseNorm ||
                n.contains(base) ||
                base.contains(n),
            orElse: () => '');
        if (matchName.isNotEmpty && !insertedReplace.contains(matchName)) {
          insertedReplace.add(matchName);
          final fieldConfig = replaceMapLower[matchName];
          if (fieldConfig != null) {
            converted.add(fieldConfig);
          }
          continue;
        }
      }

      // ── 4. Campos de data automática → ocultar ─────────────────────────
      if (fnLower == 'dh_created_at' ||
          fnLower == 'dh_updated_at' ||
          fnLower == 'dhcreatedat' ||
          fnLower == 'dhupdatedat' ||
          fnLower == 'created_at' ||
          fnLower == 'updated_at') {
        converted.add(FieldConfigWindows(
            label: f.label,
            fieldName: fn,
            isInForm: false,
            isVisibleByDefault: false));
        continue;
      }

      // ── 5. Suprimir IDs brutos de FK (pré-computado) ───────────────────
      if (_isRawFkIdField(fnLower, allDropdownNames)) continue;

      // ── 6. Auto-dropdown / auto-multiselect do backend ─────────────────
      final isAutoFk = (f.dropdownEndpoint?.isNotEmpty ?? false) &&
          !f.multiSelect;
      final isAutoMs =
          f.multiSelect || f.fieldType == TelaFieldType.multiselect;

      converted.add(FieldConfigWindows(
        label: f.label,
        fieldName: fn,
        displayFieldName: f.displayFieldName,
        isFilterable: f.isFilterable,
        isInForm: f.isInForm,
        flex: f.flex,
        maxLines: f.maxLines,
        icon: f.iconData,
        isSortable: f.isSortable,
        fieldType: isAutoMs
            ? FieldType.multiselect
            : isAutoFk
                ? FieldType.dropdown
                : _telaType(f.fieldType, fn),
        dropdownValueField:
            f.dropdownValueField.isNotEmpty ? f.dropdownValueField : 'value',
        dropdownDisplayField: f.dropdownDisplayField.isNotEmpty
            ? f.dropdownDisplayField
            : 'label',
        dropdownOptions: f.dropdownOptions
            .map((opt) => {
                  'value': opt.optionValue,
                  'label': opt.optionLabel ?? opt.optionValue.toString(),
                })
            .toList(),
        dropdownFutureBuilder:
            (isAutoFk || isAutoMs) && f.dropdownEndpoint != null
                ? _makeFuture(f.dropdownEndpoint ?? '')
                : null,
        isRequired: f.isRequired,
        validator: (v) => (f.isRequired && (v == null || v.isEmpty))
            ? '${f.label} é obrigatório'
            : null,
        isVisibleByDefault: f.isVisibleByDefault,
        isFixed: f.isFixed,
        enabled: (isAutoFk || isAutoMs)
            ? true
            : (f.fieldType == TelaFieldType.boolean)
                ? true
                : f.enabled,
        defaultValue: f.defaultValue,
        fileConfig: f.fieldType == TelaFieldType.file
            ? FileConfig(
                allowedExtensions: f.allowedExtensions,
                allowMultiple: f.allowMultipleFiles,
                maxFileSize: f.maxFileSize,
                fileFieldName: f.fileFieldName)
            : null,
        dropdownSelectedValue: f.defaultValue,
        fieldOrder: f.fieldOrder > 0 ? f.fieldOrder : null,
      ));
    }

    // Replace overrides não inseridos (campos que não existem no backend)
    for (final o in overrides.where((o) => o.isInForm)) {
      final key = o.fieldName.toLowerCase();
      if (!backendFieldNames.map((n) => n.toLowerCase()).contains(key) &&
          !insertedReplace.contains(key)) {
        converted.add(o);
      }
    }

    // Ordena campos que têm fieldOrder explícito (Flutter-only overrides ou
    // backend fields com fieldOrder definido) mantendo estabilidade dos demais.
    // Campos sem fieldOrder ficam em sua posição relativa original.
    final hasExplicit = converted.any((f) => f.fieldOrder != null);
    if (hasExplicit) {
      converted.sort((a, b) {
        final oa = financialAccountFormOrder(
          screenName: widget.telaNome,
          fieldName: a.fieldName,
          backendOrder: a.fieldOrder ?? 9999,
          isRequired: a.isRequired,
        );
        final ob = financialAccountFormOrder(
          screenName: widget.telaNome,
          fieldName: b.fieldName,
          backendOrder: b.fieldOrder ?? 9999,
          isRequired: b.isRequired,
        );
        return oa.compareTo(ob);
      });
    }

    return converted;
  }

  /// Extrai o nome base de um campo ID (ex: "app_id" → "app", "cod_app" → "app")
  static String? _extractBase(String fnLower) {
    if (fnLower.endsWith('_id') && fnLower.length > 3)
      return fnLower.substring(0, fnLower.length - 3);
    if (fnLower.startsWith('id_') && fnLower.length > 3)
      return fnLower.substring(3);
    if (fnLower.startsWith('cod_') && fnLower.length > 4)
      return fnLower.substring(4);
    if (fnLower.endsWith('id') &&
        fnLower.length > 2 &&
        !fnLower.contains('_')) {
      return fnLower.substring(0, fnLower.length - 2);
    }
    return null;
  }

  /// Retorna true se o campo é um ID bruto de FK que deve ser suprimido
  static bool _isRawFkIdField(String fnLower, Set<String> allDropdownNames) {
    const alwaysHide = {
      'file_id',
      'foto_id',
      'foto_perfil_id',
      'academia_id',
      'cod_personal',
      'cod_produtor',
      'parent_id',
      'user_id',
      'audit_id',
    };
    if (alwaysHide.contains(fnLower)) return true;

    final base = _extractBase(fnLower);
    if (base == null || base.length < 2) return false;

    for (final name in allDropdownNames) {
      if (name == base ||
          name.contains(base) ||
          base.contains(name) ||
          name.replaceAll('_', '') == base.replaceAll('_', '')) {
        return true;
      }
    }
    return false;
  }

  FieldType _telaType(TelaFieldType tft, String fn) {
    final f = fn.toLowerCase();
    if (f == 'senha' || f.endsWith('_senha') || f == 'password')
      return FieldType.password;
    if (f == 'email' || f.endsWith('_email')) return FieldType.email;
    if (f == 'cpf' || f.endsWith('_cpf')) return FieldType.cpfCnpj;
    if (f == 'cnpj' || f.endsWith('_cnpj')) return FieldType.cpfCnpj;
    if (f == 'cpfcnpj' || f == 'cpf_cnpj' || f == 'documento')
      return FieldType.cpfCnpj;
    if (f == 'cep' || f.endsWith('_cep')) return FieldType.cep;
    if (f == 'telefone' || f == 'celular' || f.endsWith('_telefone'))
      return FieldType.phone;
    if (tft.index < FieldType.values.length) return FieldType.values[tft.index];
    return FieldType.text;
  }

  Future<List<Map<String, dynamic>>> Function() _makeFuture(String endpoint) {
    return () async {
      try {
        final url = endpoint.startsWith('http')
            ? endpoint
            : ApiLinks.baseUrl + endpoint;
        final resp = await NetworkCaller().getRequest(url);
        if (resp.isSuccess && resp.body != null) return _extractList(resp.body);
      } catch (e) {
        L.e('Dropdown error: $e');
      }
      return [];
    };
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    try {
      if (data is List)
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      if (data is Map) {
        final d1 =
            data['data'] ?? data['dados'] ?? data['items'] ?? data['content'];
        if (d1 is List)
          return d1.map((e) => Map<String, dynamic>.from(e)).toList();
        if (d1 is Map) {
          final d2 = d1['dados'] ?? d1['content'] ?? d1['items'];
          if (d2 is List)
            return d2.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      if (data is String) return _extractList(jsonDecode(data));
    } catch (_) {}
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TelaConfig>(
      future: _telaFuture,
      builder: (ctx, snap) {
        // Erro definitivo — tela não encontrada após todas as tentativas
        if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Tela "${widget.telaNome}" não encontrada.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                      onPressed: () => setState(() {
                        _telaFuture = _loadTela();
                      }),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Carregando (inclui quando retornou null — fica em loading)
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final tela = snap.data;
        if (tela == null) {
          return const Scaffold(
            body: Center(child: Text('Erro: dados indisponíveis')),
          );
        }
        final fields = _convert(tela.fields);

        return GenericGridScreen<T>(
          key: _gridKey,
          title: widget.tituloOverride ?? tela.titulo,
          fetchEndpoint: widget.fetchEndpointOverride ??
              (ApiLinks.baseUrl + tela.fetchEndpoint),
          createEndpoint: widget.createEndpointOverride ??
              (ApiLinks.baseUrl + tela.createEndpoint),
          updateEndpoint: widget.updateEndpointOverride ??
              (ApiLinks.baseUrl + tela.updateEndpoint),
          deleteEndpoint: widget.deleteEndpointOverride ??
              (ApiLinks.baseUrl + tela.deleteEndpoint),
          fromJson: widget.fromJson,
          toJson: widget.toJson,
          hasPermission: widget.hasPermission,
          FieldConfigWindowss: fields,
          idFieldName: tela.idFieldName,
          dateFieldName: tela.dateFieldName ?? 'createdAt',
          enableSearch: tela.enableSearch,
          enableColumnReorder: true,
          exportConfig: const ExportConfig(
              enableCsvExport: true, filenamePrefix: 'dynamic'),
          paginationConfig: const PaginationConfig(),
          detailScreenBuilder: widget.detailScreenBuilder,
          extraParams: widget.extraParams,
          additionalFormData: widget.additionalFormData,
          transformFormData: widget.transformFormData,
          customActions: widget.customActions,
          bulkActions: widget.bulkActions,
          showAppBar: widget.showAppBar,
          headerActions: widget.headerActions,
          helpTelaNome: tela.nome,
          onAfterCreate: widget.onAfterCreate != null
              ? () => widget.onAfterCreate?.call()
              : null,
          onAfterSave: widget.onAfterSave,
          onSelectedRowsChanged: widget.onSelectedRowsChanged,
          prefetchExtraFields: widget.prefetchExtraFields,
        );
      },
    );
  }
}
