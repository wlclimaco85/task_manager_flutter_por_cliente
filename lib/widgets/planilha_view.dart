
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/planilha_service.dart';
import '../utils/app_logger.dart';
import '../utils/file_saver_compat.dart';
import '../utils/planilha_formula.dart';
import '../utils/tenant_context.dart';

/// Planilha tipo Excel: celulas com formulas, colar do Excel, importar/exportar .xlsx, salvar por empresa/parceiro e
/// (MASTER) trazer dados do sistema com SELECT. Usa so cores do tema, para nao misturar identidade entre os apps.
class PlanilhaView extends StatefulWidget {
  final PlanilhaService? servico;
  final bool? podeConsultar;

  const PlanilhaView({super.key, this.servico, this.podeConsultar});

  @override
  State<PlanilhaView> createState() => _PlanilhaViewState();
}

class _PlanilhaViewState extends State<PlanilhaView> {
  static const double _alturaLinha = 44;
  static const double _larguraColuna = 120;
  static const double _larguraIndice = 52;

  late final PlanilhaService _svc = widget.servico ?? PlanilhaService();
  late final bool _podeConsultar = widget.podeConsultar ?? TenantContext.isMaster;

  final _nome = TextEditingController(text: 'Nova planilha');
  final _barra = TextEditingController();
  final _celula = TextEditingController();

  List<PlanilhaResumo> _salvas = const [];
  int? _id;
  Map<String, String> _celulas = {};
  late PlanilhaCalculo _calculo = PlanilhaCalculo(_celulas);
  int _linha = 0;
  int _coluna = 0;
  bool _alterada = false;
  bool _ocupado = false;

  String get _selecionada => endereco(_linha, _coluna);

  @override
  void initState() {
    super.initState();
    _executar('carregar as planilhas', () async => _salvas = await _svc.listar());
  }

  @override
  void dispose() {
    _nome.dispose();
    _barra.dispose();
    _celula.dispose();
    super.dispose();
  }

  Future<void> _executar(String acao, Future<void> Function() tarefa) async {
    setState(() => _ocupado = true);
    try {
      await tarefa();
    } catch (e, s) {
      AppLogger.i.warn('PlanilhaView: erro ao $acao: $e | $s');
      _avisar(e is PlanilhaException ? e.mensagem : 'Não foi possível $acao.', erro: true);
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void _avisar(String texto, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(texto), backgroundColor: erro ? Theme.of(context).colorScheme.error : null));
  }

