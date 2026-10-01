import 'package:flutter/material.dart';
import '../../../services/devolucao_service.dart';
import '../../../utils/grid_colors.dart';
import '../../../windows/dialogs/devolucao_form_dialog.dart';
import '../../utils/grid_texts.dart';

class WindowsDevolucaoGridScreen extends StatefulWidget {
  const WindowsDevolucaoGridScreen({super.key});

  @override
  State<WindowsDevolucaoGridScreen> createState() =>
      _WindowsDevolucaoGridScreenState();
}

class _WindowsDevolucaoGridScreenState
    extends State<WindowsDevolucaoGridScreen> {
  List<Map<String, dynamic>> _devolucoes = [];
  bool _isLoading = true;

  String _statusFilter = 'Todos';
  String _clienteFilter = '';
  DateTime? _dataInicio;
  DateTime? _dataFim;

  final _statusOptions = ['Todos', 'RASCUNHO', 'CONCLUIDO', 'CANCELADO'];
  final _clienteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _clienteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await DevolucaoService.fetchAll(
      status: _statusFilter != 'Todos' ? _statusFilter : null,
      cliente: _clienteFilter.isNotEmpty ? _clienteFilter : null,
      dataInicio: _dataInicio?.toIso8601String().substring(0, 10),
      dataFim: _dataFim?.toIso8601String().substring(0, 10),
    );
    if (mounted) setState(() { _devolucoes = data; _isLoading = false; });
  }

  void _openForm(Map<String, dynamic>? item) {
    showDialog(
      context: context,
      builder: (_) => DevolucaoFormDialog(item: item, onSaved: _load),
    );
  }

  Future<void> _confirmAction(String title, String msg, Future<bool> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GridColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(GridTexts.confirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final success = await action();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success
          ? GridTexts.completedAction(title)
          : GridTexts.actionFailure(title)),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
    if (success) _load();
  }

  Future<void> _pickDate({required bool isInicio}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) _dataInicio = picked;
        else _dataFim = picked;
      });
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'RASCUNHO': return Colors.grey;
      case 'CONCLUIDO': return Colors.green;
      case 'CANCELADO': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterBar(),
        const SizedBox(height: 8),
        Row(
          children: [
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _openForm(null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text(GridTexts.newReturn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildTable()),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(GridTexts.statusLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          SizedBox(
            width: 140,
            height: 36,
            child: DropdownButtonFormField<String>(
              value: _statusFilter,
              isDense: true,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _statusFilter = v!),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            height: 36,
            child: TextField(
              controller: _clienteCtrl,
              decoration: const InputDecoration(
                hintText: GridTexts.searchCustomerHint,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _clienteFilter = v,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => _pickDate(isInicio: true),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(_dataInicio != null ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}' : 'Início', style: const TextStyle(fontSize: 13)),
              ]),
            ),
          ),
          const Text(GridTexts.until, style: TextStyle(fontSize: 13)),
          InkWell(
            onTap: () => _pickDate(isInicio: false),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(_dataFim != null ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}' : 'Fim', style: const TextStyle(fontSize: 13)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.search, size: 18),
              label: const Text(GridTexts.filter, style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _statusFilter = 'Todos';
                  _clienteFilter = '';
                  _clienteCtrl.clear();
                  _dataInicio = null;
                  _dataFim = null;
                });
                _load();
              },
              icon: const Icon(Icons.clear, size: 18),
              label: const Text(GridTexts.clear, style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_devolucoes.isEmpty) {
      return const Center(child: Text(GridTexts.noReturnFound));
    }
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 16,
        headingRowHeight: 44,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 60,
        columns: const [
          DataColumn(label: Text(GridTexts.number, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.date, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.type, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.customerColumn, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.sourceDocumentColumn, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.status, style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text(GridTexts.actions, style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _devolucoes.map((o) {
          final id = o['id'] as int?;
          final status = o['status']?.toString() ?? 'RASCUNHO';
          return DataRow(cells: [
            DataCell(Text(o['numero']?.toString() ?? '#${id ?? 0}')),
            DataCell(Text(_formatDate(o['data']?.toString()))),
            DataCell(Text(_tipoLabel(o['tipo']?.toString() ?? ''))),
            DataCell(Text(o['clienteFornecedorNome']?.toString() ?? '-')),
            DataCell(Text(o['documentoOrigemNumero']?.toString() ?? '-')),
            DataCell(Chip(
              label: Text(status, style: const TextStyle(color: Colors.white, fontSize: 11)),
              backgroundColor: _statusColor(status),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            )),
            DataCell(_buildActions(id, status)),
          ]);
        }).toList(),
      ),
    );
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'DEVOLUCAO_VENDA': return GridTexts.saleReturnType;
      case 'DEVOLUCAO_COMPRA': return GridTexts.purchaseReturnType;
      default: return tipo;
    }
  }

  Widget _buildActions(int? id, String status) {
    if (id == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _actionIcon(Icons.visibility, GridTexts.view, GridColors.info, () => _openForm(_devolucoes.firstWhere((o) => o['id'] == id))),
        if (status == 'RASCUNHO') ...[
          _actionIcon(Icons.edit, GridTexts.edit, GridColors.secondary, () => _openForm(_devolucoes.firstWhere((o) => o['id'] == id))),
          _actionIcon(Icons.check_circle, GridTexts.conclude, Colors.green, () => _confirmAction(
            GridTexts.concludeReturnTitle, GridTexts.concludeReturnQuestion, () => DevolucaoService.concluir(id))),
          _actionIcon(Icons.block, GridTexts.cancel, Colors.orange, () => _confirmAction(
            GridTexts.cancelReturnTitle, GridTexts.cancelReturnQuestion, () => DevolucaoService.delete(id))),
        ],
      ],
    );
  }

  Widget _actionIcon(IconData icon, String tooltip, Color color, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}
