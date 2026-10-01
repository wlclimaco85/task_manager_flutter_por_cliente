import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/dre_caller.dart';
import '../../services/empresa_caller.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/utils.dart';

class DreScreen extends StatefulWidget {
  const DreScreen({super.key});

  @override
  State<DreScreen> createState() => _DreScreenState();
}

class _DreScreenState extends State<DreScreen> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  bool _loading = false;
  bool _loadingDropdowns = true;
  String? _error;

  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _centrosCusto = [];

  int? _empresaId;
  DateTime? _dataInicio;
  DateTime? _dataFim;
  int? _centroCustoId;
  bool _compararAnterior = false;

  Map<String, dynamic>? _dreData;

  @override
  void initState() {
    super.initState();
    _dataInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _dataFim = DateTime.now();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    setState(() => _loadingDropdowns = true);
    try {
      _empresas = await EmpresaCaller.loadEmpresas();
      _empresaId = pegarEmpresaLogada();
      if (_empresas.length == 1) _empresaId = _empresas.first['value'] as int?;

      final ccRes =
          await NetworkCaller().getRequest(ApiLinks.allCentrosCusto);
      if (ccRes.isSuccess && ccRes.body != null) {
        _centrosCusto = _extrairLista(ccRes.body!);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingDropdowns = false);
  }

  List<Map<String, dynamic>> _extrairLista(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is List) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    if (body.containsKey('content') && body['content'] is List) {
      return List<Map<String, dynamic>>.from(body['content']);
    }
    final values = body.values.whereType<List>();
    if (values.isNotEmpty) {
      return List<Map<String, dynamic>>.from(values.first);
    }
    return [];
  }

  Future<void> _gerarDre() async {
    if (_empresaId == null) {
      _showSnack('Selecione uma empresa');
      return;
    }
    if (_dataInicio == null || _dataFim == null) {
      _showSnack('Selecione o período');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _dreData = null;
    });

    try {
      final data = await DreCaller().obterDre(
        empresaId: _empresaId!,
        dataInicio: _dateFmt.format(_dataInicio!),
        dataFim: _dateFmt.format(_dataFim!),
        centroCustoId: _centroCustoId,
        compararPeriodoAnterior: _compararAnterior,
      );

      if (!mounted) return;

      if (data.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Nenhum dado encontrado';
        });
        return;
      }

      setState(() {
        _dreData = data['data'] is Map ? data['data'] : data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Erro ao gerar DRE: $e';
      });
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  double _toDouble(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DRE Gerencial')),
      body: _loadingDropdowns
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFiltros(),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                      onPressed: _gerarDre,
                      child: const Text('Tentar novamente')),
                ],
              ),
            ),
          if (_dreData != null) ...[
            const SizedBox(height: 16),
            _buildTabela(),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_empresas.isNotEmpty)
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int>(
                  value: _empresaId,
                  decoration: const InputDecoration(
                    labelText: 'Empresa',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: _empresas
                      .map((e) => DropdownMenuItem<int>(
                            value: e['value'] as int?,
                            child: Text(e['label']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _empresaId = v),
                ),
              ),
            _dateField(
              label: 'Data Início',
              selected: _dataInicio,
              onPick: (d) => setState(() => _dataInicio = d),
            ),
            _dateField(
              label: 'Data Fim',
              selected: _dataFim,
              onPick: (d) => setState(() => _dataFim = d),
            ),
            if (_centrosCusto.isNotEmpty)
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int>(
                  value: _centroCustoId,
                  decoration: const InputDecoration(
                    labelText: 'Centro de Custo',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  items: [
                    DropdownMenuItem<int>(
                      value: null,
                      child: Text('Todos',
                          style: TextStyle(color: Colors.grey[500])),
                    ),
                    ..._centrosCusto.map((e) => DropdownMenuItem<int>(
                          value: e['id'] as int?,
                          child: Text(e['nome']?.toString() ?? ''),
                        )),
                  ],
                  onChanged: (v) => setState(() => _centroCustoId = v),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Comparar período anterior'),
                Checkbox(
                  value: _compararAnterior,
                  onChanged: (v) =>
                      setState(() => _compararAnterior = v ?? false),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _loading ? null : _gerarDre,
              icon: const Icon(Icons.calculate),
              label: const Text('Gerar DRE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? selected,
    required ValueChanged<DateTime?> onPick,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        child: Text(
          selected != null
              ? DateFormat('dd/MM/yyyy').format(selected)
              : 'Selecionar',
        ),
      ),
    );
  }

  Widget _buildTabela() {
    final receitas =
        _listFromJson(_dreData!['receitas'] ?? _dreData!['receitas']);
    final custos = _listFromJson(_dreData!['custos']);
    final despesas = _listFromJson(_dreData!['despesas']);
    final totalReceitas = _toDouble(
        _dreData!['totalReceitas'] ?? _dreData!['totalReceitas']);
    final totalCustos = _toDouble(_dreData!['totalCustos']);
    final totalDespesas = _toDouble(_dreData!['totalDespesas']);
    final resultadoLiquido =
        _toDouble(_dreData!['resultadoLiquido'] ?? _dreData!['resultado']);
    final resultadoAnterior =
        _toDouble(_dreData!['resultadoLiquidoAnterior']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('DEMONSTRAÇÃO DO RESULTADO DO EXERCÍCIO',
                style: Theme.of(context).textTheme.titleMedium),
            const Divider(thickness: 2),
            _secaoHeader(),
            const Divider(thickness: 2),
            _secaoLinhas('RECEITAS', receitas, totalReceitas,
                isFirst: true),
            const Divider(),
            _secaoLinhas('CUSTOS', custos, totalCustos),
            const Divider(),
            _secaoLinhas('DESPESAS', despesas, totalDespesas),
            const Divider(thickness: 2),
            _resultadoLinha(resultadoLiquido, resultadoAnterior),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _listFromJson(dynamic raw) {
    if (raw is List) {
      return raw.map<Map<String, dynamic>>((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
    }
    return [];
  }

  Widget _secaoHeader() {
    return Row(
      children: [
        const Expanded(flex: 4, child: Text('Descrição',
            style: TextStyle(fontWeight: FontWeight.bold))),
        const Expanded(
            flex: 3,
            child: Text('Valor',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold))),
        if (_compararAnterior)
          const Expanded(
              flex: 3,
              child: Text('Período Anterior',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold))),
        if (_compararAnterior)
          const Expanded(
              flex: 2,
              child: Text('%',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.bold))),
      ],
    );
  }

  Widget _secaoLinhas(String titulo, List<Map<String, dynamic>> itens,
      double total,
      {bool isFirst = false}) {
    final totalAnterior = itens.fold<double>(
        0, (sum, item) => sum + _toDouble(item['valorAnterior']));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(top: isFirst ? 0 : 8, bottom: 4),
          child: Text(titulo,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        ...itens.map((item) => _linhaItem(item)),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const Expanded(
                  flex: 4,
                  child: Text('Total',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontStyle: FontStyle.italic))),
              Expanded(
                  flex: 3,
                  child: Text(_currency.format(total),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
              if (_compararAnterior)
                Expanded(
                    flex: 3,
                    child: Text(
                        _currency.format(totalAnterior),
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontWeight: FontWeight.bold))),
              if (_compararAnterior) const Expanded(flex: 2, child: SizedBox()),
            ],
          ),
        ),
      ],
    );
  }

  double itemValor(Map<String, dynamic> item, String key) {
    return _toDouble(item[key]);
  }

  Widget _linhaItem(Map<String, dynamic> item) {
    final nome = item['nome']?.toString() ?? item['descricao']?.toString() ?? '';
    final valor = _toDouble(item['valor']);
    final valorAnterior = _toDouble(item['valorAnterior']);
    final percentual = _toDouble(item['percentual']);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(nome)),
          Expanded(
              flex: 3,
              child: Text(_currency.format(valor),
                  textAlign: TextAlign.right)),
          if (_compararAnterior)
            Expanded(
                flex: 3,
                child: Text(_currency.format(valorAnterior),
                    textAlign: TextAlign.right)),
          if (_compararAnterior)
            Expanded(
                flex: 2,
                child: Text(percentual > 0 ? '${percentual.toStringAsFixed(1)}%' : '',
                    textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _resultadoLinha(double resultado, double resultadoAnterior) {
    final cor = resultado >= 0 ? Colors.green : Colors.red;
    return Row(
      children: [
        const Expanded(
            flex: 4,
            child: Text('RESULTADO LÍQUIDO',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16))),
        Expanded(
            flex: 3,
            child: Text(_currency.format(resultado),
                textAlign: TextAlign.right,
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: cor, fontSize: 16))),
        if (_compararAnterior)
          Expanded(
              flex: 3,
              child: Text(_currency.format(resultadoAnterior),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: resultadoAnterior >= 0 ? Colors.green : Colors.red,
                      fontSize: 16))),
        if (_compararAnterior) const Expanded(flex: 2, child: SizedBox()),
      ],
    );
  }
}