  Future<bool> _confirmar(String pergunta) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(content: Text(pergunta), actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Continuar')),
        ]),
      ) ==
      true;

  Future<bool> _podeDescartar() async =>
      !_alterada || await _confirmar('Há alterações não salvas. Descartar?');

  // ------------------------------------------------------------------ celulas

  void _aposMudanca() {
    _alterada = true;
    _calculo = PlanilhaCalculo(_celulas);
  }

  void _editar(String valor) {
    setState(() {
      if (valor.isEmpty) {
        _celulas.remove(_selecionada);
      } else {
        _celulas[_selecionada] = valor;
      }
      _aposMudanca();
    });
  }

  void _selecionar(int linha, int coluna) {
    setState(() {
      _linha = linha.clamp(0, kPlanilhaMaxLinhas - 1);
      _coluna = coluna.clamp(0, kPlanilhaMaxColunas - 1);
      _sincronizar();
    });
  }

  void _sincronizar() {
    final v = _celulas[_selecionada] ?? '';
    _celula.text = v;
    _barra.text = v;
  }

  void _substituir(Map<String, String> celulas, {int? id, String? nome}) {
    setState(() {
      _celulas = Map.of(celulas);
      _calculo = PlanilhaCalculo(_celulas);
      _id = id;
      if (nome != null) _nome.text = nome;
      _linha = 0;
      _coluna = 0;
      _alterada = false;
      _sincronizar();
    });
  }

  Future<void> _gravarBloco(List<List<String>> bloco) async {
    final ocupadas = [
      for (var l = 0; l < bloco.length; l++)
        for (var c = 0; c < bloco[l].length; c++)
          if (_celulas.containsKey(endereco(_linha + l, _coluna + c))) 1
    ].length;
    if (ocupadas > 1 && !await _confirmar('$ocupadas células preenchidas serão substituídas. Continuar?')) return;
    if (!inserirBloco(_celulas, _linha, _coluna, bloco)) {
      _avisar('Os dados passam do limite de $kPlanilhaMaxLinhas linhas e $kPlanilhaMaxColunas colunas.', erro: true);
      return;
    }
    setState(() {
      _aposMudanca();
      _sincronizar();
    });
  }

  Future<void> _colar() => _executar('colar', () async {
        final texto = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
        if (texto.isEmpty) {
          _avisar('A área de transferência está vazia.');
          return;
        }
        await _gravarBloco(blocoDeTextoColado(texto));
      });

  // ------------------------------------------------------------------ arquivo

  Future<void> _nova() async {
    if (await _podeDescartar()) _substituir({}, nome: 'Nova planilha');
  }

  Future<void> _abrir(int? id) async {
    if (id == null || !await _podeDescartar()) return;
    await _executar('abrir a planilha', () async {
      final p = await _svc.abrir(id);
      _substituir(p.celulas, id: p.id, nome: p.nome);
    });
  }

  PlanilhaDados get _atual => PlanilhaDados(id: _id, nome: _nome.text.trim(), celulas: _celulas);

  Future<void> _salvar() => _executar('salvar a planilha', () async {
        final p = await _svc.salvar(_atual);
        _id = p.id;
        _alterada = false;
        _salvas = await _svc.listar();
        _avisar('Planilha salva.');
      });

  Future<void> _excluir() async {
    final id = _id;
    if (id == null || !await _confirmar('Excluir a planilha "${_nome.text}"? Não é possível desfazer.')) return;
    await _executar('excluir a planilha', () async {
      await _svc.excluir(id);
      _substituir({}, nome: 'Nova planilha');
      _salvas = await _svc.listar();
    });
  }

  Future<void> _importar() async {
    if (_celulas.isNotEmpty &&
        !await _confirmar('A importação substitui o conteúdo da tela (lê a primeira aba do arquivo). Continuar?')) {
      return;
    }
    await _executar('importar o Excel', () async {
      final escolha = await FilePicker.pickFiles(
          type: FileType.custom, allowedExtensions: const ['xlsx', 'xls'], withData: true);
      final arquivo = escolha?.files.firstOrNull;
      if (arquivo?.bytes == null) return;
      final celulas = await _svc.importar(arquivo!.bytes!, arquivo.name);
      _substituir(celulas, id: _id);
      setState(() => _alterada = true);
    });
  }

  Future<void> _exportar() => _executar('exportar para Excel', () async {
        final bytes = await _svc.exportar(_atual);
        final nome = _nome.text.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final destino = await FileSaver.instance.saveFile(
            name: nome.isEmpty ? 'planilha' : nome,
            bytes: Uint8List.fromList(bytes),
            fileExtension: 'xlsx',
            mimeType: MimeType.other);
        _avisar('Excel gerado: $destino');
      });

  Future<void> _dadosDoSistema() async {
    final r = await showDialog<ConsultaPlanilha>(context: context, builder: (_) => DadosSistemaDialog(servico: _svc));
    if (r == null) return;
    await _gravarBloco([
      [for (final c in r.colunas) celulaDeValor(c)],
      for (final l in r.linhas) [for (final v in l) celulaDeValor(v)],
    ]);
    if (r.truncado) _avisar('A consulta foi limitada às primeiras ${r.linhas.length} linhas.');
  }

  // ------------------------------------------------------------------ tela

  @override
  Widget build(BuildContext context) {
    var ultimaLinha = 0, ultimaColuna = 0;
    for (final ref in _celulas.keys) {
      final p = posicao(ref);
      if (p == null) continue;
      if (p.$1 > ultimaLinha) ultimaLinha = p.$1;
      if (p.$2 > ultimaColuna) ultimaColuna = p.$2;
    }
    final linhas = (ultimaLinha + 30).clamp(100, kPlanilhaMaxLinhas);
    final colunas = (ultimaColuna + 4).clamp(26, kPlanilhaMaxColunas);

    return Column(children: [
      if (_ocupado) const LinearProgressIndicator(minHeight: 2),
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<int>(
              key: ValueKey('salvas-$_id-${_salvas.length}'),
              initialValue: _salvas.any((p) => p.id == _id) ? _id : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Planilhas salvas', isDense: true),
              items: [
                for (final p in _salvas)
                  DropdownMenuItem(value: p.id, child: Text(p.nome, overflow: TextOverflow.ellipsis))
              ],
              onChanged: _ocupado ? null : _abrir,
            ),
          ),
          SizedBox(
            width: 220,
            child: TextField(
              controller: _nome,
              maxLength: 150,
              onChanged: (_) => _alterada = true,
              decoration: const InputDecoration(labelText: 'Nome', isDense: true, counterText: ''),
            ),
          ),
          _botao(Icons.note_add_outlined, 'Nova', _nova),
          _botao(Icons.save_outlined, 'Salvar', _salvar),
          _botao(Icons.delete_outline, 'Excluir', _id == null ? null : _excluir),
          _botao(Icons.upload_file, 'Importar Excel', _importar),
          _botao(Icons.download, 'Exportar Excel', _exportar),
          _botao(Icons.content_paste, 'Colar', _colar),
          if (_podeConsultar) _botao(Icons.storage, 'Dados do sistema', _dadosDoSistema),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: Row(children: [
          SizedBox(width: 56, child: Text(_selecionada, style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(
            child: TextField(
              key: const Key('barra-formula'),
              controller: _barra,
              onChanged: (v) {
                _celula.text = v;
                _editar(v);
              },
              onSubmitted: (_) => _selecionar(_linha + 1, _coluna),
              decoration: const InputDecoration(
                  isDense: true, prefixText: 'fx  ', hintText: 'Valor ou fórmula, ex.: =SOMA(A1:A10)'),
            ),
          ),
        ]),
      ),
      Expanded(child: _grade(context, linhas, colunas)),
    ]);
  }

  Widget _botao(IconData icone, String texto, VoidCallback? aoTocar) => OutlinedButton.icon(
        onPressed: _ocupado ? null : aoTocar,
        icon: Icon(icone, size: 18),
        label: Text(texto),
        style: OutlinedButton.styleFrom(minimumSize: const Size(44, 44)),
      );

  Widget _grade(BuildContext context, int linhas, int colunas) {
    final tema = Theme.of(context);
    final borda = BorderSide(color: tema.dividerColor, width: 0.5);
    Widget caixa(double largura, Widget filho, {Color? fundo, Border? contorno}) => Container(
          width: largura,
          height: _alturaLinha,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(color: fundo, border: contorno ?? Border(right: borda, bottom: borda)),
          child: filho,
        );
    final cabecalho = tema.colorScheme.surfaceContainerHighest;

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _larguraIndice + colunas * _larguraColuna,
          child: Column(children: [
            Row(children: [
              caixa(_larguraIndice, const SizedBox(), fundo: cabecalho),
              for (var c = 0; c < colunas; c++)
                caixa(_larguraColuna, Center(child: Text(nomeColuna(c))), fundo: cabecalho),
            ]),
            Expanded(
              child: ListView.builder(
                itemExtent: _alturaLinha,
                itemCount: linhas,
                itemBuilder: (_, l) => Row(children: [
                  caixa(_larguraIndice, Text('${l + 1}'), fundo: cabecalho),
                  for (var c = 0; c < colunas; c++)
                    if (l == _linha && c == _coluna)
                      caixa(
                        _larguraColuna,
                        TextField(
                          key: ValueKey('editor-${endereco(l, c)}'),
                          controller: _celula,
                          autofocus: true,
                          onChanged: (v) {
                            _barra.text = v;
                            _editar(v);
                          },
                          onSubmitted: (_) => _selecionar(l + 1, c),
                          decoration: const InputDecoration(border: InputBorder.none, isCollapsed: true),
                        ),
                        contorno: Border.all(color: tema.colorScheme.primary, width: 2),
                      )
                    else
                      GestureDetector(
                        key: ValueKey(endereco(l, c)),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _selecionar(l, c),
                        child: caixa(
                          _larguraColuna,
                          Text(_calculo.exibir(endereco(l, c)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Parte avancada: escolhe uma tabela (monta o SELECT) ou escreve a consulta, ve a previa e insere na planilha.
class DadosSistemaDialog extends StatefulWidget {
  final PlanilhaService servico;
  const DadosSistemaDialog({super.key, required this.servico});

  @override
  State<DadosSistemaDialog> createState() => _DadosSistemaDialogState();
}

class _DadosSistemaDialogState extends State<DadosSistemaDialog> {
  final _sql = TextEditingController();
  List<String> _tabelas = const [];
  ConsultaPlanilha? _resultado;
  String? _erro;
  bool _ocupado = false;

  @override
  void initState() {
    super.initState();
    _executar(() async => _tabelas = await widget.servico.tabelas());
  }

  @override
  void dispose() {
    _sql.dispose();
    super.dispose();
  }

  Future<void> _executar(Future<void> Function() tarefa) async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      await tarefa();
    } catch (e, s) {
      AppLogger.i.warn('DadosSistemaDialog: $e | $s');
      _erro = '$e';
    }
    if (mounted) setState(() => _ocupado = false);
  }

  Future<void> _escolherTabela(String tabela) => _executar(() async {
        final colunas = await widget.servico.colunas(tabela);
        // O servidor exige :empresaId; tabela sem empresa_id retorna erro claro do banco.
        final filtro = colunas.contains('empresa_id')
            ? 'empresa_id = :empresaId'
            : colunas.contains('cod_emp')
                ? 'cod_emp = :empresaId'
                : 'empresa_id = :empresaId';
        final visiveis = colunas.where((c) => !RegExp('senha|password|token|secret|pfx').hasMatch(c));
        _sql.text = 'SELECT ${visiveis.join(', ')}\nFROM $tabela\nWHERE $filtro';
        _resultado = null;
      });

  Future<void> _consultar() => _executar(() async {
        _resultado = null;
        _resultado = await widget.servico.consultar(_sql.text);
      });

  @override
  Widget build(BuildContext context) {
    final r = _resultado;
    return AlertDialog(
      title: const Text('Dados do sistema'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            DropdownMenu<String>(
              expandedInsets: EdgeInsets.zero,
              enableFilter: true,
              requestFocusOnTap: true,
              menuHeight: 300,
              label: const Text('Tabela do sistema (monta o SELECT)'),
              dropdownMenuEntries: [for (final t in _tabelas) DropdownMenuEntry(value: t, label: t)],
              onSelected: (t) {
                if (t != null) _escolherTabela(t);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('sql'),
              controller: _sql,
              minLines: 5,
              maxLines: 12,
              style: const TextStyle(fontFamily: 'monospace'),
              onChanged: (_) => setState(() => _resultado = null),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Consulta SELECT',
                helperText: 'Somente leitura. Filtre a empresa com :empresaId (e :parceiroId se precisar).',
                helperMaxLines: 2,
              ),
            ),
            if (_ocupado) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_erro!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (r != null) ...[
              const SizedBox(height: 8),
              Text('${r.linhas.length} linha(s)${r.truncado ? ' (limite atingido)' : ''}. Prévia:'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [for (final c in r.colunas) DataColumn(label: Text(c))],
                  rows: [
                    for (final l in r.linhas.take(5))
                      DataRow(cells: [for (final v in l) DataCell(Text('${v ?? ''}'))])
                  ],
                ),
              ),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar')),
        OutlinedButton(onPressed: _ocupado ? null : _consultar, child: const Text('Consultar')),
        FilledButton(
          onPressed: r == null || _ocupado ? null : () => Navigator.pop(context, r),
          child: const Text('Inserir na célula'),
        ),
      ],
    );
  }
}
