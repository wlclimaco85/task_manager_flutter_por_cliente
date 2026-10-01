import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/query_builder_caller.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import 'query_builder_edit_dialog.dart';
import 'query_builder_save_load_dialog.dart';

/// Tela Query Builder — ferramenta de consulta SQL similar ao Sankhya.
///
/// Layout de três painéis:
/// ┌──────────────────────────────────────────────────────────────┐
/// │ AppBar: "Query Builder"              [New] [Save] [Load]   │
/// ├──────────────┬───────────────────────────────────────────────┤
/// │  Database    │  SQL Editor (monospace)                      │
/// │  Explorer    │  ┌──────────────────────────────────────┐    │
/// │  (TreeView)  │  │ SELECT * FROM "login"                │    │
/// │              │  └──────────────────────────────────────┘    │
/// │  ▼ public    │  [▶ Execute] [Export CSV]                   │
/// │    ▼ login   │──────────────────────────────────────────────│
/// │      🔑 id   │  Results Grid (DataTable)                    │
/// │      nome    │  ┌────┬──────┬────────────┬──────┬──┐        │
/// │      email   │  │ id │ nome │   email    │ ativo│✏️│        │
/// │      ativo   │  ├────┼──────┼────────────┼──────┼──┤        │
/// └──────────────┴──────────────────────────────────────────────┘
class QueryBuilderWindowScreen extends StatefulWidget {
  const QueryBuilderWindowScreen({super.key});

  @override
  State<QueryBuilderWindowScreen> createState() =>
      _QueryBuilderWindowScreenState();
}

class _QueryBuilderWindowScreenState extends State<QueryBuilderWindowScreen> {
  // ── Estados ──────────────────────────────────────────────────────────
  bool _carregandoSchemas = false;
  bool _carregandoTabelas = false;
  bool _carregandoColunas = false;
  bool _executando = false;

  List<dynamic> _schemas = [];
  String? _schemaSelecionado;
  List<dynamic> _tabelas = [];
  String? _tabelaSelecionada;
  List<Map<String, dynamic>> _colunas = [];
  bool _arvoreExpandida = true;

  final TextEditingController _sqlController = TextEditingController();
  List<Map<String, dynamic>> _colunasResultado = [];
  List<List<dynamic>> _linhasResultado = [];
  String? _mensagemErro;
  int _totalRegistros = 0;
  int _paginaAtual = 1;
  static const int _tamanhoPagina = 0;

  String? _nomeQueryAtual;

  @override
  void initState() {
    super.initState();
    _carregarSchemas();
  }

  @override
  void dispose() {
    _sqlController.dispose();
    super.dispose();
  }

  // ── Carregamento de metadados ───────────────────────────────────────

  Future<void> _carregarSchemas() async {
    setState(() => _carregandoSchemas = true);
    try {
      final schemas = await QueryBuilderCaller.listarSchemas();
      if (!mounted) return;
      setState(() {
        _schemas = schemas;
        _carregandoSchemas = false;
        _mensagemErro = schemas.isEmpty ? 'Nenhum schema disponível' : null;
        if (schemas.isNotEmpty) {
          _schemaSelecionado = schemas.first.toString();
        }
      });
      if (_schemaSelecionado != null) {
        await _carregarTabelas(_schemaSelecionado!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoSchemas = false;
        _mensagemErro = 'Erro ao carregar schemas: $e';
      });
      debugPrint('[QueryBuilder] Erro ao carregar schemas: $e');
    }
  }

