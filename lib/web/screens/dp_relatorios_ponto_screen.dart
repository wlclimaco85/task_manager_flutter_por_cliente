import 'package:flutter/material.dart';

import '../../services/dp_ponto_service.dart';
import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/dropdown_helpers.dart';
import '../../utils/file_saver_compat.dart';
import '../../utils/grid_colors.dart';

/// Suite de relatorios de ponto do DP: filtros empresa(sessao)/setor/funcionario/periodo e exportacao PDF/CSV.
/// Mesma tela em Web, Windows e Mobile; em largura estreita as linhas viram cartoes.
class DpRelatoriosPontoScreen extends StatefulWidget {
  const DpRelatoriosPontoScreen({super.key, this.service, this.carregarSetores, this.carregarFuncionarios});

  /// Injetaveis para teste.
  final DpPontoService? service;
  final Future<List<Map<String, dynamic>>> Function()? carregarSetores;
  final Future<List<Map<String, dynamic>>> Function()? carregarFuncionarios;

  @override
  State<DpRelatoriosPontoScreen> createState() => _DpRelatoriosPontoScreenState();
}

class _DpRelatoriosPontoScreenState extends State<DpRelatoriosPontoScreen> {
  late final DpPontoService _service = widget.service ?? DpPontoService();

  String _tipo = 'resumo-mensal';
  String? _setorId;
  String? _funcionarioId;
  late DateTime _inicio;
  late DateTime _fim;
  List<Map<String, dynamic>> _setores = [];
  List<Map<String, dynamic>> _funcionarios = [];
  Map<String, dynamic>? _resultado;
  bool _carregando = false;
  bool _baixando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _inicio = DateTime(hoje.year, hoje.month, 1);
    _fim = hoje;
    _carregarFiltros();
  }

  Future<void> _carregarFiltros() async {
    try {
      final setores = await (widget.carregarSetores ?? () => DropdownHelpers.load(ApiLinks.allDepartamentos))();
      final funcs = await (widget.carregarFuncionarios ?? () => DropdownHelpers.load(ApiLinks.allFuncionarios))();
      if (mounted) setState(() { _setores = setores; _funcionarios = funcs; });
    } catch (e, st) {
      AppLogger.i.warn('DP: não carregou filtros de setor/funcionário: $e');
    }
  }

  static String _dataBr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _escolherData(bool inicio) async {
    final atual = inicio ? _inicio : _fim;
    final d = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (d != null) setState(() => inicio ? _inicio = d : _fim = d);
  }

  void _aviso(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: erro ? GridColors.error : GridColors.primary));
  }

  Future<void> _gerar() async {
    if (_fim.isBefore(_inicio)) {
      _aviso('A data final não pode ser anterior à inicial.', erro: true);
      return;
    }
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final r = await _service.relatorio(_tipo,
          setorId: _setorId, funcionarioId: _funcionarioId, inicio: _inicio, fim: _fim);
      if (mounted) setState(() => _resultado = r);
    } on DpPontoException catch (e) {
      if (mounted) setState(() { _resultado = null; _erro = e.message; });
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao gerar relatório $_tipo: $e', st);
      if (mounted) setState(() { _resultado = null; _erro = 'Não foi possível gerar o relatório.'; });
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _baixar(String formato) async {
    if (_fim.isBefore(_inicio)) {
      _aviso('A data final não pode ser anterior à inicial.', erro: true);
      return;
    }
    setState(() => _baixando = true);
    try {
      final bytes = await _service.baixar(_tipo, formato,
          setorId: _setorId, funcionarioId: _funcionarioId, inicio: _inicio, fim: _fim);
      await FileSaver.instance.saveFile(
        name: 'dp-$_tipo',
        bytes: bytes,
        fileExtension: formato,
        mimeType: formato == 'pdf' ? MimeType.pdf : MimeType.csv,
      );
      _aviso('Arquivo ${formato.toUpperCase()} gerado.');
    } on DpPontoException catch (e) {
      _aviso(e.message, erro: true);
    } catch (e, st) {
      AppLogger.i.error('DP: erro ao salvar relatório $_tipo/$formato: $e', st);
      _aviso('Não foi possível salvar o arquivo.', erro: true);
    } finally {
      if (mounted) setState(() => _baixando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: GridColors.pageBackground,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _filtros(),
          const SizedBox(height: 16),
          if (_carregando) const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
          if (_erro != null)
            Card(
              color: GridColors.errorLight,
              child: Padding(padding: const EdgeInsets.all(16), child: Text(_erro!, style: const TextStyle(color: GridColors.errorDark))),
            ),
          if (!_carregando && _resultado != null) _resultadoView(_resultado!),
        ],
      ),
    );
  }

  Widget _filtros() {
    return Card(
      color: GridColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String>(
                key: const Key('dp_tipo'),
                value: _tipo,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Relatório', border: OutlineInputBorder()),
                items: DpPontoService.tiposRelatorio.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setState(() { _tipo = v ?? _tipo; _resultado = null; }),
              ),
            ),
            _dropdownOpcional('dp_setor', 'Setor', _setores, _setorId, (v) => setState(() => _setorId = v)),
            _dropdownOpcional('dp_funcionario', 'Funcionário', _funcionarios, _funcionarioId, (v) => setState(() => _funcionarioId = v)),
            OutlinedButton.icon(
              key: const Key('dp_data_ini'),
              onPressed: () => _escolherData(true),
              icon: const Icon(Icons.event),
              label: Text('De ${_dataBr(_inicio)}'),
            ),
            OutlinedButton.icon(
              key: const Key('dp_data_fim'),
              onPressed: () => _escolherData(false),
              icon: const Icon(Icons.event),
              label: Text('Até ${_dataBr(_fim)}'),
            ),
            FilledButton.icon(
              key: const Key('dp_gerar'),
              onPressed: _carregando ? null : _gerar,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Gerar'),
            ),
            OutlinedButton.icon(
              key: const Key('dp_pdf'),
              onPressed: _baixando ? null : () => _baixar('pdf'),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF'),
            ),
            OutlinedButton.icon(
              key: const Key('dp_csv'),
              onPressed: _baixando ? null : () => _baixar('csv'),
              icon: const Icon(Icons.table_view),
              label: const Text('CSV'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownOpcional(String chave, String rotulo, List<Map<String, dynamic>> itens, String? valor,
      ValueChanged<String?> onChanged) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String?>(
        key: Key(chave),
        value: itens.any((i) => '${i['id']}' == valor) ? valor : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: rotulo, border: const OutlineInputBorder()),
        items: [
          const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
          ...itens.map((i) => DropdownMenuItem<String?>(
              value: '${i['id']}', child: Text('${i['nome'] ?? i['id']}', overflow: TextOverflow.ellipsis))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _resultadoView(Map<String, dynamic> r) {
    final colunas = (r['colunas'] as List).map((e) => '$e').toList();
    final linhas = (r['linhas'] as List).map((l) => (l as List).map((e) => '$e').toList()).toList();
    final totais = (r['totais'] as List?)?.map((e) => '$e').toList();
    return Card(
      color: GridColors.card,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${r['titulo']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
            Text('${r['subtitulo']}', style: const TextStyle(color: GridColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            if (linhas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum registro para os filtros informados.', key: Key('dp_vazio')),
              )
            else
              LayoutBuilder(builder: (context, c) {
                if (c.maxWidth < 700) return _cartoes(colunas, linhas, totais);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    key: const Key('dp_tabela'),
                    headingRowColor: WidgetStateProperty.all(GridColors.gridHeader),
                    columns: colunas.map((c) => DataColumn(label: Text(c))).toList(),
                    rows: [
                      ...linhas.map((l) => DataRow(cells: l.map((v) => DataCell(Text(v))).toList())),
                      if (totais != null)
                        DataRow(
                          color: WidgetStateProperty.all(GridColors.surfaceMuted),
                          cells: totais.map((v) => DataCell(Text(v, style: const TextStyle(fontWeight: FontWeight.w700)))).toList(),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _cartoes(List<String> colunas, List<List<String>> linhas, List<String>? totais) {
    Widget cartao(List<String> l, {bool total = false}) => Card(
          elevation: 0,
          color: total ? GridColors.surfaceMuted : GridColors.background,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < colunas.length; i++)
                  if (l[i].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text.rich(TextSpan(children: [
                        TextSpan(text: '${colunas[i]}: ', style: const TextStyle(color: GridColors.textSecondary, fontSize: 12)),
                        TextSpan(text: l[i], style: TextStyle(fontWeight: total || i == 0 ? FontWeight.w700 : FontWeight.w500)),
                      ])),
                    ),
              ],
            ),
          ),
        );
    return Column(
      key: const Key('dp_cartoes'),
      children: [
        ...linhas.map(cartao),
        if (totais != null) cartao(totais, total: true),
      ],
    );
  }
}
