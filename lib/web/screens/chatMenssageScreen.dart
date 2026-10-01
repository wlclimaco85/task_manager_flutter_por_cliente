import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../models/auth_utility.dart';
import '../../../models/chat_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/chat/anexo_preview_dialog.dart';
import '../../../widgets/chat/chat_message_payload.dart';
import '../../../widgets/chat/chat_support_ui.dart';
import '../../../widgets/chat/chat_transfer_dialog.dart';
import '../../../widgets/chat/chat_add_participant_dialog.dart';
import '../../../widgets/chat/finalizar_atendimento_dialog.dart';
import '../../../widgets/ticket_form_dialog.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/chat_caller.dart';

class WebChatMessageScreen extends StatefulWidget {
  final String sector;
  final String userName;
  final String chatId;
  final VoidCallback? onFinalized;
  final ValueChanged<ChatMessage>? onMessagePersisted;

  const WebChatMessageScreen({
    super.key,
    required this.sector,
    required this.userName,
    required this.chatId,
    this.onFinalized,
    this.onMessagePersisted,
  });

  @override
  State<WebChatMessageScreen> createState() => _WebChatMessageScreenState();
}

class _WebChatMessageScreenState extends State<WebChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  WebSocketChannel? _channel;
  bool _isLoading = false;
  bool _wsConnected = false;
  int _retryCount = 0;
  static const int _maxRetries = 10;
  bool _initDone = false;

  // Fix card #430: widget.chatId chega como '0' (placeholder) quando o chat
  // e novo; o backend so atribui o id real na primeira mensagem, que volta
  // pelo proprio WebSocket. _effectiveChatId comeca igual a widget.chatId e
  // e atualizado assim que uma mensagem com chatId real chega — e ele (nao
  // widget.chatId) que deve ser usado em toda chamada que precise do id
  // (enviar mensagem, upload, finalizar chat).
  late String _effectiveChatId = widget.chatId;

  String get _loggedUserName =>
      AuthUtility.userInfo?.login?.nome ?? widget.userName;
  String get _loggedUserEmail =>
      AuthUtility.userInfo?.login?.email ?? widget.userName;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages().then((_) {
      _initDone = true;
      _connectWebSocket();
    });
  }

  bool _isDuplicate(ChatMessage msg) {
    return _messages.any((message) => chatMessagesAreEquivalent(message, msg));
  }

  void _adoptRealChatIdIfNeeded(ChatMessage msg) {
    final realId = msg.chatId;
    if (realId != null &&
        realId.isNotEmpty &&
        realId != '0' &&
        realId != _effectiveChatId) {
      setState(() => _effectiveChatId = realId);
    }
  }

  void _connectWebSocket() {
    if (!mounted || _retryCount >= _maxRetries) return;
    try {
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(
        Uri.parse(TenantContext.applyToUrl(
          ApiLinks.chatStart(_loggedUserEmail, widget.sector),
        )),
      );
      _retryCount = 0;
      setState(() => _wsConnected = true);

      _channel!.stream.listen(
        (message) {
          try {
            final decoded = json.decode(message) as Map<String, dynamic>;
            final msg = ChatMessage.fromJson(decoded);
            _adoptRealChatIdIfNeeded(msg);
            if (!_isDuplicate(msg)) {
              setState(() => _messages.add(msg));
              widget.onMessagePersisted?.call(msg);
            }
            _scrollToBottom();
          } catch (_) {}
        },
        onError: (error) {
          L.d('WebSocket error: $error');
          setState(() => _wsConnected = false);
          _scheduleReconnect();
        },
        onDone: () {
          L.d('WebSocket closed');
          setState(() => _wsConnected = false);
          _scheduleReconnect();
        },
      );
    } catch (e) {
      L.d('Connection error: $e');
      setState(() => _wsConnected = false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _retryCount++;
    if (!mounted || _retryCount >= _maxRetries) return;
    final delay = Duration(
        seconds:
            (_retryCount > 5 ? 30 : 3 * (1 << (_retryCount - 1))).clamp(3, 30));
    Future.delayed(delay, () {
      if (mounted) _connectWebSocket();
    });
  }

  Future<void> _loadInitialMessages() async {
    setState(() => _isLoading = true);
    try {
      final data = await ChatCaller().fetchChatsById(context, widget.chatId);
      setState(() {
        _messages
          ..clear()
          ..addAll(data.map(_normalizeMessage));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      _showSnack('Erro ao carregar mensagens: $e', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ChatMessage _normalizeMessage(ChatMessage msg) {
    return ChatMessage(
      sender: msg.sender,
      content: msg.content.isNotEmpty ? msg.content : (msg.text ?? ''),
      type: msg.type.isNotEmpty ? msg.type : 'text',
      timestamp: msg.timestamp ?? msg.uploadDate,
      empId: msg.empId,
      codApp: msg.codApp,
      codUsuOrig: msg.codUsuOrig,
      codUsuDest: msg.codUsuDest,
      sector: msg.sector,
      chatId: msg.chatId,
      uploadDate: msg.uploadDate,
      text: msg.text,
      fileId: msg.fileId,
      fileName: msg.fileName,
      fileUrl: msg.fileUrl,
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _channel == null) return;

    _channel!.sink.add(json.encode({
      'sender': _loggedUserName,
      'senderName': _loggedUserName,
      'senderEmail': _loggedUserEmail,
      'content': content,
      'sector': widget.sector,
      'type': 'text',
      'timestamp': DateTime.now().toIso8601String(),
      'chatId': _effectiveChatId,
      if (TenantContext.empresaId != null) 'empId': TenantContext.empresaId,
      if (TenantContext.aplicativoId != null)
        'codApp': TenantContext.aplicativoId,
    }));

    _messageController.clear();
  }

  Future<void> _uploadAndSendFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || _channel == null) return;

      final file = result.files.first;
      final Uint8List? fileBytes = file.bytes;
      if (fileBytes == null) {
        _showSnack('Nao foi possivel ler o arquivo selecionado', error: true);
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(TenantContext.applyToUrl(ApiLinks.uploadFile)),
      );
      request.headers.addAll(TenantContext.headers);
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: file.name),
      );
      final int currentEmpId = TenantContext.empresaId ??
          (_messages.isNotEmpty ? (_messages.first.empId ?? 0) : 0);
      final int currentParceiroId = TenantContext.parceiroId ??
          (_messages.isNotEmpty ? (_messages.first.parceiroId ?? 0) : 0);

      request.fields.addAll({
        'user': _loggedUserEmail,
        'userEmail': _loggedUserEmail,
        'userName': _loggedUserName,
        'sector': widget.sector,
        'chatId': _effectiveChatId,
        if (currentEmpId > 0) 'empId': currentEmpId.toString(),
        if (currentParceiroId > 0) 'parceiroId': currentParceiroId.toString(),
        'fileName': file.name,
        'fileType': (file.extension ?? '').toLowerCase(),
        'diretorio': '{"id":0}',
        'empresa': '{"id":$currentEmpId}',
        'parceiro': '{"id":$currentParceiroId}',
        'modulo': 'chat',
      });

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode != 200) {
        _showSnack('Falha no upload (${response.statusCode})', error: true);
        return;
      }

      final jsonResponse = json.decode(responseBody) as Map<String, dynamic>;
      final rawId = jsonResponse['fileId'] ?? jsonResponse['data']?['fileId'];
      final fileId =
          rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      final fileUrl =
          (jsonResponse['fileUrl'] ?? jsonResponse['data']?['fileUrl'])
              ?.toString();
      if (fileId == null) {
        _showSnack('Upload concluido, mas o arquivo voltou sem identificador',
            error: true);
        return;
      }

      final payload = buildChatOutgoingPayload(
        senderName: _loggedUserName,
        senderEmail: _loggedUserEmail,
        content: 'Arquivo: ${file.name}',
        sector: widget.sector,
        type: 'file',
        chatId: _effectiveChatId,
        empresaId: currentEmpId > 0 ? currentEmpId : null,
        parceiroId: currentParceiroId > 0 ? currentParceiroId : null,
        aplicativoId: TenantContext.aplicativoId,
        userId: TenantContext.userId,
        fileName: file.name,
        fileId: fileId,
        fileUrl: fileUrl ?? ApiLinks.publicFileUrl(fileId),
      );
      _channel!.sink.add(json.encode(payload));
      if (mounted) {
        setState(() => appendOutgoingChatMessage(_messages, payload));
        _scrollToBottom();
      }
    } catch (e) {
      _showSnack('Erro no upload: $e', error: true);
    }
  }

  /// Historico da conversa formatado como texto, para pre-preencher a
  /// descricao do chamado (card #432).
  String _buildHistoricoChat() {
    return _messages
        .where((m) => (m.content.isNotEmpty ? m.content : (m.text ?? ''))
            .trim()
            .isNotEmpty)
        .map((m) =>
            '${m.sender}: ${m.content.isNotEmpty ? m.content : (m.text ?? '')}')
        .join('\n');
  }

  /// Imagens anexadas na conversa (mensagens tipo 'file' com extensao de
  /// imagem), para reanexar automaticamente ao chamado (card #432).
  List<Map<String, dynamic>> _buildImagensChat() {
    const extensoesImagem = ['jpg', 'jpeg', 'png'];
    return _messages
        .where((m) =>
            m.type == 'file' &&
            m.fileId != null &&
            extensoesImagem
                .contains((m.fileName ?? '').split('.').last.toLowerCase()))
        .map((m) => {'fileId': m.fileId, 'fileName': m.fileName})
        .toList();
  }

  // Fix (card #475): dialog demora (upload de imagens do chat pode levar
  // vários segundos) -- se o WebSocket cair ou o widget for desmontado
  // nesse meio tempo, a mensagem de confirmação nunca era enviada e o
  // usuário não tinha NENHUM aviso, nem no chat nem em outro lugar, de que
  // o chamado (que já foi criado com sucesso) existia. Agora sempre mostra
  // um SnackBar de fallback, e a frase no chat ficou mais amigável.
  Future<void> _createTicket() async {
    final criado = await showDialog(
      context: context,
      builder: (_) => TicketFormDialog(
        sectorDescricao: widget.sector,
        initialDescricao: _buildHistoricoChat(),
        anexosChat: _buildImagensChat(),
      ),
    );
    if (criado == null || !mounted) return;
    final id = (criado as dynamic).id;
    final mensagem =
        'Chamado aberto número #$id. Para acompanhar, acesse a tela de chamados.';

    final payload = buildChatOutgoingPayload(
      senderName: _loggedUserName,
      senderEmail: _loggedUserEmail,
      content: mensagem,
      sector: widget.sector,
      type: 'ticket',
      chatId: _effectiveChatId,
      empresaId: TenantContext.empresaId,
      parceiroId: TenantContext.parceiroId,
      aplicativoId: TenantContext.aplicativoId,
      userId: TenantContext.userId,
      ticketId: id is int ? id : int.tryParse(id.toString()),
    );

    if (_channel != null) {
      try {
        _channel!.sink.add(json.encode(payload));
      } catch (e) {
        L.d('Erro ao enviar confirmação de chamado no chat: $e');
      }
    }

    if (!mounted) return;
    setState(() => appendOutgoingChatMessage(_messages, payload));
    _scrollToBottom();
    _showSnack(mensagem, error: false);
  }

  Future<void> _correctDraft() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    try {
      final result = await AiAssistantService().correctMessage(text: text);
      _messageController.text = result.correctedText;
      _messageController.selection = TextSelection.collapsed(
        offset: _messageController.text.length,
      );
    } catch (e) {
      _showSnack('Erro ao corrigir mensagem: $e', error: true);
    }
  }

  Future<void> _summarizeChat() async {
    try {
      final result = await AiAssistantService().summarizeChat(
        chatId: _effectiveChatId,
        messages: _messages
            .map((m) => m.content.isNotEmpty ? m.content : (m.text ?? ''))
            .where((m) => m.trim().isNotEmpty)
            .toList(),
      );
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Resumo do atendimento'),
          content: Text(
            '${result.summary}\n\nPrioridade: ${result.priority}\nSentimento: ${result.sentiment}',
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
      _showSnack('Erro ao resumir atendimento: $e', error: true);
    }
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    try {
      // Fix card #446: ApiLinks.getFile(id) => '/api/files/$id' so existe
      // como PUT/DELETE no backend (405 no GET). O download real e via
      // ApiLinks.downloadArquivo, mesmo endpoint ja usado pelo GED.
      final response = await http.get(
        Uri.parse(TenantContext.applyToUrl(
            ApiLinks.downloadArquivo(fileId.toString()))),
        headers: TenantContext.headers,
      );
      if (response.statusCode == 200) {
        await FileSaver.instance
            .saveFile(name: fileName, bytes: response.bodyBytes);
        _showSnack('Arquivo $fileName baixado');
      } else {
        _showSnack('Falha ao baixar o arquivo (${response.statusCode})',
            error: true);
      }
    } catch (e) {
      _showSnack('Erro ao baixar o arquivo: $e', error: true);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isMine(ChatMessage message) {
    return message.sender == _loggedUserName ||
        message.sender == _loggedUserEmail ||
        message.codUsuOrig == TenantContext.userId;
  }

  String _displayName(ChatMessage message) {
    if (message.sender.trim().isNotEmpty) return message.sender.trim();
    return _isMine(message) ? _loggedUserName : widget.sector;
  }

  String _formatTime(String? timestamp) {
    final time = DateTime.tryParse(timestamp ?? '');
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? GridColors.error : GridColors.success,
        content: Text(message),
      ),
    );
  }

  // Fase 2 da fila de atendimento (card #448): permite transferir a
  // conversa para outro funcionario do setor. ChatTransferDialog ja
  // existia, so faltava a ligacao com a tela real de chat.
  Future<void> _transferirChat() async {
    if (_effectiveChatId.isEmpty || _effectiveChatId == '0') {
      _showSnack('Envie ao menos uma mensagem antes de transferir.',
          error: true);
      return;
    }
    final transferido = await showDialog<bool>(
      context: context,
      builder: (_) => ChatTransferDialog(chatId: _effectiveChatId),
    );
    if (transferido == true && mounted) {
      widget.onFinalized?.call();
    }
  }

  // Card #474 (Fase 3 fila de atendimento).
  Future<void> _incluirParticipante() async {
    if (_effectiveChatId.isEmpty || _effectiveChatId == '0') {
      _showSnack('Envie ao menos uma mensagem antes de incluir participante.',
          error: true);
      return;
    }
    await showDialog<bool>(
      context: context,
      builder: (_) => ChatAddParticipantDialog(chatId: _effectiveChatId),
    );
  }

  Future<void> _finalizarChat() async {
    if (_effectiveChatId.isEmpty || _effectiveChatId == '0') {
      _showSnack('Envie ao menos uma mensagem antes de finalizar.',
          error: true);
      return;
    }
    // Fix card #444: popup de finalizar substituido por pesquisa de
    // satisfacao (resolvido/parcial/nao resolvido) + nota 1-10 + opcao de
    // abrir chamado, design ui-ux-pro-max.
    final resultado = await showFinalizarAtendimentoDialog(
      context,
      sectorDescricao: widget.sector,
      historicoConversa: _buildHistoricoChat(),
    );
    if (resultado == null || !mounted) return;
    try {
      final url = TenantContext.applyToUrl(ApiLinks.chatFinalizarConversa(
        _effectiveChatId,
        satisfacao: resultado.satisfacao.valor,
        nota: resultado.nota,
      ));
      final response =
          await http.put(Uri.parse(url), headers: TenantContext.headers);
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnack('Atendimento finalizado com sucesso.');
        // Fix card #444: apos finalizar, volta para a lista de atendimentos
        // em vez de manter a conversa finalizada aberta.
        widget.onFinalized?.call();
      } else {
        _showSnack('Não foi possível finalizar (${response.statusCode}).',
            error: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erro ao finalizar atendimento: $e', error: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _channel?.sink.close();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChatConversationHeader(
          // Fix (card #473): se a conversa foi aberta a partir de um
          // chamado, o número dele fica embutido no chatId
          // ("...-chamado-Z") -- extrai e mostra no cabeçalho.
          sector: extrairChamadoIdDoChatId(_effectiveChatId) != null
              ? 'Chamado #${extrairChamadoIdDoChatId(_effectiveChatId)} · ${widget.sector}'
              : widget.sector,
          userName: _loggedUserEmail,
          onTransfer: _transferirChat,
          onAddParticipant: _incluirParticipante,
          onFinalize: _finalizarChat,
        ),
        if (_isLoading)
          const LinearProgressIndicator(color: GridColors.primary),
        Expanded(
          child: ColoredBox(
            color: ChatSupportPalette.page,
            child: _messages.isEmpty && !_isLoading
                ? ChatEmptyState(
                    title: 'Conversa vazia',
                    message:
                        'Envie a primeira mensagem para iniciar o atendimento deste setor.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = _isMine(message);
                      return ChatMessageBubble(
                        message: message,
                        isMe: isMe,
                        displayName: _displayName(message),
                        time: _formatTime(
                            message.timestamp ?? message.uploadDate),
                        // Fix card #454: abre popup de pre-visualizacao em
                        // vez de baixar direto ao clicar no anexo.
                        onOpenFile: message.fileId == null
                            ? null
                            : () => showAnexoPreviewDialog(
                                  context,
                                  fileId: message.fileId!,
                                  fileName: message.fileName ?? 'arquivo',
                                  onBaixar: () => _downloadFile(
                                    message.fileId!,
                                    message.fileName ?? 'arquivo',
                                  ),
                                ),
                      );
                    },
                  ),
          ),
        ),
        ChatComposer(
          controller: _messageController,
          onAttach: _uploadAndSendFile,
          onTicket: _createTicket,
          onSend: _sendMessage,
        ),
      ],
    );
  }
}