  Future<void> _carregarTabelas(String schema) async {
    setState(() {
      _carregandoTabelas = true;
      _tabelas = [];
      _tabelaSelecionada = null;
      _colunas = [];
      _mensagemErro = null;
    });
    try {
      final tabelas = await QueryBuilderCaller.listarTabelas();
      if (!mounted) return;
      setState(() {
        _tabelas = tabelas;
        _carregandoTabelas = false;
        if (tabelas.isEmpty) {
          _mensagemErro = 'Nenhuma tabela encontrada no schema $schema';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoTabelas = false;
        _mensagemErro = 'Erro ao carregar tabelas: $e';
      });
      debugPrint('[QueryBuilder] Erro ao carregar tabelas: $e');
    }
  }

  Future<void> _carregarColunas(String schema, String tabela) async {
    setState(() {
      _carregandoColunas = true;
      _colunas = [];
      _mensagemErro = null;
    });
    try {
      final colunas = await QueryBuilderCaller.listarColunas(schema, tabela);
      if (!mounted) return;
      setState(() {
        _colunas = colunas.map((c) {
          if (c is Map<String, dynamic>) return c;
          if (c is String) return {'nome': c};
          return {'nome': c.toString()};
        }).toList();
        _carregandoColunas = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoColunas = false;
        _mensagemErro = 'Erro ao carregar colunas: $e';
      });
      debugPrint('[QueryBuilder] Erro ao carregar colunas: $e');
    }
  }

  // ── Execução ────────────────────────────────────────────────────────

  Future<void> _executarQuery({int pagina = 1}) async {
    final sql = _sqlController.text.trim();
    if (sql.isEmpty) {
      _mostrarSnackBar('Digite uma consulta SQL antes de executar.');
      return;
    }

    setState(() {
      _executando = true;
      _mensagemErro = null;
      _colunasResultado = [];
      _linhasResultado = [];
    });

    final resultado = await QueryBuilderCaller.executarQuery(
      sql,
      pagina: pagina,
      tamanhoPagina: _tamanhoPagina,
    );

    if (!mounted) return;

    final dados = resultado['data'] is Map
        ? Map<String, dynamic>.from(resultado['data'])
        : resultado;

    final erro = dados['erro'] ?? dados['error'];
    final temErro =
        erro != null && erro != false && erro.toString().trim().isNotEmpty;
    if (temErro) {
      setState(() {
        _mensagemErro = erro.toString();
        _executando = false;
      });
      return;
    }

    setState(() {
      _paginaAtual = pagina;
      _totalRegistros = (dados['totalLinhas'] ?? dados['total'] ?? 0) as int;
      _executando = false;

      // Colunas do resultado
      final cols = dados['colunas'];
      if (cols is List) {
        _colunasResultado = cols
            .map((c) => c is Map<String, dynamic> ? c : {'nome': c.toString()})
            .toList();
      } else {
        _colunasResultado = [];
      }

      // Linhas do resultado
      final linhas = dados['linhas'] ?? dados['data'] ?? dados['rows'];
      if (linhas is List) {
        _linhasResultado = linhas.map((linha) {
          if (linha is List) return linha;
          if (linha is Map<String, dynamic>) {
            return _colunasResultado
                .map((c) =>
                    linha.containsKey(c['nome']) ? linha[c['nome']] : null)
                .toList();
          }
          return <dynamic>[];
        }).toList();
      } else {
        _linhasResultado = [];
      }
    });
  }

  // ── Edição de linha ─────────────────────────────────────────────────

  Future<void> _editarLinha(int rowIndex) async {
    if (_colunasResultado.isEmpty || rowIndex >= _linhasResultado.length) {
      return;
    }

    // Monta rowData a partir do resultado
    final Map<String, dynamic> rowData = {};
    for (int i = 0; i < _colunasResultado.length; i++) {
      final nomeCol = _colunasResultado[i]['nome']?.toString() ?? 'col_$i';
      rowData[nomeCol] = i < _linhasResultado[rowIndex].length
          ? _linhasResultado[rowIndex][i]
          : null;
    }

    final editou = await showEditRowDialog(
      context,
      schema: _schemaSelecionado ?? 'public',
      colunas: _colunasResultado,
      rowData: rowData,
    );

    if (editou == true && mounted) {
      _executarQuery(pagina: _paginaAtual);
    }
  }

  // ── Inserir nome da coluna no editor ────────────────────────────────

  void _inserirNoEditor(String texto) {
    final cursorPos = _sqlController.selection.baseOffset;
    final currentText = _sqlController.text;
    final novoTexto = currentText.substring(0, cursorPos) +
        texto +
        currentText.substring(cursorPos);
    _sqlController.value = TextEditingValue(
      text: novoTexto,
      selection: TextSelection.collapsed(
        offset: cursorPos + texto.length,
      ),
    );
  }

  // ── Exportar CSV ────────────────────────────────────────────────────

  void _exportarCsv() {
    if (_colunasResultado.isEmpty || _linhasResultado.isEmpty) {
      _mostrarSnackBar('Nenhum resultado para exportar.');
      return;
    }

    try {
      final buffer = StringBuffer();

      // Cabeçalho
      final headers = _colunasResultado
          .map((c) => _escaparCsv(c['nome']?.toString() ?? ''))
          .join(',');
      buffer.writeln(headers);

      // Linhas
      for (final linha in _linhasResultado) {
        final valores = linha.map((v) {
          final str = v?.toString() ?? '';
          return _escaparCsv(str);
        }).join(',');
        buffer.writeln(valores);
      }

      final csv = buffer.toString();
      Clipboard.setData(ClipboardData(text: csv));
      _mostrarSnackBar(
          'CSV copiado para área de transferência (${_linhasResultado.length} linhas).');
    } catch (e) {
      _mostrarSnackBar('Erro ao exportar CSV: $e');
    }
  }

  String _escaparCsv(String valor) {
    if (valor.contains(',') || valor.contains('"') || valor.contains('\n')) {
      return '"${valor.replaceAll('"', '""')}"';
    }
    return valor;
  }

  // ── Salvar / Carregar queries ───────────────────────────────────────

  Future<void> _novaQuery() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Query'),
        content: const Text('Limpar o editor e começar uma nova consulta?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirm == true && mounted) {
      setState(() {
        _sqlController.clear();
        _colunasResultado = [];
        _linhasResultado = [];
        _mensagemErro = null;
        _totalRegistros = 0;
        _nomeQueryAtual = null;
      });
    }
  }

