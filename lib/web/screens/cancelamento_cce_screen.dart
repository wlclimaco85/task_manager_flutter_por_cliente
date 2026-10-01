import 'package:flutter/material.dart';
import '../../services/cancelamento_cce_caller.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

class CancelamentoCceScreen extends StatefulWidget {
  const CancelamentoCceScreen({super.key});

  @override
  State<CancelamentoCceScreen> createState() => _CancelamentoCceScreenState();
}

class _CancelamentoCceScreenState extends State<CancelamentoCceScreen> {
  final _nfeIdController = TextEditingController();
  final _justificativaCancelamento = TextEditingController();
  final _correcaoCce = TextEditingController();

  bool _processando = false;
  bool _carregandoHistorico = false;
  List<dynamic> _historico = [];
  String? _mensagem;

  @override
  void dispose() {
    _nfeIdController.dispose();
    _justificativaCancelamento.dispose();
    _correcaoCce.dispose();
    super.dispose();
  }

  Future<void> _cancelar() async {
    final nfeId = _nfeIdController.text.trim();
    if (nfeId.isEmpty) {
      _snack('Informe o ID da NF-e', error: true);
      return;
    }

    final justificativa = await _showInputDialog(
      titulo: 'Cancelar NF-e',
      mensagem: 'Informe a justificativa para o cancelamento:',
      controller: _justificativaCancelamento,
    );
    if (justificativa == null || !mounted) return;

    setState(() {
      _processando = true;
      _mensagem = null;
    });

    final result = await CancelamentoCceCaller.cancelar(nfeId, justificativa: justificativa);
    if (!mounted) return;

    setState(() => _processando = false);
    _snack(result.success ? 'Cancelamento realizado com sucesso' : result.message ?? 'Erro ao cancelar',
        error: !result.success);
    if (result.success) _carregarHistorico(nfeId);
  }

  Future<void> _enviarCce() async {
    final nfeId = _nfeIdController.text.trim();
    if (nfeId.isEmpty) {
      _snack('Informe o ID da NF-e', error: true);
      return;
    }

    final correcao = await _showInputDialog(
      titulo: 'Enviar CC-e',
      mensagem: 'Descreva a correção a ser enviada:',
      controller: _correcaoCce,
      multiline: true,
    );
    if (correcao == null || correcao.trim().isEmpty || !mounted) return;

    setState(() {
      _processando = true;
      _mensagem = null;
    });

    final result = await CancelamentoCceCaller.enviarCce(nfeId, correcao: correcao);
    if (!mounted) return;

    setState(() => _processando = false);
    _snack(result.success ? 'CC-e enviada com sucesso' : result.message ?? 'Erro ao enviar CC-e',
        error: !result.success);
    if (result.success) _carregarHistorico(nfeId);
  }

  Future<void> _carregarHistorico(String? nfeId) async {
    final id = nfeId ?? _nfeIdController.text.trim();
    if (id.isEmpty) return;

    setState(() {
      _carregandoHistorico = true;
      _mensagem = null;
    });

    final result = await CancelamentoCceCaller.historico(id);
    if (!mounted) return;

    setState(() {
      _carregandoHistorico = false;
      if (result.success) {
        _historico = result.list ?? [];
      } else {
        _mensagem = result.message;
      }
    });
  }

  Future<String?> _showInputDialog({
    required String titulo,
    required String mensagem,
    required TextEditingController controller,
    bool multiline = false,
  }) async {
    controller.clear();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(titulo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mensagem, style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: multiline ? 4 : 1,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(GridTexts.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Este campo é obrigatório'), backgroundColor: Colors.red),
                  );
                  return;
                }
                Navigator.pop(ctx, text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Cancelamento e CC-e'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFiltrosCard(),
            const SizedBox(height: 24),
            if (_processando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_mensagem != null && _historico.isEmpty)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_mensagem!, style: TextStyle(color: Colors.red.shade900))),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildHistoricoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltrosCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Selecionar NF-e', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _nfeIdController,
                decoration: const InputDecoration(
                  labelText: 'ID da NF-e',
                  hintText: 'Informe o ID numérico da NF-e',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _processando ? null : _cancelar,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar NF-e'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _processando ? null : _enviarCce,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Enviar CC-e'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _carregandoHistorico
                      ? null
                      : () => _carregarHistorico(_nfeIdController.text.trim()),
                  icon: _carregandoHistorico
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.history),
                  label: Text(_carregandoHistorico ? 'Carregando...' : 'Carregar Histórico'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoCard() {
    if (_carregandoHistorico) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_historico.isEmpty) {
      return Card(
        color: Colors.blue.shade50,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Nenhum histórico encontrado. Informe o ID da NF-e e clique em "Carregar Histórico".'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_historico.length} registro(s) no histórico',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Data/Hora')),
                  DataColumn(label: Text('Protocolo')),
                  DataColumn(label: Text('Descrição')),
                  DataColumn(label: Text('Status')),
                ],
                rows: _historico.asMap().entries.map((entry) {
                  final item = entry.value is Map<String, dynamic>
                      ? entry.value as Map<String, dynamic>
                      : <String, dynamic>{};
                  final tipo = item['tipo'] ?? item['tipoEvento'] ?? '-';
                  final data = item['data'] ?? item['dataHora'] ?? item['dataEvento'] ?? '-';
                  final protocolo = item['protocolo'] ?? item['numeroProtocolo'] ?? '-';
                  final descricao = item['descricao'] ?? item['justificativa'] ?? item['correcao'] ?? '-';
                  final status = item['status'] ?? '-';
                  return DataRow(cells: [
                    DataCell(_buildTipoBadge(tipo.toString())),
                    DataCell(Text(data.toString(), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(protocolo.toString(), style: const TextStyle(fontSize: 12))),
                    DataCell(SizedBox(
                      width: 250,
                      child: Text(descricao.toString(), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                    )),
                    DataCell(_buildStatusBadge(status.toString())),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoBadge(String tipo) {
    final isCancelamento = tipo.toUpperCase().contains('CANCEL') || tipo == 'Cancelamento';
    final isCce = tipo.toUpperCase().contains('CCE') || tipo.toUpperCase().contains('CARTA') || tipo == 'CC-e';
    final cor = isCancelamento ? Colors.red : (isCce ? Colors.blue : Colors.grey);
    final label = isCancelamento ? 'Cancelamento' : (isCce ? 'CC-e' : tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final sucesso = status.toUpperCase() == 'SUCESSO' || status.toUpperCase() == 'CONCLUIDO' || status.toUpperCase() == 'APROVADO';
    final cor = sucesso ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor, width: 1),
      ),
      child: Text(
        sucesso ? 'Sucesso' : status,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cor),
      ),
    );
  }
}
