import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/io.dart';
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
import '../../services/ai_assistant_service.dart';
import '../../services/chat_caller.dart';
import 'ticket_form_bottom_sheet.dart';

class ChatMessageScreen extends StatefulWidget {
  final String sector;
  final String userName;
  final String chatId;
  // Fix card #444: chamado apos finalizar com sucesso, para o container
  // (lista de atendimento) voltar para a lista.
  final VoidCallback? onFinalized;

  const ChatMessageScreen({
    super.key,
    required this.sector,
    required this.userName,
    required this.chatId,
    this.onFinalized,
  });

  @override
  State<ChatMessageScreen> createState() => _ChatMessageScreenState();
}

class _ChatMessageScreenState extends State<ChatMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  WebSocketChannel? _channel;
  bool _isLoading = false;
  bool _wsConnected = false;
  int _retryCount = 0;
  static const int _maxRetries = 10;
  bool _initDone = false;
  bool _disposed = false;

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
      if (mounted && !_disposed) setState(() => _effectiveChatId = realId);
    }
  }

  void _connectWebSocket() {
    if (!mounted || _retryCount >= _maxRetries || _disposed) return;
    try {
      _channel?.sink.close();
      _channel = IOWebSocketChannel.connect(
        TenantContext.applyToUrl(
            ApiLinks.chatStart(_loggedUserEmail, widget.sector)),
      );
      _retryCount = 0;
      if (mounted && !_disposed) setState(() => _wsConnected = true);

      _channel!.stream.listen(
        (message) {
          try {
            final decoded = json.decode(message) as Map<String, dynamic>;
            final msg = ChatMessage.fromJson(decoded);
            _adoptRealChatIdIfNeeded(msg);
            if (!_isDuplicate(msg)) {
              if (mounted && !_disposed) setState(() => _messages.add(msg));
            }
            _scrollToBottom();
          } catch (_) {}
        },
        onError: (error) {
          if (mounted && !_disposed) setState(() => _wsConnected = false);
          _scheduleReconnect();
        },
        onDone: () {
          if (mounted && !_disposed) setState(() => _wsConnected = false);
          _scheduleReconnect();
        },
      );
    } catch (_) {
      if (mounted && !_disposed) setState(() => _wsConnected = false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _retryCount++;
    if (!mounted || _retryCount >= _maxRetries || _disposed) return;
    final delay = Duration(
        seconds:
            (_retryCount > 5 ? 30 : 3 * (1 << (_retryCount - 1))).clamp(3, 30));
    Future.delayed(delay, () {
      if (mounted && !_disposed) _connectWebSocket();
    });
  }

  Future<void> _loadInitialMessages() async {
    if (mounted && !_disposed) setState(() => _isLoading = true);
    try {
      final data = await ChatCaller().fetchChatsById(context, widget.chatId);
      if (mounted && !_disposed)
        setState(() {
          _messages
            ..clear()
            ..addAll(data.map(_normalizeMessage));
        });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      _showSnack('Erro ao carregar mensagens: $e', error: true);
    } finally {
      if (mounted && !_disposed) setState(() => _isLoading = false);
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
    // Bug de producao: usuario reportou "nao esta dando certo fazer upload"
    // sem nenhum erro visivel nem log -- este metodo so mostrava SnackBar,
    // nunca chamava AppLogger (mesma classe de bug ja corrigida no download
    // do GED, ver bottom_navbar_screen.dart._baixarArquivo). Alem disso, o
    // envio so' checava _channel == null, nao _wsConnected -- se o usuario
    // tentar anexar arquivo logo ao abrir um chat NOVO, antes do handshake
    // do WebSocket terminar (que e' quando o chat recebe seu chatId real,
    // ver _adoptRealChatIdIfNeeded), o upload pode ser enviado com
    // chatId='0' (placeholder), que o backend rejeita.
    if (!_wsConnected) {
      AppLogger.i.warn(
        'Upload de chat cancelado: WebSocket ainda nao conectado (chatId=$_effectiveChatId).',
      );
      _showSnack('Conexao do chat ainda nao esta pronta. Tente novamente.',
          error: true);
      return;
    }
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || _channel == null) return;

      final file = result.files.first;
      Uint8List? fileBytes = file.bytes;
      if (fileBytes == null && file.path != null) {
        fileBytes = await File(file.path!).readAsBytes();
      }
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
        // Fix card #429: FileController.uploadFile exige estes 5 campos
        // (fileName/fileType/diretorio/empresa/parceiro), nenhum era enviado
        // pelo chat -> 400. diretorio:{"id":0} e o mesmo default usado pelo
        // GED (ged_arquivos_screen.dart) quando nenhum diretorio e escolhido.
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
        AppLogger.i.error(
          'Falha no upload de chat (chatId=$_effectiveChatId, arquivo=${file.name}): '
          'HTTP ${response.statusCode} — $responseBody',
        );
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
        AppLogger.i.error(
          'Upload de chat concluido sem fileId (chatId=$_effectiveChatId, resposta=$responseBody)',
        );
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
      if (mounted && !_disposed) {
        setState(() => appendOutgoingChatMessage(_messages, payload));
        _scrollToBottom();
      }
      AppLogger.i.info(
        'Upload de chat concluido: fileId=$fileId, arquivo=${file.name}, chatId=$_effectiveChatId',
      );
    } catch (e, st) {
      AppLogger.i.error(
        'Erro no upload de chat (chatId=$_effectiveChatId): $e',
        st,
      );
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

  Future<void> _createTicket() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, controller) => DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            child: TicketFormBottomSheet(
              sectorDescricao: widget.sector,
              initialDescricao: _buildHistoricoChat(),
              anexosChat: _buildImagensChat(),
            ),
          ),
        ),
      ),
    );

    if (result == null || !mounted || _disposed) return;
    final id = (result as dynamic).id;
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
      if (!mounted || _disposed) return;
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

  Future<void> _openOrDownload(int fileId, String fileName,
      {String? fileUrl}) async {
    if (fileUrl != null && fileUrl.isNotEmpty) {
      final uri = Uri.parse(fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    await _downloadFile(fileId, fileName);
  }

  Future<void> _downloadFile(int fileId, String fileName) async {
    // Bug de producao: usuario reportou "nao esta dando certo... nem
    // download do arquivo do chat" sem nenhum log -- este metodo tambem so
    // mostrava SnackBar, nunca chamava AppLogger (mesma classe de bug ja
    // corrigida no download do GED, ver bottom_navbar_screen.dart).
    try {
      final response = await http.get(
        Uri.parse(
            TenantContext.applyToUrl(ApiLinks.downloadFile(fileId.toString()))),
        headers: TenantContext.headers,
      );
      if (response.statusCode == 200) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          AppLogger.i.warn(
            'Download de chat: arquivo salvo mas sem app instalado pra abrir '
            '${file.path} (fileId=$fileId).',
          );
        }
        AppLogger.i
            .info('Download de chat concluido: fileId=$fileId -> ${file.path}');
        _showSnack('Arquivo salvo em: ${file.path}');
      } else {
        AppLogger.i.error(
          'Falha no download de chat (fileId=$fileId): HTTP ${response.statusCode} — ${response.body}',
        );
        _showSnack('Falha ao baixar (${response.statusCode})', error: true);
      }
    } catch (e, st) {
      AppLogger.i.error('Erro no download de chat (fileId=$fileId): $e', st);
      _showSnack('Erro ao baixar: $e', error: true);
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
    if (!mounted || _disposed) return;
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
    if (resultado == null || !mounted || _disposed) return;

    try {
      final url = TenantContext.applyToUrl(ApiLinks.chatFinalizarConversa(
        _effectiveChatId,
        satisfacao: resultado.satisfacao.valor,
        nota: resultado.nota,
      ));
      final response = await http.put(
        Uri.parse(url),
        headers: TenantContext.headers,
      );

      if (!mounted || _disposed) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnack('Atendimento finalizado com sucesso.');
        widget.onFinalized?.call();
        Navigator.of(context).pop();
      } else {
        _showSnack(
          'Não foi possível finalizar o atendimento (${response.statusCode}).',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted || _disposed) return;
      _showSnack('Erro ao finalizar atendimento: $e', error: true);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _scrollController.dispose();
    // Fechar o channel de forma segura para evitar setState() apos dispose
    try {
      _channel?.sink.close();
    } catch (_) {
      // Ignorar erros ao fechar o channel
    }
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatSupportPalette.page,
      body: Column(
        children: [
          ChatConversationHeader(
            // Fix (card #473): se a conversa foi aberta a partir de um
            // chamado, o número dele fica embutido no chatId
            // ("...-chamado-Z") -- extrai e mostra no cabeçalho.
            sector: extrairChamadoIdDoChatId(_effectiveChatId) != null
                ? 'Chamado #${extrairChamadoIdDoChatId(_effectiveChatId)} · ${widget.sector}'
                : widget.sector,
            userName: _loggedUserEmail,
            compact: true,
            onBack: () => Navigator.pop(context),
            onTransfer: _transferirChat,
            onAddParticipant: _incluirParticipante,
            onFinalize: _finalizarChat,
          ),
          if (_isLoading)
            const LinearProgressIndicator(color: GridColors.primary),
          Expanded(
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
                      return ChatMessageBubble(
                        message: message,
                        isMe: _isMine(message),
                        displayName: _displayName(message),
                        time: _formatTime(
                            message.timestamp ?? message.uploadDate),
                        // Fix card #454: abre popup de pre-visualizacao em
                        // vez de baixar/abrir direto ao clicar no anexo.
                        onOpenFile: message.fileId == null
                            ? null
                            : () => showAnexoPreviewDialog(
                                  context,
                                  fileId: message.fileId!,
                                  fileName: message.fileName ?? 'arquivo',
                                  onBaixar: () => _openOrDownload(
                                    message.fileId!,
                                    message.fileName ?? 'arquivo',
                                    fileUrl: message.fileUrl,
                                  ),
                                ),
                      );
                    },
                  ),
          ),
          ChatComposer(
            controller: _messageController,
            onAttach: _uploadAndSendFile,
            onTicket: _createTicket,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}