  Future<void> _salvarQuery() async {
    final sql = _sqlController.text.trim();
    if (sql.isEmpty) {
      _mostrarSnackBar('Digite uma query antes de salvar.');
      return;
    }

    final nome = await showSaveQueryDialog(context, nomeAtual: _nomeQueryAtual);
    if (nome == null || !mounted) return;

    final result = await QueryBuilderCaller.salvarQuery({
      'nome': nome,
      'sqlTexto': sql,
    });

    if (mounted) {
      if (result.isNotEmpty &&
          !result.containsKey('erro') &&
          !result.containsKey('error')) {
        setState(() => _nomeQueryAtual = nome);
        _mostrarSnackBar('Query "$nome" salva com sucesso.');
      } else {
        _mostrarSnackBar('Erro ao salvar query.');
      }
    }
  }

  Future<void> _carregarQuery() async {
    final queries = await QueryBuilderCaller.listarQueriesSalvas();
    if (!mounted) return;

    final queryData = await showLoadQueryDialog(context, queries);
    if (queryData == null || !mounted) return;

    setState(() {
      _sqlController.text = queryData['sqlTexto']?.toString() ?? '';
      _nomeQueryAtual = queryData['nome']?.toString();
      _colunasResultado = [];
      _linhasResultado = [];
      _mensagemErro = null;
      _totalRegistros = 0;
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  void _mostrarSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatarValor(dynamic valor) {
    if (valor == null) return GridTexts.noRecords;
    if (valor is bool) return valor ? 'true' : 'false';
    return valor.toString();
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        iconTheme: const IconThemeData(color: GridColors.textPrimary),
        title: Text(
          _nomeQueryAtual != null
              ? 'Query Builder — $_nomeQueryAtual'
              : 'Query Builder',
          style: const TextStyle(
            color: GridColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        actions: [
          _botaoAppBar(Icons.add, 'Nova Query', _novaQuery),
          _botaoAppBar(Icons.save, 'Salvar Query', _salvarQuery),
          _botaoAppBar(Icons.folder_open, 'Carregar Query', _carregarQuery),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _botaoAppBar(IconData icone, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icone, color: GridColors.textPrimary.withValues(alpha: 0.9)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildBody() {
    if (_mensagemErro != null && !_carregandoSchemas && _schemas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: GridColors.error),
            const SizedBox(height: 16),
            Text(
              _mensagemErro!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GridColors.error,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _carregarSchemas,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Painel esquerdo: Database Explorer ─────────────────────
        _buildDatabaseExplorer(),
        const VerticalDivider(
            width: 1, thickness: 1, color: GridColors.divider),
        // ── Painel direito: Editor + Resultados ────────────────────
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSqlEditor(),
              const Divider(height: 1, thickness: 1, color: GridColors.divider),
              Expanded(child: _buildResultsPanel()),
            ],
          ),
        ),
      ],
    );
  }

  // ── Database Explorer ──────────────────────────────────────────────

  Widget _buildDatabaseExplorer() {
    return Container(
      width: 260,
      color: GridColors.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: GridColors.gridHeader,
            child: const Row(
              children: [
                Icon(Icons.storage, size: 16, color: GridColors.primary),
                SizedBox(width: 8),
                Text(
                  'Database Explorer',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: GridColors.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _carregandoSchemas
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _schemas.isEmpty
                    ? const Center(
                        child: Text(
                          'Nenhum schema encontrado',
                          style: TextStyle(
                            color: GridColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: _schemas.map((schema) {
                          final nome = schema.toString();
                          final selecionado = nome == _schemaSelecionado;
                          return _buildSchemaNode(nome, selecionado);
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemaNode(String nome, bool selecionado) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _schemaSelecionado = nome;
              _arvoreExpandida = !_arvoreExpandida;
            });
            _carregarTabelas(nome);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: selecionado ? GridColors.selectedRow : null,
            child: Row(
              children: [
                Icon(
                  _arvoreExpandida && selecionado
                      ? Icons.expand_more
                      : Icons.chevron_right,
                  size: 16,
                  color: GridColors.textMuted,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.schema,
                  size: 16,
                  color: GridColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  nome,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        selecionado ? FontWeight.w600 : FontWeight.normal,
                    color: selecionado
                        ? GridColors.textSecondary
                        : GridColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selecionado && _arvoreExpandida) ..._buildTabelasNodes(),
      ],
    );
  }

  List<Widget> _buildTabelasNodes() {
    if (_carregandoTabelas) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 48, top: 4, bottom: 4),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ];
    }

    if (_tabelas.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 48, top: 4, bottom: 4),
          child: Text(
            'Nenhuma tabela',
            style: TextStyle(fontSize: 12, color: GridColors.textMuted),
          ),
        ),
      ];
    }

    return _tabelas.map((tabela) {
      final nome = tabela.toString();
      final selecionada = nome == _tabelaSelecionada;
      return _buildTabelaNode(nome, selecionada);
    }).toList();
  }

  Widget _buildTabelaNode(String nome, bool selecionada) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _tabelaSelecionada = _tabelaSelecionada == nome ? null : nome;
            });
            if (_tabelaSelecionada == nome) {
              _carregarColunas(_schemaSelecionado ?? 'public', nome);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.only(left: 48, top: 4, bottom: 4, right: 8),
            child: Row(
              children: [
                Icon(
                  selecionada ? Icons.table_chart : Icons.table_chart_outlined,
                  size: 14,
                  color:
                      selecionada ? GridColors.secondary : GridColors.textMuted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    nome,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selecionada ? FontWeight.w600 : FontWeight.normal,
                      color: selecionada
                          ? GridColors.textSecondary
                          : GridColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (selecionada) ..._buildColunasNodes(),
      ],
    );
  }

  List<Widget> _buildColunasNodes() {
    if (_carregandoColunas) {
      return [
        const Padding(
          padding: EdgeInsets.only(left: 64, top: 2, bottom: 2),
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ];
    }

    return _colunas.map((col) {
      final nome =
          col['nome']?.toString() ?? col['column_name']?.toString() ?? '?';
      final isPk = col['pk'] == true ||
          col['primaryKey'] == true ||
          col['isPrimaryKey'] == true;
      final isFk = col['fk'] == true || col['foreignKey'] == true;
      final tipo = col['tipo']?.toString() ?? '';
      final tamanho = col['tamanho'];
      final nullable = col['nullable'] == true;
      return _buildColunaNode(nome, isPk, isFk, tipo, tamanho, nullable);
    }).toList();
  }

  Widget _buildColunaNode(String nome, bool isPk, bool isFk, String tipo,
      dynamic tamanho, bool nullable) {
    final tipoStr = tipo.isNotEmpty ? tipo.toUpperCase() : '';
    final tamStr =
        (tamanho != null && tamanho is int && tamanho > 0) ? '($tamanho)' : '';
    final suf = '$tipoStr$tamStr';
    return InkWell(
      onTap: () => _inserirNoEditor(nome),
      onSecondaryTap: () => _inserirNoEditor('"$nome"'),
      child: Container(
        padding: const EdgeInsets.only(left: 64, top: 3, bottom: 3, right: 8),
        child: Row(
          children: [
            Icon(
              isPk ? Icons.vpn_key : (isFk ? Icons.link : Icons.arrow_right),
              size: 12,
              color: isPk
                  ? GridColors.warning
                  : (isFk ? GridColors.info : GridColors.textMuted),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                        text: nome,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: isPk
                              ? GridColors.warningDark
                              : GridColors.textMuted,
                        )),
                    if (suf.isNotEmpty)
                      TextSpan(
                        text: ' ($suf${nullable ? ', nullable' : ''})',
                        style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: GridColors.textMuted),
                      ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── SQL Editor ──────────────────────────────────────────────────────

  Widget _buildSqlEditor() {
    return Container(
      decoration: BoxDecoration(
        color: GridColors.card,
        border: Border(
          bottom: BorderSide(color: GridColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de ferramentas do editor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: GridColors.gridHeader,
            child: Row(
              children: [
                const Icon(Icons.code, size: 14, color: GridColors.primary),
                const SizedBox(width: 6),
                const Text(
                  'SQL Editor',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: GridColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Ctrl+Enter para executar',
                  style: TextStyle(
                    fontSize: 11,
                    color: GridColors.textMuted.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Limpar editor',
                  child: InkWell(
                    onTap: () {
                      _sqlController.clear();
                      setState(() {
                        _colunasResultado = [];
                        _linhasResultado = [];
                        _mensagemErro = null;
                      });
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.clear,
                          size: 16, color: GridColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Área de texto monospace
          SizedBox(
            height: 120,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.enter, control: true):
                    () => _executarQuery(),
              },
              child: Focus(
                autofocus: false,
                child: TextField(
                  controller: _sqlController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.4,
                    color: GridColors.textSecondary,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                    hintText:
                        'Digite sua consulta SQL aqui...\nEx: SELECT * FROM "login" LIMIT 50',
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: GridColors.textMuted,
                    ),
                  ),
                  onSubmitted: (_) => _executarQuery(),
                ),
              ),
            ),
          ),
          // Barra de ações do editor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: GridColors.card,
              border: Border(
                top: BorderSide(
                    color: GridColors.divider.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                _botaoAcao(
                  Icons.play_arrow,
                  'Executar',
                  GridColors.success,
                  _executando ? null : () => _executarQuery(),
                ),
                const SizedBox(width: 8),
                _botaoAcao(
                  Icons.file_download,
                  'Exportar CSV',
                  GridColors.primary,
                  _linhasResultado.isEmpty ? null : _exportarCsv,
                ),
                const Spacer(),
                if (_totalRegistros > 0)
                  Text(
                    '$_totalRegistros registro(s)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: GridColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoAcao(
      IconData icone, String texto, Color cor, VoidCallback? onPressed) {
    return SizedBox(
      height: 32,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icone, size: 16),
        label: Text(texto, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          foregroundColor: GridColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }

  // ── Painel de Resultados ───────────────────────────────────────────

  Widget _buildResultsPanel() {
    if (_executando) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 12),
            Text(
              'Executando consulta...',
              style: TextStyle(
                color: GridColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (_mensagemErro != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GridColors.errorLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GridColors.error.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 36, color: GridColors.error),
              const SizedBox(height: 12),
              const Text(
                'Erro ao executar consulta',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: GridColors.errorDark,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _mensagemErro!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: GridColors.errorDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => setState(() => _mensagemErro = null),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Fechar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_colunasResultado.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_chart_outlined,
                size: 48, color: GridColors.divider),
            SizedBox(height: 12),
            Text(
              'Nenhum resultado',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: GridColors.textMuted,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Execute uma consulta para ver os resultados aqui.',
              style: TextStyle(
                fontSize: 12,
                color: GridColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return _buildDataTable();
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(GridColors.gridHeader),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return GridColors.hover;
            }
            return GridColors.rowEven;
          }),
          border: TableBorder.all(
            color: GridColors.divider.withValues(alpha: 0.5),
            width: 0.5,
          ),
          columnSpacing: 16,
          horizontalMargin: 12,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 48,
          headingRowHeight: 40,
          columns: [
            // Coluna de edição
            const DataColumn(
              label: Icon(Icons.edit, size: 14, color: GridColors.textMuted),
            ),
            // Colunas do resultado
            ..._colunasResultado.map((col) {
              final nome = col['nome']?.toString() ?? '?';
              final tipo = col['tipo']?.toString() ?? '';
              return DataColumn(
                label: Tooltip(
                  message: tipo.isNotEmpty ? '$nome ($tipo)' : nome,
                  child: Text(
                    nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: GridColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          ],
          rows: List.generate(_linhasResultado.length, (rowIndex) {
            return DataRow(
              color: WidgetStateProperty.all(
                rowIndex.isEven ? GridColors.rowEven : GridColors.rowOdd,
              ),
              cells: [
                // Botão editar
                DataCell(
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      icon: const Icon(Icons.edit_note, size: 18),
                      onPressed: () => _editarLinha(rowIndex),
                      tooltip: 'Editar linha',
                      padding: EdgeInsets.zero,
                      color: GridColors.primary,
                    ),
                  ),
                ),
                // Valores
                ..._colunasResultado.asMap().entries.map((entry) {
                  final colIndex = entry.key;
                  final colMeta = entry.value;
                  final valor = colIndex < _linhasResultado[rowIndex].length
                      ? _linhasResultado[rowIndex][colIndex]
                      : null;
                  final tipo = colMeta['tipo']?.toString() ?? '';

                  return DataCell(
                    _buildCellValue(valor, tipo),
                  );
                }),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCellValue(dynamic valor, String tipo) {
    if (valor == null) {
      return Text(
        GridTexts.noRecords,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: GridColors.textMuted,
        ),
      );
    }

    final texto = valor.toString();
    final cor = tipo.toUpperCase().contains('BOOL')
        ? (valor == true ? GridColors.success : GridColors.error)
        : null;

    return Text(
      texto,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: 12,
        color: cor ?? GridColors.textSecondary,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
