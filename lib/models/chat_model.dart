class ChatMessage {
  final String sender;
  final String content;
  final String type;
  final int? fileId;
  final String? fileName;
  final String? timestamp;
  final String? fileUrl; // <- novo

  // Novos campos do payload
  final int? empId;
  final int? parceiroId;
  final int? codApp;
  final int? codUsuOrig;
  final int? codUsuDest;
  final String? sector;
  final String? chatId;
  final String? uploadDate;
  final String? text;
  // Fix card #444: status real da conversa (Aberto/Finalizado), vindo do
  // backend agrupado por chatId (antes nao existia e a UI usava 'Ativo' fixo).
  final String? status;
  final int? atendenteId;

  // Nome e foto reais do remetente, enriquecidos pelo backend a partir de
  // Login.nome e Login.foto (codUsuOrig). Permitem substituir o texto do
  // setor pela identidade real de quem respondeu.
  final String? senderName;
  final String? senderFoto;

  ChatMessage({
    required this.sender,
    required this.content,
    required this.type,
    this.fileId,
    this.fileName,
    this.timestamp,
    this.empId,
    this.parceiroId,
    this.codApp,
    this.codUsuOrig,
    this.codUsuDest,
    this.sector,
    this.chatId,
    this.uploadDate,
    this.text,
    this.fileUrl,
    this.status,
    this.atendenteId,
    this.senderName,
    this.senderFoto,
  });

  // Construtor a partir de JSON com suporte a fileAttachment aninhado e inferência de tipo
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final fileAttachment = json['fileAttachment'] is Map
        ? json['fileAttachment'] as Map<String, dynamic>
        : (json['file_attachment'] is Map
            ? json['file_attachment'] as Map<String, dynamic>
            : null);

    final extractedFileId = _intFromJson(json['fileId'] ??
        json['file_id'] ??
        fileAttachment?['id'] ??
        fileAttachment?['fileId']);

    final extractedFileName = (json['fileName'] ??
            json['file_name'] ??
            fileAttachment?['fileName'] ??
            fileAttachment?['file_name'] ??
            fileAttachment?['name'])
        ?.toString();

    final rawContent = (json['content'] ?? json['text'] ?? '').toString();
    String type = (json['type'] ?? '').toString();
    if (type.isEmpty) {
      if (extractedFileId != null || extractedFileName != null) {
        type = 'file';
      } else if (rawContent.contains('Chamado #') ||
          rawContent.contains('🎫 Chamado')) {
        type = 'ticket';
      } else {
        type = 'text';
      }
    }

    final finalContent = rawContent.isNotEmpty
        ? rawContent
        : (extractedFileName != null ? 'Arquivo: $extractedFileName' : '');

    return ChatMessage(
      sender: json['sender'] ?? '',
      content: finalContent,
      type: type,
      fileId: extractedFileId,
      fileName: extractedFileName,
      timestamp: json['timestamp'],
      fileUrl: json['fileUrl'] ?? (fileAttachment?['fileUrl']?.toString()),
      empId: _intFromJson(json['empId'] ?? json['empresaId']),
      parceiroId: _intFromJson(
          json['parceiroId'] ?? json['parcId'] ?? json['clienteId']),
      codApp: _intFromJson(json['codApp']),
      codUsuOrig: _intFromJson(json['codUsuOrig']),
      codUsuDest: _intFromJson(json['codUsuDest']),
      sector: json['sector'],
      chatId: json['chatId'],
      uploadDate: json['uploadDate'],
      text: json['text'] ?? finalContent,
      status: json['status'],
      atendenteId: _intFromJson(json['atendenteId']),
      senderName: json['senderName'],
      senderFoto: json['senderFoto'],
    );
  }

  // Converter para JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['sender'] = sender;
    data['content'] = content;
    data['type'] = type;
    data['fileId'] = fileId;
    data['fileName'] = fileName;
    data['timestamp'] = timestamp;
    data['fileUrl'] = fileUrl;

    // Novos campos
    data['empId'] = empId;
    data['parceiroId'] = parceiroId;
    data['codApp'] = codApp;
    data['codUsuOrig'] = codUsuOrig;
    data['codUsuDest'] = codUsuDest;
    data['sector'] = sector;
    data['chatId'] = chatId;
    data['uploadDate'] = uploadDate;
    data['text'] = text;
    data['status'] = status;
    data['atendenteId'] = atendenteId;
    if (senderName != null) data['senderName'] = senderName;
    if (senderFoto != null) data['senderFoto'] = senderFoto;

    return data;
  }

  // Converter lista de JSON em lista de ChatMessage
  static List<ChatMessage> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((item) => ChatMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static int? _intFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

ChatMessage normalizeChatMessageForDisplay(ChatMessage msg) {
  return ChatMessage(
    sender: msg.sender,
    content: msg.content.isNotEmpty ? msg.content : (msg.text ?? ''),
    type: msg.type.isNotEmpty ? msg.type : 'text',
    timestamp: msg.timestamp ?? msg.uploadDate,
    empId: msg.empId,
    parceiroId: msg.parceiroId,
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
    status: msg.status,
    atendenteId: msg.atendenteId,
    senderName: msg.senderName,
    senderFoto: msg.senderFoto,
  );
}

String chatMessageDisplayName(
  ChatMessage message, {
  required bool isMine,
  required String loggedUserName,
  required String sector,
}) {
  final senderName = message.senderName?.trim() ?? '';
  if (senderName.isNotEmpty) return senderName;
  final sender = message.sender.trim();
  if (sender.isNotEmpty) return sender;
  return isMine ? loggedUserName : sector;
}

/// Modelo para item do kanban de chat.
class ChatKanbanItem {
  final String chatId;
  final String? cliente;
  final String? clienteEmail;
  final String? setor;
  final String? setorId;
  final String? ultimaMensagem;
  final String status;
  final int naoLidos;
  final DateTime? dataUltimaMensagem;
  final String? usuarioResponsavel;
  final String? usuarioResponsavelId;
  final int? empresaId;

  ChatKanbanItem({
    required this.chatId,
    this.cliente,
    this.clienteEmail,
    this.setor,
    this.setorId,
    this.ultimaMensagem,
    required this.status,
    this.naoLidos = 0,
    this.dataUltimaMensagem,
    this.usuarioResponsavel,
    this.usuarioResponsavelId,
    this.empresaId,
  });

  factory ChatKanbanItem.fromJson(Map<String, dynamic> json) {
    return ChatKanbanItem(
      chatId: json['chatId']?.toString() ?? json['id']?.toString() ?? '',
      cliente: json['cliente']?.toString() ?? json['clienteNome']?.toString(),
      clienteEmail: json['clienteEmail']?.toString(),
      setor: json['setor']?.toString() ?? json['sector']?.toString(),
      setorId: json['setorId']?.toString(),
      ultimaMensagem:
          json['ultimaMensagem']?.toString() ?? json['lastMessage']?.toString(),
      status: json['status']?.toString() ?? 'Aguardando',
      naoLidos: int.tryParse(json['naoLidos']?.toString() ?? '0') ?? 0,
      dataUltimaMensagem: json['dataUltimaMensagem'] != null
          ? DateTime.tryParse(json['dataUltimaMensagem'].toString())
          : null,
      usuarioResponsavel: json['usuarioResponsavel']?.toString(),
      usuarioResponsavelId: json['usuarioResponsavelId']?.toString(),
      empresaId: int.tryParse(json['empresaId']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'chatId': chatId,
        'cliente': cliente,
        'clienteEmail': clienteEmail,
        'setor': setor,
        'setorId': setorId,
        'ultimaMensagem': ultimaMensagem,
        'status': status,
        'naoLidos': naoLidos,
        'dataUltimaMensagem': dataUltimaMensagem?.toIso8601String(),
        'usuarioResponsavel': usuarioResponsavel,
        'usuarioResponsavelId': usuarioResponsavelId,
        'empresaId': empresaId,
      };
}

class ChatMessageModel {
  String? status;
  String? token;
  List<ChatMessage>? messages;

  ChatMessageModel({this.status, this.token, this.messages});

  ChatMessageModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    messages = json['data'] != null
        ? ChatMessage.fromJsonList(json['data']['dados'])
        : [];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;
    if (messages != null) {
      data['data'] = {
        'messages': messages!.map((msg) => msg.toJson()).toList(),
      };
    }
    return data;
  }
}
