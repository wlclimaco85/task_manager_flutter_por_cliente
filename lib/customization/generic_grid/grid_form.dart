// lib/data/customization/grid_form.dart
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/tenant_context.dart';

import 'grid_theme.dart';
import 'grid_models.dart';
import 'grid_network.dart';
import 'grid_utils.dart';
import '../../utils/grid_texts.dart';

class GridFormDialog extends StatefulWidget {
  final String titleNew;
  final String titleEdit;
  final List<FieldConfig> fieldConfigs;
  final String createEndpoint;
  final String updateEndpoint; // ':id'
  final Future<Map<String, String>> Function()? authHeadersProvider;
  final String? baseUrlForMultipart;
  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic>? item)?
      dynamicAdditionalFormData;

  /// Hook opcional para ajustar o formData final (já com os valores dos
  /// controllers) antes do envio — ex.: copiar um campo do form para outro
  /// campo fixo do payload. Não afeta telas que não o utilizarem.
  final Map<String, dynamic> Function(Map<String, dynamic> formData)?
      transformFormData;
  final Map<String, dynamic>? editingItem;
  final String idFieldName;

  const GridFormDialog({
    super.key,
    required this.titleNew,
    required this.titleEdit,
    required this.fieldConfigs,
    required this.createEndpoint,
    required this.updateEndpoint,
    this.authHeadersProvider,
    this.baseUrlForMultipart,
    this.additionalFormData,
    this.dynamicAdditionalFormData,
    this.transformFormData,
    required this.editingItem,
    required this.idFieldName,
  });

  @override
  State<GridFormDialog> createState() => _GridFormDialogState();
}

