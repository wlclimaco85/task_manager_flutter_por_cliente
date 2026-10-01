import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/grid_texts.dart';
import '../../../utils/ged_file_type.dart';
import '../../../utils/ged_upload_scope.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show RemoteDropdownSearchDialog;
import '../../../widgets/user_banners.dart'
    show AppBarActions, UserBannerAppBar;
import '../../services/ai_assistant_service.dart';
import '../../services/network_caller.dart';
import '../widgets/ged_file_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Tela GED — Gestão Eletrônica de Documentos (layout mobile/web com cards)
///
/// Parâmetros opcionais para filtro automático por módulo de origem:
///   [moduloOrigem]  ex: 'funcionario', 'produto', 'parceiro', 'alvara'
///   [idOrigem]      ID do registro de origem
///   [nomeOrigem]    Nome para exibir no título da tela
///   [empresaId]     Empresa do contexto de origem
// ─────────────────────────────────────────────────────────────────────────────
class GedArquivosScreen extends StatefulWidget {
  /// Módulo de origem que originou a navegação para o GED.
  final String? moduloOrigem;

  /// ID do registro de origem.
  final int? idOrigem;

  /// Nome do registro de origem para exibir no AppBar.
  final String? nomeOrigem;

  /// Empresa do registro de origem.
  final int? empresaId;
  final bool useUserBannerHeader;
  final VoidCallback? onUserBannerTapped;

  const GedArquivosScreen({
    super.key,
    this.moduloOrigem,
    this.idOrigem,
    this.nomeOrigem,
    this.empresaId,
    this.useUserBannerHeader = false,
    this.onUserBannerTapped,
  });

  @override
  State<GedArquivosScreen> createState() => _GedArquivosScreenState();
}

class _GedArquivosScreenState extends State<GedArquivosScreen> {
  // ── Dados ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _arquivos = [];
  bool _carregando = false;
  String _busca = '';

  // ── Filtros ───────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _diretorios = [];

  int? _empresaFiltroId;
  String? _empresaFiltroNome;
  int? _parceiroFiltroId;
  String? _parceiroFiltroNome;

  // ── Filtro por módulo de origem ───────────────────────────────────────────
  String? _moduloOrigemFiltro;
  int? _idOrigemFiltro;

  // ── Upload ────────────────────────────────────────────────────────────────
  PlatformFile? _arquivoSelecionado;
  int? _diretorioUploadId;
  int? _parceiroUploadId;
  String? _parceiroUploadNome;
  bool _enviando = false;

  // Pedido do usuario: tempo de retencao do arquivo no servidor + descricao
  // pra ser localizado pelo Chat GED Inteligente (ver bugs.md 2026-09-09
  // 16:25:39 -- backend ja aceitava esses campos, so' faltava a UI).
  int _diasRetencaoUpload = 30;
  final TextEditingController _descricaoChatUploadCtrl =
      TextEditingController();

  static const _opcoesDiasRetencao = <int, String>{
    1: '1 dia',
    10: '10 dias',
    20: '20 dias',
    30: '30 dias (padrão)',
    40: '40 dias',
    50: '50 dias',
    60: '60 dias',
    180: '180 dias',
    365: '1 ano',
    730: '2 anos',
    1825: '5 anos',
  };

  bool get _contextualizado =>
      widget.moduloOrigem != null && widget.idOrigem != null;

  bool get _contextoParceiro =>
      widget.moduloOrigem?.toLowerCase() == 'parceiro' &&
      widget.idOrigem != null;

