// lib/data/customization/generic_grid_card_1_1.dart
// -----------------------------------------------------------------------------
// GenericMobileGridScreen v1.1
// - Mantém API e comportamento base do 1_0 (busca, filtros, paginação infinita,
//   formulário com campos dinâmicos, upload de arquivo, debug JSON, etc.)
// - 🔐 Suporte a permissões assíncronas (asyncHasPermission)
// - ⚙️ ServerAction (ações vindas do banco / dinâmicas) com confirmação opcional
// - ✅ Botões padrão (criar/editar/excluir) com confirmação antes de executar
// - 🧱 Correções de tipagem em DropdownButtonFormField
// - 🧰 Várias proteções contra nulos e formatos variados de resposta
// -----------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/grid_colors.dart';
import '../utils/grid_texts.dart';

import '../../../models/network_response.dart';
// Serviços existentes no seu projeto
import '../../services/network_caller.dart';
import '../../../models/auth_utility.dart';
import '../../../widgets/user_banners.dart';

// ---------------------- CONFIGS ----------------------
enum FieldType {
  text,
  number,
  email,
  date,
  multiline,
  dropdown,
  boolean,
  file,
  password,
  phone,
  cpf,
  cnpj,
  currency,
  percentage,
  url,
  multiselect,
}

class FileConfig {
  final List<String> allowedExtensions;
  final bool allowMultiple;
  final int maxFileSize;
  final String fileFieldName;

  const FileConfig({
    this.allowedExtensions = const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    this.allowMultiple = false,
    this.maxFileSize = 5 * 1024 * 1024,
    this.fileFieldName = 'file',
  });
}

class FieldConfig {
  final String label;
  final String fieldName;
  final bool isFilterable;
  final bool isInForm;
  final int flex;
  final int maxLines;
  final IconData? icon;
  final bool isSortable;
  final FieldType fieldType;
  final List<Map<String, dynamic>>? dropdownOptions;
  final Future<List<Map<String, dynamic>>> Function()? dropdownFutureBuilder;
  final String dropdownValueField;
  final String dropdownDisplayField;
  final bool isRequired;
  final String? Function(String?)? validator;
  final String? displayFieldName;
  final bool isVisibleByDefault;
  final bool isFixed;
  final bool enabled;
  final dynamic defaultValue;
  final FileConfig? fileConfig;
  final dynamic dropdownSelectedValue;
  final Map<String, dynamic>? fieldSpecificConfig;
  final bool showInCard;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String dateFormat;

  const FieldConfig({
    required this.label,
    required this.fieldName,
    this.isFilterable = true,
    this.isInForm = true,
    this.flex = 1,
    this.maxLines = 1,
    this.icon,
    this.isSortable = true,
    this.fieldType = FieldType.text,
    this.dropdownOptions,
    this.dropdownFutureBuilder,
    this.dropdownValueField = 'value',
    this.dropdownDisplayField = 'label',
    this.isRequired = false,
    this.validator,
    this.displayFieldName,
    this.isVisibleByDefault = true,
    this.isFixed = false,
    this.enabled = true,
    this.defaultValue,
    this.fileConfig,
    this.dropdownSelectedValue,
    this.fieldSpecificConfig,
    this.showInCard = true,
    this.firstDate,
    this.lastDate,
    this.dateFormat = 'dd/MM/yyyy',
  });
}

class PaginationConfig {
  final int defaultRowsPerPage;
  final List<int> availableRowsPerPage;
  final bool showItemsPerPageSelector;

  const PaginationConfig({
    this.defaultRowsPerPage = 25,
    this.availableRowsPerPage = const [10, 25, 50, 100],
    this.showItemsPerPageSelector = true,
  });
}

// ✅ Ação de servidor dinâmica (vinda do banco)
class ServerAction {
  final String label;
  final IconData? icon;
  final String method; // GET/POST/PUT/DELETE
  final String endpoint; // pode conter :id
  final String? confirmMessage;
  final String? requiredPermission;

  const ServerAction({
    required this.label,
    required this.method,
    required this.endpoint,
    this.icon,
    this.confirmMessage,
    this.requiredPermission,
  });
}

class CustomAction {
  final IconData icon;
  final String label;
  final void Function(BuildContext context, Map<String, dynamic> item)
      onPressed;
  final bool Function(Map<String, dynamic> item)? isVisible;

  const CustomAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isVisible,
  });
}

// ---------------------- WIDGET ----------------------
class GenericMobileGridScreen extends StatefulWidget {
  final String title;
  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint; // ':id'
  final String deleteEndpoint; // ':id'
  final bool Function(String permission) hasPermission;
  final Future<bool> Function(String permission)? asyncHasPermission; // 🔥 novo
  final List<FieldConfig> fieldConfigs;

  final String idFieldName;
  final String? dateFieldName;
  final PaginationConfig paginationConfig;

  final void Function(Map<String, dynamic> item, BuildContext context)?
      onItemTap;
  final List<CustomAction> Function()? customActions;

  final bool enableSearch;
  final Map<String, dynamic>? initialFilters;
  final String storageKey;
  final Widget Function(Map<String, dynamic> item)? detailScreenBuilder;
  final Map<String, dynamic>? extraParams;
  final bool enableDebugMode;
  final bool useUserBannerAppBar;
  final VoidCallback? onUserBannerTapped;
  final VoidCallback? onBannerRefresh;

  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic>? item)?
      dynamicAdditionalFormData;

  final String? baseUrlForMultipart;
  final Future<Map<String, String>> Function()? authHeadersProvider;

  // 🔥 Ações dinâmicas vindas do banco
  final List<ServerAction>? serverActions;

  const GenericMobileGridScreen({
    super.key,
    required this.title,
    required this.fetchEndpoint,
    required this.createEndpoint,
    required this.updateEndpoint,
    required this.deleteEndpoint,
    required this.hasPermission,
    this.asyncHasPermission,
    required this.fieldConfigs,
    this.idFieldName = 'id',
    this.dateFieldName,
    this.paginationConfig = const PaginationConfig(),
    this.onItemTap,
    this.customActions,
    this.enableSearch = true,
    this.initialFilters,
    this.storageKey = 'generic_mobile_grid_settings',
    this.detailScreenBuilder,
    this.extraParams,
    this.enableDebugMode = false,
    this.useUserBannerAppBar = false,
    this.onUserBannerTapped,
    this.onBannerRefresh,
    this.additionalFormData,
    this.dynamicAdditionalFormData,
    this.baseUrlForMultipart,
    this.authHeadersProvider,
    this.serverActions = const [],
  });

  @override
  State<GenericMobileGridScreen> createState() =>
      _GenericMobileGridScreenState();
}

