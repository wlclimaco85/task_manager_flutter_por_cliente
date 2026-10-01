import 'package:flutter/material.dart';
import '../../services/consulta_dfe_caller.dart';
import '../../utils/grid_colors.dart';

class ConsultaDfeScreen extends StatefulWidget {
  const ConsultaDfeScreen({super.key});

  @override
  State<ConsultaDfeScreen> createState() => _ConsultaDfeScreenState();
}

class _ConsultaDfeScreenState extends State<ConsultaDfeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _cnpjController = TextEditingController();
  final _chaveController = TextEditingController();
  final _dataInicioController = TextEditingController();
  final _dataFimController = TextEditingController();
  final _empresaController = TextEditingController();

  bool _consultando = false;
  List<dynamic> _resultados = [];
  String? _mensagem;
  bool? _sucesso;

  bool _carregandoImportacoes = false;
  List<dynamic> _importacoes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) _carregarImportacoes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cnpjController.dispose();
    _chaveController.dispose();
    _dataInicioController.dispose();
    _dataFimController.dispose();
    _empresaController.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    setState(() {
      _consultando = true;
      _mensagem = null;
      _sucesso = null;
      _resultados = [];
    });

    final result = await ConsultaDfeCaller.consultar(
      cnpjEmitente: _cnpjController.text,
      chave: _chaveController.text,
      dataInicio: _dataInicioController.text,
      dataFim: _dataFimController.text,
    );

    if (!mounted) return;

    setState(() {
      _consultando = false;
      _sucesso = result.success;
      _mensagem = result.message;
      if (result.success && result.data != null) {
        _resultados = result.data!['data'] as List<dynamic>? ??
            result.data!['resultados'] as List<dynamic>? ??
            result.data!['notas'] as List<dynamic>? ??
            [];
      }
    });
  }

  Future<void> _baixar(String nsu, int index) async {
    final result = await ConsultaDfeCaller.baixar(nsu);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.success ? 'Download realizado com sucesso' : result.message ?? 'Erro ao baixar'),
      backgroundColor: result.success ? Colors.green : Colors.red,
    ));

    if (result.success) {
      setState(() {
        if (index < _resultados.length) {
          final item = _resultados[index];
          if (item is Map<String, dynamic>) {
            item['baixado'] = true;
          }
        }
      });
    }
  }

  Future<void> _carregarImportacoes() async {
    setState(() {
      _carregandoImportacoes = true;
      _importacoes = [];
    });

    final result = await ConsultaDfeCaller.listarImportacoes();
    if (!mounted) return;

    setState(() {
      _carregandoImportacoes = false;
      if (result.success) {
        _importacoes = result.list ?? [];
      } else {
        _mensagem = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: GridColors.secondary,
        foregroundColor: Colors.white,
        title: const Text('Consulta e Download DF-e'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Consultar DF-e'),
            Tab(text: 'Importações Realizadas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConsultaTab(),
          _buildImportacoesTab(),
        ],
      ),
    );
  }

  Widget _buildConsultaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFiltrosCard(),
          const SizedBox(height: 24),
          if (_consultando)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_sucesso != null && !_sucesso! && _mensagem != null)
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
          if (_resultados.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTabelaResultados(),
          ],
          if (!_consultando && _resultados.isEmpty && _sucesso == true)
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Nenhum documento encontrado para os filtros informados.'),
                  ],
                ),
              ),
            ),
        ],
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
            const Text('Filtros de Consulta', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _cnpjController,
                    decoration: const InputDecoration(
                      labelText: 'CNPJ Emitente',
                      hintText: 'Apenas números',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _chaveController,
                    decoration: const InputDecoration(
                      labelText: 'Chave de Acesso',
                      hintText: '44 dígitos',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _dataInicioController,
                    decoration: const InputDecoration(
                      labelText: 'Data Início',
                      hintText: 'dd/MM/yyyy',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _dataFimController,
                    decoration: const InputDecoration(
                      labelText: 'Data Fim',
                      hintText: 'dd/MM/yyyy',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                SizedBox(
                  width: 250,
                  child: TextField(
                    controller: _empresaController,
                    decoration: const InputDecoration(
                      labelText: 'Empresa',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: _consultando ? null : _consultar,
              icon: _consultando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
              label: Text(_consultando ? 'Consultando...' : 'Consultar SEFAZ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaResultados() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_resultados.length} documento(s) encontrado(s)',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Chave de Acesso')),
                  DataColumn(label: Text('Emitente')),
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Valor')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: _resultados.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value is Map<String, dynamic> ? entry.value as Map<String, dynamic> : {};
                  final chave = item['chave'] ?? item['chaveAcesso'] ?? '-';
                  final emitente = item['emitente'] ?? item['nomeEmitente'] ?? '-';
                  final data = item['data'] ?? item['dataEmissao'] ?? '-';
                  final valor = item['valor'] ?? item['valorTotal'] ?? '-';
                  final baixado = item['baixado'] == true || item['importado'] == true;
                  final nsu = (item['nsu'] ?? item['id'] ?? '').toString();
                  return DataRow(cells: [
                    DataCell(Text(chave.toString(), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(emitente.toString(), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(data.toString(), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(valor.toString(), style: const TextStyle(fontSize: 12))),
                    DataCell(_buildStatusBadge(baixado)),
                    DataCell(
                      baixado
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () => _baixar(nsu, i),
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Baixar'),
                            ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool baixado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: baixado ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baixado ? Colors.green : Colors.blue, width: 1),
      ),
      child: Text(
        baixado ? 'Baixado' : 'Disponível',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: baixado ? Colors.green.shade800 : Colors.blue.shade800,
        ),
      ),
    );
  }

  Widget _buildImportacoesTab() {
    if (_carregandoImportacoes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_importacoes.isEmpty) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_download_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Nenhuma importação realizada ainda.',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _carregarImportacoes,
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
              Text('${_importacoes.length} importação(ões)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _carregarImportacoes,
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
                  DataColumn(label: Text('NSU')),
                  DataColumn(label: Text('Chave')),
                  DataColumn(label: Text('Emitente')),
                  DataColumn(label: Text('Data Importação')),
                  DataColumn(label: Text('Status')),
                ],
                rows: _importacoes.map((item) {
                  final map = item is Map<String, dynamic> ? item : <String, dynamic>{};
                  return DataRow(cells: [
                    DataCell(Text((map['nsu'] ?? '-').toString(), style: const TextStyle(fontSize: 12))),
                    DataCell(Text((map['chave'] ?? map['chaveAcesso'] ?? '-').toString(), style: const TextStyle(fontSize: 12))),
                    DataCell(Text((map['emitente'] ?? map['nomeEmitente'] ?? '-').toString(), style: const TextStyle(fontSize: 12))),
                    DataCell(Text((map['dataImportacao'] ?? map['data'] ?? '-').toString(), style: const TextStyle(fontSize: 12))),
                    DataCell(_buildStatusBadge(map['status'] == 'CONCLUIDO' || map['status'] == 'BAIXADO')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
