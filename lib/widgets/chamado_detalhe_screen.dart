import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/auth_utility.dart';
import '../models/chamado_model.dart';
import '../services/chamado_caller.dart';
import '../services/chat_caller.dart';
import '../utils/grid_colors.dart';
import 'anexo_financeiro_widget.dart';

/// Tela de detalhe/timeline do Chamado — card Trello #451.
///
/// Mostra cabeçalho com os dados do chamado, timeline de eventos
/// (comentários humanos + eventos automáticos do workflow), compositor de
/// comentário, acesso aos anexos multi-arquivo e barra de ações
/// (fechar/reabrir/atribuir/transferir/retornar/notificar empresa).
///
/// Usada nas três plataformas (web/windows via [detailScreenBuilder] do
/// DynamicGridWindowsScreen, mobile via Navigator.push a partir da lista
/// agrupada por setor).
class ChamadoDetalheScreen extends StatefulWidget {
  final Chamado chamado;

  /// Fix (card #473): callback opcional que abre a tela de Chat/Atendimento
  /// (específica por plataforma) já com a conversa deste chamado
  /// selecionada. Cada tela de plataforma (web/windows/mobile) que
  /// instancia ChamadoDetalheScreen fornece sua própria navegação -- este
  /// widget compartilhado não importa nenhuma tela de chat diretamente.
  final void Function(BuildContext context, Chamado chamado)? onAbrirChat;

  const ChamadoDetalheScreen({super.key, required this.chamado, this.onAbrirChat});

  @override
  State<ChamadoDetalheScreen> createState() => _ChamadoDetalheScreenState();
}

class _ChamadoDetalheScreenState extends State<ChamadoDetalheScreen> {
  final _caller = ChamadoCaller();
  final _comentarioController = TextEditingController();

  late Chamado _chamado;
  List<Map<String, dynamic>> _historico = [];
  bool _carregandoHistorico = true;
  bool _enviandoComentario = false;
  bool _executandoAcao = false;
  String? _erroHistorico;

  int get _usuarioId =>
      AuthUtility.userInfo?.data?.id ?? AuthUtility.userInfo?.login?.id ?? 0;

  @override
  void initState() {
    super.initState();
    _chamado = widget.chamado;
    _comentarioController.addListener(() => setState(() {}));
    _carregarHistorico();
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  // ── Dados ──────────────────────────────────────────────────────────────

  Future<void> _carregarHistorico() async {
    setState(() {
      _carregandoHistorico = true;
      _erroHistorico = null;
    });
    try {
      final historico = await _caller.getHistoricoChamado(_chamado.id ?? 0);
      historico.sort((a, b) => (a['dataEvento'] ?? '')
          .toString()
          .compareTo((b['dataEvento'] ?? '').toString()));
      if (mounted) setState(() => _historico = historico);
    } catch (e) {
      if (mounted) setState(() => _erroHistorico = 'Erro ao carregar histórico: $e');
    } finally {
      if (mounted) setState(() => _carregandoHistorico = false);
    }
  }

  Future<void> _enviarComentario() async {
    final texto = _comentarioController.text.trim();
    if (texto.isEmpty || _chamado.id == null) return;
    setState(() => _enviandoComentario = true);
    try {
      await _caller.comentarChamado(_chamado.id!, _usuarioId, texto);
      _comentarioController.clear();
      await _carregarHistorico();
    } catch (e) {
      _mostrarSnack('Erro ao enviar comentário: $e', erro: true);
    } finally {
      if (mounted) setState(() => _enviandoComentario = false);
    }
  }

  Future<void> _executarAcao(
      Future<bool> Function() acao, String mensagemSucesso) async {
    if (_chamado.id == null || _executandoAcao) return;
    setState(() => _executandoAcao = true);
    try {
      final ok = await acao();
      if (ok) {
        _mostrarSnack(mensagemSucesso, erro: false);
        await _carregarHistorico();
      } else {
        _mostrarSnack('Não foi possível concluir a ação', erro: true);
      }
    } catch (e) {
      _mostrarSnack('Erro: $e', erro: true);
    } finally {
      if (mounted) setState(() => _executandoAcao = false);
    }
  }

  Future<void> _reabrir() => _executarAcao(
      () => _caller.reabrirChamado(_chamado.id!, _usuarioId), 'Chamado reaberto');

  Future<void> _notificarEmpresa() => _executarAcao(
      () => _caller.notificarEmpresaChamado(_chamado.id!, _usuarioId),
      'Notificação enviada para a empresa');

  Future<void> _fechar() async {
    final motivo = await _pedirTexto(
      titulo: 'Fechar chamado',
      label: 'Descreva a solução',
      multilinha: true,
    );
    if (motivo == null || motivo.trim().isEmpty) return;
    await _executarAcao(
        () => _caller.fecharChamado(_chamado.id!, motivo, _usuarioId),
        'Chamado fechado');
  }

  Future<void> _atribuir() async {
    final destino = await _pedirUsuarioDoSetor('Atribuir chamado');
    if (destino == null) return;
    await _executarAcao(
        () => _caller.atribuirChamado(_chamado.id!, destino), 'Chamado atribuído');
  }

  Future<void> _transferir() async {
    final destino = await _pedirUsuarioDoSetor('Transferir chamado');
    if (destino == null) return;
    await _executarAcao(
        () => _caller.transferirChamado(_chamado.id!, destino, _usuarioId),
        'Chamado transferido');
  }

  Future<void> _retornar() async {
    final destino = await _pedirUsuarioDoSetor('Retornar chamado');
    if (destino == null) return;
    await _executarAcao(
        () => _caller.retornarChamado(_chamado.id!, _usuarioId, destino),
        'Chamado retornado');
  }

  // Dropdown com os funcionarios do setor do chamado (em vez de pedir o ID
  // do usuario destino digitado a mao) -- reaproveita
  // ChatCaller.fetchUsuariosSetor, ja usado no dialogo de transferencia de
  // chat (chat_transfer_dialog.dart).
  Future<int?> _pedirUsuarioDoSetor(String titulo) async {
    final setorNome = _chamado.setor?.nome;
    if (setorNome == null || setorNome.isEmpty) {
      _mostrarSnack('Chamado sem setor definido — não é possível listar funcionários.',
          erro: true);
      return null;
    }
    final usuarios = await ChatCaller().fetchUsuariosSetor(setorNome);
    if (!mounted) return null;
    if (usuarios.isEmpty) {
      _mostrarSnack('Nenhum funcionário encontrado no setor "$setorNome".', erro: true);
      return null;
    }

    String? selecionado;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text(titulo),
          content: DropdownButtonFormField<String>(
            value: selecionado,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Funcionário',
              border: OutlineInputBorder(),
            ),
            items: usuarios
                .map((u) => DropdownMenuItem(value: u['id'], child: Text(u['nome'] ?? '')))
                .toList(),
            onChanged: (v) => setStateDialog(() => selecionado = v),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: selecionado == null ? null : () => Navigator.pop(ctx, selecionado),
              style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary, foregroundColor: Colors.white),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
    return int.tryParse(result ?? '');
  }

