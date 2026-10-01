import 'package:flutter/material.dart';

import '../../../services/contingencia_rejeicao_service.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/grid_texts.dart';

class ContingenciaRejeicaoScreen extends StatefulWidget {
  const ContingenciaRejeicaoScreen({super.key});

  @override
  State<ContingenciaRejeicaoScreen> createState() => _ContingenciaRejeicaoScreenState();
}

class _ContingenciaRejeicaoScreenState extends State<ContingenciaRejeicaoScreen> {
  final ContingenciaRejeicaoService _service = ContingenciaRejeicaoService();

  List<Map<String, dynamic>> _fila = [];
  List<Map<String, dynamic>> _logs = [];
  bool _loadingFila = false;
  bool _loadingLogs = false;

  @override
  void initState() {
    super.initState();
    _carregarFila();
    _carregarLogs();
  }

  Future<void> _carregarFila() async {
    setState(() => _loadingFila = true);
    try {
      final data = await _service.listarFilaContingencia();
      if (mounted) setState(() => _fila = data);
    } catch (e) {
      if (mounted) _snack('Erro ao carregar fila: $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingFila = false);
    }
  }

  Future<void> _carregarLogs() async {
    setState(() => _loadingLogs = true);
    try {
      final data = await _service.listarLogsRejeicao();
      if (mounted) setState(() => _logs = data);
    } catch (e) {
      if (mounted) _snack('Erro ao carregar logs: $e', error: true);
    } finally {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  Future<void> _reenviar(int id) async {
    final ok = await _service.reenviarContingencia(id);
    if (mounted) {
      _snack(ok ? GridTexts.resendSuccess : GridTexts.resendFailure, error: !ok);
      if (ok) _carregarFila();
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: GridColors.primary,
          foregroundColor: GridColors.textPrimary,
          title: const Text('Contingência e Rejeições'),
          elevation: 0,
          bottom: const TabBar(
            labelColor: GridColors.textPrimary,
            unselectedLabelColor: GridColors.textPrimaryMuted,
            indicatorColor: GridColors.textPrimary,
            tabs: [
              Tab(text: 'Fila de Contingência'),
              Tab(text: 'Logs de Rejeição'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFilaTab(),
            _buildLogsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilaTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loadingFila ? null : _carregarFila,
                icon: _loadingFila
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: GridColors.textPrimary),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text(GridTexts.refresh),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.info,
                  foregroundColor: GridColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _fila.isEmpty && !_loadingFila
              ? const Center(
                  child: Text(GridTexts.noContingencyQueueItem,
                      style: TextStyle(color: Colors.grey, fontSize: 14)))
              : _buildFilaTable(),
        ),
      ],
    );
  }

  Widget _buildFilaTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(GridColors.secondaryLight),
          headingTextStyle: const TextStyle(color: GridColors.textPrimary, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Documento')),
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Motivo')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _fila.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['id']?.toString() ?? '')),
              DataCell(SizedBox(
                  width: 180,
                  child: Text(item['documento']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis))),
              DataCell(Text(item['data']?.toString().substring(0, 10) ?? '')),
              DataCell(SizedBox(
                  width: 180,
                  child: Text(item['documento']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis))),
              DataCell(SizedBox(
                  width: 250,
                  child: Text(item['erro']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis))),
              DataCell(_buildStatusBadge(item['status']?.toString() ?? '')),
              DataCell(
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () => _reenviar(item['id'] as int),
                    icon: const Icon(Icons.send, size: 14),
                    label: const Text(GridTexts.resend, style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.success,
                      foregroundColor: GridColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLogsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loadingLogs ? null : _carregarLogs,
                icon: _loadingLogs
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: GridColors.textPrimary),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text(GridTexts.refresh),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.info,
                  foregroundColor: GridColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _logs.isEmpty && !_loadingLogs
              ? const Center(
                  child: Text(GridTexts.noRejectionLogFound,
                      style: TextStyle(color: Colors.grey, fontSize: 14)))
              : _buildLogsTable(),
        ),
      ],
    );
  }

  Widget _buildLogsTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(GridColors.secondaryLight),
          headingTextStyle: const TextStyle(color: GridColors.textPrimary, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Documento')),
            DataColumn(label: Text('Erro')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Protocolo')),
          ],
          rows: _logs.map((item) {
            return DataRow(cells: [
              DataCell(Text(item['data']?.toString().substring(0, 10) ?? '')),
              DataCell(SizedBox(
                  width: 180,
                  child: Text(item['documento']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis))),
              DataCell(SizedBox(
                  width: 200,
                  child: Text(item['motivo']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis))),
              DataCell(SizedBox(
                  width: 250,
                  child: Text(item['erro']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis))),
              DataCell(Text(item['tipo']?.toString() ?? '')),
              DataCell(Text(item['protocolo']?.toString() ?? '—')),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color cor;
    switch (status.toUpperCase()) {
      case 'PENDENTE':
        cor = GridColors.warning;
        break;
      case 'REJEITADO':
        cor = GridColors.error;
        break;
      case 'REENVIADO':
      case 'CONCLUIDO':
        cor = GridColors.success;
        break;
      default:
        cor = GridColors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cor.withAlpha(120)),
      ),
      child: Text(status,
          style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}