  @override
  void dispose() {
    _descricaoChatUploadCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _carregarEmpresas();
    _carregarDiretorios();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final empresaInicial = widget.empresaId ?? TenantContext.empresaId;
      if (empresaInicial != null) {
        setState(() => _empresaFiltroId = empresaInicial);
      }
      if (_contextoParceiro) {
        setState(() {
          _parceiroFiltroId = widget.idOrigem;
          _parceiroFiltroNome = widget.nomeOrigem;
        });
      } else if (TenantContext.hasParceiro) {
        final parceiroId = TenantContext.parceiroId;
        setState(() => _parceiroFiltroId = parceiroId);
        if (parceiroId != null) {
          DropdownHelpers.parceiroLabelPorId(parceiroId.toString())
              .then((nome) {
            if (mounted && nome != null) {
              setState(() => _parceiroFiltroNome = nome);
            }
          });
        }
      }
      if (widget.moduloOrigem != null && widget.idOrigem != null) {
        setState(() {
          _moduloOrigemFiltro = widget.moduloOrigem;
          _idOrigemFiltro = widget.idOrigem;
        });
      }
      if (empresaInicial != null || TenantContext.hasParceiro) {
        _buscarArquivos();
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Carregamentos
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _carregarEmpresas() async {
    final r = await NetworkCaller().getRequest(ApiLinks.allEmpresas);
    if (!mounted) return;
    if (r.isSuccess && r.body != null) {
      final raw = r.body!['data']?['dados'] ??
          r.body!['data'] ??
          r.body!['content'] ??
          r.body;
      if (raw is List) {
        setState(() {
          _empresas = raw
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    }
  }

  Future<void> _carregarDiretorios() async {
    final r = await NetworkCaller().getRequest(ApiLinks.allDiretorios);
    if (!mounted) return;
    if (r.isSuccess && r.body != null) {
      final raw = r.body!['data']?['dados'] ??
          r.body!['data'] ??
          r.body!['content'] ??
          r.body;
      if (raw is List) {
        setState(() {
          _diretorios = raw
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    }
  }

  Future<void> _buscarArquivos() async {
    if (_empresaFiltroId == null) {
      _snack('Selecione uma empresa primeiro', erro: true);
      return;
    }
    setState(() => _carregando = true);
    final url = ApiLinks.arquivosPorEmpresa(
      _empresaFiltroId!,
      parceiroId: _parceiroFiltroId,
      modulo: _moduloOrigemFiltro,
      idOrigem: _idOrigemFiltro,
    );
    final r = await NetworkCaller().getRequest(url);
    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (r.isSuccess && r.body != null) {
        final raw = r.body is List
            ? r.body
            : r.body!['data'] ?? r.body!['content'] ?? [];
        if (raw is List) {
          _arquivos = raw
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList()
            ..sort((a, b) {
              final da = DateTime.tryParse(a['uploadDate']?.toString() ?? '');
              final db = DateTime.tryParse(b['uploadDate']?.toString() ?? '');
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return db.compareTo(da);
            });
        }
      } else {
        _arquivos = [];
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Upload
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.pickFiles(withData: true);
    if (result != null)
      setState(() => _arquivoSelecionado = result.files.first);
  }

  Future<void> _fazerUpload(BuildContext ctx) async {
    if (_arquivoSelecionado == null) {
      _snack('Selecione um arquivo', erro: true);
      return;
    }
    if (_empresaFiltroId == null) {
      _snack('Empresa é obrigatória', erro: true);
      return;
    }
    setState(() => _enviando = true);
    try {
      final token = AuthUtility.userInfo?.token ?? '';
      final uri = Uri.parse(ApiLinks.uploadArquivo);
      final req = http.MultipartRequest('POST', uri);
      if (token.isNotEmpty) req.headers['Authorization'] = 'Bearer $token';

      req.files.add(http.MultipartFile.fromBytes(
        'file',
        _arquivoSelecionado!.bytes!,
        filename: _arquivoSelecionado!.name,
      ));
      req.fields['fileName'] = _arquivoSelecionado!.name;
      req.fields['fileType'] =
          gedMimeTypeForFileName(_arquivoSelecionado!.name);
      req.fields['diretorio'] = '{"id":${_diretorioUploadId ?? 0}}';
      req.fields['empresa'] = '{"id":$_empresaFiltroId}';
      req.fields['parceiro'] = '{"id":${_parceiroUploadId ?? 0}}';
      req.fields['diasRetencao'] = _diasRetencaoUpload.toString();
      if (_descricaoChatUploadCtrl.text.trim().isNotEmpty) {
        req.fields['descricaoChat'] = _descricaoChatUploadCtrl.text.trim();
      }
      req.fields['modulo'] = resolveGedUploadModule(_moduloOrigemFiltro);
      if (_idOrigemFiltro != null)
        req.fields['idOrigem'] = _idOrigemFiltro.toString();

      final resp = await req.send();
      if (!mounted) return;
      if (resp.statusCode == 200) {
        Navigator.of(ctx).pop();
        setState(() => _arquivoSelecionado = null);
        _snack('Arquivo enviado com sucesso!');
        await _buscarArquivos();
      } else {
        _snack('Erro no upload: ${resp.statusCode}', erro: true);
        AppLogger.i.warn('[GED] Erro no upload (status ${resp.statusCode})');
      }
    } catch (e, st) {
      _snack('Erro: $e', erro: true);
      AppLogger.i.error('[GED] Erro no upload: $e', st);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Download
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _baixarArquivo(Map<String, dynamic> arq) async {
    final id = arq['id'];
    final nome = arq['fileName'] ?? 'arquivo';
    final url = ApiLinks.downloadArquivo(id.toString());
    try {
      final token = AuthUtility.userInfo?.token ?? '';
      final uri = Uri.parse(url);
      final resp = await http.get(uri,
          headers: token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {});
      if (resp.statusCode == 200) {
        await FileSaver.instance.saveFile(name: nome, bytes: resp.bodyBytes);
        _snack('Download concluído: $nome');
      } else {
        _snack('Erro ao baixar: ${resp.statusCode}', erro: true);
      }
    } catch (e) {
      _snack('Erro: $e', erro: true);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Edição (rename)
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> _salvarEdicaoNome(
      Map<String, dynamic> arq, String novoNome) async {
    final r = await NetworkCaller().putRequest(
      ApiLinks.updateArquivo(arq['id'].toString()),
      {'fileName': novoNome},
    );
    if (r.isSuccess) {
      _snack('Nome atualizado');
      await _buscarArquivos();
      return true;
    }
    _snack('Erro ao atualizar', erro: true);
    return false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Classificação com IA
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _classificarArquivo(Map<String, dynamic> arq) async {
    try {
      final result = await AiAssistantService().classifyDocument(
        fileName: arq['fileName']?.toString(),
        fileType: arq['fileType']?.toString(),
        description: [
          arq['diretorioNome']?.toString(),
          arq['parceiroNome']?.toString(),
        ].whereType<String>().join(' '),
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Classificação do documento'),
          content: Text(
            'Categoria: ${result.category}\n'
            'Confiança: ${((double.tryParse(result.confidence.toString()) ?? 0) * 100).toStringAsFixed(0)}%\n'
            'Status sugerido: ${result.suggestedStatus}\n'
            'Tags: ${result.tags.join(', ')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      _snack('Erro ao classificar documento: $e', erro: true);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Delete
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _confirmarDelete(Map<String, dynamic> arq) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Remover "${arq['fileName']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final r = await NetworkCaller()
          .deleteRequest(ApiLinks.deleteArquivo(arq['id'].toString()));
      if (r.isSuccess) {
        _snack('Arquivo removido');
        await _buscarArquivos();
      } else {
        _snack('Erro ao remover', erro: true);
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  String get _tituloAppBar {
    if (widget.moduloOrigem != null && widget.nomeOrigem != null) {
      return 'GED — ${_capitalize(widget.moduloOrigem!)} · ${widget.nomeOrigem}';
    }
    return 'GED — Gestão Eletrônica de Documentos';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // Quando embutido em tab (contextualizado), o pai já tem AppBar — suprimir o nosso
      appBar: _contextualizado
          ? null
          : widget.useUserBannerHeader
              ? UserBannerAppBar(
                  screenTitle: _tituloAppBar,
                  showFilterButton: false,
                  onUserTap: widget.onUserBannerTapped,
                )
              : AppBar(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  title: Text(_tituloAppBar),
                  elevation: 0,
                  actions: [
                    if (widget.moduloOrigem != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 4),
                        child: Chip(
                          label: Text(
                            _capitalize(widget.moduloOrigem!),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white),
                          ),
                          backgroundColor: GridColors.primary,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.upload_file),
                      tooltip: 'Novo Upload',
                      onPressed:
                          _empresaFiltroId != null ? _abrirDialogUpload : null,
                    ),
                    // Alertas e logout padrão do sistema
                    const AppBarActions(),
                    const SizedBox(width: 4),
                  ],
                ),
      floatingActionButton: (!_contextualizado && widget.useUserBannerHeader)
          ? FloatingActionButton.small(
              heroTag: 'ged_upload_fab',
              tooltip: 'Novo Upload',
              backgroundColor: GridColors.primary,
              onPressed: _empresaFiltroId != null ? _abrirDialogUpload : null,
              child: const Icon(Icons.upload_file, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          if (!_contextualizado) _buildFiltros(),
          if (_contextualizado) _buildBarraContextualizada(),
          Expanded(child: _buildGridCards()),
        ],
      ),
    );
  }

  // Barra compacta de busca + upload quando GED é embutido em tab (sem AppBar próprio)
  Widget _buildBarraContextualizada() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar arquivo...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Recarregar',
            onPressed: _carregando ? null : _buscarArquivos,
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            icon: const Icon(Icons.upload_file, size: 18),
            label: const Text('Upload'),
            onPressed: _empresaFiltroId != null ? _abrirDialogUpload : null,
          ),
        ],
      ),
    );
  }

  // ── Barra de filtros ──────────────────────────────────────────────────────
  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 200,
            child: _buildDropdown<int>(
              label: 'Empresa *',
              value: _empresaFiltroId,
              items: _empresas
                  .map((e) => DropdownMenuItem<int>(
                        value: e['id'] as int?,
                        child: Text(e['nome']?.toString() ?? ''),
                      ))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _empresaFiltroId = v;
                  _empresaFiltroNome = _empresas
                      .firstWhere((e) => e['id'] == v, orElse: () => {})['nome']
                      ?.toString();
                  _parceiroFiltroId = null;
                  _parceiroFiltroNome = null;
                  _parceiroUploadId = null;
                  _parceiroUploadNome = null;
                  _arquivos = [];
                });
              },
              icon: Icons.business,
            ),
          ),
          SizedBox(
            width: 200,
            child: _buildParceiroBuscaField(
              label: 'Parceiro/Cliente',
              placeholder: 'Todos',
              enabled: _empresaFiltroId != null,
              empresaId: _empresaFiltroId,
              valorId: _parceiroFiltroId,
              valorNome: _parceiroFiltroNome,
              onSelecionado: (id, nome) => setState(() {
                _parceiroFiltroId = id;
                _parceiroFiltroNome = nome;
              }),
            ),
          ),
          SizedBox(
            width: 180,
            child: TextField(
              decoration: _inputDecoration('Buscar por nome...', Icons.search),
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            icon: const Icon(Icons.filter_alt),
            label: const Text('Filtrar'),
            onPressed: _carregando ? null : _buscarArquivos,
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            icon: const Icon(Icons.upload),
            label: const Text('Novo Upload'),
            onPressed: _empresaFiltroId != null ? _abrirDialogUpload : null,
          ),
        ],
      ),
    );
  }

  // ── Grid de Cards ─────────────────────────────────────────────────────────
  // ── Árvore de Diretórios ──────────────────────────────────────────────────
  Widget _buildGridCards() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtrados = _arquivos.where((a) {
      final nome = (a['fileName'] ?? '').toString().toLowerCase();
      return _busca.isEmpty || nome.contains(_busca.toLowerCase());
    }).toList();

    if (filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              _empresaFiltroId == null && !_contextualizado
                  ? 'Selecione uma empresa e clique em Filtrar'
                  : 'Nenhum arquivo encontrado',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Agrupa por diretório (null/vazio → "Sem pasta")
    final Map<String, List<Map<String, dynamic>>> grupos = {};
    for (final arq in filtrados) {
      final dir = arq['diretorioNome']?.toString().trim();
      final chave = (dir == null || dir.isEmpty) ? 'Sem pasta' : dir;
      grupos.putIfAbsent(chave, () => []).add(arq);
    }

    // Ordena as chaves: "Sem pasta" por último
    final chaves = grupos.keys.toList()
      ..sort((a, b) {
        if (a == 'Sem pasta') return 1;
        if (b == 'Sem pasta') return -1;
        return a.compareTo(b);
      });

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: chaves.map((chave) {
        final itens = grupos[chave]!;
        return _buildDiretorioSecao(chave, itens);
      }).toList(),
    );
  }

  Widget _buildDiretorioSecao(
      String nomeDir, List<Map<String, dynamic>> itens) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: GridColors.divider),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Icon(
          nomeDir == 'Sem pasta' ? Icons.inbox : Icons.folder,
          color: nomeDir == 'Sem pasta' ? Colors.grey : GridColors.secondary,
        ),
        title: Text(
          nomeDir,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: GridColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${itens.length}',
                style: const TextStyle(
                    fontSize: 12,
                    color: GridColors.primary,
                    fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          LayoutBuilder(
            builder: (ctx, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(10),
                gridDelegate: gedFileGridDelegate(constraints.maxWidth),
                itemCount: itens.length,
                itemBuilder: (context, index) => _buildCard(itens[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Card individual ───────────────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> arq) {
    final podeExcluir =
        arq['usuarioUploadId']?.toString() == TenantContext.userId?.toString();

    return GedFileCard(
      arq: arq,
      podeExcluir: podeExcluir,
      onDownload: () => _baixarArquivo(arq),
      onDelete: () => _confirmarDelete(arq),
      onRename: (novoNome) => _salvarEdicaoNome(arq, novoNome),
      onClassify: () => _classificarArquivo(arq),
    );
  }

  // ── Dialog Upload ─────────────────────────────────────────────────────────
  void _abrirDialogUpload() {
    setState(() {
      _arquivoSelecionado = null;
      _diretorioUploadId = null;
      _parceiroUploadId =
          _contextoParceiro ? widget.idOrigem : _parceiroFiltroId;
      _parceiroUploadNome =
          _contextoParceiro ? widget.nomeOrigem : _parceiroFiltroNome;
      _diasRetencaoUpload = 30;
      _descricaoChatUploadCtrl.clear();
    });

    showDialog(
      context: context,
      barrierDismissible: !_enviando,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.upload_file, color: GridColors.secondary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.moduloOrigem != null && widget.nomeOrigem != null
                      ? 'Upload — ${_capitalize(widget.moduloOrigem!)} · ${widget.nomeOrigem}'
                      : 'Upload de Arquivo${_empresaFiltroNome != null ? ' — $_empresaFiltroNome' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Indicador de módulo de origem
                if (_moduloOrigemFiltro != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: GridColors.secondary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: GridColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link,
                            size: 16, color: GridColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          'Módulo: ${_capitalize(_moduloOrigemFiltro!)}${_idOrigemFiltro != null ? '  #$_idOrigemFiltro' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: GridColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Diretório
                _buildDropdown<int>(
                  label: 'Diretório',
                  value: _diretorioUploadId,
                  items: [
                    const DropdownMenuItem<int>(
                        value: null, child: Text('Sem diretório')),
                    ..._diretorios.map((d) => DropdownMenuItem<int>(
                          value: d['id'] as int?,
                          child: Text(d['nome']?.toString() ?? ''),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _diretorioUploadId = v);
                    setStateDialog(() {});
                  },
                  icon: Icons.folder,
                ),
                const SizedBox(height: 12),
                if (!_contextoParceiro) ...[
                  _buildParceiroBuscaField(
                    label: 'Parceiro/Cliente (opcional)',
                    placeholder: 'Sem parceiro',
                    empresaId: _empresaFiltroId,
                    valorId: _parceiroUploadId,
                    valorNome: _parceiroUploadNome,
                    onSelecionado: (id, nome) {
                      setState(() {
                        _parceiroUploadId = id;
                        _parceiroUploadNome = nome;
                      });
                      setStateDialog(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 4),
                // Seletor de arquivo
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _arquivoSelecionado != null
                        ? _arquivoSelecionado!.name
                        : 'Selecionar Arquivo',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: GridColors.secondary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    await _selecionarArquivo();
                    setStateDialog(() {});
                  },
                ),
                if (_arquivoSelecionado != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Tamanho: ${(_arquivoSelecionado!.size / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                _buildDropdown<int>(
                  label: 'Tempo de permanência no servidor',
                  value: _diasRetencaoUpload,
                  items: _opcoesDiasRetencao.entries
                      .map((e) => DropdownMenuItem<int>(
                            value: e.key,
                            child: Text(e.value),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _diasRetencaoUpload = v ?? 30);
                    setStateDialog(() {});
                  },
                  icon: Icons.schedule,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descricaoChatUploadCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descrição / período (opcional)',
                    helperText:
                        'Usado pelo Chat para localizar e enviar este arquivo quando o '
                        'cliente pedir (ex.: "boleto de água de agosto").',
                    helperMaxLines: 2,
                    prefixIcon: Icon(Icons.chat_outlined),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  minLines: 1,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _enviando ? null : () => Navigator.of(ctx).pop(),
              child: const Text(GridTexts.cancel),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.secondary,
                foregroundColor: Colors.white,
              ),
              icon: _enviando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload),
              label: Text(_enviando ? 'Enviando...' : 'Fazer Upload'),
              onPressed: _enviando ? null : () => _fazerUpload(ctx),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Widgets auxiliares
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData icon,
    bool enabled = true,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      decoration: _inputDecoration(label, icon),
      items: items,
      onChanged: enabled ? onChanged : null,
    );
  }

  /// Campo de Parceiro/Cliente com busca remota (LIKE multi-campo + scroll
  /// infinito) — mesmo padrão já usado em Contas a Pagar/Receber (card 580).
  /// Substitui o antigo dropdown simples (GET /api/parceiro/empresa/{id} sem
  /// paginação, só os 25 primeiros, sem filtro) pelo mesmo componente
  /// (RemoteDropdownSearchDialog) usado no resto do sistema.
  Widget _buildParceiroBuscaField({
    required String label,
    required String placeholder,
    required int? empresaId,
    required int? valorId,
    required String? valorNome,
    required void Function(int? id, String? nome) onSelecionado,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: !enabled
          ? null
          : () async {
              final resultado = await showDialog<Map<String, dynamic>>(
                context: context,
                builder: (_) => RemoteDropdownSearchDialog(
                  title: label,
                  valueField: 'id',
                  displayField: 'nome',
                  currentValue: valorId?.toString(),
                  loadPage: ({busca, required pagina}) =>
                      DropdownHelpers.parceirosBusca(
                    busca: busca,
                    pagina: pagina,
                    empresaId: empresaId?.toString(),
                  ),
                ),
              );
              if (resultado == null) return;
              if (resultado.isEmpty) {
                onSelecionado(null, null);
                return;
              }
              onSelecionado(
                int.tryParse(resultado['id']?.toString() ?? ''),
                resultado['nome']?.toString(),
              );
            },
      child: InputDecorator(
        decoration: _inputDecoration(label, Icons.person).copyWith(
          suffixIcon: const Icon(Icons.arrow_drop_down),
          enabled: enabled,
        ),
        child: Text(
          valorNome ?? placeholder,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valorNome == null ? Colors.grey.shade600 : null,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: GridColors.secondary),
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    );
  }

  void _snack(String msg, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          Icon(
            erro ? Icons.error_outline : Icons.check_circle_outline,
            color: erro ? Colors.white : GridColors.successDark,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                color: erro ? Colors.white : GridColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: erro ? GridColors.error : GridColors.successLight,
      duration: const Duration(seconds: 3),
    ));
  }
}