  Future<String?> _pedirTexto({
    required String titulo,
    required String label,
    bool numerico = false,
    bool multilinha = false,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: numerico ? TextInputType.number : TextInputType.multiline,
          maxLines: multilinha ? 4 : 1,
          decoration:
              InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.primary, foregroundColor: Colors.white),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _mostrarSnack(String mensagem, {required bool erro}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(mensagem, style: const TextStyle(color: Colors.white)),
      backgroundColor: erro ? GridColors.error : GridColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  void _abrirAnexos() {
    if (_chamado.id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, __) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AnexoFinanceiroWidget(
            lancamentoId: _chamado.id!,
            lancamentoTipo: 'CHAMADO',
            empresaId: _chamado.empresa.id,
            // Fix (card #468): anexo era salvo mas nunca aparecia na
            // timeline "Histórico e comentários" -- registra o evento no
            // backend e recarrega o histórico assim que o upload confirma.
            onAnexoSalvo: (nomeArquivo) async {
              await _caller.registrarAnexoChamado(
                  _chamado.id!, _usuarioId, nomeArquivo);
              await _carregarHistorico();
            },
          ),
        ),
      ),
    );
  }

  // ── Estilo ─────────────────────────────────────────────────────────────

  Color _corStatus(StatusChamadoEnum status) {
    switch (status) {
      case StatusChamadoEnum.ABERTO:
        return GridColors.info;
      case StatusChamadoEnum.EM_ANDAMENTO:
        return GridColors.warning;
      case StatusChamadoEnum.FECHADO:
        return GridColors.success;
      case StatusChamadoEnum.CANCELADO:
        return GridColors.neutral;
    }
  }

  Color _corPrioridade(PrioridadeChamadoEnum prioridade) {
    switch (prioridade) {
      case PrioridadeChamadoEnum.BAIXA:
        return GridColors.neutral;
      case PrioridadeChamadoEnum.MEDIA:
        return GridColors.info;
      case PrioridadeChamadoEnum.ALTA:
        return GridColors.warning;
      case PrioridadeChamadoEnum.URGENTE:
        return GridColors.error;
    }
  }

  ({IconData icone, Color cor}) _estiloAcao(String acao) {
    switch (acao.toUpperCase()) {
      case 'COMENTARIO':
      case 'COMENTÁRIO':
        return (icone: Icons.chat_bubble_outline, cor: GridColors.textSecondary);
      case 'ABERTURA':
        return (icone: Icons.add_circle_outline, cor: GridColors.info);
      case 'ATRIBUICAO':
      case 'ATRIBUIÇÃO':
        return (icone: Icons.person_add_alt, cor: GridColors.secondary);
      case 'TRANSFERENCIA':
      case 'TRANSFERÊNCIA':
        return (icone: Icons.swap_horiz, cor: GridColors.warning);
      case 'RETORNO':
        return (icone: Icons.undo, cor: GridColors.neutral);
      case 'FECHAMENTO':
        return (icone: Icons.check_circle_outline, cor: GridColors.success);
      case 'REABERTURA':
        return (icone: Icons.replay_circle_filled, cor: GridColors.error);
      case 'NOTIFICACAO_EMPRESA':
      case 'NOTIFICAÇÃO_EMPRESA':
        return (icone: Icons.mail_outline, cor: GridColors.info);
      case 'ANEXO':
        return (icone: Icons.attach_file, cor: GridColors.secondary);
      default:
        return (icone: Icons.history, cor: GridColors.neutral);
    }
  }

  bool _ehComentario(String acao) =>
      acao.toUpperCase() == 'COMENTARIO' || acao.toUpperCase() == 'COMENTÁRIO';

  String _formatarData(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final larguraLarga = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: Text('Chamado #${_chamado.id ?? ''}'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (widget.onAbrirChat != null && _chamado.parceiro?.id != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Abrir Chat',
              onPressed: () => widget.onAbrirChat!(context, _chamado),
            ),
          IconButton(
            icon: const Icon(Icons.attach_file),
            tooltip: 'Anexos',
            onPressed: _abrirAnexos,
          ),
          if (_executandoAcao)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            PopupMenuButton<String>(
              onSelected: (v) {
                switch (v) {
                  case 'fechar':
                    _fechar();
                    break;
                  case 'reabrir':
                    _reabrir();
                    break;
                  case 'atribuir':
                    _atribuir();
                    break;
                  case 'transferir':
                    _transferir();
                    break;
                  case 'retornar':
                    _retornar();
                    break;
                  case 'notificar':
                    _notificarEmpresa();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'fechar', child: Text('Fechar chamado')),
                PopupMenuItem(value: 'reabrir', child: Text('Reabrir chamado')),
                PopupMenuItem(value: 'atribuir', child: Text('Atribuir')),
                PopupMenuItem(value: 'transferir', child: Text('Transferir')),
                PopupMenuItem(value: 'retornar', child: Text('Retornar')),
                PopupMenuItem(value: 'notificar', child: Text('Notificar empresa')),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: larguraLarga ? _buildLayoutLargo() : _buildLayoutEstreito(),
      ),
    );
  }

  Widget _buildLayoutEstreito() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildCabecalho(),
              const SizedBox(height: 16),
              _buildTimelineTitulo(),
              const SizedBox(height: 8),
              _buildTimelineCorpo(),
            ],
          ),
        ),
        _buildComposer(),
      ],
    );
  }

  Widget _buildLayoutLargo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 340,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildCabecalho(),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTimelineTitulo(),
                    const SizedBox(height: 8),
                    _buildTimelineCorpo(),
                  ],
                ),
              ),
              _buildComposer(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCabecalho() {
    return Card(
      color: GridColors.card,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_chamado.titulo,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(_chamado.descricao,
                style: TextStyle(color: GridColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _badge(_chamado.status.label, _corStatus(_chamado.status)),
              _badge(_chamado.prioridade.label, _corPrioridade(_chamado.prioridade)),
            ]),
            const Divider(height: 24),
            // Fix: usuario pediu para trazer TODOS os dados do chamado no
            // painel lateral -- antes so mostrava um subconjunto (aberto
            // por, data abertura, setor, empresa, parceiro se houver).
            // Adicionados: número do chamado, prioridade com rótulo (antes
            // so aparecia como badge sem legenda), e os campos de
            // fechamento (fechado por/data/motivo), visíveis somente
            // quando o chamado já foi fechado.
            _linhaInfo(Icons.tag, 'Nº do chamado', '#${_chamado.id ?? '—'}'),
            _linhaInfo(Icons.flag_outlined, 'Prioridade', _chamado.prioridade.label),
            _linhaInfo(Icons.person_outline, 'Aberto por',
                _chamado.usuarioAbertura?.nome ?? _chamado.usuarioAbertura?.email ?? '—'),
            _linhaInfo(Icons.calendar_today, 'Data abertura',
                _formatarData(_chamado.dataAbertura.toIso8601String())),
            _linhaInfo(Icons.business, 'Setor', _chamado.setor?.nome ?? '—'),
            _linhaInfo(Icons.apartment, 'Empresa',
                _chamado.empresa.nome ?? _chamado.empresa.razaoSocial ?? '—'),
            if (_chamado.parceiro != null)
              _linhaInfo(Icons.handshake, 'Parceiro', _chamado.parceiro?.nome ?? '—'),
            if (_chamado.usuarioFechamento != null)
              _linhaInfo(Icons.person_off_outlined, 'Fechado por',
                  _chamado.usuarioFechamento?.nome ??
                      _chamado.usuarioFechamento?.email ??
                      '—'),
            if (_chamado.dataFechamento != null)
              _linhaInfo(Icons.event_available, 'Data fechamento',
                  _formatarData(_chamado.dataFechamento!.toIso8601String())),
            if (_chamado.motivoFechamento != null &&
                _chamado.motivoFechamento!.isNotEmpty)
              _linhaInfo(Icons.notes, 'Motivo fechamento', _chamado.motivoFechamento!),
          ],
        ),
      ),
    );
  }

  Widget _badge(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cor),
      ),
      child: Text(texto,
          style: TextStyle(color: cor, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  Widget _linhaInfo(IconData icone, String label, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 16, color: GridColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12.5, color: GridColors.textSecondary),
                children: [
                  TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: valor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineTitulo() {
    return const Text('Histórico e comentários',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
  }

  Widget _buildTimelineCorpo() {
    if (_carregandoHistorico) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: GridColors.primary)),
      );
    }
    if (_erroHistorico != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: GridColors.error, size: 32),
            const SizedBox(height: 8),
            Text(_erroHistorico!,
                style: TextStyle(color: GridColors.error), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(onPressed: _carregarHistorico, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_historico.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Nenhuma movimentação ainda',
              style: TextStyle(color: GridColors.textMuted)),
        ),
      );
    }

    return Column(
      children: List.generate(_historico.length, (i) {
        final item = _historico[i];
        return _timelineItem(item, i == _historico.length - 1);
      }),
    );
  }

  Widget _timelineItem(Map<String, dynamic> item, bool isLast) {
    final acao = (item['acao'] ?? '').toString();
    final estilo = _estiloAcao(acao);
    final comentario = _ehComentario(acao);
    final observacao = (item['observacao'] ?? '').toString();
    final usuarioOrigem = (item['usuarioOrigem'] ?? '—').toString();
    final usuarioDestino = item['usuarioDestino']?.toString();
    final data = _formatarData(item['dataEvento']?.toString());

    return Stack(
      children: [
        Positioned(
          left: 15,
          top: 0,
          bottom: isLast ? 12 : 0,
          child: Container(width: 2, color: GridColors.divider),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40, right: 4, bottom: 14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: comentario ? GridColors.card : GridColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: comentario ? GridColors.divider : Colors.transparent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(estilo.icone, size: 16, color: estilo.cor),
                    const SizedBox(width: 6),
                    Text(
                      comentario ? 'Comentário' : acao.replaceAll('_', ' '),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: comentario ? 13 : 11.5,
                          color: estilo.cor),
                    ),
                    const Spacer(),
                    Text(data,
                        style: TextStyle(fontSize: 11, color: GridColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  usuarioDestino != null && usuarioDestino.isNotEmpty
                      ? 'De $usuarioOrigem para $usuarioDestino'
                      : 'Por $usuarioOrigem',
                  style: TextStyle(
                      fontSize: comentario ? 12 : 11,
                      fontWeight: FontWeight.w600,
                      color: GridColors.textSecondary),
                ),
                if (observacao.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(observacao,
                      style: TextStyle(
                          fontSize: comentario ? 13 : 12,
                          color: GridColors.textSecondary)),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          left: 6,
          top: 8,
          child: CircleAvatar(
            radius: 9,
            backgroundColor: estilo.cor,
            child: Icon(estilo.icone, color: Colors.white, size: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: GridColors.card,
        boxShadow: [BoxShadow(color: GridColors.shadow, blurRadius: 6, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _comentarioController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Escreva um comentário...',
                  filled: true,
                  fillColor: GridColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _enviandoComentario
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: GridColors.primary),
                    ),
                  )
                : IconButton(
                    onPressed: _comentarioController.text.trim().isEmpty
                        ? null
                        : _enviarComentario,
                    icon: const Icon(Icons.send),
                    color: GridColors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor: GridColors.primary.withOpacity(0.12),
                      shape: const CircleBorder(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