class _GridFormDialogState extends State<GridFormDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<PlatformFile>> _fileCache = {};
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  bool _req(FieldConfig c) =>
      c.isRequired || (c.requiredOnCreate && widget.editingItem == null);

  @override
  void initState() {
    super.initState();
    L.d('[GridForm] initState');
    for (final c in widget.fieldConfigs.where((x) => x.isInForm)) {
      final initial =
          getNestedValue(widget.editingItem, c.fieldName)?.toString() ??
              (c.defaultValue?.toString() ?? '');
      _controllers[c.fieldName] = TextEditingController(text: initial);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingItem != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Cabeçalho ──────────────────────────────────────────────────
            Row(children: [
              const Icon(Icons.edit_outlined,
                  color: GridColors.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEditing ? widget.titleEdit : widget.titleNew,
                  style: const TextStyle(
                    color: GridColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF616161)),
              ),
            ]),
            const Divider(height: 20, thickness: 1, color: Color(0xFFEEEEEE)),
            // ── Campos ─────────────────────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.fieldConfigs
                        .where((c) => c.isInForm)
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildFormField(c),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // ── Rodapé — botões ────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBDBDBD)),
                    foregroundColor: const Color(0xFF616161),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(GridTexts.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Salvar' : 'Adicionar'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField(FieldConfig c) {
    final ctrl = _controllers[c.fieldName];
    if (ctrl == null) return const Text('Campo não inicializado');

    switch (c.fieldType) {
      case FieldType.dropdown:
        return _buildDropdown(c, ctrl);
      case FieldType.boolean:
        final v = ctrl.text.toLowerCase() == 'true';
        return Row(children: [
          Checkbox(
            value: v,
            activeColor: GridColors.primary,
            onChanged: c.enabled
                ? (nv) {
                    ctrl.text = (nv ?? false).toString();
                    setState(() {});
                  }
                : null,
          ),
          Text(c.label,
              style: const TextStyle(color: Color(0xFF212121), fontSize: 14)),
        ]);
      case FieldType.multiline:
        return _textField(c, ctrl, maxLines: 4);
      case FieldType.date:
        return _dateField(c, ctrl);
      case FieldType.file:
        return _fileField(c, ctrl);
      case FieldType.multiselect:
        return _buildMultiselect(c, ctrl);
      case FieldType.cep:
        return _cepField(c, ctrl);
      default:
        return _textField(c, ctrl);
    }
  }

  // ── Bordas dos campos de texto ─────────────────────────────────────────────

  InputBorder _defaultBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
      );

  InputBorder _focusedBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GridColors.primary, width: 2),
      );

  InputBorder _disabledBorder() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      );

  Widget _textField(FieldConfig c, TextEditingController ctrl,
      {int? maxLines}) {
    return TextFormField(
      controller: ctrl,
      enabled: c.enabled,
      maxLines: maxLines ?? c.maxLines,
      style: const TextStyle(color: Color(0xFF212121)),
      validator: (v) {
        if (_req(c) && (v?.isEmpty ?? true)) {
          return '${c.label} é obrigatório';
        }
        return c.validator?.call(v);
      },
      decoration: InputDecoration(
        labelText: c.label + (_req(c) ? ' *' : ''),
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        filled: true,
        fillColor: c.enabled ? Colors.white : const Color(0xFFF5F5F5),
        border: _defaultBorder(),
        enabledBorder: _defaultBorder(),
        focusedBorder: _focusedBorder(),
        disabledBorder: _disabledBorder(),
      ),
      keyboardType: keyboardForFieldType(c.fieldType),
    );
  }

  Widget _cepField(FieldConfig c, TextEditingController ctrl) {
    var lastCepBuscado = '';
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus) return;
        final cep = ctrl.text.replaceAll(RegExp(r'\D'), '');
        if (cep.length == 8 && cep != lastCepBuscado) {
          lastCepBuscado = cep;
          _buscarCepEPreencher(cep);
        }
      },
      child: TextFormField(
        controller: ctrl,
        enabled: c.enabled,
        maxLines: 1,
        style: const TextStyle(color: Color(0xFF212121)),
        validator: (v) {
          if (_req(c) && (v?.isEmpty ?? true)) {
            return '${c.label} é obrigatório';
          }
          return c.validator?.call(v);
        },
        decoration: InputDecoration(
          labelText: c.label + (_req(c) ? ' *' : ''),
          labelStyle: const TextStyle(color: Color(0xFF757575)),
          suffixIcon:
              const Icon(Icons.search, color: GridColors.primary, size: 18),
          filled: true,
          fillColor: c.enabled ? Colors.white : const Color(0xFFF5F5F5),
          border: _defaultBorder(),
          enabledBorder: _defaultBorder(),
          focusedBorder: _focusedBorder(),
          disabledBorder: _disabledBorder(),
          hintText: '00000-000',
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(8),
        ],
      ),
    );
  }

  Future<void> _buscarCepEPreencher(String cep) async {
    try {
      final resp =
          await http.get(Uri.parse('https://viacep.com.br/ws/$cep/json/'));
      if (resp.statusCode != 200) return;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      if (data['erro'] == true) return;

      void setField(String field, String? value) {
        final text = value?.trim() ?? '';
        final ctrl = _controllers[field];
        if (text.isNotEmpty && ctrl != null) ctrl.text = text;
      }

      setState(() {
        setField('rua', data['logradouro']?.toString());
        setField('bairro', data['bairro']?.toString());
        setField('cidade', data['localidade']?.toString());
        setField('estado', data['uf']?.toString());
        setField('pais', 'Brasil');
      });
    } catch (_) {
      // Permite preenchimento manual quando a consulta falhar.
    }
  }

  Widget _dateField(FieldConfig c, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      readOnly: true,
      enabled: c.enabled,
      style: const TextStyle(color: Color(0xFF212121)),
      decoration: InputDecoration(
        labelText: c.label + (_req(c) ? ' *' : ''),
        labelStyle: const TextStyle(color: Color(0xFF757575)),
        suffixIcon: const Icon(Icons.calendar_today,
            color: GridColors.primary, size: 18),
        filled: true,
        fillColor: c.enabled ? Colors.white : const Color(0xFFF5F5F5),
        border: _defaultBorder(),
        enabledBorder: _defaultBorder(),
        focusedBorder: _focusedBorder(),
        disabledBorder: _disabledBorder(),
      ),
      onTap: c.enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate:
                    tryParseDate(ctrl.text, c.dateFormat) ?? DateTime.now(),
                firstDate: c.firstDate ?? DateTime(1900),
                lastDate: c.lastDate ?? DateTime(2100),
                locale: const Locale('pt', 'BR'),
                builder: (context, child) => Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: GridColors.primary,
                      onPrimary: Colors.white,
                      secondary: GridColors.secondary,
                      onSecondary: Colors.white,
                      surface: Colors.white,
                      onSurface: GridColors.textSecondary,
                    ),
                    dialogBackgroundColor: Colors.white,
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                ctrl.text = DateFormat(c.dateFormat).format(picked);
                setState(() {});
              }
            }
          : null,
      validator: c.validator,
    );
  }

  Widget _fileField(FieldConfig c, TextEditingController ctrl) {
    final picked = _fileCache[c.fieldName] ?? [];
    final cfg = c.fileConfig ?? const FileConfig();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (picked.isNotEmpty)
        ...picked.map((f) => Card(
              margin: const EdgeInsets.only(bottom: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              child: ListTile(
                dense: true,
                leading:
                    const Icon(Icons.attach_file, color: GridColors.primary),
                title: Text(f.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
                subtitle: Text('${(f.size / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(fontSize: 11)),
                trailing: IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: GridColors.error),
                  onPressed: () {
                    setState(() {
                      _fileCache[c.fieldName]?.remove(f);
                      if (_fileCache[c.fieldName]?.isEmpty ?? false) {
                        _fileCache.remove(c.fieldName);
                      }
                      ctrl?.clear();
                    });
                  },
                ),
              ),
            )),
      OutlinedButton.icon(
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
                      _snack(
                          'Alguns arquivos excedem o tamanho permitido.', true);
                    }
                    setState(() {
                      _fileCache[c.fieldName] = valid;
                      ctrl.text = valid.map((e) => e.name).join(', ');
                    });
                  }
                } catch (e) {
                  _snack('Erro ao selecionar arquivo: $e', true);
                }
              }
            : null,
        icon: const Icon(Icons.attach_file, size: 16),
        label:
            Text(picked.isEmpty ? 'Selecionar Arquivo' : 'Adicionar Arquivo'),
        style: OutlinedButton.styleFrom(
          foregroundColor: GridColors.primary,
          side: const BorderSide(color: GridColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      if (cfg.allowedExtensions.isNotEmpty) const SizedBox(height: 4),
      if (cfg.allowedExtensions.isNotEmpty)
        Text(
          'Extensões permitidas: ${cfg.allowedExtensions.join(', ')}',
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
    ]);
  }

  Widget _buildDropdown(FieldConfig c, TextEditingController ctrl) {
    Future<List<Map<String, dynamic>>> fetchOptions() async {
      if (c.dropdownFutureBuilder != null)
        return await c.dropdownFutureBuilder!();
      return c.dropdownOptions ?? [];
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchOptions(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(color: GridColors.primary);
        }
        final opts = s.data ?? [];
        final valueField =
            c.dropdownValueField.isNotEmpty ? c.dropdownValueField : 'id';
        final displayField =
            c.dropdownDisplayField.isNotEmpty ? c.dropdownDisplayField : 'nome';

        // Resolve initial label
        String? initVal = ctrl.text.isNotEmpty
            ? ctrl.text
            : (c.defaultValue ?? c.dropdownSelectedValue)?.toString();
        String? initLabel;
        for (final o in opts) {
          if (o[valueField]?.toString() == initVal) {
            initLabel = o[displayField]?.toString();
            break;
          }
        }
        if (ctrl.text.isEmpty && initVal != null) ctrl.text = initVal;

        return _SearchableDropdownForm(
          config: c,
          controller: ctrl,
          options: opts,
          valueField: valueField,
          displayField: displayField,
          initialLabel: initLabel,
          defaultBorder: _defaultBorder(),
          focusedBorder: _focusedBorder(),
          isEditing: widget.editingItem != null,
          onChanged: (v) {
            ctrl.text = v ?? '';
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildMultiselect(FieldConfig c, TextEditingController ctrl) {
    Future<List<Map<String, dynamic>>> fetchOptions() async {
      if (c.dropdownFutureBuilder != null)
        return await c.dropdownFutureBuilder!();
      return c.dropdownOptions ?? [];
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchOptions(),
      builder: (context, s) {
        if (s.connectionState == ConnectionState.waiting)
          return const LinearProgressIndicator(color: GridColors.primary);
        final opts = s.data ?? [];
        final valueField =
            c.dropdownValueField.isNotEmpty ? c.dropdownValueField : 'id';
        final displayField =
            c.dropdownDisplayField.isNotEmpty ? c.dropdownDisplayField : 'nome';
        final selectedValues = ctrl.text.isNotEmpty
            ? ctrl.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : <String>[];
        final labels = opts
            .where((o) => selectedValues.contains(o[valueField]?.toString()))
            .map((o) => o[displayField]?.toString() ?? '')
            .join(', ');
        return InkWell(
          onTap: c.enabled
              ? () async {
                  final result = await showDialog<List<String>>(
                    context: context,
                    builder: (ctx) => _GridMultiSelectDialog(
                      title: c.label,
                      options: opts,
                      valueField: valueField,
                      displayField: displayField,
                      initialSelected: selectedValues,
                    ),
                  );
                  if (result != null) {
                    ctrl.text = result.join(', ');
                    setState(() {});
                  }
                }
              : null,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: c.label + (_req(c) ? ' *' : ''),
              labelStyle: const TextStyle(color: Color(0xFF757575)),
              filled: true,
              fillColor: c.enabled ? Colors.white : const Color(0xFFF5F5F5),
              border: _defaultBorder(),
              enabledBorder: _defaultBorder(),
              focusedBorder: _focusedBorder(),
              suffixIcon: c.enabled
                  ? const Icon(Icons.arrow_drop_down, color: Color(0xFF757575))
                  : const Icon(Icons.lock_outline,
                      size: 16, color: Colors.grey),
            ),
            child: Text(
              labels.isEmpty ? 'Selecione...' : labels,
              style: TextStyle(
                  color: labels.isEmpty
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFF212121)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _saving = false);
      return;
    }
    setState(() => _saving = true);

    try {
      final isEditing = widget.editingItem != null;
      final endpoint = isEditing
          ? widget.updateEndpoint.replaceFirst(
              ':id',
              (getNestedValue(widget.editingItem, widget.idFieldName) ?? '')
                  .toString())
          : widget.createEndpoint;

      final formData = <String, dynamic>{};

      // extra fixos
      if (widget.additionalFormData != null) {
        addAllNested(formData, widget.additionalFormData!);
      }
      // extra dinâmicos (dependem do item editado)
      if (widget.dynamicAdditionalFormData != null) {
        final dyn = widget.dynamicAdditionalFormData!(widget.editingItem);
        addAllNested(formData, dyn);
      }

      // dropdowns que usam selectedValue default
      for (final c in widget.fieldConfigs) {
        if (c.fieldType == FieldType.dropdown &&
            c.dropdownSelectedValue != null) {
          addToFormData(formData, c.fieldName, c.dropdownSelectedValue);
        }
      }

      // campos normais
      for (final c in widget.fieldConfigs
          .where((x) => x.isInForm && x.fieldType != FieldType.file)) {
        final ctrl = _controllers[c.fieldName];
        final valueText = ctrl?.text ?? '';
        if (valueText.isEmpty) continue;

        if (c.fieldType == FieldType.date) {
          final iso = tryDateToIso(valueText, c.dateFormat);
          addToFormData(formData, c.fieldName, iso ?? valueText);
        } else if (c.fieldType == FieldType.number) {
          final numVal = num.tryParse(valueText);
          addToFormData(formData, c.fieldName, numVal ?? valueText);
        } else if (c.fieldType == FieldType.boolean) {
          addToFormData(
              formData, c.fieldName, valueText.toLowerCase() == 'true');
        } else if (c.fieldName == 'regime') {
          final regimeId = int.tryParse(valueText);
          addToFormData(formData, 'regime.id', regimeId ?? valueText);
        } else {
          addToFormData(formData, c.fieldName, valueText);
        }
      }

      for (final c in widget.fieldConfigs
          .where((x) => x.isInForm && x.fieldType == FieldType.boolean)) {
        if (!formData.containsKey(c.fieldName)) {
          addToFormData(formData, c.fieldName, false);
        }
      }

      // valor fixo de payload (TelaField.defaultValue) — preenche campos sem
      // valor (tipicamente ocultos do form via isInForm=false configurado no
      // Editor de Telas), suportando templates {{now+Nd}} e {{campo:xxx}}.
      for (final c in widget.fieldConfigs) {
        if (c.defaultValue == null) continue;
        final atual = getNestedValue(formData, c.fieldName);
        if (atual != null && atual.toString().isNotEmpty) continue;
        final resolvido = resolveFieldDefaultTemplate(c.defaultValue, formData);
        addToFormData(formData, c.fieldName, resolvido);
      }

      // ajuste final do formData (já com os valores digitados no form)
      if (widget.transformFormData != null) {
        final transformed = widget.transformFormData!(formData);
        formData
          ..clear()
          ..addAll(transformed);
      }

      // arquivos
      final filesToUpload = <MultipartFieldFile>[];
      for (final c
          in widget.fieldConfigs.where((x) => x.fieldType == FieldType.file)) {
        final picked = _fileCache[c.fieldName];
        if (picked != null && picked.isNotEmpty) {
          final cfg = c.fileConfig ?? const FileConfig();
          for (final f in picked) {
            filesToUpload.add(
              MultipartFieldFile(fieldName: cfg.fileFieldName, file: f),
            );
          }
        }
      }

      // Guarda: impede envio JSON quando há campo de arquivo obrigatório sem
      // arquivo selecionado — o validator do FormField não re-executa aqui.
      for (final c
          in widget.fieldConfigs.where((x) => x.fieldType == FieldType.file)) {
        if (_req(c) && (_fileCache[c.fieldName]?.isEmpty ?? true)) {
          _snack(
              '${c.label} é obrigatório — selecione um arquivo antes de salvar.',
              true);
          if (mounted) setState(() => _saving = false);
          return;
        }
      }

      dynamic resp;
      if (filesToUpload.isNotEmpty) {
        _prepareMultipartFields(formData, filesToUpload);
        L.d('[GridForm] sending MULTIPART to: $endpoint');
        resp = await sendMultipart(
          endpoint: endpoint,
          isUpdate: isEditing,
          fields: flattenForMultipart(formData),
          files: filesToUpload,
          baseUrlForMultipart: widget.baseUrlForMultipart,
          authHeadersProvider: widget.authHeadersProvider,
        );
      } else {
        final normalized = normalizeDotted(formData);
        L.d('[GridForm] sending JSON to: $endpoint payload: ${jsonEncode(normalized)}');
        resp = isEditing
            ? await putJson(endpoint, normalized)
            : await postJson(endpoint, normalized);
      }

      if (respSuccess(resp)) {
        if (mounted) Navigator.pop(context, true);
        _snack(isEditing ? 'Item atualizado!' : 'Item criado!');
      } else {
        // Extrai apenas a mensagem de erro real do backend (campo 'message'
        // de ExceptionResponse/GlobalException, ex.: validacoes de negocio
        // como CNPJ/CPF duplicado) em vez de despejar o Map inteiro ou so
        // o status code, que nao explicam o motivo ao usuario.
        final body = respBody(resp);
        final mensagem = (body is Map && body['message'] is String)
            ? body['message'] as String
            : (body ?? respStatus(resp)).toString();
        _showSaveError('Erro ao salvar: $mensagem');
      }
    } catch (e, st) {
      L.e('[GridForm] save error: $e', st);
      _showSaveError('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _prepareMultipartFields(
    Map<String, dynamic> formData,
    List<MultipartFieldFile> filesToUpload,
  ) {
    formData.putIfAbsent(
      'fileName',
      () => filesToUpload.first.file.name?.toString() ?? '',
    );
    formData.putIfAbsent(
      'fileType',
      () => _mimeFromFileName(filesToUpload.first.file.name?.toString() ?? ''),
    );

    for (final key in const ['empresa', 'diretorio', 'parceiro']) {
      final value = formData[key];
      if (value == null || value.toString().trim().isEmpty) {
        // O backend (FileController) exige os 3 params SEMPRE presentes
        // (@RequestParam sem required=false) — sem fallback aqui, o multipart
        // saia sem a chave e o backend respondia 400 "Required request
        // parameter 'empresa'/'diretorio' ... is not present". 'empresa' usa
        // o tenant do usuario logado quando disponivel; os demais ficam
        // {"id": null} (o backend trata null graciosamente).
        if (key == 'empresa' && TenantContext.empresaId != null) {
          formData[key] = jsonEncode({'id': TenantContext.empresaId});
        } else {
          formData[key] = jsonEncode({'id': null});
        }
        continue;
      }
      if (value is Map) {
        formData[key] = jsonEncode(value);
        continue;
      }
      final text = value.toString().trim();
      if (text.startsWith('{')) continue;
      final parsed = int.tryParse(text);
      formData[key] = jsonEncode({'id': parsed ?? text});
    }
  }

  String _mimeFromFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.csv')) return 'text/csv';
    return 'application/octet-stream';
  }

  void _snack(String msg, [bool error = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: error ? GridColors.error : GridColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _showSaveError(String msg) async {
    if (!mounted) return;
    _snack(msg, true);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erro ao salvar'),
        content: TextField(
          controller: TextEditingController(text: msg),
          readOnly: true,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            label: const Text('Copiar erro'),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: msg));
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) _snack('Erro copiado.');
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _GridMultiSelectDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final String valueField;
  final String displayField;
  final List<String> initialSelected;

  const _GridMultiSelectDialog({
    required this.title,
    required this.options,
    required this.valueField,
    required this.displayField,
    required this.initialSelected,
  });

  @override
  State<_GridMultiSelectDialog> createState() => _GridMultiSelectDialogState();
}

class _GridMultiSelectDialogState extends State<_GridMultiSelectDialog> {
  late List<String> _selected;
  late List<Map<String, dynamic>> _filtered;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialSelected);
    _filtered = widget.options;
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.options
            : widget.options
                .where((o) =>
                    o[widget.displayField]
                        ?.toString()
                        .toLowerCase()
                        .contains(q) ??
                    false)
                .toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _isSelected(String val) => _selected.contains(val);

  void _toggle(String val) {
    setState(() {
      if (_isSelected(val)) {
        _selected.remove(val);
      } else {
        _selected.add(val);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520, maxWidth: 400),
        child: Column(children: [
          // Cabeçalho
          Container(
            decoration: const BoxDecoration(
              color: GridColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const Icon(Icons.checklist, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),
          // Busca
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: Color(0xFF757575)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFBDBDBD))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: GridColors.primary, width: 2)),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (ctx, i) {
                final opt = _filtered[i];
                final val = opt[widget.valueField]?.toString() ?? '';
                final label = opt[widget.displayField]?.toString() ?? val;
                return CheckboxListTile(
                  title: Text(label, style: const TextStyle(fontSize: 13)),
                  value: _isSelected(val),
                  activeColor: GridColors.primary,
                  onChanged: (_) => _toggle(val),
                  dense: true,
                );
              },
            ),
          ),
          const Divider(height: 1),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(GridTexts.cancel,
                  style: TextStyle(color: Color(0xFF616161))),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, _selected),
              child: const Text('Confirmar',
                  style: TextStyle(color: GridColors.primary)),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─── Searchable Dropdown for grid_form ───────────────────────────────────────

class _SearchableDropdownForm extends StatefulWidget {
  final FieldConfig config;
  final TextEditingController controller;
  final List<Map<String, dynamic>> options;
  final String valueField;
  final String displayField;
  final String? initialLabel;
  final InputBorder defaultBorder;
  final InputBorder focusedBorder;
  final void Function(String?) onChanged;
  final bool isEditing;

  const _SearchableDropdownForm({
    required this.config,
    required this.controller,
    required this.options,
    required this.valueField,
    required this.displayField,
    required this.defaultBorder,
    required this.focusedBorder,
    required this.onChanged,
    required this.isEditing,
    this.initialLabel,
  });

  @override
  State<_SearchableDropdownForm> createState() =>
      _SearchableDropdownFormState();
}

class _SearchableDropdownFormState extends State<_SearchableDropdownForm> {
  String? _label;

  @override
  void initState() {
    super.initState();
    _label = widget.initialLabel;
  }

  Future<void> _open() async {
    if (!widget.config.enabled) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _GridDropdownSearchDialog(
        title: widget.config.label,
        options: widget.options,
        valueField: widget.valueField,
        displayField: widget.displayField,
        currentValue: widget.controller.text,
      ),
    );
    if (result != null) {
      final val = result[widget.valueField]?.toString() ?? '';
      final lbl = result[widget.displayField]?.toString() ?? '';
      setState(() => _label = lbl.isEmpty ? null : lbl);
      widget.onChanged(val.isEmpty ? null : val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final effReq = widget.config.isRequired ||
        (widget.config.requiredOnCreate && !widget.isEditing);
    final label = widget.config.label + (effReq ? ' *' : '');
    final display = _label ?? widget.controller.text;
    final isEmpty = display.isEmpty;
    final isDisabled = !widget.config.enabled;

    return FormField<String>(
      initialValue: widget.controller.text,
      validator: (v) {
        if (effReq && (widget.controller.text.isEmpty)) {
          return '${widget.config.label} é obrigatório';
        }
        return widget.config.validator?.call(widget.controller.text);
      },
      builder: (state) => InkWell(
        onTap: isDisabled ? null : _open,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Color(0xFF757575)),
            filled: true,
            fillColor: isDisabled ? const Color(0xFFF5F5F5) : Colors.white,
            border: widget.defaultBorder,
            enabledBorder: widget.defaultBorder,
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: widget.focusedBorder,
            suffixIcon: isDisabled
                ? const Icon(Icons.lock_outline, size: 16, color: Colors.grey)
                : const Icon(Icons.search, size: 18, color: Color(0xFF757575)),
            errorText: state.errorText,
          ),
          child: Text(
            isEmpty ? 'Selecione...' : display,
            style: TextStyle(
              fontSize: 13,
              color: isEmpty || isDisabled
                  ? const Color(0xFF9E9E9E)
                  : const Color(0xFF212121),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

// ─── Dialog de busca para grid_form ──────────────────────────────────────────

class _GridDropdownSearchDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final String valueField;
  final String displayField;
  final String? currentValue;

  const _GridDropdownSearchDialog({
    required this.title,
    required this.options,
    required this.valueField,
    required this.displayField,
    this.currentValue,
  });

  @override
  State<_GridDropdownSearchDialog> createState() =>
      _GridDropdownSearchDialogState();
}

class _GridDropdownSearchDialogState extends State<_GridDropdownSearchDialog> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
  }

  void _search(String q) {
    final query = q.toLowerCase().trim();
    setState(() {
      _filtered = query.isEmpty
          ? widget.options
          : widget.options
              .where((o) => (o[widget.displayField]?.toString() ?? '')
                  .toLowerCase()
                  .contains(query))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 520),
        child: Column(
          children: [
            // ── Cabeçalho ─────────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: GridColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // ── Campo de busca ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: Color(0xFF757575)),
                  suffixIcon: _ctrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _ctrl.clear();
                            _search('');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFBDBDBD)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: GridColors.primary, width: 2),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('${_filtered.length} resultado(s)',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop(<String, dynamic>{}),
                    child: const Text('Limpar',
                        style:
                            TextStyle(fontSize: 11, color: Color(0xFF616161))),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // ── Lista de opções ────────────────────────────────────────────
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(
                      child: Text('Nenhum resultado',
                          style: TextStyle(color: Color(0xFF9E9E9E))))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final o = _filtered[i];
                        final val = o[widget.valueField]?.toString();
                        final lbl =
                            o[widget.displayField]?.toString() ?? val ?? '';
                        final isSel = val == widget.currentValue;
                        return ListTile(
                          dense: true,
                          selected: isSel,
                          selectedTileColor:
                              GridColors.primary.withValues(alpha: 0.08),
                          leading: isSel
                              ? const Icon(Icons.check_circle,
                                  color: GridColors.primary, size: 18)
                              : const Icon(Icons.radio_button_unchecked,
                                  color: Color(0xFF9E9E9E), size: 18),
                          title: Text(lbl,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isSel ? FontWeight.bold : FontWeight.normal,
                                color: isSel
                                    ? GridColors.primary
                                    : const Color(0xFF212121),
                              )),
                          onTap: () => Navigator.of(context).pop(o),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
