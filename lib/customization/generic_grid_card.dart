import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/grid_colors.dart';
import '../utils/grid_texts.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../services/upload_file_caller.dart';
import '../../../widgets/user_banners.dart';

import 'package:task_manager_flutter/utils/app_logger.dart';
import '../widgets/searchable_dropdown.dart';
import '../mobile/widgets/mobile_detalhe_popup.dart';
// ==============================================
// MOBILE GRID SCREEN - MATERIAL DESIGN 3 COMPLETO
// ==============================================

// Enum para tipos de campo
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
  cpfCnpj,
  cep,
  currency,
  percentage,
  url,
  multiselect,
}

// Configuração de arquivo
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

// Configuração avançada de campo
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

// Configuração de exportação
class ExportConfig {
  final bool enableCsvExport;
  final bool enablePdfExport;
  final String filenamePrefix;

  const ExportConfig({
    this.enableCsvExport = true,
    this.enablePdfExport = true,
    this.filenamePrefix = 'export',
  });
}

// Configuração de paginação
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

// Configuração de ação personalizada
class CustomAction<T> {
  final IconData icon;
  final String label;
  final void Function(BuildContext context, T item) onPressed;
  final bool Function(T item)? isVisible;

  const CustomAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isVisible,
  });
}

class GenericMobileGridScreen<T> extends StatefulWidget {
  final String title;
  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint;
  final String deleteEndpoint;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T item) toJson;
  final bool Function(String permission) hasPermission;
  final List<FieldConfig> fieldConfigs;
  final String idFieldName;
  final String? dateFieldName;
  final PaginationConfig paginationConfig;
  final void Function(T item, BuildContext context)? onItemTap;
  final List<CustomAction<T>> Function()? customActions;
  final bool enableSearch;
  final Map<String, dynamic>? initialFilters;
  final String storageKey;
  final Widget Function(T item)? detailScreenBuilder;
  final Map<String, dynamic>? extraParams;
  final bool enableDebugMode;
  final bool useUserBannerAppBar;
  /// Quando false, nenhum AppBar e renderizado — util quando a tela e encapsulada
  /// em um Scaffold externo que ja tem seu proprio AppBar (ex: UserBannerAppBar).
  final bool showAppBar;
  final VoidCallback? onUserBannerTapped;
  final VoidCallback? onBannerRefresh;
  // NOVA PROPRIEDADE SIMPLES
  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(T? item)? dynamicAdditionalFormData;

  const GenericMobileGridScreen({
    super.key,
    required this.title,
    required this.fetchEndpoint,
    required this.createEndpoint,
    required this.updateEndpoint,
    required this.deleteEndpoint,
    required this.fromJson,
    required this.toJson,
    required this.hasPermission,
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
    this.showAppBar = true,
    this.onUserBannerTapped,
    this.onBannerRefresh,
    this.additionalFormData, // NOVO PARÂMETRO
    this.dynamicAdditionalFormData, // NOVO: Para dados dinâmicos
  });

  @override
  State<GenericMobileGridScreen<T>> createState() =>
      _GenericMobileGridScreenState<T>();
}

