import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/dp_exportacao_folha_service.dart';
import '../../utils/tenant_context.dart';

/// Exportacao do fechamento de ponto para a folha (Dominio / Alterdata / Questor) e
/// configuracao do mapeamento evento do ponto -> codigo de evento. Mesmo widget em Web, Windows e Mobile
/// (coluna unica, alvos de toque >= 44px).
class DpExportacaoFolhaScreen extends StatefulWidget {
  const DpExportacaoFolhaScreen({super.key, this.service, this.empresaId, this.salvarArquivo});

  final DpExportacaoFolhaService? service;
  final int? empresaId;

  /// Injetavel para teste; por padrao usa o FileSaver.
  final Future<void> Function(DpExportacaoArquivo arquivo)? salvarArquivo;

  @override
  State<DpExportacaoFolhaScreen> createState() => _DpExportacaoFolhaScreenState();
}

class _DpExportacaoFolhaScreenState extends State<DpExportacaoFolhaScreen> {
  late final DpExportacaoFolhaService _service = widget.service ?? DpExportacaoFolhaService();
  final _codEmpresaCtrl = TextEditingController();
  final Map<String, TextEditingController> _codCtrls = {};

  List<DpMapeamentoLinha> _mapa = [];
  List<String> _erros = [];
  String _layout = 'dominio';
  late String _competencia = _competencias().first;
  bool _carregando = true;
  bool _gerando = false;
  bool _salvando = false;
  String? _aviso;

  int? get _empId => widget.empresaId ?? TenantContext.empresaId;

  static List<String> _competencias() {
    final hoje = DateTime.now();
    return List.generate(
        12, (i) => DateFormat('yyyy-MM').format(DateTime(hoje.year, hoje.month - 1 - i)));
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _codEmpresaCtrl.dispose();
    for (final c in _codCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregar() async {
    final emp = _empId;
    if (emp == null) {
      setState(() {
        _carregando = false;
        _erros = ['Empresa não identificada na sessão.'];
      });
      return;
    }
    setState(() => _carregando = true);
    try {
      _aplicarMapa(await _service.carregarMapeamento(emp));
      _erros = [];
    } on DpExportacaoErro catch (e) {
      _erros = e.erros;
    }
    if (mounted) setState(() => _carregando = false);
  }

  void _aplicarMapa(List<DpMapeamentoLinha> mapa) {
    _mapa = mapa;
    for (final l in mapa) {
      final ctrl = _codCtrls.putIfAbsent(l.eventoPonto, () => TextEditingController());
      ctrl.text = l.codigoEvento;
    }
  }

  Future<void> _salvarMapa() async {
    final emp = _empId;
    if (emp == null) return;
    for (final l in _mapa) {
      l.codigoEvento = _codCtrls[l.eventoPonto]?.text ?? '';
    }
    setState(() {
      _salvando = true;
      _aviso = null;
    });
    try {
      _aplicarMapa(await _service.salvarMapeamento(emp, _mapa));
      _erros = [];
      _aviso = 'Mapeamento salvo.';
    } on DpExportacaoErro catch (e) {
      _erros = e.erros;
    }
    if (mounted) setState(() => _salvando = false);
  }

  Future<void> _gerar() async {
    final emp = _empId;
    if (emp == null) return;
    setState(() {
      _gerando = true;
      _erros = [];
      _aviso = null;
    });
    try {
      final arq = await _service.gerar(
          empId: emp, competencia: _competencia, layout: _layout, codEmpresa: _codEmpresaCtrl.text);
      await (widget.salvarArquivo ?? _salvarComFileSaver)(arq);
      _aviso = 'Arquivo ${arq.nome} gerado com ${arq.linhas} linha(s)'
          '${arq.ignorados > 0 ? ' (${arq.ignorados} funcionário(s) com ponto ainda não fechado ficaram de fora)' : ''}.';
    } on DpExportacaoErro catch (e) {
      _erros = e.erros;
    } catch (_) {
      _erros = ['Não foi possível salvar o arquivo.'];
    }
    if (mounted) setState(() => _gerando = false);
  }

  Future<void> _salvarComFileSaver(DpExportacaoArquivo a) async {
    final ponto = a.nome.lastIndexOf('.');
    await FileSaver.instance.saveFile(
      name: ponto > 0 ? a.nome.substring(0, ponto) : a.nome,
      bytes: a.bytes,
      fileExtension: ponto > 0 ? a.nome.substring(ponto + 1) : 'txt',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar ponto para a folha')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_aviso != null)
                      _caixa(_aviso!, cs.primaryContainer, cs.onPrimaryContainer, key: const Key('dpExpAviso')),
                    if (_erros.isNotEmpty)
                      _caixa(_erros.join('\n'), cs.errorContainer, cs.onErrorContainer, key: const Key('dpExpErros')),
                    _cardExportar(),
                    const SizedBox(height: 16),
                    _cardMapeamento(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _caixa(String texto, Color fundo, Color letra, {Key? key}) => Container(
        key: key,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(8)),
        child: SelectableText(texto, style: TextStyle(color: letra)),
      );

  Widget _cardExportar() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Exportar fechamento', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Somente funcionários com o ponto da competência FECHADO são exportados.'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('dpExpCompetencia'),
              initialValue: _competencia,
              decoration: const InputDecoration(labelText: 'Competência'),
              items: _competencias()
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.split('-').reversed.join('/'))))
                  .toList(),
              onChanged: (v) => setState(() => _competencia = v ?? _competencia),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('dpExpLayout'),
              initialValue: _layout,
              decoration: const InputDecoration(labelText: 'Sistema de folha (layout)'),
              items: DpExportacaoFolhaService.layouts.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _layout = v ?? _layout),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('dpExpCodEmpresa'),
              controller: _codEmpresaCtrl,
              decoration: const InputDecoration(
                  labelText: 'Código da empresa na folha (opcional)',
                  helperText: 'Se vazio, usa o código desta empresa no sistema.'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                key: const Key('dpExpGerar'),
                onPressed: _gerando ? null : _gerar,
                icon: _gerando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download),
                label: const Text('Gerar arquivo'),
              ),
            ),
          ]),
        ),
      );

  Widget _cardMapeamento() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Mapeamento de eventos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Informe o código do evento/rubrica de cada verba na sua folha. '
                'Evento com horas apuradas e sem código bloqueia a exportação.'),
            const SizedBox(height: 8),
            for (final l in _mapa)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(
                      flex: 3,
                      child: Text('${l.descricao}\n(${l.unidade == 'DIAS' ? 'dias' : 'horas'})')),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      key: Key('dpExpCod_${l.eventoPonto}'),
                      controller: _codCtrls[l.eventoPonto],
                      decoration: const InputDecoration(labelText: 'Código'),
                    ),
                  ),
                  Switch(value: l.ativo, onChanged: (v) => setState(() => l.ativo = v)),
                ]),
              ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                key: const Key('dpExpSalvarMapa'),
                onPressed: _salvando ? null : _salvarMapa,
                icon: const Icon(Icons.save),
                label: const Text('Salvar mapeamento'),
              ),
            ),
          ]),
        ),
      );
}