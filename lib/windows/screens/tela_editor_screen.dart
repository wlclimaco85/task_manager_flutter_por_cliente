import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:http/http.dart' as http;
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
// ─────────────────────────────────────────────────────────────────────────────
// TELA EDITOR — Grid de telas + editor de campos
// ─────────────────────────────────────────────────────────────────────────────

class TelaEditorScreen extends StatefulWidget {
  const TelaEditorScreen({super.key});

  @override
  State<TelaEditorScreen> createState() => _TelaEditorScreenState();
}

class _TelaEditorScreenState extends State<TelaEditorScreen> {
  List<Map<String, dynamic>> _telas = [];
  bool _loading = true;
  String? _erro;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/telas?tamanho=500'),
        headers: { if (token != null) 'Authorization': 'Bearer $token' },
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body is Map) {
          final d = body['data'];
          if (d is List) {
            lista = d;
          } else if (d is Map) lista = d['dados'] ?? d['content'] ?? [];
        }
        setState(() => _telas = lista.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
      } else {
        setState(() => _erro = 'Erro ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtradas {
    final q = _search.text.toLowerCase();
    if (q.isEmpty) return _telas;
    return _telas.where((t) =>
      (t['nome']?.toString().toLowerCase().contains(q) ?? false) ||
      (t['titulo']?.toString().toLowerCase().contains(q) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D27),
        title: const Text('Editor de Telas', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh, color: Colors.white54)),
        ],
      ),
      body: Column(
        children: [
          // Barra de busca
          Container(
            color: const Color(0xFF1A1D27),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar tela...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                filled: true,
                fillColor: const Color(0xFF0F1117),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(color: GridColors.success),
          if (_erro != null) Padding(padding: const EdgeInsets.all(8), child: Text(_erro!, style: const TextStyle(color: Colors.red))),
          // Grid de telas
          Expanded(
            child: _filtradas.isEmpty && !_loading
                ? const Center(child: Text('Nenhuma tela encontrada.', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtradas.length,
                    itemBuilder: (_, i) {
                      final t = _filtradas[i];
                      return _TelaCard(
                        tela: t,
                        onEdit: () => _abrirEditor(t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _abrirEditor(Map<String, dynamic> tela) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _FieldEditorScreen(telaId: tela['id'], telaNome: tela['nome'] ?? '', telaTitulo: tela['titulo'] ?? ''),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD DE TELA
// ─────────────────────────────────────────────────────────────────────────────

class _TelaCard extends StatelessWidget {
  final Map<String, dynamic> tela;
  final VoidCallback onEdit;
  const _TelaCard({required this.tela, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final fields = (tela['fields'] as List?)?.length ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.table_chart, color: GridColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tela['titulo'] ?? tela['nome'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13)),
                Text(tela['nome'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
            child: Text('$fields campos', style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 14),
            label: const Text('Editar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD EDITOR SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _FieldEditorScreen extends StatefulWidget {
  final int telaId;
  final String telaNome;
  final String telaTitulo;
  const _FieldEditorScreen({required this.telaId, required this.telaNome, required this.telaTitulo});

  @override
  State<_FieldEditorScreen> createState() => _FieldEditorScreenState();
}

class _FieldEditorScreenState extends State<_FieldEditorScreen> {
  List<Map<String, dynamic>> _fields = [];
  bool _loading = true;
  Map<String, dynamic>? _selectedField;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() { _loading = true; });
    try {
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/telas/${widget.telaNome}'),
        headers: { if (token != null) 'Authorization': 'Bearer $token' },
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final fields = body['fields'] as List? ?? [];
        setState(() => _fields = fields.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          ..sort((a, b) => (a['fieldOrder'] ?? 0).compareTo(b['fieldOrder'] ?? 0)));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _salvarCampo(Map<String, dynamic> field) async {
    setState(() => _saving = true);
    try {
      final token = AuthUtility.userInfo?.token;
      final fieldId = field['id'];
      if (fieldId == null) return;
      await http.put(
        Uri.parse('${ApiLinks.baseUrl}/api/telas/${widget.telaId}/fields/$fieldId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(field),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campo salvo!'), backgroundColor: GridColors.success),
      );
      _carregar();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D27),
        title: Text('Editar: ${widget.telaTitulo}', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: GridColors.success))
          : Row(
              children: [
                // Lista de campos (esquerda)
                SizedBox(
                  width: 300,
                  child: Container(
                    color: const Color(0xFF1A1D27),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          color: const Color(0xFF252836),
                          child: Row(children: [
                            const Icon(Icons.list, color: Colors.white54, size: 16),
                            const SizedBox(width: 8),
                            Text('${_fields.length} campos', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ]),
                        ),
                        Expanded(
                          child: ReorderableListView.builder(
                            itemCount: _fields.length,
                            onReorder: (oldIndex, newIndex) async {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = _fields.removeAt(oldIndex);
                                _fields.insert(newIndex, item);
                                for (int i = 0; i < _fields.length; i++) {
                                  _fields[i] = {..._fields[i], 'fieldOrder': i + 1};
                                }
                              });
                              // Salva nova ordem no backend
                              try {
                                final token = AuthUtility.userInfo?.token;
                                final orders = _fields.asMap().entries
                                    .map((e) => {'id': e.value['id'], 'fieldOrder': e.key + 1})
                                    .toList();
                                await http.put(
                                  Uri.parse('${ApiLinks.baseUrl}/api/telas/${widget.telaId}/fields/reorder'),
                                  headers: {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token'},
                                  body: jsonEncode(orders),
                                );
                              } catch (_) {}
                            },
                            itemBuilder: (_, i) {
                              final f = _fields[i];
                              final isSelected = _selectedField?['id'] == f['id'];
                              return _FieldListItem(
                                key: ValueKey(f['id'] ?? i),
                                field: f,
                                isSelected: isSelected,
                                onTap: () => setState(() => _selectedField = Map.from(f)),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Painel de propriedades (direita)
                Expanded(
                  child: _selectedField == null
                      ? const Center(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app, color: Colors.white24, size: 48),
                            SizedBox(height: 12),
                            Text('Selecione um campo para editar', style: TextStyle(color: Colors.white38)),
                          ],
                        ))
                      : _FieldPropertiesPanel(
                          field: _selectedField!,
                          saving: _saving,
                          onChanged: (updated) => setState(() => _selectedField = updated),
                          onSave: () => _salvarCampo(_selectedField!),
                        ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD LIST ITEM
// ─────────────────────────────────────────────────────────────────────────────

class _FieldListItem extends StatelessWidget {
  final Map<String, dynamic> field;
  final bool isSelected;
  final VoidCallback onTap;
  const _FieldListItem({super.key, required this.field, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final type = field['fieldType']?.toString() ?? 'text';
    final enabled = field['enabled'] != false;
    final inForm = field['isInForm'] != false;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0).withValues(alpha: 0.3) : Colors.transparent,
          border: Border(
            left: BorderSide(color: isSelected ? const Color(0xFF1565C0) : Colors.transparent, width: 3),
            bottom: const BorderSide(color: Colors.white12),
          ),
        ),
        child: Row(
          children: [
            Icon(_typeIcon(type), size: 14, color: isSelected ? const Color(0xFF42A5F5) : Colors.white38),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(field['label'] ?? field['fieldName'] ?? '', style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  Text(field['fieldName'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
            if (!inForm) const Icon(Icons.visibility_off, size: 12, color: Colors.white24),
            if (!enabled) const Icon(Icons.lock, size: 12, color: Colors.white24),
            if (field['isRequired'] == true) const Icon(Icons.star, size: 10, color: Color(0xFFFFB300)),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'dropdown': return Icons.arrow_drop_down_circle;
      case 'multiselect': return Icons.checklist;
      case 'boolean': return Icons.toggle_on;
      case 'date': return Icons.calendar_today;
      case 'number': return Icons.numbers;
      case 'email': return Icons.email;
      case 'password': return Icons.lock;
      case 'phone': return Icons.phone;
      case 'currency': return Icons.attach_money;
      case 'multiline': return Icons.notes;
      case 'file': return Icons.attach_file;
      default: return Icons.text_fields;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD PROPERTIES PANEL
// ─────────────────────────────────────────────────────────────────────────────

class _FieldPropertiesPanel extends StatefulWidget {
  final Map<String, dynamic> field;
  final bool saving;
  final void Function(Map<String, dynamic>) onChanged;
  final VoidCallback onSave;
  const _FieldPropertiesPanel({required this.field, required this.saving, required this.onChanged, required this.onSave});

  @override
  State<_FieldPropertiesPanel> createState() => _FieldPropertiesPanelState();
}

class _FieldPropertiesPanelState extends State<_FieldPropertiesPanel> {
  late Map<String, dynamic> _f;
  late TextEditingController _labelCtrl;
  late TextEditingController _fieldNameCtrl;
  late TextEditingController _displayFieldCtrl;
  late TextEditingController _dropdownEndpointCtrl;
  late TextEditingController _maxLinesCtrl;
  late TextEditingController _fieldOrderCtrl;
  late TextEditingController _maskCtrl;
  late TextEditingController _defaultValueCtrl;

  static const _fieldTypes = [
    'text', 'number', 'email', 'date', 'multiline', 'dropdown',
    'multiselect', 'boolean', 'file', 'password', 'phone', 'cpf',
    'cnpj', 'currency', 'percentage', 'url',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(_FieldPropertiesPanel old) {
    super.didUpdateWidget(old);
    if (old.field['id'] != widget.field['id']) _init();
  }

  void _init() {
    _f = Map.from(widget.field);
    _labelCtrl = TextEditingController(text: _f['label']?.toString() ?? '');
    _fieldNameCtrl = TextEditingController(text: _f['fieldName']?.toString() ?? '');
    _displayFieldCtrl = TextEditingController(text: _f['displayFieldName']?.toString() ?? '');
    _dropdownEndpointCtrl = TextEditingController(text: _f['dropdownEndpoint']?.toString() ?? '');
    _maxLinesCtrl = TextEditingController(text: _f['maxLines']?.toString() ?? '1');
    _fieldOrderCtrl = TextEditingController(text: _f['fieldOrder']?.toString() ?? '0');
    _maskCtrl = TextEditingController(text: _f['mask']?.toString() ?? '');
    final dv = _f['defaultValue'];
    _defaultValueCtrl = TextEditingController(
      text: dv == null
          ? ''
          : (dv is String ? dv : jsonEncode(dv)),
    );
  }

  void _update(String key, dynamic value) {
    setState(() { _f[key] = value; });
    widget.onChanged(_f);
  }

  /// Converte o texto digitado em "Valor Fixo (Payload)" para o tipo mais
  /// adequado: JSON (objeto/lista) se começar com `{`/`[`, bool, num, ou
  /// String literal (inclui os templates `{{now+Nd}}` / `{{campo:xxx}}`).
  void _updateDefaultValue(String text) {
    if (text.isEmpty) {
      _update('defaultValue', null);
      return;
    }
    if (text.startsWith('{{') || (!text.startsWith('{') && !text.startsWith('['))) {
      if (text == 'true' || text == 'false') {
        _update('defaultValue', text == 'true');
        return;
      }
      final asNum = num.tryParse(text);
      if (asNum != null) {
        _update('defaultValue', asNum);
        return;
      }
      _update('defaultValue', text);
      return;
    }
    try {
      _update('defaultValue', jsonDecode(text));
    } catch (_) {
      _update('defaultValue', text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.settings, color: GridColors.success, size: 20),
              const SizedBox(width: 8),
              Text('Propriedades: ${_f['fieldName'] ?? ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: widget.saving ? null : widget.onSave,
                icon: widget.saving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save, size: 14),
                label: Text(widget.saving ? 'Salvando...' : 'Salvar'),
                style: ElevatedButton.styleFrom(backgroundColor: GridColors.success),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Identificação ──────────────────────────────────────────────
          _section('Identificação'),
          _textField('Label (exibição)', _labelCtrl, (v) => _update('label', v)),
          _textField('Field Name (código)', _fieldNameCtrl, (v) => _update('fieldName', v)),
          _textField('Display Field Name', _displayFieldCtrl, (v) => _update('displayFieldName', v)),
          _numberField('Ordem no Form', _fieldOrderCtrl, (v) => _update('fieldOrder', int.tryParse(v) ?? 0)),

          // ── Tipo ───────────────────────────────────────────────────────
          _section('Tipo do Campo'),
          _dropdown('Tipo', _f['fieldType']?.toString() ?? 'text', _fieldTypes,
              (v) => _update('fieldType', v)),
          if (_f['fieldType'] == 'multiline')
            _numberField('Máx. Linhas', _maxLinesCtrl, (v) => _update('maxLines', int.tryParse(v) ?? 1)),
          if (_f['fieldType'] == 'dropdown' || _f['fieldType'] == 'multiselect') ...[
            _textField('Endpoint Dropdown', _dropdownEndpointCtrl, (v) => _update('dropdownEndpoint', v)),
          ],
          _textField('Máscara (ex: ##/##/####)', _maskCtrl, (v) => _update('mask', v)),

          // ── Visibilidade ───────────────────────────────────────────────
          _section('Visibilidade'),
          _switch('Visível no Form', _f['isInForm'] != false, (v) => _update('isInForm', v)),
          _switch('Visível na Grid', _f['isVisibleByDefault'] != false, (v) => _update('isVisibleByDefault', v)),
          _switch('Filtrável', _f['isFilterable'] != false, (v) => _update('isFilterable', v)),
          _switch('Ordenável', _f['isSortable'] != false, (v) => _update('isSortable', v)),
          _switch('Mostrar no Insert', _f['showInInsert'] != false, (v) => _update('showInInsert', v)),
          _switch('Mostrar no Update', _f['showInUpdate'] != false, (v) => _update('showInUpdate', v)),

          // ── Comportamento ──────────────────────────────────────────────
          _section('Comportamento'),
          _switch('Obrigatório', _f['isRequired'] == true, (v) => _update('isRequired', v)),
          _switch('Habilitado (editável)', _f['enabled'] != false, (v) => _update('enabled', v)),
          _switch('Fixo (não ocultar)', _f['isFixed'] == true, (v) => _update('isFixed', v)),
          _switch('Multi-select', _f['multiSelect'] == true, (v) => _update('multiSelect', v)),

          // ── Payload ────────────────────────────────────────────────────
          _section('Payload'),
          _textField(
            'Valor Fixo (Payload)',
            _defaultValueCtrl,
            _updateDefaultValue,
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Enviado no salvar mesmo com o campo oculto do form '
              '(Visível no Form = desligado). Aceita texto, número, true/false, '
              'JSON ({"id": 1}) ou os templates {{now+Nd}} e {{campo:xxx}}.',
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(title, style: const TextStyle(color: GridColors.success, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
  );

  Widget _textField(String label, TextEditingController ctrl, void Function(String) onChanged) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
          filled: true, fillColor: const Color(0xFF1A1D27),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: GridColors.success)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
      ),
    );

  Widget _numberField(String label, TextEditingController ctrl, void Function(String) onChanged) =>
    _textField(label, ctrl, onChanged);

  Widget _dropdown(String label, String value, List<String> options, void Function(String?) onChanged) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(value) ? value : options.first,
        dropdownColor: const Color(0xFF1A1D27),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 11),
          filled: true, fillColor: const Color(0xFF1A1D27),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Colors.white12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          isDense: true,
        ),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
        onChanged: onChanged,
      ),
    );

  Widget _switch(String label, bool value, void Function(bool) onChanged) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: GridColors.success,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
}
