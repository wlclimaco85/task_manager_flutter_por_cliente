import 'package:flutter/material.dart';
import '../../services/manifestacao_caller.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

class ManifestacaoDestinatarioScreen extends StatefulWidget {
  const ManifestacaoDestinatarioScreen({super.key});

  @override
  State<ManifestacaoDestinatarioScreen> createState() =>
      _ManifestacaoDestinatarioScreenState();
}

class _ManifestacaoDestinatarioScreenState
    extends State<ManifestacaoDestinatarioScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _carregandoPendentes = false;
  List<dynamic> _pendentes = [];
  bool _carregandoHistorico = false;
  List<dynamic> _historico = [];
  String? _mensagemErro;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 0) _carregarPendentes();
      if (_tabController.index == 1) _carregarHistorico();
    });
    _carregarPendentes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarPendentes() async {
    setState(() {
      _carregandoPendentes = true;
      _mensagemErro = null;
    });
    final result = await ManifestacaoCaller.listarPendentes();
    if (!mounted) return;
    setState(() {
      _carregandoPendentes = false;
      if (result.success) {
        _pendentes = result.list ?? [];
      } else {
        _mensagemErro = result.message;
      }
    });
  }

  Future<void> _carregarHistorico() async {
    setState(() {
      _carregandoHistorico = true;
      _mensagemErro = null;
    });
    final result = await ManifestacaoCaller.listarHistorico();
    if (!mounted) return;
    setState(() {
      _carregandoHistorico = false;
      if (result.success) {
        _historico = result.list ?? [];
      } else {
        _mensagemErro = result.message;
      }
    });
  }

  Future<void> _abrirDialogManifestacao(Map<String, dynamic> item) async {
    final chave = item['chave'] ?? item['chaveAcesso'] ?? '';
    final tipoController = TextEditingController();
    final justificativaController = TextEditingController();
    String tipoSelecionado = 'CIENCIA';
    bool requerJustificativa = false;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Registrar Manifestação'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chave: $chave', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tipoSelecionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Manifestação',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'CIENCIA', child: Text('Ciência')),
                        DropdownMenuItem(
                            value: 'CONFIRMACAO',
                            child: Text('Confirmar')),
                        DropdownMenuItem(
                            value: 'DESCONHECIMENTO',
                            child: Text('Desconhecer')),
                        DropdownMenuItem(
                            value: 'NAO_REALIZADA',
                            child: Text('Não Realizada')),
                      ],
                      onChanged: (v) {
                        setDialogState(() {
                          tipoSelecionado = v!;
                          requerJustificativa = v == 'NAO_REALIZADA';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: justificativaController,
                      decoration: InputDecoration(
                        labelText: requerJustificativa
                            ? 'Justificativa *'
                            : 'Justificativa (opcional)',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 3,
                    ),
                    if (requerJustificativa)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Justificativa obrigatória para "Não Realizada"',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(GridTexts.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (requerJustificativa &&
                        justificativaController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Justificativa é obrigatória para Não Realizada'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, {
                      'tipo': tipoSelecionado,
                      'justificativa': justificativaController.text.trim(),
                    });
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
      },
    );

    if (result == null || !mounted) return;

    setState(() => _mensagemErro = null);
    final response = await ManifestacaoCaller.registrarManifestacao(
      chave: chave,
      tipo: result['tipo']!,
      justificativa: result['justificativa'],
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          response.success ? 'Manifestação registrada com sucesso' : response.message ?? 'Erro'),
      backgroundColor: response.success ? Colors.green : Colors.red,
    ));

    if (response.success) _carregarPendentes();
  }

  String _traduzirTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'CIENCIA':
        return 'Ciência';
      case 'CONFIRMACAO':
        return 'Confirmar';
      case 'DESCONHECIMENTO':
        return 'Desconhecer';
      case 'NAO_REALIZADA':
        return 'Não Realizada';
      default:
        return tipo;
    }
  }

  Color _corTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'CIENCIA':
        return Colors.blue;
      case 'CONFIRMACAO':
        return Colors.green;
      case 'DESCONHECIMENTO':
        return Colors.orange;
      case 'NAO_REALIZADA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Manifestação do Destinatário'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Pendências'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendenciasTab(),
          _buildHistoricoTab(),
        ],
      ),
    );
  }

  Widget _buildPendenciasTab() {
    if (_carregandoPendentes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensagemErro != null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_mensagemErro!,
                    style: const TextStyle(color: Colors.red, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _carregarPendentes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_pendentes.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Nenhuma pendência encontrada.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _carregarPendentes,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recarregar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_pendentes.length} pendência(s)',
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _carregarPendentes,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Recarregar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Chave de Acesso')),
                  DataColumn(label: Text('Emitente')),
                  DataColumn(label: Text('Valor')),
                  DataColumn(label: Text('Data Emissão')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: _pendentes.asMap().entries.map((entry) {
                  final item = entry.value is Map<String, dynamic>
                      ? entry.value as Map<String, dynamic>
                      : <String, dynamic>{};
                  final chave =
                      item['chave'] ?? item['chaveAcesso'] ?? '-';
                  final emitente =
                      item['emitente'] ?? item['nomeEmitente'] ?? '-';
                  final valor =
                      item['valor'] ?? item['valorTotal'] ?? '-';
                  final data =
                      item['dataEmissao'] ?? item['data'] ?? '-';
                  return DataRow(cells: [
                    DataCell(Text(chave.toString(),
                        style: const TextStyle(fontSize: 12))),
                    DataCell(Text(emitente.toString(),
                        style: const TextStyle(fontSize: 12))),
                    DataCell(Text(valor.toString(),
                        style: const TextStyle(fontSize: 12))),
                    DataCell(Text(data.toString(),
                        style: const TextStyle(fontSize: 12))),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _botaoAcao('Ciência', 'CIENCIA', item),
                          const SizedBox(width: 4),
                          _botaoAcao('Confirmar', 'CONFIRMACAO', item),
                          const SizedBox(width: 4),
                          _botaoAcao('Desconhecer', 'DESCONHECIMENTO', item),
                          const SizedBox(width: 4),
                          _botaoAcao('Não Realizada', 'NAO_REALIZADA', item),
                        ],
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoAcao(String label, String tipo, Map<String, dynamic> item) {
    Color cor;
    switch (tipo) {
      case 'CIENCIA':
        cor = Colors.blue;
        break;
      case 'CONFIRMACAO':
        cor = Colors.green;
        break;
      case 'DESCONHECIMENTO':
        cor = Colors.orange;
        break;
      case 'NAO_REALIZADA':
        cor = Colors.red;
        break;
      default:
        cor = Colors.grey;
    }
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          textStyle: const TextStyle(fontSize: 10),
        ),
        onPressed: () {
          _abrirDialogManifestacao(item);
        },
        child: Text(label),
      ),
    );
  }

  Widget _buildHistoricoTab() {
    if (_carregandoHistorico) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensagemErro != null && _historico.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(_mensagemErro!,
                    style: const TextStyle(color: Colors.red, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _carregarHistorico,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_historico.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.history, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Nenhuma manifestação realizada.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _carregarHistorico,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recarregar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_historico.length} manifestação(ões)',
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _carregarHistorico,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Recarregar'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Chave de Acesso')),
                  DataColumn(label: Text('Emitente')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Protocolo')),
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Status')),
                ],
                rows: _historico.asMap().entries.map((entry) {
                  final item = entry.value is Map<String, dynamic>
                      ? entry.value as Map<String, dynamic>
                      : <String, dynamic>{};
                  final chave =
                      item['chave'] ?? item['chaveAcesso'] ?? '-';
                  final emitente =
                      item['emitente'] ?? item['nomeEmitente'] ?? '-';
                  final tipo = item['tipo'] ?? item['tipoManifestacao'] ?? '-';
                  final protocolo = item['protocolo'] ?? '-';
                  final data = item['dataManifestacao'] ?? item['data'] ?? '-';
                  final status = item['status'] ?? 'REALIZADO';
                  return DataRow(cells: [
                    DataCell(Text(chave.toString(),
                        style: const TextStyle(fontSize: 12))),
                    DataCell(Text(emitente.toString(),
                        style: const TextStyle(fontSize: 12))),
                    DataCell(_buildTipoBadge(tipo.toString())),
                    DataCell(Text(protocolo.toString(),
                        style: const TextStyle(fontSize: 12))),
                    DataCell(Text(data.toString(),
                        style: const TextStyle(fontSize: 12))),
                    DataCell(_buildStatusBadge(status.toString())),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipoBadge(String tipo) {
    final label = _traduzirTipo(tipo);
    final cor = _corTipo(tipo);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final realizado = status.toUpperCase() == 'REALIZADO' ||
        status.toUpperCase() == 'CONCLUIDO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: realizado ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: realizado ? Colors.green : Colors.blue, width: 1),
      ),
      child: Text(
        realizado ? 'Realizado' : status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: realizado ? Colors.green.shade800 : Colors.blue.shade800,
        ),
      ),
    );
  }
}