class _GenericMobileGridScreenState extends State<GenericMobileGridScreen> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filtered = [];
  final Map<String, List<PlatformFile>> _fileCache = {};

  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;
  bool filtrosAbertos = false;
  bool _isSelectionMode = false;
  final Map<String, bool> _cardSelection = {};
  Set<String> selectedRows = {};
  late List<CustomAction> _customActions;

  final Map<String, TextEditingController> _filterControllers = {};
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 20;
  bool _hasMoreItems = true;

  final Map<String, bool> _fieldVisibility = {};
  Map<String, dynamic>? _itemParaEditar;

  // 🔐 cache de permissões (async)
  final Map<String, bool> _asyncPermCache = {};
  bool _createdResolved = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    for (final c in widget.fieldConfigs) {
      _fieldVisibility[c.fieldName] = c.isVisibleByDefault;
      if (c.isFilterable) {
        _filterControllers[c.fieldName] = TextEditingController();
      }
    }

    if (widget.initialFilters != null) {
      final filters = widget.initialFilters;
      if (filters != null) {
        filters.forEach((k, v) {
          if (_filterControllers.containsKey(k)) {
            final ctrl = _filterControllers[k];
            if (ctrl != null) {
              ctrl.text = v?.toString() ?? '';
            }
          }
        });
      }
    }

    _customActions =
        widget.customActions?.call() ?? [];

    await _loadFieldPreferences();
    _scrollController.addListener(_onScroll);

    // resolve permissões assíncronas para os botões padrão
    await _resolveAsyncPermissions();

    await _loadItems(reset: true);
  }

  Future<void> _resolveAsyncPermissions() async {
    final f = widget.asyncHasPermission;
    // 🔸 Se não existir asyncHasPermission, libera tudo por padrão
    if (f == null) {
      _asyncPermCache.addAll({
        'create': true,
        'edit': true,
        'delete': true,
        'view': true,
      });
      for (final a in widget.serverActions ?? []) {
        if ((a.requiredPermission?.isNotEmpty ?? false)) {
          final perm = a.requiredPermission;
          if (perm != null) {
            _asyncPermCache[perm] = true;
          }
        }
      }
      setState(() {
        _createdResolved = true;
      });
      return;
    }

    // 🔸 Caso exista, tenta resolver as permissões normalmente
    final needs = <String>{'create', 'edit', 'delete', 'view'};
    final also = widget.serverActions
            ?.map((a) => a.requiredPermission)
            .whereType<String>() ??
        const Iterable<String>.empty();
    needs.addAll(also);

    for (final p in needs) {
      try {
        final result = await f(p);
        _asyncPermCache[p] = result == true; // se nulo -> false
      } catch (_) {
        // 🔸 fallback default: true
        _asyncPermCache[p] = true;
      }
    }

    setState(() {
      _createdResolved = true;
    });
  }

  bool _can(String perm) {
    /*
    // 🔹 Se já resolvemos as permissões assíncronas
    if (_createdResolved) {
      // 🔹 Retorna a permissão do cache se existir
      if (_asyncPermCache.containsKey(perm)) {
        return _asyncPermCache[perm] ?? true; // default TRUE
      }
      // 🔹 Se não existir, assume TRUE por padrão
      return true;
    }

    // 🔹 fallback para permissão síncrona
    try {
      return widget.hasPermission(perm);
    } catch (_) {
      // 🔹 fallback total — retorna TRUE
      return true;
  } */
    // "TODO QUANDO APLICAR REGRAS DE PERMISSÃO";
    return true;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final c in _filterControllers.values) {
      c.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFieldPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${widget.storageKey}_${widget.title}';
      for (final c in widget.fieldConfigs) {
        final saved = prefs.getBool('$key${c.fieldName}');
        if (saved != null) _fieldVisibility[c.fieldName] = saved;
      }
    } catch (_) {}
  }

  Future<void> _saveFieldPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${widget.storageKey}_${widget.title}';
      for (final c in widget.fieldConfigs) {
        await prefs.setBool(
          '$key${c.fieldName}',
          _fieldVisibility[c.fieldName] ?? c.isVisibleByDefault,
        );
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (_hasMoreItems && !isLoading) _loadMore();
    }
  }

  Future<void> _loadMore() async => _loadItems(reset: false);

  Future<void> _loadItems({bool reset = true}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _hasMoreItems = true;
        isLoading = true;
      });
    } else {
      setState(() => isLoading = true);
    }

    try {
      final url = _buildUrl(reset ? 0 : _currentPage);
      final NetworkResponse resp = await NetworkCaller().getRequest(url);

      if (resp.statusCode == 200 && resp.body != null) {
        final body = resp.body ?? {};
// Normaliza QUALQUER formato para List<Map<String, dynamic>>
        final list = _extractAnyList(body['data'] ?? body['dados'] ?? body);

// total seguro: tenta nas chaves usuais ou cai no length da lista
        final total = ((body['totalElements'] ??
                body['total'] ??
                (body['data'] is Map ? body['data']['totalElements'] : null) ??
                (body['dados'] is Map
                    ? body['dados']['totalElements']
                    : null))) as int? ??
            list.length;

        final newItems = list; // já está tipado/normalizado

        setState(() {
          if (reset) {
            items = newItems;
          } else {
            items.addAll(newItems);
          }
          filtered = List.from(items);
          _totalItems = total;
          _hasMoreItems = items.length < _totalItems;
          _currentPage++;
        });
      } else {
        _showSnack('Erro ao carregar: ${resp.statusCode}', error: true);
      }
    } catch (e) {
      _showSnack('Erro ao carregar: $e', error: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _buildUrl(int page) {
    String url = '${widget.fetchEndpoint}?page=$page&size=$_itemsPerPage';

    if (_searchController.text.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(_searchController.text)}';
    }

    for (final c in widget.fieldConfigs.where((x) => x.isFilterable)) {
      final v = _filterControllers[c.fieldName]?.text;
      if (v != null && v.isNotEmpty) {
        url += '&${c.fieldName}=${Uri.encodeComponent(v)}';
      }
    }

    if (widget.extraParams != null) {
      final params = widget.extraParams;
      if (params != null) {
        params.forEach((k, v) {
          url += '&$k=${Uri.encodeComponent(v.toString())}';
        });
      }
    }

    return url;
  }

  Future<void> _saveForm(
    Map<String, TextEditingController> controllers,
    BuildContext context, {
    Map<String, dynamic>? editingItem,
  }) async {
    try {
      final formData = <String, dynamic>{};

      if (widget.additionalFormData != null) {
        final data = widget.additionalFormData;
        if (data != null) {
          _addAllNested(formData, data);
        }
      }
      if (widget.dynamicAdditionalFormData != null) {
        final dyn = widget.dynamicAdditionalFormData?.call(editingItem) ?? {};
        _addAllNested(formData, dyn);
      }

      for (final c in widget.fieldConfigs) {
        if (c.fieldType == FieldType.dropdown &&
            c.dropdownSelectedValue != null) {
          _addToFormData(formData, c.fieldName, c.dropdownSelectedValue);
        }
      }

      for (final c in widget.fieldConfigs
          .where((x) => x.isInForm && x.fieldType != FieldType.file)) {
        final ctrl = controllers[c.fieldName];
        final valueText = ctrl?.text ?? '';
        if (valueText.isEmpty) continue;

        if (c.fieldType == FieldType.date) {
          final iso = _tryDateToIso(valueText, c.dateFormat);
          _addToFormData(formData, c.fieldName, iso ?? valueText);
        } else if (c.fieldType == FieldType.number) {
          final numVal = num.tryParse(valueText);
          _addToFormData(formData, c.fieldName, numVal ?? valueText);
        } else if (c.fieldType == FieldType.boolean) {
          _addToFormData(
              formData, c.fieldName, valueText.toLowerCase() == 'true');
        } else {
          _addToFormData(formData, c.fieldName, valueText);
        }
      }

      for (final c in widget.fieldConfigs
          .where((x) => x.isInForm && x.fieldType == FieldType.boolean)) {
        if (!formData.containsKey(c.fieldName)) {
          _addToFormData(formData, c.fieldName, false);
        }
      }

      final filesToUpload = <_MultipartFieldFile>[];
      for (final c
          in widget.fieldConfigs.where((x) => x.fieldType == FieldType.file)) {
        final picked = _fileCache[c.fieldName];
        if (picked != null && picked.isNotEmpty) {
          final cfg = c.fileConfig ?? const FileConfig();
          for (final f in picked) {
            filesToUpload.add(
                _MultipartFieldFile(fieldName: cfg.fileFieldName, file: f));
          }
        }
      }

      final isEditing = editingItem != null;
      final endpoint = isEditing
          ? widget.updateEndpoint
              .replaceFirst(':id', _getId(editingItem).toString())
          : widget.createEndpoint;

      // `resp` pode ser NetworkResponse (JSON) ou _LocalResponse (multipart):
      final dynamic resp;

      if (filesToUpload.isNotEmpty) {
        resp = await _sendMultipart(
          endpoint: endpoint,
          isUpdate: isEditing,
          fields: _flattenForMultipart(formData),
          files: filesToUpload,
        );
      } else {
        final normalized = _normalizeDotted(formData);
        resp = isEditing
            ? await NetworkCaller().putRequest(endpoint, normalized)
            : await NetworkCaller().postRequest(endpoint, normalized);
      }

      if (_respSuccess(resp)) {
        if (mounted) Navigator.pop(context);
        for (final c in widget.fieldConfigs
            .where((x) => x.fieldType == FieldType.file)) {
          _fileCache.remove(c.fieldName);
        }
        _showSnack(isEditing ? 'Item atualizado!' : 'Item criado!');
        await _loadItems(reset: true);
      } else {
        _showSnack(
          'Erro ao salvar: ${_respBody(resp) ?? _respStatus(resp)}',
          error: true,
        );
      }
    } catch (e) {
      _showSnack('Erro ao salvar: $e', error: true);
    }
  }

  // ---------- Helpers p/ tratar NetworkResponse OU _LocalResponse ----------
  bool _respSuccess(dynamic resp) {
    // NetworkResponse (seu tipo)
    try {
      if (resp is NetworkResponse) return resp.isSuccess;
    } catch (_) {}
    // _LocalResponse (multipart)
    if (resp is _LocalResponse) {
      return resp.statusCode >= 200 && resp.statusCode < 300;
    }
    return false;
  }

  int _respStatus(dynamic resp) {
    try {
      if (resp is NetworkResponse) return resp.statusCode ?? 0;
    } catch (_) {}
    if (resp is _LocalResponse) return resp.statusCode;
    return 0;
  }

  dynamic _respBody(dynamic resp) {
    try {
      if (resp is NetworkResponse) return resp.body;
    } catch (_) {}
    if (resp is _LocalResponse) return resp.body;
    return null;
  }

  Future<_LocalResponse> _sendMultipart({
    required String endpoint,
    required bool isUpdate,
    required Map<String, String> fields,
    required List<_MultipartFieldFile> files,
  }) async {
    final uri = _resolveUri(endpoint);
    final request = http.MultipartRequest(isUpdate ? 'PUT' : 'POST', uri);

    if (widget.authHeadersProvider != null) {
      final headers = await widget.authHeadersProvider?.call() ?? {};
      request.headers.addAll(headers);
    } else {
      // Fallback: injeta Bearer token para uploads sem authHeadersProvider (ex. GED dinamico)
      final token = AuthUtility.userInfo?.token;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    request.fields.addAll(fields);

    for (final f in files) {
      if (f.file.bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            f.fieldName,
            f.file.bytes!,
            filename: f.file.name,
            contentType: _lookupContentType(f.file.name),
          ),
        );
      } else if (f.file.path != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            f.fieldName,
            f.file.path!,
            contentType: _lookupContentType(f.file.name),
          ),
        );
      }
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    Map<String, dynamic>? body;
    try {
      body = res.body.isNotEmpty ? (jsonDecode(res.body) as dynamic) : null;
    } catch (_) {
      body = null;
    }

    return _LocalResponse(statusCode: res.statusCode, body: body);
  }

  Uri _resolveUri(String endpoint) {
    if (endpoint.startsWith('http://') || endpoint.startsWith('https://')) {
      return Uri.parse(endpoint);
    }
    if ((widget.baseUrlForMultipart?.isNotEmpty ?? false)) {
      final base = widget.baseUrlForMultipart ?? '';
      final sep = base.endsWith('/') || endpoint.startsWith('/') ? '' : '/';
      return Uri.parse('$base$sep$endpoint');
    }
    return Uri.parse(endpoint);
  }

  Map<String, String> _flattenForMultipart(Map<String, dynamic> src) {
    final out = <String, String>{};
    void walk(String prefix, dynamic v) {
      if (v == null) return;
      if (v is Map) {
        v.forEach((k, val) {
          final key = prefix.isEmpty ? k.toString() : '$prefix.$k';
          walk(key, val);
        });
      } else {
        out[prefix] = v.toString();
      }
    }

    src.forEach((k, v) => walk(k, v));
    return out;
  }

  Future<void> _deleteItem(String id) async {
    try {
      final doDelete = await _confirm(
        title: 'Excluir',
        message: 'Deseja excluir o item #$id? Esta ação não pode ser desfeita.',
        confirmText: 'Excluir',
      );
      if (doDelete != true) return;

      final resp = await NetworkCaller().deleteRequest(
        widget.deleteEndpoint.replaceFirst(':id', id),
      );
      if (resp.isSuccess) {
        _showSnack('Item excluído!');
        await _loadItems(reset: true);
      } else {
        _showSnack('Erro ao excluir: ${resp.statusCode}', error: true);
      }
    } catch (e) {
      _showSnack('Erro ao excluir: $e', error: true);
    }
  }

  void _addToFormData(
      Map<String, dynamic> map, String fieldName, dynamic value) {
    if (!fieldName.contains('.')) {
      map[fieldName] = value;
      return;
    }
    final parts = fieldName.split('.');
    _buildNested(map, parts, value);
  }

  void _buildNested(
      Map<String, dynamic> map, List<String> parts, dynamic value) {
    final head = parts.first;
    if (parts.length == 1) {
      map[head] = value;
      return;
    }
    map[head] =
        (map[head] is Map<String, dynamic>) ? map[head] : <String, dynamic>{};
    _buildNested(map[head] as Map<String, dynamic>, parts.sublist(1), value);
  }

  void _addAllNested(Map<String, dynamic> target, Map<String, dynamic> src) {
    for (final e in src.entries) {
      _addToFormData(target, e.key, e.value);
    }
  }

  Map<String, dynamic> _normalizeDotted(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    for (final e in input.entries) {
      _addToFormData(out, e.key, e.value);
    }
    return out;
  }

  String? _tryDateToIso(String input, String format) {
    try {
      final df = DateFormat(format);
      final dt = df.parseStrict(input);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (_) {
      return null;
    }
  }

  dynamic _getNestedValue(dynamic map, String fieldName) {
    if (map == null) return null;
    if (!fieldName.contains('.')) {
      if (map is! Map) return null;
      final val = map[fieldName];
      if (val != null && (val is int || (val is String && int.tryParse(val) != null))) {
        final nameVal = map['${fieldName}Nome'] ?? map['${fieldName}_nome'];
        if (nameVal != null && nameVal.toString().trim().isNotEmpty) return nameVal;
      }
      return val;
    }
    final parts = fieldName.split('.');
    dynamic v = map;
    for (final p in parts) {
      if (v is Map && v.containsKey(p)) {
        v = v[p];
      } else {
        v = null;
        break;
      }
    }
    if (v != null && v.toString().trim().isNotEmpty) return v;

    if (map is Map && parts.length > 1) {
      final camelAlias = '${parts[0]}${parts[1][0].toUpperCase()}${parts[1].substring(1)}';
      final camelVal = map[camelAlias];
      if (camelVal != null && camelVal.toString().trim().isNotEmpty) return camelVal;
      final snakeAlias = '${parts[0]}_${parts[1]}';
      final snakeVal = map[snakeAlias];
      if (snakeVal != null && snakeVal.toString().trim().isNotEmpty) return snakeVal;
    }

    return v;
  }

  dynamic _getId(Map<String, dynamic> item) {
    return _getNestedValue(item, widget.idFieldName) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: widget.useUserBannerAppBar
          ? PreferredSize(
              preferredSize: Size.fromHeight(
                  widget.useUserBannerAppBar ? 94 : kToolbarHeight),
              child: UserBannerAppBar(
                screenTitle: widget.title,
                onTapped: widget.onUserBannerTapped,
                onUserTap: widget.onUserBannerTapped,
                onRefresh:
                    widget.onBannerRefresh ?? () => _loadItems(reset: true),
                isLoading: isLoading,
                onFilterToggle: () =>
                    setState(() => filtrosAbertos = !filtrosAbertos),
                showFilterButton: widget.useUserBannerAppBar,
              ),
            )
          : (_isSelectionMode
              ? _buildSelectionAppBar(context)
              : _buildNormalAppBar(context)),
      floatingActionButton: _buildFab(),
      body: Column(
        children: [
          if (filtrosAbertos) _buildFilters(context),
          // 🔥 Ações dinâmicas (top bar) se houver
          if ((widget.serverActions?.isNotEmpty ?? false))
            _buildServerActionsBar(context),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator.adaptive(
                  onRefresh: () => _loadItems(reset: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filtered.length + (isLoading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == filtered.length) {
                        return _buildLoadingIndicator(ctx);
                      }
                      return _buildItemCard(ctx, filtered[i], i);
                    },
                  ),
                ),
                if (isLoading && filtered.isEmpty)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- AppBars ----------

  AppBar _buildNormalAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AppBar(
      title: Text(widget.title,
          style: tt.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary)),
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 3,
      actions: [
        IconButton(
          onPressed: isLoading ? null : () => _loadItems(reset: true),
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(cs.onPrimary)),
                )
              : const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: _showFieldSettings,
          icon: const Icon(Icons.view_column),
          tooltip: 'Configurar campos',
        ),
        IconButton(
          onPressed: () => setState(() => filtrosAbertos = !filtrosAbertos),
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtros',
        ),
      ],
    );
  }

  AppBar _buildSelectionAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AppBar(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _toggleSelectionMode,
      ),
      title: Text('${selectedRows.length} selecionado(s)',
          style: tt.bodyMedium?.copyWith(color: cs.onPrimary)),
      actions: [
        if (selectedRows.length == filtered.length)
          IconButton(
              icon: const Icon(Icons.deselect), onPressed: _deselectAllCards)
        else
          IconButton(
              icon: const Icon(Icons.select_all), onPressed: _selectAllCards),
        if (_can('delete') && selectedRows.isNotEmpty)
          IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteSelected),
      ],
    );
  }

  // ---------- Top Actions Bar (dinâmicas) ----------
  Widget _buildServerActionsBar(BuildContext context) {
    final actions = widget.serverActions ?? const <ServerAction>[];
    if (actions.isEmpty) return const SizedBox.shrink();

    final visible = actions.where((a) {
      final perm = a.requiredPermission;
      if (perm == null || perm.isEmpty) return true;
      return _can(perm);
    }).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: visible.map((a) {
          return ElevatedButton.icon(
            icon: Icon(a.icon ?? Icons.play_arrow),
            label: Text(a.label),
            onPressed: () => _runServerAction(context, a, null),
          );
        }).toList(),
      ),
    );
  }

  // ---------- FloatingActionButton (Create) ----------
  Widget? _buildFab() {
    final canCreate = _can('create');
    if (!canCreate) return null;

    return FloatingActionButton(
      onPressed: () async {
        final ok = await _confirm(
          title: 'Novo registro',
          message: 'Deseja abrir o formulário para adicionar um novo item?',
          confirmText: 'Abrir',
        );
        if (ok == true) {
          _openForm();
        }
      },
      backgroundColor: GridColors.primary,
      foregroundColor: GridColors.textPrimary,
      tooltip: GridTexts.add,
      child: const Icon(Icons.add),
    );
  }

  // ---------- Filtros ----------

  Widget _buildFilters(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.filter_alt, color: cs.primary),
            const SizedBox(width: 8),
            Text('Filtros e Busca', style: tt.titleMedium),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => filtrosAbertos = false),
              icon:
                  Icon(Icons.close, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ]),
          const SizedBox(height: 12),
          if (widget.enableSearch) ...[
            Text('Busca Global', style: tt.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar...',
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
              onChanged: (_) => _applyFilters(),
            ),
            const SizedBox(height: 16),
          ],
          Text('Filtros por Campo', style: tt.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: widget.fieldConfigs
                .where((c) => c.isFilterable)
                .map((c) => SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _filterControllers[c.fieldName],
                        decoration: InputDecoration(
                          labelText: c.label,
                          prefixIcon:
                              Icon(c.icon ?? Icons.filter_list_alt, size: 18),
                          suffixIcon: _filterControllers[c.fieldName]
                                      ?.text
                                      .isNotEmpty ==
                                  true
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _filterControllers[c.fieldName]?.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                        ),
                        onChanged: (_) => _applyFilters(),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            FilledButton.tonal(
              onPressed: _clearFilters,
              child: const Row(children: [
                Icon(Icons.clear_all, size: 18),
                SizedBox(width: 6),
                Text('Limpar')
              ]),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _applyFilters,
              child: const Row(children: [
                Icon(Icons.check, size: 18),
                SizedBox(width: 6),
                Text('Aplicar')
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  void _applyFilters() => _loadItems(reset: true);
  void _clearFilters() {
    for (final c in _filterControllers.values) {
      c.clear();
    }
    _searchController.clear();
    _applyFilters();
  }

  // ---------- Lista / Card ----------

  Widget _buildLoadingIndicator(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: _hasMoreItems
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(cs.primary)),
                const SizedBox(height: 12),
                const Text(GridTexts.loadingMore)
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle,
                    color: cs.primary.withValues(alpha: 0.6), size: 40),
                const SizedBox(height: 8),
                const Text(GridTexts.allItemsLoaded)
              ]),
      ),
    );
  }

  Widget _buildItemCard(
      BuildContext context, Map<String, dynamic> item, int index) {
    final id = _getId(item).toString();
    final isSelected = _cardSelection[id] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: isSelected
                  ? GridColors.primary
                  : GridColors.primary.withValues(alpha: 0.3)),
        ),
        color: isSelected
            ? GridColors.primary.withValues(alpha: 0.06)
            : GridColors.card,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _isSelectionMode
              ? () => _toggleCardSelection(id, !isSelected)
              : () => widget.onItemTap?.call(item, context),
          onLongPress: () {
            if (!_isSelectionMode) {
              _toggleSelectionMode();
              _toggleCardSelection(id, true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (_isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (v) => _toggleCardSelection(id, v ?? false),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GridColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('#$id',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: GridColors.primary)),
                ),
                const Spacer(),
                if (_hasStatusField(item)) _buildStatusBadge(item),
              ]),
              const SizedBox(height: 8),
              ..._buildVisibleFieldsForCard(item),
              const SizedBox(height: 8),
              _buildCardActions(item),
            ]),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVisibleFieldsForCard(Map<String, dynamic> item) {
    final visible = widget.fieldConfigs
        .where((c) =>
            _fieldVisibility[c.fieldName] == true &&
            c.fieldName != widget.idFieldName &&
            c.showInCard)
        .toList();
    final rows = <Widget>[];
    for (int i = 0; i < visible.length; i += 2) {
      final children = <Widget>[];
      children.add(_buildFieldInline(visible[i], item));
      if (i + 1 < visible.length) {
        children.add(const SizedBox(width: 16));
        children.add(_buildFieldInline(visible[i + 1], item));
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: children),
      ));
    }
    return rows;
  }

  Widget _buildFieldInline(FieldConfig c, Map<String, dynamic> item) {
    if (c.fieldType == FieldType.file) {
      final display = _getNestedValue(item, c.displayFieldName ?? c.fieldName)
              ?.toString() ??
          '';
      if (display.isEmpty) return const SizedBox.shrink();
      return Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.label,
              style: TextStyle(
                  fontSize: 11, color: Colors.black.withValues(alpha: 0.6))),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.attach_file, size: 14, color: GridColors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                display,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: GridColors.primary,
                ),
              ),
            ),
          ]),
        ]),
      );
    }

    final value =
        _getNestedValue(item, c.displayFieldName ?? c.fieldName)?.toString() ??
            '';
    if (value.isEmpty) return const SizedBox.shrink();
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.label,
            style: TextStyle(
                fontSize: 11, color: Colors.black.withValues(alpha: 0.6))),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _buildStatusBadge(Map<String, dynamic> item) {
    final raw = (_getNestedValue(item, 'status') ??
            _getNestedValue(item, 'ativo') ??
            _getNestedValue(item, 'situacao'))
        ?.toString()
        .toLowerCase();
    Color color;
    String text;
    switch (raw) {
      case 'ativo':
      case 'true':
      case '1':
      case 'aberto':
        color = GridColors.success;
        text = 'Ativo';
        break;
      case 'inativo':
      case 'false':
      case '0':
      case 'fechado':
        color = GridColors.error;
        text = 'Inativo';
        break;
      case 'pendente':
        color = GridColors.warning;
        text = 'Pendente';
        break;
      default:
        color = GridColors.primary;
        text = raw?.toUpperCase() ?? 'Status';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // ---------- Card Actions (Edit/Delete + Server) ----------
  Widget _buildCardActions(Map<String, dynamic> item) {
    final perItemServer = (widget.serverActions ?? const <ServerAction>[])
        .where((a) => (a.endpoint).contains(':id'))
        .where((a) {
      final perm = a.requiredPermission;
      if (perm == null || perm.isEmpty) return true;
      return _can(perm);
    }).toList();

    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      if (widget.enableDebugMode)
        IconButton(
          icon: Icon(Icons.bug_report,
              size: 16, color: Colors.black.withValues(alpha: 0.6)),
          tooltip: 'Ver JSON',
          onPressed: () => _showAllFieldsDebug(context, item),
        ),
      if (_can('view'))
        IconButton(
          icon: Icon(Icons.visibility_outlined,
              size: 16, color: Colors.black.withValues(alpha: 0.6)),
          onPressed: () {
            if (widget.detailScreenBuilder != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => widget.detailScreenBuilder?.call(item) ?? const SizedBox()),
              );
            } else {
              _openDetailPage(item);
            }
          },
        ),
      if (_can('edit'))
        IconButton(
          icon: Icon(Icons.edit_outlined,
              size: 16, color: Colors.black.withValues(alpha: 0.6)),
          onPressed: () async {
            final ok = await _confirm(
              title: 'Editar',
              message: 'Deseja abrir o formulário para editar o item?',
              confirmText: 'Abrir',
            );
            if (ok == true) {
              _openForm(editingItem: item);
            }
          },
        ),
      if (_can('delete'))
        IconButton(
          icon: const Icon(Icons.delete_outline,
              size: 16, color: GridColors.error),
          onPressed: () => _deleteItem(_getId(item).toString()),
        ),
      // server actions por item
      ...perItemServer.map(
        (a) => IconButton(
          icon: Icon(a.icon ?? Icons.play_arrow,
              size: 16, color: Colors.black.withValues(alpha: 0.7)),
          tooltip: a.label,
          onPressed: () => _runServerAction(context, a, item),
        ),
      ),
      // custom actions locais (se houver)
      ..._customActions.where((a) => a.isVisible?.call(item) ?? true).map(
            (a) => IconButton(
              icon: Icon(a.icon,
                  size: 16, color: Colors.black.withValues(alpha: 0.6)),
              onPressed: () => a.onPressed(context, item),
              tooltip: a.label,
            ),
          ),
    ]);
  }

  // ---------- Ações de servidor ----------
  Future<void> _runServerAction(BuildContext context, ServerAction action,
      Map<String, dynamic>? item) async {
    final msg = action.confirmMessage?.trim().isNotEmpty == true
        ? action.confirmMessage!
        : 'Deseja realmente executar "${action.label}"?';
    final ok = await _confirm(
      title: action.label,
      message: msg,
      confirmText: 'Executar',
    );
    if (ok != true) return;

    try {
      final endpoint = item == null
          ? action.endpoint
          : action.endpoint.replaceFirst(':id', _getId(item).toString());

      NetworkResponse resp;
      switch (action.method.toUpperCase()) {
        case 'GET':
          resp = await NetworkCaller().getRequest(endpoint);
          break;
        case 'POST':
          resp = await NetworkCaller().postRequest(endpoint, const {});
          break;
        case 'PUT':
          resp = await NetworkCaller().putRequest(endpoint, const {});
          break;
        case 'DELETE':
          resp = await NetworkCaller().deleteRequest(endpoint);
          break;
        default:
          _showSnack('Método não suportado: ${action.method}', error: true);
          return;
      }

      if (resp.isSuccess) {
        _showSnack('Ação "${action.label}" executada com sucesso!');
        await _loadItems(reset: true);
      } else {
        _showSnack(
          'Falha em "${action.label}": ${resp.statusCode}',
          error: true,
        );
      }
    } catch (e) {
      _showSnack('Erro ao executar ação: $e', error: true);
    }
  }

  // ---------- Form ----------

  void _openForm({Map<String, dynamic>? editingItem}) {
    _itemParaEditar = editingItem;
    showDialog(
      context: context,
      barrierColor: GridColors.primary.withValues(alpha: 0.7),
      builder: (ctx) => _buildFormDialog(editingItem),
    );
  }

  Widget _buildFormDialog(Map<String, dynamic>? editingItem) {
    final formCtrls = <String, TextEditingController>{};
    final data = editingItem ?? <String, dynamic>{};

    for (final c in widget.fieldConfigs.where((x) => x.isInForm)) {
      final initial = _getNestedValue(data, c.fieldName)?.toString() ??
          (c.defaultValue?.toString() ?? '');
      formCtrls[c.fieldName] = TextEditingController(text: initial);
    }

    return Dialog(
      backgroundColor: GridColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GridColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.edit, color: GridColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              editingItem == null ? GridTexts.add : 'Editar',
              style: const TextStyle(
                color: GridColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: GridColors.textPrimary),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: widget.fieldConfigs
                    .where((c) => c.isInForm)
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFormField(c, formCtrls[c.fieldName]!),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GridColors.textPrimary),
                  foregroundColor: GridColors.textPrimary,
                ),
                child: const Text(GridTexts.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  final ok = await _confirm(
                    title: editingItem == null
                        ? 'Confirmar inclusão'
                        : 'Confirmar alteração',
                    message: editingItem == null
                        ? 'Deseja salvar este novo registro?'
                        : 'Deseja salvar as alterações deste registro?',
                    confirmText: GridTexts.save,
                  );
                  if (ok == true) {
                    _saveForm(formCtrls, context, editingItem: editingItem);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.textPrimary,
                  foregroundColor: GridColors.primary,
                ),
                child:
                    Text(editingItem == null ? GridTexts.add : GridTexts.save),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildFormField(FieldConfig c, TextEditingController ctrl) {
    switch (c.fieldType) {
      case FieldType.dropdown:
        return _buildDropdown(c, ctrl);
      case FieldType.boolean:
        return Row(children: [
          Checkbox(
            value: ctrl.text.toLowerCase() == 'true',
            onChanged: c.enabled
                ? (v) => setState(() => ctrl.text = (v ?? false).toString())
                : null,
          ),
          Text(c.label, style: const TextStyle(color: GridColors.textPrimary)),
        ]);
      case FieldType.multiline:
        return _textField(c, ctrl, maxLines: 4);
      case FieldType.date:
        return _dateField(c, ctrl);
      case FieldType.file:
        return _fileField(c, ctrl);
      default:
        return _textField(c, ctrl);
    }
  }

  Widget _textField(FieldConfig c, TextEditingController ctrl,
      {int? maxLines}) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: ctrl,
      enabled: c.enabled,
      maxLines: maxLines ?? c.maxLines,
      decoration: InputDecoration(
        labelText: c.label + (c.isRequired ? ' *' : ''),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      keyboardType: _keyboard(c.fieldType),
    );
  }

  TextInputType _keyboard(FieldType t) {
    switch (t) {
      case FieldType.number:
        return TextInputType.number;
      case FieldType.email:
        return TextInputType.emailAddress;
      case FieldType.phone:
        return TextInputType.phone;
      case FieldType.multiline:
        return TextInputType.multiline;
      default:
        return TextInputType.text;
    }
  }

  Widget _dateField(FieldConfig c, TextEditingController ctrl) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      enabled: c.enabled,
      decoration: InputDecoration(
        labelText: c.label + (c.isRequired ? ' *' : ''),
        suffixIcon: Icon(
          Icons.calendar_today,
          color: c.enabled ? cs.primary : cs.onSurface.withValues(alpha: 0.38),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
      ),
      onTap: c.enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    _parseDate(ctrl.text, c.dateFormat) ?? DateTime.now(),
                firstDate: c.firstDate ?? DateTime(1900),
                lastDate: c.lastDate ?? DateTime(2100),
                locale: const Locale('pt', 'BR'),
              );
              if (picked != null) {
                ctrl.text = DateFormat(c.dateFormat).format(picked);
              }
            }
          : null,
      validator: c.validator,
    );
  }

  DateTime? _parseDate(String v, String format) {
    if (v.isEmpty) return null;
    try {
      return DateFormat(format).parseStrict(v);
    } catch (_) {
      return null;
    }
  }

  Widget _fileField(FieldConfig c, TextEditingController ctrl) {
    final picked = _fileCache[c.fieldName] ?? [];
    final cfg = c.fileConfig ?? const FileConfig();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (picked.isNotEmpty)
        ...picked.map((f) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                leading: const Icon(Icons.attach_file),
                title: Text(f.name, overflow: TextOverflow.ellipsis),
                subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: GridColors.error),
                  onPressed: () {
                    setState(() {
                      _fileCache[c.fieldName]?.remove(f);
                      final cached = _fileCache[c.fieldName];
                      if (cached?.isEmpty ?? false) {
                        _fileCache.remove(c.fieldName);
                      }
                      ctrl.clear();
                    });
                  },
                ),
              ),
            )),
      ElevatedButton.icon(
        onPressed: c.enabled
            ? () async {
                try {
                  final res = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: cfg.allowedExtensions,
                    allowMultiple: cfg.allowMultiple,
                    withData: true,
                  );
                  if (res != null && res.files.isNotEmpty) {
                    final valid = res.files
                        .where((f) => f.size <= cfg.maxFileSize)
                        .toList();
                    if (valid.length != res.files.length) {
                      _showSnack('Alguns arquivos excedem o tamanho permitido.',
                          error: true);
                    }
                    setState(() {
                      _fileCache[c.fieldName] = valid;
                      ctrl.text = valid.map((e) => e.name).join(', ');
                    });
                  }
                } catch (e) {
                  _showSnack('Erro ao selecionar arquivo: $e', error: true);
                }
              }
            : null,
        icon: const Icon(Icons.attach_file),
        label: Text(picked.isEmpty ? GridTexts.selectFile : GridTexts.addFile),
      ),
      if (cfg.allowedExtensions.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Extensões permitidas: ${cfg.allowedExtensions.join(', ')}',
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
          ),
        ),
    ]);
  }

  // 🔧 Tip-safe Dropdown
  Widget _buildDropdown(FieldConfig c, TextEditingController ctrl) {
    Future<List<Map<String, dynamic>>> fetchOptions() async {
      if (c.dropdownFutureBuilder != null) {
        return await c.dropdownFutureBuilder?.call() ?? [];
      }
      return c.dropdownOptions ?? [];
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchOptions(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (s.hasError) {
          return Text('Erro: ${s.error}',
              style: const TextStyle(color: Colors.white));
        }
        final opts = s.data ?? [];

        final seen = <String, Map<String, dynamic>>{};
        for (final o in opts) {
          final v = o[c.dropdownValueField]?.toString() ?? '';
          if (v.isNotEmpty && !seen.containsKey(v)) seen[v] = o;
        }
        final unique = seen.values.toList();

        String? current = ctrl.text.isNotEmpty
            ? ctrl.text
            : (c.defaultValue ?? c.dropdownSelectedValue)?.toString();

        String? safeValue;
        for (final o in unique) {
          final ov = o[c.dropdownValueField]?.toString();
          if (ov == current) {
            safeValue = ov;
            break;
          }
        }

        final items = <DropdownMenuItem<String?>>[];
        if (!c.isRequired || safeValue == null) {
          items.add(const DropdownMenuItem<String?>(
            value: null,
            child: Text('Selecione...', style: TextStyle(color: Colors.grey)),
          ));
        }
        for (final o in unique) {
          final ov = o[c.dropdownValueField]?.toString();
          final ol =
              o[c.dropdownDisplayField]?.toString() ?? ov?.toString() ?? '';
          items.add(DropdownMenuItem<String?>(value: ov, child: Text(ol)));
        }

        final validValue =
            items.any((i) => i.value == safeValue) ? safeValue : null;
        return AbsorbPointer(
          absorbing: !c.enabled,
          child: Opacity(
            opacity: c.enabled ? 1 : 0.6,
            child: DropdownButtonFormField<String?>(
              isExpanded: true,
              initialValue: validValue,
              items: items,
              onChanged:
                  c.enabled ? (v) => setState(() => ctrl.text = v ?? '') : null,
              decoration: InputDecoration(
                labelText: c.label + (c.isRequired ? ' *' : ''),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (v) {
                if (c.isRequired && (v == null || (v.isEmpty))) {
                  return '${c.label} é obrigatório';
                }
                return c.validator?.call(v?.toString());
              },
            ),
          ),
        );
      },
    );
  }

  // ---------- Seleção múltipla ----------

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _cardSelection.clear();
        selectedRows.clear();
      }
    });
  }

  void _toggleCardSelection(String id, bool selected) {
    setState(() {
      if (selected) {
        _cardSelection[id] = true;
        selectedRows.add(id);
      } else {
        _cardSelection.remove(id);
        selectedRows.remove(id);
      }
    });
  }

  void _selectAllCards() {
    setState(() {
      for (final it in filtered) {
        final id = _getId(it).toString();
        _cardSelection[id] = true;
        selectedRows.add(id);
      }
    });
  }

  void _deselectAllCards() {
    setState(() {
      _cardSelection.clear();
      selectedRows.clear();
    });
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Excluir ${selectedRows.length} item(s)?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in selectedRows) {
                await _deleteItem(id);
              }
              setState(() {
                selectedRows.clear();
                _cardSelection.clear();
                _isSelectionMode = false;
              });
              await _loadItems(reset: true);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // ---------- Outras UIs ----------

  void _openDetailPage(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DetalhePageV11(
          titulo: widget.title,
          item: item,
          fieldConfigs: widget.fieldConfigs,
        ),
      ),
    );
  }

  void _showAllFieldsDebug(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(children: [
            const Text('DEBUG - JSON do item',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(const JsonEncoder.withIndent('  ').convert(item)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar')),
          ]),
        ),
      ),
    );
  }

  void _showFieldSettings() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          title: const Text('Campos visíveis'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: widget.fieldConfigs.map((c) {
                return CheckboxListTile(
                  title: Text(c.label),
                  value: _fieldVisibility[c.fieldName] ?? c.isVisibleByDefault,
                  onChanged: c.isFixed
                      ? null
                      : (v) {
                          setSt(() {
                            _fieldVisibility[c.fieldName] = v ?? false;
                          });
                        },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(GridTexts.cancel)),
            ElevatedButton(
              onPressed: () async {
                await _saveFieldPreferences();
                if (mounted) setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      }),
    );
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? GridColors.error : GridColors.success,
        behavior: SnackBarBehavior.floating,
        action: error
            ? SnackBarAction(
                label: 'Copiar',
                textColor: Colors.white,
                onPressed: () => Clipboard.setData(ClipboardData(text: msg)),
              )
            : null,
      ),
    );
  }

  bool _hasStatusField(Map<String, dynamic> item) {
    return item.containsKey('status') ||
        item.containsKey('ativo') ||
        item.containsKey('situacao');
  }

  // ---------- Utils ----------

  Future<bool?> _confirm({
    required String title,
    required String message,
    String confirmText = 'Confirmar',
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

// --------------- Auxiliares multipart ----------------
class _MultipartFieldFile {
  final String fieldName;
  final PlatformFile file;
  _MultipartFieldFile({required this.fieldName, required this.file});
}

http_parser.MediaType? _lookupContentType(String filename) {
  final ext = filename.split('.').last.toLowerCase();
  switch (ext) {
    case 'png':
      return http_parser.MediaType('image', 'png');
    case 'jpg':
    case 'jpeg':
      return http_parser.MediaType('image', 'jpeg');
    case 'pdf':
      return http_parser.MediaType('application', 'pdf');
    case 'doc':
      return http_parser.MediaType('application', 'msword');
    case 'docx':
      return http_parser.MediaType('application',
          'vnd.openxmlformats-officedocument.wordprocessingml.document');
    default:
      return null;
  }
}

// ---- Normalizador de listas vindas da API ----
List<Map<String, dynamic>> _extractAnyList(dynamic body) {
  if (body == null) return <Map<String, dynamic>>[];

  // Caso já seja uma lista de mapas
  if (body is List) {
    return body
        .whereType<Map>()
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // Se veio como Map, tentamos achar uma lista dentro de chaves comuns
  if (body is Map) {
    final map = Map<String, dynamic>.from(body);

    // Chaves comuns em APIs
    final candidates = [
      map['data'],
      map['dados'],
      map['content'],
      map['items'],
      map['results'],
      map['list'],
    ];

    for (final c in candidates) {
      if (c is List) {
        return c
            .whereType<Map>()
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    // Nenhuma lista interna? então é um objeto único: devolve lista com 1 elemento
    return [map];
  }

  // Se veio String JSON, tenta decodificar
  if (body is String) {
    try {
      return _extractAnyList(jsonDecode(body));
    } catch (_) {}
  }

  return <Map<String, dynamic>>[];
}

class _LocalResponse {
  final int statusCode;
  final Map<String, dynamic>? body;
  _LocalResponse({required this.statusCode, this.body});
}

// -----------------------------------------------------------------------------
// 📄 Página de detalhes com exportação PDF (para GenericMobileGridScreen v1.1)
// -----------------------------------------------------------------------------
class _DetalhePageV11 extends StatelessWidget {
  final String titulo;
  final Map<String, dynamic> item;
  final List<FieldConfig> fieldConfigs;

  const _DetalhePageV11({
    required this.titulo,
    required this.item,
    required this.fieldConfigs,
  });

  @override
  Widget build(BuildContext context) {
    final campos =
        fieldConfigs.where((f) => f.isInForm || f.showInCard).toList();

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportPdf(context, campos),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: campos.map((f) => _buildFieldCard(f)).toList(),
        ),
      ),
    );
  }

  Widget _buildFieldCard(FieldConfig campo) {
    final valor = _resolverValor(campo);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: GridColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              campo.icon ?? Icons.label_outline,
              size: 18,
              color: GridColors.secondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campo.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GridColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 14,
                      color: GridColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolverValor(FieldConfig campo) {
    dynamic raw = _getNestedValue(item, campo.fieldName);
    if (raw == null) return '—';

    if (campo.fieldType == FieldType.boolean) {
      return raw == true || raw == 'true' ? 'Sim' : 'Não';
    }
    if (campo.fieldType == FieldType.date) {
      try {
        final dt = DateTime.parse(raw.toString());
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }
    if (campo.fieldType == FieldType.dropdown) {
      final displayField = campo.displayFieldName ?? campo.dropdownDisplayField;
      if (raw is Map && raw.containsKey(displayField)) {
        return raw[displayField].toString();
      }
      final options = campo.dropdownOptions ?? [];
      for (final opt in options) {
        if (opt[campo.dropdownValueField].toString() == raw.toString()) {
          return opt[displayField]?.toString() ?? raw.toString();
        }
      }
    }
    return raw.toString();
  }

  dynamic _getNestedValue(dynamic map, String fieldName) {
    if (map == null) return null;
    if (!fieldName.contains('.')) {
      if (map is! Map) return null;
      return map[fieldName];
    }
    final parts = fieldName.split('.');
    dynamic v = map;
    for (final p in parts) {
      if (v is Map && v.containsKey(p)) {
        v = v[p];
      } else {
        return null;
      }
    }
    return v;
  }

  Future<void> _exportPdf(
      BuildContext context, List<FieldConfig> campos) async {
    final doc = pw.Document();

    final linhas = campos
        .map((f) => MapEntry(f.label, _resolverValor(f)))
        .where((e) => e.value != '—')
        .toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.green900),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Campo',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Valor',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...linhas.asMap().entries.map((entry) {
                    final par = entry.key.isEven;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: par ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            entry.value.key,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            entry.value.value,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await doc.save();
    if (!context.mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '$titulo.pdf',
    );
  }
}