class _GenericMobileGridScreenState<T>
    extends State<GenericMobileGridScreen<T>> {
  List<T> items = [];
  List<T> filtered = [];
  Set<String> selectedRows = {};
  bool isLoading = false;
  final bool _isUpdating = false;
  final bool _isDeleting = false;
  bool filtrosAbertos = false;
  final Map<String, List<PlatformFile>> _fileCache =
      {}; // NOVO: Cache para arquivos

  int _currentPage = 0;
  int _totalItems = 0;
  final int _itemsPerPage = 20;
  bool _hasMoreItems = true;
  final ScrollController _scrollController = ScrollController();

  final Map<String, TextEditingController> _filterControllers = {};
  final TextEditingController _searchController = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> _dropdownCache = {};

  final Map<String, bool> _fieldVisibility = {};
  List<CustomAction<T>> _customActions = [];

  bool _isSelectionMode = false;
  final Map<String, bool> _cardSelection = {};
  T? _itemParaEditar;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    for (final config in widget.fieldConfigs) {
      _fieldVisibility[config.fieldName] = config.isVisibleByDefault;
    }

    for (final config in widget.fieldConfigs.where((c) => c.isFilterable)) {
      _filterControllers[config.fieldName] = TextEditingController();
    }

    if (widget.initialFilters != null) {
      final filters = widget.initialFilters;
      if (filters != null) {
        filters.forEach((key, value) {
          if (_filterControllers.containsKey(key)) {
            final ctrl = _filterControllers[key];
            if (ctrl != null) {
              ctrl.text = value.toString();
            }
          }
        });
      }
    }

    _loadFieldPreferences().then((_) {
      _loadItems();
    });

    if (widget.customActions != null) {
      _customActions = widget.customActions?.call() ?? [];
    }

    if (widget.enableDebugMode) {
      _customActions.add(
        CustomAction<T>(
          icon: Icons.bug_report,
          label: 'Ver Todos Campos',
          onPressed: _showAllFieldsDebug,
        ),
      );
    }

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final controller in _filterControllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFieldPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${widget.storageKey}_${widget.title}';

      for (final config in widget.fieldConfigs) {
        final savedValue = prefs.getBool('$key${config.fieldName}');
        if (savedValue != null) {
          _fieldVisibility[config.fieldName] = savedValue;
        }
      }
    } catch (e) {
      L.d('Erro ao carregar preferências: $e');
    }
  }

  Future<void> _saveFieldPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '${widget.storageKey}_${widget.title}';

      for (final config in widget.fieldConfigs) {
        await prefs.setBool(
          '$key${config.fieldName}',
          _fieldVisibility[config.fieldName] ?? config.isVisibleByDefault,
        );
      }
    } catch (e) {
      L.d('Erro ao salvar preferências: $e');
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        _hasMoreItems &&
        !isLoading) {
      _loadMoreItems();
    }
  }

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
      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.statusCode == 200 && response.body != null) {
        final responseData = response.body?['data'];
        final List<dynamic> data = responseData is Map
            ? responseData['dados'] ?? []
            : responseData ?? [];

        final processedData = data.map((json) {
          final itemMap = json is Map ? Map<String, dynamic>.from(json) : {};

          if (json is Map && json['file'] != null) {
            for (final config in widget.fieldConfigs.where(
              (c) => c.fieldType == FieldType.file,
            )) {
              final fileField = config.fieldName.split('.')[0];
              if (!itemMap.containsKey(fileField)) {
                itemMap[fileField] = {'id': 0, 'nome': ''};
              }
            }
          }
          return itemMap;
        }).toList();

        setState(() {
          if (reset) {
            items = processedData.map((json) {
              Map<String, dynamic> jsonMap = Map<String, dynamic>.from(json);
              return widget.fromJson(jsonMap);
            }).toList();
            filtered = List.from(items);
            _totalItems = responseData is Map
                ? responseData['totalElements'] ?? 0
                : data.length;
          } else {
            items.addAll(processedData.map((json) {
              Map<String, dynamic> jsonMap = Map<String, dynamic>.from(json);
              return widget.fromJson(jsonMap);
            }).toList());
            filtered = List.from(items);
          }

          _totalItems = responseData is Map
              ? responseData['totalElements'] ??
                  responseData['total'] ??
                  data.length
              : data.length;
          _hasMoreItems = items.length < _totalItems;
          _currentPage++;
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao carregar dados: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadMoreItems() async {
    if (!_hasMoreItems || isLoading) return;

    await _loadItems(reset: false);
  }

  String _buildUrl(int page) {
    String url = '${widget.fetchEndpoint}?page=$page&size=$_itemsPerPage';

    if (_searchController.text.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(_searchController.text)}';
    }

    for (final config in widget.fieldConfigs.where((c) => c.isFilterable)) {
      final filterValue = _filterControllers[config.fieldName]?.text;
      if (filterValue != null && filterValue.isNotEmpty) {
        url += '&${config.fieldName}=${Uri.encodeComponent(filterValue)}';
      }
    }

    if (widget.extraParams != null) {
      final params = widget.extraParams;
      if (params != null) {
        params.forEach((key, value) {
          url += '&$key=${Uri.encodeComponent(value.toString())}';
        });
      }
    }

    return url;
  }

  void _applyFilters() {
    _loadItems(reset: true);
  }

  void _clearFilters() {
    for (final controller in _filterControllers.values) {
      controller.clear();
    }
    _searchController.clear();
    _applyFilters();
  }

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
      for (final item in filtered) {
        final itemMap = widget.toJson(item);
        final id = _getNestedValue(itemMap, widget.idFieldName).toString();
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

  Future<void> _openForm({T? item}) async {
    _itemParaEditar = item;
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _buildFormDialog(item),
    );
    if (result == true && mounted) {
      _loadItems(reset: true);
    }
  }

  Widget _buildFormDialog(T? item) {
    final Map<String, dynamic> itemData =
        item != null ? widget.toJson(item) : {};
    final Map<String, TextEditingController> formControllers = {};

    for (final config in widget.fieldConfigs.where((c) => c.isInForm)) {
      // Campos de senha nunca sao pre-populados na edicao, mesmo que o
      // backend retorne algum valor (ex: hash) — evita exibir/reenviar
      // segredo sem alteracao intencional do usuario.
      final initialValue = config.fieldType == FieldType.password
          ? ''
          : _getNestedValue(itemData, config.fieldName)?.toString() ?? '';
      formControllers[config.fieldName] =
          TextEditingController(text: initialValue);
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cabeçalho colorido ────────────────────────────────────────
            Container(
              color: GridColors.primary,
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item == null ? GridTexts.addNew : GridTexts.editItem,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    tooltip: GridTexts.cancel,
                  ),
                ],
              ),
            ),
            // ── Corpo do formulário ───────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  children: widget.fieldConfigs
                      .where((config) => config.isInForm)
                      .map((config) => _buildFormField(
                          config, formControllers[config.fieldName]!))
                      .toList(),
                ),
              ),
            ),
            // ── Rodapé com botões ─────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: GridColors.primary),
                        foregroundColor: GridColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text(GridTexts.cancel,
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          _saveForm(item, formControllers, context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        item == null ? GridTexts.add : GridTexts.save,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildFormField(FieldConfig config, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            config.label + (config.isRequired ? ' *' : ''),
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          if (config.fieldType == FieldType.dropdown)
            _buildDropdownField(config, controller)
          else if (config.fieldType == FieldType.boolean)
            _buildBooleanField(config, controller)
          else if (config.fieldType == FieldType.multiline)
            _buildMultilineField(config, controller)
          else if (config.fieldType == FieldType.date) // NOVO: Campo de data
            _buildDateField(config, controller)
          else if (config.fieldType == FieldType.file) // NOVO: Campo de arquivo
            _buildFileField(config, controller)
          else
            _buildTextField(config, controller),
        ],
      ),
    );
  }

  Widget _buildFileField(FieldConfig config, TextEditingController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentFiles = _fileCache[config.fieldName] ?? [];
    final fileConfig = config.fileConfig ?? const FileConfig();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Exibe arquivos selecionados
        if (currentFiles.isNotEmpty)
          ...currentFiles.map((file) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(
                    file.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${(file.size / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: GridColors.error),
                    onPressed: () {
                      setState(() {
                        _fileCache[config.fieldName]?.remove(file);
                        final cached = _fileCache[config.fieldName];
                        if (cached?.isEmpty ?? false) {
                          _fileCache.remove(config.fieldName);
                        }
                        controller.clear();
                      });
                    },
                  ),
                ),
              )),

        // Botão para selecionar arquivos
        ElevatedButton.icon(
          onPressed: () => _selectFiles(config, controller),
          icon: const Icon(Icons.attach_file),
          label: Text(
            currentFiles.isEmpty
                ? GridTexts.selectFile
                : GridTexts.addMoreFiles,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.primary,
            foregroundColor: GridColors.card,
          ),
        ),

        // Informações sobre extensões permitidas
        if (fileConfig.allowedExtensions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Extensões permitidas: ${fileConfig.allowedExtensions.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _selectFiles(
      FieldConfig config, TextEditingController controller) async {
    final fileConfig = config.fileConfig ?? const FileConfig();

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: fileConfig.allowedExtensions,
        allowMultiple: fileConfig.allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _fileCache[config.fieldName] = result.files;
          controller.text = result.files.map((f) => f.name).join(', ');
        });
      }
    } catch (e) {
      _showSnackBar('Erro ao selecionar arquivo: $e', isError: true);
    }
  }

  Widget _buildDateField(FieldConfig config, TextEditingController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: config.enabled, // CORREÇÃO: Propriedade enabled funcionando
      decoration: InputDecoration(
        hintText: 'Selecione a data',
        suffixIcon: Icon(
          Icons.calendar_today,
          color: config.enabled
              ? colorScheme.primary
              : colorScheme.onSurface.withValues(alpha: 0.38),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: colorScheme.onSurface.withValues(alpha: 0.38)),
        ),
        filled: !config.enabled,
        fillColor: !config.enabled
            ? colorScheme.onSurface.withValues(alpha: 0.04)
            : Colors.transparent,
      ),
      style: TextStyle(
        color: config.enabled
            ? textTheme.bodyMedium?.color
            : colorScheme.onSurface.withValues(alpha: 0.38),
      ),
      onTap: config.enabled ? () => _selectDate(config, controller) : null,
      validator: config.validator,
    );
  }

  Future<void> _selectDate(
      FieldConfig config, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(controller.text) ?? DateTime.now(),
      firstDate: config.firstDate ?? DateTime(1900),
      lastDate: config.lastDate ?? DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: _buildDatePickerTheme(),
          child: child!,
        );
      },
      locale: const Locale('pt', 'BR'), // Português Brasil
    );

    if (picked != null) {
      final formattedDate = _formatDate(picked, config.dateFormat);
      controller.text = formattedDate;
    }
  }

  ThemeData _buildDatePickerTheme() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: GridColors.primary,
        primary: GridColors.primary,
        secondary: GridColors.secondary,
        error: GridColors.error,
        surface: GridColors.card,
        onPrimary: GridColors.textPrimary,
        onSecondary: GridColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        centerTitle: false,
        elevation: 2,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GridColors.secondary,
        foregroundColor: GridColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: GridColors.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(color: GridColors.secondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GridColors.primary,
          foregroundColor: GridColors.textPrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GridColors.secondary,
          side: const BorderSide(color: GridColors.secondary),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
      dividerColor: GridColors.divider,
      cardColor: GridColors.card,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: GridColors.secondary,
        contentTextStyle: TextStyle(color: GridColors.textPrimary),
      ),
    );
  }

  DateTime? _parseDate(String dateString) {
    if (dateString.isEmpty) return null;

    try {
      // Tenta vários formatos de data comuns
      final formats = [
        'dd/MM/yyyy',
        'dd-MM-yyyy',
        'yyyy-MM-dd',
        'dd/MM/yy',
      ];

      for (final format in formats) {
        try {
          final inputFormat = DateFormat(format);
          return inputFormat.parse(dateString);
        } catch (e) {
          continue;
        }
      }

      // Se nenhum formato funcionar, tenta parse padrão
      return DateTime.tryParse(dateString);
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date, String format) {
    try {
      final dateFormat = DateFormat(format);
      return dateFormat.format(date);
    } catch (e) {
      // Fallback para formato padrão
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Widget _buildTextField(FieldConfig config, TextEditingController controller) {
    return TextField(
      controller: controller,
      enabled: config.enabled, // CORREÇÃO ADICIONADA
      decoration: InputDecoration(
        hintText: 'Digite ${config.label.toLowerCase()}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
      keyboardType: _getKeyboardType(config.fieldType),
      maxLines: config.maxLines,
    );
  }

  Widget _buildMultilineField(
      FieldConfig config, TextEditingController controller) {
    return TextField(
      enabled: config.enabled, // CORREÇÃO ADICIONADA
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Digite ${config.label.toLowerCase()}',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
      maxLines: 4,
      minLines: 3,
    );
  }

  Widget _buildBooleanField(
      FieldConfig config, TextEditingController controller) {
    return Row(
      children: [
        Checkbox(
          value: controller.text.toLowerCase() == 'true',
          onChanged: (value) {
            controller.text = value.toString();
            setState(() {});
          },
        ),
        Text(config.label),
      ],
    );
  }

  Widget _buildDropdownField(
      FieldConfig config, TextEditingController controller) {
    // Campos com FutureBuilder e lista dinâmica usam SearchableDropdownField
    if (config.dropdownFutureBuilder != null) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: config.dropdownFutureBuilder!(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            );
          }
          return SearchableDropdownField(
            label: config.label + (config.isRequired ? ' *' : ''),
            items: snapshot.data ?? [],
            valueField: config.dropdownValueField,
            displayField: config.dropdownDisplayField,
            value: controller.text.isNotEmpty ? controller.text : null,
            enabled: config.enabled,
            onChanged: (v) {
              setState(() => controller.text = v ?? '');
            },
          );
        },
      );
    }

    // Campos com opções estáticas também usam SearchableDropdownField
    if ((config.dropdownOptions?.isNotEmpty ?? false)) {
      return SearchableDropdownField(
        label: config.label + (config.isRequired ? ' *' : ''),
        items: config.dropdownOptions ?? [],
        valueField: config.dropdownValueField,
        displayField: config.dropdownDisplayField,
        value: controller.text.isNotEmpty ? controller.text : null,
        enabled: config.enabled,
        onChanged: (v) {
          setState(() => controller.text = v ?? '');
        },
      );
    }

    // Fallback: DropdownButtonFormField nativo (sem opções dinâmicas)
    Future<List<Map<String, dynamic>>> getOptions() async {
      return config.dropdownOptions ?? [];
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getOptions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Erro: ${snapshot.error}');
        }

        final options = snapshot.data ?? [];

        // **CORREÇÃO: Remove duplicatas de forma mais robusta**
        final uniqueOptions = <String, Map<String, dynamic>>{};
        for (final option in options) {
          try {
            final value = option[config.dropdownValueField]?.toString() ?? '';
            if (value.isNotEmpty && !uniqueOptions.containsKey(value)) {
              uniqueOptions[value] = option;
            }
          } catch (e) {
            continue;
          }
        }

        final uniqueOptionsList = uniqueOptions.values.toList();

        // **CORREÇÃO COMPLETA: Obter e validar o valor atual**
        dynamic currentValue = _getCurrentValue(config, controller);

        // **DEBUG: Log para troubleshooting**
        if (widget.enableDebugMode) {
          L.d('=== DEBUG DROPDOWN ${config.fieldName} ===');
          L.d('Valor atual: $currentValue (${currentValue?.runtimeType})');
          L.d('Opções disponíveis:');
          for (var opt in uniqueOptionsList) {
            final optValue = opt[config.dropdownValueField];
            L.d('  - $optValue (${optValue.runtimeType}) -> ${opt[config.dropdownDisplayField]}');
          }
        }

        // **CORREÇÃO: Validação robusta do valor atual**
        bool valueExists = false;
        dynamic safeValue;

        for (final option in uniqueOptionsList) {
          final optionValue = option[config.dropdownValueField];

          // Tenta diferentes formas de comparação
          if (_valuesMatch(currentValue, optionValue)) {
            valueExists = true;
            safeValue = optionValue; // Usa o valor exato da opção
            break;
          }
        }

        if (!valueExists) {
          safeValue = null;
          // **CORREÇÃO: Limpa o controller se o valor não existe**
          if (controller.text.isNotEmpty && currentValue != null) {
            controller.clear();
          }
        }

        // **CORREÇÃO: Constrói os itens do dropdown de forma segura**
        final dropdownItems = <DropdownMenuItem<dynamic>>[];

        // Adiciona item vazio se não for obrigatório
        if (!config.isRequired || safeValue == null) {
          dropdownItems.add(
            const DropdownMenuItem<dynamic>(
              value: null,
              child: Text(
                'Selecione uma opção',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        // Adiciona as opções únicas
        for (final option in uniqueOptionsList) {
          try {
            final optionValue = option[config.dropdownValueField];
            final optionLabel =
                option[config.dropdownDisplayField]?.toString() ??
                    optionValue?.toString() ??
                    'Sem label';

            dropdownItems.add(
              DropdownMenuItem<dynamic>(
                value: optionValue,
                child: Text(optionLabel),
              ),
            );
          } catch (e) {
            // Ignora opções com erro
            continue;
          }
        }

        // **VERIFICAÇÃO FINAL DE SEGURANÇA**
        final validSafeValue =
            dropdownItems.any((item) => item.value == safeValue)
                ? safeValue
                : null;

        return AbsorbPointer(
          absorbing: !config.enabled,
          child: Opacity(
            opacity: config.enabled ? 1.0 : 0.6,
            child: DropdownButtonFormField<dynamic>(
              initialValue: validSafeValue,
              decoration: InputDecoration(
                labelText: config.label + (config.isRequired ? ' *' : ''),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.38)),
                ),
                filled: !config.enabled,
                fillColor: !config.enabled
                    ? Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.04)
                    : Colors.transparent,
              ),
              isExpanded: true,
              items: dropdownItems,
              onChanged: config.enabled
                  ? (dynamic newValue) {
                      setState(() {
                        if (newValue == null) {
                          controller.clear();
                        } else {
                          controller.text = newValue.toString();
                        }
                      });
                    }
                  : null,
              validator: (dynamic value) {
                if (config.isRequired && (value == null)) {
                  return '${config.label} é obrigatório';
                }
                return config.validator?.call(value?.toString());
              },
            ),
          ),
        );
      },
    );
  }

