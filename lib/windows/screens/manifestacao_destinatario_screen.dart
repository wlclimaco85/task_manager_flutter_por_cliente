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
              title: const Text(GridTexts.registerManifestation),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(GridTexts.accessKeyLabel(chave), style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: tipoSelecionado,
                      decoration: const InputDecoration(
                        labelText: GridTexts.manifestationType,
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'CIENCIA', child: Text(GridTexts.science)),
                        DropdownMenuItem(
                            value: 'CONFIRMACAO',
                            child: Text(GridTexts.confirm)),
                        DropdownMenuItem(
                            value: 'DESCONHECIMENTO',
                            child: Text(GridTexts.unknown)),
                        DropdownMenuItem(
                            value: 'NAO_REALIZADA',
                            child: Text(GridTexts.notPerformed)),
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
                            ? GridTexts.justificationRequired
                            : GridTexts.justificationOptional,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 3,
                    ),
                    if (requerJustificativa)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          GridTexts.notPerformedJustificationHint,
                          style: TextStyle(color: GridColors.error, fontSize: 12),
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
                              Text(GridTexts.notPerformedJustificationRequired),
                          backgroundColor: GridColors.error,
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
                    foregroundColor: GridColors.textPrimary,
                  ),
                  child: const Text(GridTexts.confirm),
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
      content: Text(response.success
          ? GridTexts.manifestationRegisteredSuccess
          : response.message ?? GridTexts.error),
      backgroundColor:
          response.success ? GridColors.success : GridColors.error,
    ));

    if (response.success) _carregarPendentes();
  }

  String _traduzirTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'CIENCIA':
        return GridTexts.science;
      case 'CONFIRMACAO':
        return GridTexts.confirm;
      case 'DESCONHECIMENTO':
        return GridTexts.unknown;
      case 'NAO_REALIZADA':
        return GridTexts.notPerformed;
      default:
        return tipo;
    }
  }

  Color _corTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'CIENCIA':
        return GridColors.info;
      case 'CONFIRMACAO':
        return GridColors.success;
      case 'DESCONHECIMENTO':
        return GridColors.statusUnknown;
      case 'NAO_REALIZADA':
        return GridColors.error;
      default:
        return GridColors.neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        title: const Text(GridTexts.manifestRecipientTitle),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GridColors.textPrimary,
          labelColor: GridColors.textPrimary,
          unselectedLabelColor: GridColors.textPrimaryMuted,
          tabs: const [
            Tab(text: GridTexts.pendingTab),
            Tab(text: GridTexts.history),
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
                const Icon(Icons.error_outline, size: 64, color: GridColors.error),
                const SizedBox(height: 16),
                Text(_mensagemErro!,
                    style: const TextStyle(color: GridColors.error, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: GridColors.textPrimary,
                  ),
                  onPressed: _carregarPendentes,
                  icon: const Icon(Icons.refresh),
                  label: const Text(GridTexts.retryAgain),
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
                    size: 64, color: GridColors.neutral),
                const SizedBox(height: 16),
                const Text(GridTexts.noPendingFound,
                    style: TextStyle(fontSize: 16, color: GridColors.neutral)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: GridColors.textPrimary,
                  ),
                  onPressed: _carregarPendentes,
                  icon: const Icon(Icons.refresh),
                  label: const Text(GridTexts.reload),
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
              Text(GridTexts.pendingCount(_pendentes.length),
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: GridColors.textPrimary,
                ),
                onPressed: _carregarPendentes,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(GridTexts.reload),
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
                  DataColumn(label: Text(GridTexts.accessKey)),
                  DataColumn(label: Text(GridTexts.issuer)),
                  DataColumn(label: Text(GridTexts.value)),
                  DataColumn(label: Text(GridTexts.issueDateShort)),
                  DataColumn(label: Text(GridTexts.actions)),
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
                          _botaoAcao(GridTexts.science, 'CIENCIA', item),
                          const SizedBox(width: 4),
                          _botaoAcao(GridTexts.confirm, 'CONFIRMACAO', item),
                          const SizedBox(width: 4),
                          _botaoAcao(GridTexts.unknown, 'DESCONHECIMENTO', item),
                          const SizedBox(width: 4),
                          _botaoAcao(GridTexts.notPerformed, 'NAO_REALIZADA', item),
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
    final cor = _corTipo(tipo);
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: GridColors.textPrimary,
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
                const Icon(Icons.error_outline, size: 64, color: GridColors.error),
                const SizedBox(height: 16),
                Text(_mensagemErro!,
                    style: const TextStyle(color: GridColors.error, fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: GridColors.textPrimary,
                  ),
                  onPressed: _carregarHistorico,
                  icon: const Icon(Icons.refresh),
                  label: const Text(GridTexts.retryAgain),
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
                const Icon(Icons.history, size: 64, color: GridColors.neutral),
                const SizedBox(height: 16),
                const Text(GridTexts.noManifestationDone,
                    style: TextStyle(fontSize: 16, color: GridColors.neutral)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: GridColors.textPrimary,
                  ),
                  onPressed: _carregarHistorico,
                  icon: const Icon(Icons.refresh),
                  label: const Text(GridTexts.reload),
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
              Text(GridTexts.manifestationCount(_historico.length),
                  style:
                      const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: GridColors.textPrimary,
                ),
                onPressed: _carregarHistorico,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text(GridTexts.reload),
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
                  DataColumn(label: Text(GridTexts.accessKey)),
                  DataColumn(label: Text(GridTexts.issuer)),
                  DataColumn(label: Text(GridTexts.type)),
                  DataColumn(label: Text(GridTexts.protocol)),
                  DataColumn(label: Text(GridTexts.date)),
                  DataColumn(label: Text(GridTexts.status)),
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
    final cor = realizado ? GridColors.success : GridColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor, width: 1),
      ),
      child: Text(
        realizado ? GridTexts.realized : status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cor,
        ),
      ),
    );
  }
}
