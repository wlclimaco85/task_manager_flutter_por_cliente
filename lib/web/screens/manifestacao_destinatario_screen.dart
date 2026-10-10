import 'package:flutter/material.dart';
import '../../services/manifestacao_caller.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

/// Tela de Manifestação do Destinatário de NFe (Windows).
///
/// Contrato real do backend (ManifestacaoDestinatarioController):
/// - POST /api/fiscal/manifestacao { nfeChave, tipoEvento, justificativa }
/// - GET  /api/fiscal/manifestacao/pendentes (empresaId opcional; quando
///   omitido pelo cliente, como aqui, o backend usa o tenant da sessão)
/// - GET  /api/fiscal/manifestacao/historico (idem; período default 30 dias)
/// tipoEvento aceito: CIENCIA, CONFIRMACAO, DESCONHECIMENTO, NAO_REALIZADA.
/// Justificativa é obrigatória apenas para CONFIRMACAO e NAO_REALIZADA.
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

  /// Abre o formulário de manifestação. Quando [item] é informado, a chave da
  /// NFe vem pré-preenchida e somente leitura; caso contrário (botão "Nova
  /// Manifestação"), o usuário digita a chave manualmente — não existe
  /// endpoint no backend que liste NFes aguardando manifestação por chave.
  Future<void> _abrirDialogManifestacao({Map<String, dynamic>? item}) async {
    final chaveExistente = item != null
        ? (item['nfeChave']?.toString() ?? '')
        : '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => _ManifestacaoFormDialog(
        titulo: item != null
            ? GridTexts.registerManifestation
            : GridTexts.newManifestation,
        chaveExistente: chaveExistente,
        chaveEditavel: item == null,
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _mensagemErro = null);
    final response = await ManifestacaoCaller.registrarManifestacao(
      nfeChave: result['nfeChave']!,
      tipoEvento: result['tipoEvento']!,
      justificativa:
          result['justificativa']!.isEmpty ? null : result['justificativa'],
    );
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.success
          ? GridTexts.manifestationRegisteredSuccess
          : response.message ?? GridTexts.error),
      backgroundColor:
          response.success ? GridColors.success : GridColors.error,
    ));

    if (response.success) {
      // Sequencial (não em paralelo): as duas chamadas compartilham
      // _mensagemErro, disparar em paralelo permite que uma sobrescreva o
      // resultado da outra dependendo do timing de rede.
      await _carregarPendentes();
      if (!mounted) return;
      await _carregarHistorico();
    }
  }

  String _traduzirTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case ManifestacaoTipoEvento.ciencia:
        return GridTexts.cienciaLabel;
      case ManifestacaoTipoEvento.confirmacao:
        return GridTexts.confirmation;
      case ManifestacaoTipoEvento.desconhecimento:
        return GridTexts.unknownLabel;
      case ManifestacaoTipoEvento.naoRealizada:
        return GridTexts.notPerformedLabel;
      default:
        return tipo;
    }
  }

  Color _corTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case ManifestacaoTipoEvento.ciencia:
        return GridColors.info;
      case ManifestacaoTipoEvento.confirmacao:
        return GridColors.success;
      case ManifestacaoTipoEvento.desconhecimento:
        return GridColors.statusUnknown;
      case ManifestacaoTipoEvento.naoRealizada:
        return GridColors.error;
      default:
        return GridColors.neutral;
    }
  }

  Color _corStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ENVIADO':
        return GridColors.success;
      case 'ERRO':
        return GridColors.error;
      default:
        return GridColors.info;
    }
  }

  String _formatarChave(String chave) {
    if (chave.length != 44) return chave;
    final buffer = StringBuffer();
    for (var i = 0; i < chave.length; i += 4) {
      if (i > 0) buffer.write(' ');
      buffer.write(chave.substring(i, i + 4 > chave.length ? chave.length : i + 4));
    }
    return buffer.toString();
  }

  /// Abaixo de 700px (mobile 320-480px) a tela usa layout em cards em vez de
  /// DataTable com scroll horizontal, que é ruim de usar em telas pequenas.
  static const double _mobileBreakpoint = 700;

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < _mobileBreakpoint;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        title: const Text(GridTexts.manifestRecipientTitle),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: isMobile
                ? IconButton(
                    tooltip: GridTexts.newManifestation,
                    onPressed: () => _abrirDialogManifestacao(),
                    icon: const Icon(Icons.add_circle, size: 26),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.secondary,
                      foregroundColor: GridColors.textPrimary,
                    ),
                    onPressed: () => _abrirDialogManifestacao(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(GridTexts.newManifestation),
                  ),
          ),
        ],
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
      return _buildErroState(_mensagemErro!, _carregarPendentes);
    }

    if (_pendentes.isEmpty) {
      return _buildVazioState(
        Icons.check_circle_outline,
        GridTexts.noPendingFound,
        _carregarPendentes,
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
          if (_isMobile(context))
            Column(
              children: _pendentes.map((entry) {
                final item = entry is Map<String, dynamic>
                    ? entry
                    : <String, dynamic>{};
                final chave = (item['nfeChave'] ?? '-').toString();
                final tipo = (item['tipoEvento'] ?? '-').toString();
                final justificativa = (item['justificativa'] ?? '-').toString();
                final status = (item['status'] ?? GridTexts.pendingStatus).toString();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                  chave.length == 44 ? _formatarChave(chave) : chave,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTipoBadge(tipo),
                        if (justificativa != '-') ...[
                          const SizedBox(height: 8),
                          Text(justificativa, style: const TextStyle(fontSize: 12)),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Card(
              elevation: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text(GridTexts.accessKey)),
                    DataColumn(label: Text(GridTexts.type)),
                    DataColumn(label: Text(GridTexts.justification)),
                    DataColumn(label: Text(GridTexts.status)),
                  ],
                  rows: _pendentes.asMap().entries.map((entry) {
                    final item = entry.value is Map<String, dynamic>
                        ? entry.value as Map<String, dynamic>
                        : <String, dynamic>{};
                    final chave = (item['nfeChave'] ?? '-').toString();
                    final tipo = (item['tipoEvento'] ?? '-').toString();
                    final justificativa = (item['justificativa'] ?? '-').toString();
                    final status = (item['status'] ?? GridTexts.pendingStatus).toString();
                    return DataRow(cells: [
                      DataCell(Text(
                          chave.length == 44 ? _formatarChave(chave) : chave,
                          style: const TextStyle(fontSize: 12))),
                      DataCell(_buildTipoBadge(tipo)),
                      DataCell(Text(justificativa,
                          style: const TextStyle(fontSize: 12))),
                      DataCell(_buildStatusBadge(status)),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoricoTab() {
    if (_carregandoHistorico) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_mensagemErro != null && _historico.isEmpty) {
      return _buildErroState(_mensagemErro!, _carregarHistorico);
    }

    if (_historico.isEmpty) {
      return _buildVazioState(
        Icons.history,
        GridTexts.noManifestationDone,
        _carregarHistorico,
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
          if (_isMobile(context))
            Column(
              children: _historico.map((entry) {
                final item = entry is Map<String, dynamic>
                    ? entry
                    : <String, dynamic>{};
                final chave = (item['nfeChave'] ?? '-').toString();
                final tipo = (item['tipoEvento'] ?? '-').toString();
                final protocolo = (item['protocolo'] ?? '-').toString();
                final data = (item['dataEvento'] ?? '-').toString();
                final status = (item['status'] ?? '-').toString();
                final erro = item['erro']?.toString();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                  chave.length == 44 ? _formatarChave(chave) : chave,
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTipoBadge(tipo),
                        const SizedBox(height: 8),
                        Text('${GridTexts.protocol}: $protocolo | ${GridTexts.date}: $data',
                            style: const TextStyle(fontSize: 11, color: GridColors.neutral)),
                        if (erro != null && erro.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(erro,
                              style: const TextStyle(fontSize: 11, color: GridColors.error)),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Card(
              elevation: 2,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text(GridTexts.accessKey)),
                    DataColumn(label: Text(GridTexts.type)),
                    DataColumn(label: Text(GridTexts.protocol)),
                    DataColumn(label: Text(GridTexts.date)),
                    DataColumn(label: Text(GridTexts.status)),
                  ],
                  rows: _historico.asMap().entries.map((entry) {
                    final item = entry.value is Map<String, dynamic>
                        ? entry.value as Map<String, dynamic>
                        : <String, dynamic>{};
                    final chave = (item['nfeChave'] ?? '-').toString();
                    final tipo = (item['tipoEvento'] ?? '-').toString();
                    final protocolo = (item['protocolo'] ?? '-').toString();
                    final data = (item['dataEvento'] ?? '-').toString();
                    final status = (item['status'] ?? '-').toString();
                    final erro = item['erro']?.toString();
                    return DataRow(cells: [
                      DataCell(Text(
                          chave.length == 44 ? _formatarChave(chave) : chave,
                          style: const TextStyle(fontSize: 12))),
                      DataCell(_buildTipoBadge(tipo)),
                      DataCell(Text(protocolo,
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Text(data,
                          style: const TextStyle(fontSize: 12))),
                      DataCell(Tooltip(
                        message: erro ?? '',
                        child: _buildStatusBadge(status),
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErroState(String mensagem, VoidCallback onRetry) {
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
              Text(mensagem,
                  style: const TextStyle(color: GridColors.error, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: GridColors.textPrimary,
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(GridTexts.retryAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVazioState(IconData icon, String mensagem, VoidCallback onRetry) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 64, color: GridColors.neutral),
              const SizedBox(height: 16),
              Text(mensagem,
                  style: const TextStyle(fontSize: 16, color: GridColors.neutral)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.secondary,
                  foregroundColor: GridColors.textPrimary,
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(GridTexts.reload),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipoBadge(String tipo) {
    final label = _traduzirTipo(tipo);
    final cor = _corTipo(tipo);
    // WCAG a11y FIX (card P2-502): rotulo explicito "Tipo de manifestacao: X"
    // para screen reader (o texto visivel sozinho ja e legivel, mas o
    // Semantics evita ambiguidade quando o badge aparece ao lado de outros
    // textos curtos na mesma linha/celula da tabela).
    return Semantics(
      label: '${GridTexts.manifestationType}: $label',
      // excludeSemantics: true (achado real do code review - WR-01): sem
      // isso, o Icon.semanticLabel e o Text filhos tambem geram conteudo
      // de semantics, resultando em leitor de tela anunciando o texto
      // duplicado (ex: "Tipo de Manifestação: X\nX"). Confirmado
      // empiricamente via debugDumpSemanticsTree() em teste de widget.
      excludeSemantics: true,
      child: Container(
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
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final cor = _corStatus(status);
    IconData icone;
    String label;
    switch (status.toUpperCase()) {
      case 'ENVIADO':
        icone = Icons.check_circle;
        label = GridTexts.sent;
        break;
      case 'ERRO':
        icone = Icons.error;
        label = GridTexts.error;
        break;
      default:
        icone = Icons.schedule;
        label = GridTexts.pending;
    }
    // WCAG a11y FIX (card P2-502): Semantics agrupa icone+texto numa unica
    // leitura coerente para screen reader ("Status: Enviado" em vez de
    // "check circle, Enviado" separados); mesmo padrao ja usado em
    // nfse_detail_screen.dart (Icon(..., semanticLabel: ...)).
    return Semantics(
      label: '${GridTexts.status}: $label',
      // excludeSemantics: true (achado real do code review - WR-01): sem
      // isso, o Icon.semanticLabel e o Text filhos tambem geram conteudo
      // de semantics, resultando em leitor de tela anunciando o texto
      // duplicado (ex: "Status: Enviado\nEnviado\nEnviado"). Confirmado
      // empiricamente via debugDumpSemanticsTree() em teste de widget.
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 12, color: cor, semanticLabel: label),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Conteúdo do diálogo de nova manifestação/manifestação de item pendente.
/// Extraído como StatefulWidget próprio (em vez de controllers locais numa
/// função async + StatefulBuilder) para que o Flutter dispose os
/// TextEditingController automaticamente quando o diálogo é removido da
/// árvore — evita o vazamento de memória de criar controllers a cada
/// abertura do formulário sem um dono com ciclo de vida garantido.
class _ManifestacaoFormDialog extends StatefulWidget {
  final String titulo;
  final String chaveExistente;
  final bool chaveEditavel;

  const _ManifestacaoFormDialog({
    required this.titulo,
    required this.chaveExistente,
    required this.chaveEditavel,
  });

  @override
  State<_ManifestacaoFormDialog> createState() =>
      _ManifestacaoFormDialogState();
}

class _ManifestacaoFormDialogState extends State<_ManifestacaoFormDialog> {
  late final TextEditingController _chaveController =
      TextEditingController(text: widget.chaveExistente);
  late final TextEditingController _justificativaController =
      TextEditingController();

  String _tipoSelecionado = ManifestacaoTipoEvento.ciencia;
  bool _requerJustificativa = false;
  String? _erroChave;
  String? _erroJustificativa;

  @override
  void dispose() {
    _chaveController.dispose();
    _justificativaController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final chave = _chaveController.text.trim();
    bool valido = true;
    setState(() {
      if (!RegExp(r'^\d{44}$').hasMatch(chave)) {
        _erroChave = GridTexts.accessKeyInvalidLength;
        valido = false;
      }
      if (_requerJustificativa && _justificativaController.text.trim().isEmpty) {
        _erroJustificativa = GridTexts.manifestationJustificationRequired;
        valido = false;
      }
    });
    if (!valido) return;
    Navigator.pop(context, {
      'nfeChave': chave,
      'tipoEvento': _tipoSelecionado,
      'justificativa': _justificativaController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titulo),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _chaveController,
              readOnly: !widget.chaveEditavel,
              maxLength: 44,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: GridTexts.accessKeyFieldLabel,
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: _erroChave,
                counterText: '',
              ),
              onChanged: (_) => setState(() => _erroChave = null),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tipoSelecionado,
              decoration: const InputDecoration(
                labelText: GridTexts.manifestationType,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                    value: ManifestacaoTipoEvento.ciencia,
                    child: Text(GridTexts.cienciaLabel)),
                DropdownMenuItem(
                    value: ManifestacaoTipoEvento.confirmacao,
                    child: Text(GridTexts.confirmation)),
                DropdownMenuItem(
                    value: ManifestacaoTipoEvento.desconhecimento,
                    child: Text(GridTexts.unknownLabel)),
                DropdownMenuItem(
                    value: ManifestacaoTipoEvento.naoRealizada,
                    child: Text(GridTexts.notPerformedLabel)),
              ],
              onChanged: (v) {
                setState(() {
                  _tipoSelecionado = v!;
                  _requerJustificativa =
                      ManifestacaoTipoEvento.exigeJustificativa(v);
                  _erroJustificativa = null;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _justificativaController,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: _requerJustificativa
                    ? GridTexts.justificationRequired
                    : GridTexts.justificationOptional,
                border: const OutlineInputBorder(),
                isDense: true,
                errorText: _erroJustificativa,
              ),
              maxLines: 3,
              onChanged: (_) => setState(() => _erroJustificativa = null),
            ),
            if (_requerJustificativa && _erroJustificativa == null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  GridTexts.manifestationJustificationHint,
                  style: TextStyle(color: GridColors.error, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.secondary,
            foregroundColor: GridColors.textPrimary,
          ),
          child: const Text(GridTexts.confirm),
        ),
      ],
    );
  }
}