// **NOVO MÉTODO: Comparação robusta de valores**
  bool _valuesMatch(dynamic value1, dynamic value2) {
    if (value1 == null && value2 == null) return true;
    if (value1 == null || value2 == null) return false;

    // Converte ambos para string para comparação
    final str1 = value1.toString();
    final str2 = value2.toString();

    // Tenta comparar como números se ambos forem numéricos
    if (_isNumeric(str1) && _isNumeric(str2)) {
      final num1 = num.tryParse(str1);
      final num2 = num.tryParse(str2);
      if (num1 != null && num2 != null) {
        return num1 == num2;
      }
    }

    // Comparação como string
    return str1 == str2;
  }

// **NOVO MÉTODO: Verifica se string é numérica**
  bool _isNumeric(String str) {
    if (str.isEmpty) return false;
    return double.tryParse(str) != null;
  }

// **ATUALIZE também o método _getCurrentValue:**
  dynamic _getCurrentValue(
      FieldConfig config, TextEditingController controller) {
    // Prioridade 1: Valor do controller (edição)
    if (controller.text.isNotEmpty) {
      return controller.text;
    }

    // Prioridade 2: Valor padrão da configuração
    if (config.defaultValue != null) {
      return config.defaultValue;
    }

    // Prioridade 3: Valor selecionado da configuração
    if (config.dropdownSelectedValue != null) {
      return config.dropdownSelectedValue;
    }

    return null;
  }

  bool _isIntegerField(FieldConfig config) {
    return config.dropdownValueField == 'id' ||
        config.fieldName.toLowerCase().contains('id') ||
        config.fieldName.toLowerCase().endsWith('id') ||
        config.fieldName.toLowerCase().contains('codigo') ||
        config.fieldName.toLowerCase().contains('code');
  }

  TextInputType _getKeyboardType(FieldType fieldType) {
    switch (fieldType) {
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

  String? _parseDates(String dateString) {
    try {
      // Tenta parsear no formato "MM/dd/yyyy"
      final parts = dateString.split('/');
      if (parts.length == 3) {
        final month = parts[1].padLeft(2, '0');
        final day = parts[0].padLeft(2, '0');
        final year = parts[2];

        // Retorna no formato ISO "yyyy-MM-dd"
        return '$year-$month-$day';
      }

      // Se não conseguir parsear, retorna null para usar o valor original
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveForm(
      T? item,
      Map<String, TextEditingController> controllers,
      BuildContext context) async {
    try {
      final Map<String, dynamic> formData = {};

      // ==================================================
      // ADICIONA DADOS ADICIONAIS FIXOS
      // ==================================================
      if (widget.additionalFormData != null) {
        final data = widget.additionalFormData;
        if (data != null) {
          _addAllNested(formData, data);

          if (widget.enableDebugMode) {
            L.d('=== DADOS ADICIONAIS DO FORMULÁRIO ===');
            data.forEach((key, value) {
              L.d('$key: $value (${value.runtimeType})');
            });
            L.d('=====================================');
          }
        }
      }

      // ==================================================
      // ADICIONA DADOS DINÂMICOS (create vs update)
      // ==================================================
      if (widget.dynamicAdditionalFormData != null) {
        final dynamicData = widget.dynamicAdditionalFormData?.call(item) ?? {};
        _addAllNested(formData, dynamicData);
      }

      // ==================================================
      // PROCESSA DROPDOWNS COM VALOR SELECIONADO PADRÃO
      // ==================================================
      for (final config in widget.fieldConfigs) {
        if (config.fieldType == FieldType.dropdown &&
            config.dropdownSelectedValue != null) {
          final value = config.dropdownSelectedValue;
          _addToFormData(formData, config.fieldName, value);
        }
      }

      // ==================================================
      // PROCESSA CAMPOS DE FORMULÁRIO (CONTROLLERS)
      // ==================================================
      for (final config in widget.fieldConfigs
          .where((c) => c.isInForm && c.fieldType != FieldType.file)) {
        final controller = controllers[config.fieldName];
        if (controller != null && controller.text.isNotEmpty) {
          final fieldValue = controller.text;

          if (config.fieldType == FieldType.date) {
            final dateValue = _parseDates(controller.text);
            if (dateValue != null) {
              _addToFormData(formData, config.fieldName, dateValue);
            } else {
              _addToFormData(formData, config.fieldName, controller.text);
            }
          } else if (config.fieldType == FieldType.dropdown) {
            final value = controller.text;
            final dynamic finalValue =
                (_isIntegerField(config) && _isNumeric(value))
                    ? (int.tryParse(value) ?? value)
                    : value;
            _addToFormData(formData, config.fieldName, finalValue);
          } else if (config.fieldType == FieldType.boolean) {
            _addToFormData(
                formData, config.fieldName, fieldValue.toLowerCase() == 'true');
          } else {
            _addToFormData(formData, config.fieldName, fieldValue);
          }
        }
      }

      for (final config in widget.fieldConfigs
          .where((c) => c.isInForm && c.fieldType == FieldType.boolean)) {
        if (!formData.containsKey(config.fieldName)) {
          _addToFormData(formData, config.fieldName, false);
        }
      }

      // ==================================================
      // PROCESSA ARQUIVOS (UPLOAD)
      // ==================================================
      final filesToUpload = <String, List<PlatformFile>>{};
      for (final config
          in widget.fieldConfigs.where((c) => c.fieldType == FieldType.file)) {
        final files = _fileCache[config.fieldName];
        if (files != null && files.isNotEmpty) {
          filesToUpload[config.fieldName] = files;
        }
      }

      final endpoint = item == null
          ? widget.createEndpoint
          : widget.updateEndpoint.replaceFirst(':id', _getItemId(item));

      // Upload de arquivos antes da requisição principal
      if (filesToUpload.isNotEmpty) {
        final itemId = item == null ? '0' : _getItemId(item);
        final fileId =
            await UploadFileCaller().uploadFiles(itemId, filesToUpload);
        if (fileId > 0) {
          _addToFormData(formData, 'file.id', fileId);
        }
      }

      // ==================================================
      // NORMALIZA CAMPOS COM PONTO (formaPagamento.id -> { formaPagamento: {id:...} })
      // ==================================================
      final normalized = _normalizeDotted(formData);

      if (widget.enableDebugMode) {
        L.d('=== PAYLOAD FINAL NORMALIZADO ===');
        L.d('=================================');
      }

      final NetworkResponse response = item == null
          ? await NetworkCaller().postRequest(endpoint, normalized)
          : await NetworkCaller().putRequest(endpoint, normalized);

      if (response.isSuccess) {
        Navigator.pop(context);
        // Limpa o cache de arquivos
        for (final config in widget.fieldConfigs
            .where((c) => c.fieldType == FieldType.file)) {
          _fileCache.remove(config.fieldName);
        }
        _showSnackBar(item == null
            ? 'Item adicionado com sucesso!'
            : 'Item atualizado com sucesso!');
        _loadItems(reset: true);
      } else {
        _showSaveErrorDialog(
            'Erro ao salvar: ${response.body ?? response.statusCode}');
      }
    } catch (e) {
      _showSaveErrorDialog('Erro: $e');
    }
  }

  // ==========================================================
// SUPORTE A CAMPOS ANINHADOS COM PONTO (formaPagamento.id)
// ==========================================================
  void _addToFormData(
      Map<String, dynamic> formData, String fieldName, dynamic value) {
    if (fieldName.contains('.')) {
      final parts = fieldName.split('.');
      _buildNestedStructure(formData, parts, value);
    } else {
      formData[fieldName] = value;
    }
  }

  void _buildNestedStructure(
      Map<String, dynamic> map, List<String> parts, dynamic value) {
    final currentPart = parts.first;

    if (parts.length == 1) {
      map[currentPart] = value;
      return;
    }

    // Cria o próximo nível se necessário
    if (!map.containsKey(currentPart) || map[currentPart] == null) {
      map[currentPart] = <String, dynamic>{};
    }

    if (map[currentPart] is! Map<String, dynamic>) {
      map[currentPart] = <String, dynamic>{};
    }

    _buildNestedStructure(
        map[currentPart] as Map<String, dynamic>, parts.sublist(1), value);
  }

  void _addAllNested(Map<String, dynamic> target, Map<String, dynamic> src) {
    for (final entry in src.entries) {
      _addToFormData(target, entry.key, entry.value);
    }
  }

  Map<String, dynamic> _normalizeDotted(Map<String, dynamic> input) {
    final out = <String, dynamic>{};
    for (final e in input.entries) {
      _addToFormData(out, e.key, e.value);
    }
    return out;
  }

  // Mantém compatibilidade se for usada em outro ponto
  void _addNestedField(
      Map<String, dynamic> map, List<String> parts, dynamic value) {
    if (parts.isEmpty) return;

    final currentPart = parts.first;
    if (parts.length == 1) {
      map[currentPart] = value;
    } else {
      if (!map.containsKey(currentPart) || map[currentPart] is! Map) {
        map[currentPart] = <String, dynamic>{};
      }
      _addNestedField(
          map[currentPart] as Map<String, dynamic>, parts.sublist(1), value);
    }
  }

  String _getItemId(T item) {
    final itemMap = widget.toJson(item);
    return _getNestedValue(itemMap, widget.idFieldName).toString();
  }

  Future<void> _deleteItem(String id) async {
    try {
      final response = await NetworkCaller().deleteRequest(
        widget.deleteEndpoint.replaceFirst(':id', id),
      );

      if (response.isSuccess) {
        _showSnackBar('Item excluído com sucesso!');
        _loadItems(reset: true);
      } else {
        _showSnackBar('Erro ao excluir: $response', isError: true);
      }
    } catch (e) {
      _showSnackBar('Erro: $e', isError: true);
    }
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(GridTexts.confirmDelete),
        content: Text(
            'Deseja excluir ${selectedRows.length} item(s) selecionado(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(GridTexts.cancel),
          ),
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
              _loadItems(reset: true);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showAllFieldsDebug(BuildContext context, T item) {
    final itemMap = widget.toJson(item);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Text(
                'DEBUG - Todos os Campos',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: itemMap.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 150,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                entry.value?.toString() ?? 'null',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFieldSettings() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setDialogState) {
          return AlertDialog(
            title: const Text('Campos Visíveis'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: widget.fieldConfigs.map((config) {
                  return CheckboxListTile(
                    title: Text(config.label),
                    value: _fieldVisibility[config.fieldName] ??
                        config.isVisibleByDefault,
                    onChanged: config.isFixed
                        ? null
                        : (value) {
                            setDialogState(() {
                              _fieldVisibility[config.fieldName] =
                                  value ?? false;
                            });
                          },
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(GridTexts.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  _saveFieldPreferences();
                  // Chama setState do widget pai para atualizar os cards
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('Aplicar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==============================================
  // FILTROS RESTAURADOS - VERSÃO COMPLETA
  // ==============================================

  Widget _buildFilters() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Filtros e Busca',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close,
                      color: colorScheme.onSurface.withValues(alpha: 0.6)),
                  onPressed: () => setState(() => filtrosAbertos = false),
                  tooltip: 'Fechar filtros',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Busca Global
            if (widget.enableSearch)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Busca Global',
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Digite para buscar em todos os campos...',
                      prefixIcon: const Icon(Icons.search),
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
                      fillColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Filtros por Campo
            Text(
              'Filtros por Campo',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: widget.fieldConfigs
                  .where((c) => c.isFilterable)
                  .map((config) {
                // Campos dropdown com lista dinâmica: usa SearchableDropdownField
                if (config.fieldType == FieldType.dropdown &&
                    config.dropdownFutureBuilder != null) {
                  return SizedBox(
                    width: 250,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: config.dropdownFutureBuilder?.call() ?? Future.value([]),
                      builder: (context, snapshot) {
                        return SearchableDropdownField(
                          label: config.label,
                          items: snapshot.data ?? [],
                          valueField: config.dropdownValueField,
                          displayField: config.dropdownDisplayField,
                          value: (_filterControllers[config.fieldName]?.text.isNotEmpty ?? false)
                              ? _filterControllers[config.fieldName]?.text
                              : null,
                          onChanged: (v) {
                            _filterControllers[config.fieldName]?.text =
                                v ?? '';
                            _applyFilters();
                          },
                        );
                      },
                    ),
                  );
                }

                // Campos dropdown com opções estáticas
                if (config.fieldType == FieldType.dropdown &&
                    config.dropdownOptions != null) {
                  return SizedBox(
                    width: 250,
                    child: SearchableDropdownField(
                      label: config.label,
                      items: config.dropdownOptions!,
                      valueField: config.dropdownValueField,
                      displayField: config.dropdownDisplayField,
                      value: _filterControllers[config.fieldName]?.text
                          .isNotEmpty == true
                          ? _filterControllers[config.fieldName]!.text
                          : null,
                      onChanged: (v) {
                        _filterControllers[config.fieldName]?.text = v ?? '';
                        _applyFilters();
                      },
                    ),
                  );
                }

                // Demais campos: TextField padrão
                return SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _filterControllers[config.fieldName],
                    decoration: InputDecoration(
                      labelText: config.label,
                      hintText:
                          'Filtrar por ${config.label.toLowerCase()}...',
                      prefixIcon: Icon(
                          config.icon ?? Icons.filter_list_alt,
                          size: 20),
                      suffixIcon: _filterControllers[config.fieldName]
                                  ?.text
                                  .isNotEmpty ==
                              true
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _filterControllers[config.fieldName]?.clear();
                                _applyFilters();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Botões de Ação dos Filtros
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.tonal(
                    onPressed: _clearFilters,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear_all, size: 18),
                        SizedBox(width: 8),
                        Text(GridTexts.clearAll),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _applyFilters,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 18),
                        SizedBox(width: 8),
                        Text(GridTexts.applyFilters),
                      ],
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

  // ==============================================
  // BOTÃO DE REFRESH RESTAURADO
  // ==============================================

  Widget _buildRefreshButton() {
    return IconButton(
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : const Icon(Icons.refresh),
      onPressed: isLoading ? null : () => _loadItems(reset: true),
      tooltip: 'Recarregar dados',
    );
  }

  // ==============================================
  // HEADER COM TODAS AS AÇÕES RESTAURADAS
  // ==============================================

  AppBar _buildNormalAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      title: Text(
        widget.title,
        style: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
      ),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 3,
      shadowColor: colorScheme.shadow,
      surfaceTintColor: Colors.transparent,
      actions: [
        // Notificações + Logout — presentes em toda tela mobile
        const AppBarActions(),

        // Botão de Refresh
        _buildRefreshButton(),

        // Configuração de Campos
        IconButton(
          icon: const Icon(Icons.view_column),
          onPressed: _showFieldSettings,
          tooltip: 'Configurar campos visíveis',
        ),

        // Filtros
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () => setState(() => filtrosAbertos = !filtrosAbertos),
          tooltip: 'Mostrar/ocultar filtros',
        ),

        // Botão Adicionar (se tiver permissão)
        if (widget.hasPermission('create')) ...[
          const SizedBox(width: 8),
          _buildAddButton(),
        ],
      ],
    );
  }

  Widget _buildAddButton() {
    return FloatingActionButton.small(
      onPressed: () => _openForm(),
      backgroundColor: GridColors.primary,
      foregroundColor: GridColors.textPrimary,
      elevation: 2,
      child: const Icon(Icons.add),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _openForm(),
      backgroundColor: GridColors.primary,
      foregroundColor: GridColors.textPrimary,
      elevation: 4,
      child: const Icon(Icons.add),
    );
  }

  AppBar _buildSelectionAppBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _toggleSelectionMode,
      ),
      title: Text(
        '${selectedRows.length} selecionado(s)',
        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary),
      ),
      actions: [
        if (selectedRows.length == filtered.length)
          IconButton(
            icon: const Icon(Icons.deselect),
            onPressed: _deselectAllCards,
            tooltip: 'Desmarcar todos',
          )
        else
          IconButton(
            icon: const Icon(Icons.select_all),
            onPressed: _selectAllCards,
            tooltip: 'Selecionar todos',
          ),
        if (widget.hasPermission('delete') && selectedRows.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteSelected,
            tooltip: 'Excluir selecionados',
          ),
      ],
    );
  }

  // ==============================================
  // WIDGET PRINCIPAL COMPLETO COM CARDS COMPACTOS
  // ==============================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    PreferredSizeWidget? resolvedAppBar;
    if (!widget.showAppBar) {
      resolvedAppBar = null;
    } else if (widget.useUserBannerAppBar) {
      resolvedAppBar = UserBannerAppBar(
        screenTitle: widget.title,
        onTapped: widget.onUserBannerTapped,
        onRefresh: widget.onBannerRefresh ?? () => _loadItems(reset: true),
        isLoading: isLoading,
        onFilterToggle: () => setState(() => filtrosAbertos = !filtrosAbertos),
        onColumns: _showFieldSettings,
        showFilterButton: true,
      );
    } else {
      resolvedAppBar =
          _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar();
    }

    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: resolvedAppBar,
      floatingActionButton:
          widget.hasPermission('create') ? _buildFloatingActionButton() : null,
      body: Column(
        children: [
          // Filtros (quando abertos)
          if (filtrosAbertos) _buildFilters(),

          // Lista de Itens
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator.adaptive(
                  onRefresh: () => _loadItems(reset: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filtered.length + (isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return _buildLoadingIndicator();
                      }
                      return _buildItemCard(filtered[index], index);
                    },
                  ),
                ),

                // Overlay de carregamento
                if (isLoading && filtered.isEmpty)
                  Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasMoreItems) ...[
              CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                GridTexts.loadingMoreItems,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ] else ...[
              Icon(
                Icons.check_circle,
                color: colorScheme.primary.withValues(alpha: 0.5),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                GridTexts.allItemsLoaded,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==============================================
  // CARD COMPACTO COM LAYOUT EM LINHA
  // ==============================================

  Widget _buildItemCard(T item, int index) {
    final itemMap = widget.toJson(item);
    final id = _getNestedValue(itemMap, widget.idFieldName).toString();
    final isSelected = _cardSelection[id] ?? false;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? GridColors.primary.withValues(alpha: 0.06)
            : GridColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? GridColors.primary
              : GridColors.divider,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: GridColors.primary.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra vertical esquerda (left accent)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isSelected
                        ? [GridColors.primary, GridColors.secondary]
                        : [GridColors.primary, GridColors.primary.withValues(alpha: 0.5)],
                  ),
                ),
              ),
              // Conteúdo do card
              Expanded(
                child: InkWell(
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
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header com ID, Checkbox e Status
                        Row(
                          children: [
                            if (_isSelectionMode)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: isSelected,
                                    onChanged: (value) =>
                                        _toggleCardSelection(id, value ?? false),
                                    fillColor: WidgetStateProperty.all(
                                        GridColors.primary),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),

                            // Badge de ID
                            if (_fieldVisibility[widget.idFieldName] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      GridColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#$id',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: GridColors.primary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),

                            const Spacer(),

                            // Badge de Status
                            if (_hasStatusField(itemMap))
                              _buildStatusBadge(itemMap),
                          ],
                        ),

                        const SizedBox(height: 5),

                        // Separador fino
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: GridColors.divider,
                        ),

                        const SizedBox(height: 5),

                        // Campos em duas colunas
                        ..._buildVisibleFieldsForCard(itemMap),

                        // Separador antes das ações
                        if (!_isSelectionMode) ...[
                          const SizedBox(height: 4),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: GridColors.divider,
                          ),
                          _buildCardActions(item, itemMap),
                        ] else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==============================================
  // CAMPOS EM LINHA (LABEL E VALOR LADO A LADO)
  // ==============================================

  List<Widget> _buildVisibleFieldsForCard(Map<String, dynamic> itemMap) {
    final visibleConfigs = widget.fieldConfigs
        .where((config) =>
            _fieldVisibility[config.fieldName] == true &&
            config.fieldName != widget.idFieldName &&
            config.showInCard &&
            _hasVisibleValue(config, itemMap))
        .toList();

    final rows = <Widget>[];
    for (int i = 0; i < visibleConfigs.length; i += 2) {
      final col1 = _buildFieldInLine(visibleConfigs[i], itemMap);
      final col2 = i + 1 < visibleConfigs.length
          ? _buildFieldInLine(visibleConfigs[i + 1], itemMap)
          : const Expanded(child: SizedBox.shrink());

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [col1, const SizedBox(width: 8), col2],
          ),
        ),
      );
    }

    return rows;
  }

  bool _hasVisibleValue(FieldConfig config, Map<String, dynamic> itemMap) {
    if (config.fieldType == FieldType.file) {
      final fileData = _extractFileData(itemMap, config);
      return (fileData['id'] ?? 0) != 0 && (fileData['nome'] ?? fileData['fileName'] ?? '').isNotEmpty;
    }
    final rawValue = _getNestedValue(itemMap, config.displayFieldName ?? config.fieldName);
    return rawValue != null && rawValue.toString().isNotEmpty;
  }

  Widget _buildFieldInLine(FieldConfig config, Map<String, dynamic> itemMap) {
    if (config.fieldType == FieldType.file) {
      final fileData = _extractFileData(itemMap, config);
      final int fileId = fileData['id'] ?? 0;
      final String fileName = fileData['nome'] ?? fileData['fileName'] ?? '';

      if (fileId == 0 || fileName.isEmpty) {
        return const Expanded(child: SizedBox.shrink());
      }

      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: GridColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 3),
            InkWell(
              onTap: () => _downloadFile(fileId, fileName),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file,
                      size: 13, color: GridColors.primary),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      fileName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GridColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      dynamic rawValue =
          _getNestedValue(itemMap, config.displayFieldName ?? config.fieldName);

      // Resolve dropdown values to display labels (e.g. 0 -> "Ativo")
      if (rawValue != null &&
          config.fieldType == FieldType.dropdown &&
          config.dropdownOptions != null &&
          config.dropdownOptions!.isNotEmpty) {
        for (final option in config.dropdownOptions!) {
          final optionValue = option[config.dropdownValueField]?.toString();
          if (optionValue == rawValue.toString()) {
            rawValue = option[config.dropdownDisplayField];
            break;
          }
        }
      }

      final displayValue = _formatDisplayValue(rawValue, config);

      if (displayValue.isEmpty) return const Expanded(child: SizedBox.shrink());

      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: GridColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              displayValue,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: GridColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    final response = await UploadFileCaller().downloadFile(fileId, fileName);

    if (response == 200) {
      _showSnackBar('Download realizado com sucesso');
    } else {
      _showSnackBar('Falha no download: $response', isError: true);
    }
  }

  Map<String, dynamic> _extractFileData(
    Map<String, dynamic> itemMap,
    FieldConfig config,
  ) {
    try {
      final fileData =
          _getNestedValue(itemMap, config.fieldName.split('.')[0]) ?? {};

      if (fileData is Map) {
        return {
          'id': _getNestedValue(fileData, 'id') ?? 0,
          'nome': _getNestedValue(fileData, 'nome') ?? '',
          'fileName': _getNestedValue(fileData, 'fileName') ?? '',
          'fileType': _getNestedValue(fileData, 'fileType') ?? '',
        };
      }

      return {
        'id': _getObjectProperty(fileData, 'id') ?? 0,
        'nome': _getObjectProperty(fileData, 'nome') ??
            _getObjectProperty(fileData, 'fileName') ??
            '',
        'fileName': _getObjectProperty(fileData, 'fileName') ??
            _getObjectProperty(fileData, 'nome') ??
            '',
        'fileType': _getObjectProperty(fileData, 'fileType') ?? '',
      };
    } catch (e) {
      return {'id': 0, 'nome': '', 'fileName': '', 'fileType': ''};
    }
  }

  dynamic _getObjectProperty(dynamic object, String propertyName) {
    if (object == null) return null;

    switch (propertyName.toLowerCase()) {
      case 'id':
        return object.id ??
            object.ID ??
            object.Id ??
            object.fileId ??
            object.fileID ??
            0;
      case 'nome':
      case 'filename':
      case 'name':
        return object.nome ??
            object.fileName ??
            object.filename ??
            object.name ??
            '';
      case 'filetype':
      case 'type':
        return object.fileType ?? object.type ?? object.contentType ?? '';
      case 'tamanho':
      case 'size':
        return object.tamanho ?? object.size ?? object.fileSize ?? 0;
      default:
        try {
          if (object.toJson != null) {
            final jsonMap = object.toJson();
            if (jsonMap is Map && jsonMap.containsKey(propertyName)) {
              return jsonMap[propertyName];
            }
          }
        } catch (e) {
          // Ignora erro e retorna null
        }
        return null;
    }
  }

  /// Converte datas ISO (ex: 2026-06-28T00:00:00.000) para dd/MM/yyyy.
  /// Para outros campos retorna o valor como string normalmente.
  String _formatDisplayValue(dynamic rawValue, FieldConfig config) {
    if (rawValue == null) return '';
    final str = rawValue.toString();
    if (str.isEmpty) return '';

    // Tenta formatar automaticamente se o valor parece uma data ISO
    if (config.fieldType == FieldType.date ||
        config.fieldName.toLowerCase().contains('data') ||
        config.fieldName.toLowerCase().contains('vencimento') ||
        config.fieldName.toLowerCase().contains('criado') ||
        config.fieldName.toLowerCase().contains('date')) {
      final dt = DateTime.tryParse(str);
      if (dt != null) {
        final d = dt.day.toString().padLeft(2, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final y = dt.year.toString();
        return '$d/$m/$y';
      }
    }

    return str;
  }

  Widget _buildStatusBadge(Map<String, dynamic> itemMap) {
    // Lê campo status; se ausente, tenta o campo 'ativo' (boolean) como fallback
    String rawStatus = _getNestedValue(itemMap, 'status')?.toString() ?? '';
    if (rawStatus.isEmpty) {
      final rawAtivo = _getNestedValue(itemMap, 'ativo');
      if (rawAtivo != null) {
        rawStatus = rawAtivo.toString(); // 'true' ou 'false'
      }
    }
    final status = rawStatus.toLowerCase();

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      // Ativo / Aberto / Pago confirmado
      case 'ativo':
      case 'true':
      case 'aberto':
      case 'aberta':
        badgeColor = GridColors.success;
        badgeText = status == 'aberto' || status == 'aberta' ? 'Aberto' : 'Ativo';
        badgeIcon = Icons.check_circle_outline;
        break;
      // Pago / Baixado
      case 'pago':
      case 'baixado':
      case 'baixada':
      case '1':
        badgeColor = GridColors.success;
        badgeText = status == 'baixado' || status == 'baixada' ? 'Baixada' : 'Pago';
        badgeIcon = Icons.check_circle_outline;
        break;
      // Inativo / Fechado
      case 'inativo':
      case 'false':
      case 'fechado':
        badgeColor = GridColors.error;
        badgeText = 'Inativo';
        badgeIcon = Icons.cancel_outlined;
        break;
      // Cancelado
      case 'cancelado':
      case 'cancelada':
      case '2':
        badgeColor = GridColors.error;
        badgeText = 'Cancelado';
        badgeIcon = Icons.cancel_outlined;
        break;
      // Aberto como inteiro 0 (ContaPagar/ContaReceber ABERTA)
      case '0':
        badgeColor = GridColors.success;
        badgeText = 'Aberto';
        badgeIcon = Icons.check_circle_outline;
        break;
      // Pendente / Atrasado / Vencido
      case 'pendente':
      case 'atrasado':
      case 'atrasada':
      case 'vencido':
      case 'vencida':
        badgeColor = GridColors.warning;
        badgeText = status[0].toUpperCase() + status.substring(1);
        badgeIcon = Icons.schedule_outlined;
        break;
      // Suspenso
      case 'suspenso':
      case 'suspensa':
        badgeColor = GridColors.primary;
        badgeText = 'Suspenso';
        badgeIcon = Icons.pause_circle_outline;
        break;
      default:
        badgeColor = GridColors.primary;
        badgeText = rawStatus.isNotEmpty
            ? rawStatus[0].toUpperCase() + rawStatus.substring(1)
            : 'Status';
        badgeIcon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 11, color: badgeColor),
          const SizedBox(width: 3),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActions(T item, Map<String, dynamic> itemMap) {
    Widget actionBtn(
        IconData icon, Color iconColor, Color bgColor, VoidCallback onPressed,
        String tooltip) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.enableDebugMode) ...[
            actionBtn(
              Icons.bug_report,
              GridColors.textSecondary,
              GridColors.textSecondary.withValues(alpha: 0.1),
              () => _showAllFieldsDebug(context, item),
              'Debug',
            ),
            const SizedBox(width: 4),
          ],
          if (widget.detailScreenBuilder != null &&
              widget.hasPermission('view')) ...[
            actionBtn(
              Icons.visibility_outlined,
              GridColors.secondary,
              GridColors.secondary.withValues(alpha: 0.1),
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => widget.detailScreenBuilder?.call(item) ?? const SizedBox())),
              'Visualizar',
            ),
            const SizedBox(width: 4),
          ] else if (widget.detailScreenBuilder == null &&
              widget.hasPermission('view')) ...[
            actionBtn(
              Icons.info_outline,
              GridColors.secondary,
              GridColors.secondary.withValues(alpha: 0.1),
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MobileDetalhePopup(
                    titulo: widget.title,
                    dados: itemMap,
                    fieldConfigs: widget.fieldConfigs,
                  ),
                ),
              ),
              'Detalhes',
            ),
            const SizedBox(width: 4),
          ],
          if (widget.hasPermission('edit')) ...[
            actionBtn(
              Icons.edit_outlined,
              GridColors.primary,
              GridColors.primary.withValues(alpha: 0.1),
              () => _openForm(item: item),
              'Editar',
            ),
            const SizedBox(width: 4),
          ],
          ..._customActions
              .where((action) => action.isVisible?.call(item) ?? true)
              .expand((action) => [
                    actionBtn(
                      action.icon,
                      GridColors.secondary,
                      GridColors.secondary.withValues(alpha: 0.1),
                      () => action.onPressed(context, item),
                      action.label,
                    ),
                    const SizedBox(width: 4),
                  ]),
          if (widget.hasPermission('delete'))
            actionBtn(
              Icons.delete_outline,
              GridColors.error,
              GridColors.error.withValues(alpha: 0.1),
              () => _deleteItem(
                  _getNestedValue(itemMap, widget.idFieldName).toString()),
              'Excluir',
            ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? GridColors.error : GridColors.success,
        behavior: SnackBarBehavior.floating,
        action: isError
            ? SnackBarAction(
                label: 'Copiar',
                textColor: Colors.white,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message));
                },
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _showSaveErrorDialog(String message) async {
    _showSnackBar(message, isError: true);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Erro ao salvar'),
        content: TextField(
          controller: TextEditingController(text: message),
          readOnly: true,
          maxLines: 7,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar erro'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: message));
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (mounted) _showSnackBar('Erro copiado.');
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
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
    dynamic value = map;

    for (final part in parts) {
      if (value == null) break;
      if (value is Map) {
        value = value[part];
      } else {
        value = null;
        break;
      }
    }

    if (value != null && value.toString().trim().isNotEmpty) return value;

    // Fallbacks para campos relacionais (ex.: parceiro.nome -> parceiroNome / parceiro_nome)
    if (map is Map && parts.length > 1) {
      final camelAlias = '${parts[0]}${parts[1][0].toUpperCase()}${parts[1].substring(1)}';
      final camelVal = map[camelAlias];
      if (camelVal != null && camelVal.toString().trim().isNotEmpty) return camelVal;
      final snakeAlias = '${parts[0]}_${parts[1]}';
      final snakeVal = map[snakeAlias];
      if (snakeVal != null && snakeVal.toString().trim().isNotEmpty) return snakeVal;
    }

    return value;
  }

  bool _hasStatusField(Map<String, dynamic> itemMap) {
    return itemMap.containsKey('status') ||
        itemMap.containsKey('ativo') ||
        itemMap.containsKey('situacao');
  }
}

// Typedefs necessários
typedef FromJson<T> = T Function(Map<String, dynamic> json);
typedef ToJson<T> = Map<String, dynamic> Function(T item);
typedef SecurityCheck = bool Function(String permission);
typedef OnItemTap<T> = void Function(T item, BuildContext context);
typedef CustomActionBuilder<T> = List<CustomAction<T>> Function();
