import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/automacao_financeira_caller.dart';
import '../../utils/grid_texts.dart';

class WebIntegracoesFinanceirasScreen extends StatefulWidget {
  const WebIntegracoesFinanceirasScreen({super.key});

  @override
  State<WebIntegracoesFinanceirasScreen> createState() =>
      _WebIntegracoesFinanceirasScreenState();
}

class _WebIntegracoesFinanceirasScreenState
    extends State<WebIntegracoesFinanceirasScreen> {
  List<dynamic> _automacoes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final data = await AutomacaoFinanceiraCaller.listar();
    if (mounted) setState(() { _automacoes = data; _loading = false; });
  }

  Future<void> _executar(dynamic item) async {
    final id = item['id']?.toString() ?? '';
    final result = await AutomacaoFinanceiraCaller.executar(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['success'] == true
          ? 'Execucao iniciada com sucesso'
          : result['message'] ?? 'Erro ao executar'),
      backgroundColor: result['success'] == true ? Colors.green : Colors.red,
    ));
    _carregar();
  }

  Future<void> _toggleAtivo(dynamic item, bool value) async {
    final id = item['id']?.toString() ?? '';
    item['ativo'] = value;
    await AutomacaoFinanceiraCaller.salvar(Map<String, dynamic>.from(item), id: id);
    _carregar();
  }

  void _abrirDialog({dynamic item}) {
    final isEdit = item != null;
    final nomeCtrl = TextEditingController(text: isEdit ? item['nome'] ?? '' : '');
    final configCtrl = TextEditingController(
        text: isEdit && item['config'] != null
            ? item['config'] is String
                ? item['config']
                : jsonEncode(item['config'])
            : '{}');
    String tipo = isEdit ? item['tipo'] ?? 'Webhook' : 'Webhook';
    String entidade = isEdit ? item['entidade'] ?? 'Conta Pagar' : 'Conta Pagar';
    String acao = isEdit ? item['acao'] ?? 'Criar' : 'Criar';
    bool ativo = isEdit ? item['ativo'] ?? true : true;

    final tipos = ['Webhook', 'Job Agendado', 'Sincronizacao'];
    final entidades = ['Conta Pagar', 'Conta Receber', 'Extrato', 'Conciliacao'];
    final acoes = ['Criar', 'Baixar', 'Conciliar', 'Importar'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Editar Automacao' : 'Nova Automacao'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeCtrl,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                  DropdownButtonFormField<String>(
                    value: tipo,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => tipo = v!),
                  ),
                  DropdownButtonFormField<String>(
                    value: entidade,
                    decoration: const InputDecoration(labelText: 'Entidade'),
                    items: entidades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setDialogState(() => entidade = v!),
                  ),
                  DropdownButtonFormField<String>(
                    value: acao,
                    decoration: const InputDecoration(labelText: 'Acao'),
                    items: acoes.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                    onChanged: (v) => setDialogState(() => acao = v!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: configCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Config JSON',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SwitchListTile(
                    title: const Text('Ativa'),
                    value: ativo,
                    onChanged: (v) => setDialogState(() => ativo = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(GridTexts.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'nome': nomeCtrl.text,
                  'tipo': tipo,
                  'entidade': entidade,
                  'acao': acao,
                  'config': configCtrl.text,
                  'ativo': ativo,
                };
                final result = await AutomacaoFinanceiraCaller.salvar(
                  data,
                  id: isEdit ? item['id']?.toString() : null,
                );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (result['success'] == true) {
                  _carregar();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message'] ?? 'Erro ao salvar'),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: Text(isEdit ? 'Salvar' : 'Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirLogs(dynamic item) {
    final id = item['id']?.toString() ?? '';
    final nome = item['nome'] ?? 'Logs';
    showDialog(
      context: context,
      builder: (ctx) => WebLogsAutomacaoDialog(automacaoId: id, automacaoNome: nome),
    );
  }

  Color _statusColor(dynamic item) {
    final ultimaExecucao = item['ultimaExecucao'];
    if (ultimaExecucao == null) return Colors.grey;
    if (ultimaExecucao is Map) {
      final status = ultimaExecucao['status'] ?? '';
      if (status == 'SUCESSO' || status == 'SUCCESS') return Colors.green;
      if (status == 'ERRO' || status == 'ERROR' || status == 'FALHA') return Colors.red;
    }
    return Colors.grey;
  }

  String _formatData(dynamic data) {
    if (data == null) return '-';
    if (data is String) {
      try {
        final dt = DateTime.parse(data);
        return DateFormat('dd/MM/yyyy HH:mm').format(dt);
      } catch (_) {
        return data;
      }
    }
    if (data is Map) {
      final status = data['status'] ?? '';
      final dataHora = data['dataExecucao'] ?? data['data'] ?? '';
      return '$status - ${_formatData(dataHora)}';
    }
    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Integracoes Financeiras')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Nova Automacao'),
                        onPressed: () => _abrirDialog(),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _carregar,
                        tooltip: 'Recarregar',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _automacoes.isEmpty
                      ? const Center(child: Text('Nenhuma automacao cadastrada'))
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Nome')),
                                DataColumn(label: Text('Tipo')),
                                DataColumn(label: Text('Entidade/Acao')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Ultima Execucao')),
                                DataColumn(label: Text('Acoes')),
                              ],
                              rows: _automacoes.map((item) {
                                final ativo = item['ativo'] ?? true;
                                return DataRow(cells: [
                                  DataCell(Text(item['nome'] ?? '-')),
                                  DataCell(Text(item['tipo'] ?? '-')),
                                  DataCell(Text(
                                      '${item['entidade'] ?? '-'} / ${item['acao'] ?? '-'}')),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _statusColor(item),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(ativo ? 'Ativa' : 'Inativa'),
                                    ],
                                  )),
                                  DataCell(Text(_formatData(item['ultimaExecucao']))),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: ativo,
                                        onChanged: (v) => _toggleAtivo(item, v),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        tooltip: 'Editar',
                                        onPressed: () => _abrirDialog(item: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.play_arrow, size: 18),
                                        tooltip: 'Executar Agora',
                                        onPressed: () => _executar(item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.history, size: 18),
                                        tooltip: 'Logs',
                                        onPressed: () => _abrirLogs(item),
                                      ),
                                    ],
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class WebLogsAutomacaoDialog extends StatefulWidget {
  final String automacaoId;
  final String automacaoNome;
  const WebLogsAutomacaoDialog({
    super.key,
    required this.automacaoId,
    required this.automacaoNome,
  });

  @override
  State<WebLogsAutomacaoDialog> createState() => _WebLogsAutomacaoDialogState();
}

class _WebLogsAutomacaoDialogState extends State<WebLogsAutomacaoDialog> {
  List<dynamic> _logs = [];
  bool _loading = true;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final data = await AutomacaoFinanceiraCaller.logs(widget.automacaoId);
    if (mounted) {
      setState(() {
        _logs = data;
        _loading = false;
      });
    }
  }

  List<dynamic> get _logsFiltrados {
    var result = _logs;
    if (_dataInicio != null) {
      final inicio = _dataInicio!.millisecondsSinceEpoch;
      result = result.where((l) {
        final dt = l['dataHora'] ?? l['dataExecucao'] ?? '';
        try {
          return DateTime.parse(dt).millisecondsSinceEpoch >= inicio;
        } catch (_) {
          return true;
        }
      }).toList();
    }
    if (_dataFim != null) {
      final fim = _dataFim!.millisecondsSinceEpoch;
      result = result.where((l) {
        final dt = l['dataHora'] ?? l['dataExecucao'] ?? '';
        try {
          return DateTime.parse(dt).millisecondsSinceEpoch <= fim;
        } catch (_) {
          return true;
        }
      }).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 900,
        height: 600,
        child: Column(
          children: [
            AppBar(
              title: Text('Logs - ${widget.automacaoNome}'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _carregar,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dataInicio ?? DateTime.now().subtract(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _dataInicio = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _dataInicio != null
                            ? DateFormat('dd/MM/yyyy').format(_dataInicio!)
                            : 'Data Inicio',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dataFim ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) setState(() => _dataFim = date);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _dataFim != null
                            ? DateFormat('dd/MM/yyyy').format(_dataFim!)
                            : 'Data Fim',
                      ),
                    ),
                  ),
                  if (_dataInicio != null || _dataFim != null)
                    TextButton(
                      onPressed: () => setState(() { _dataInicio = null; _dataFim = null; }),
                      child: const Text('Limpar Filtros'),
                    ),
                  const Spacer(),
                  Text('${_logsFiltrados.length} registro(s)'),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _logsFiltrados.isEmpty
                      ? const Center(child: Text('Nenhum log encontrado'))
                      : SingleChildScrollView(
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Data/Hora')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Request')),
                              DataColumn(label: Text('Response')),
                              DataColumn(label: Text('Erro')),
                              DataColumn(label: Text('Duracao')),
                            ],
                            rows: _logsFiltrados.map((log) {
                              final status = log['status'] ?? '';
                              final isSuccess = status == 'SUCESSO' || status == 'SUCCESS';
                              final isError = status == 'ERRO' || status == 'ERROR' || status == 'FALHA';
                              return DataRow(cells: [
                                DataCell(Text(_formatLogDate(log['dataHora'] ?? log['dataExecucao'] ?? ''))),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSuccess
                                          ? Icons.check_circle
                                          : isError
                                              ? Icons.error
                                              : Icons.schedule,
                                      size: 18,
                                      color: isSuccess
                                          ? Colors.green
                                          : isError
                                              ? Colors.red
                                              : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(status),
                                  ],
                                )),
                                DataCell(
                                  _collapsibleText(log['request']?.toString() ?? '-'),
                                ),
                                DataCell(
                                  _collapsibleText(log['response']?.toString() ?? '-'),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      log['erro']?.toString() ?? log['error']?.toString() ?? '-',
                                      style: TextStyle(
                                        color: isError ? Colors.red : null,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                ),
                                DataCell(Text(_formatDuration(log['duracao'] ?? log['duration'] ?? ''))),
                              ]);
                            }).toList(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _collapsibleText(String text) {
    if (text == '-' || text.isEmpty) return const Text('-');
    return SizedBox(
      width: 120,
      child: GestureDetector(
        onTap: () => showDialog(
          context: context,
          builder: (_) => Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              width: 500,
              child: SingleChildScrollView(
                child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ),
            ),
          ),
        ),
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  String _formatLogDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatDuration(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return '-';
    if (raw is num) return '${raw}ms';
    return raw.toString();
  }
}
