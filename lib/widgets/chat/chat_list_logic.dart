import '../../models/chat_model.dart';

class ChatListItemData {
  final String chatId;
  final String sector;
  final String lastMessage;
  final DateTime timestamp;
  final String status;
  final int? responsavelId;

  const ChatListItemData({
    required this.chatId,
    required this.sector,
    required this.lastMessage,
    required this.timestamp,
    required this.status,
    this.responsavelId,
  });
}

List<ChatListItemData> buildChatListItemsFromMessages(
  Iterable<ChatMessage> messages,
) {
  final chats = messages
      .where((msg) => (msg.chatId ?? '').trim().isNotEmpty)
      .map(
        (msg) => ChatListItemData(
          chatId: msg.chatId ?? '0',
          sector: msg.sector ?? 'Setor desconhecido',
          lastMessage: msg.text ?? msg.content,
          timestamp: DateTime.tryParse(msg.uploadDate ?? msg.timestamp ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
          status: chatStatusLabel(msg.status),
          responsavelId: msg.atendenteId ?? msg.codUsuDest,
        ),
      )
      .toList();
  chats.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return chats;
}

String chatStatusLabel(String? status) {
  final normalized = (status ?? '').trim().toUpperCase();
  return normalized == 'FECHADO' ||
          normalized == 'FINALIZADO' ||
          normalized == 'RESOLVIDO' ||
          normalized == 'CANCELADO'
      ? 'Finalizado'
      : 'Ativo';
}

List<String> sectorLabelsFromCadastro(
  Iterable<Map<String, dynamic>> setores, {
  required List<String> fallback,
}) {
  final labels = setores
      .map((item) => (item['label'] ?? item['descricao'] ?? item['nome'] ?? '')
          .toString()
          .trim())
      .where((label) => label.isNotEmpty)
      .toList();
  return labels.isEmpty ? fallback : labels;
}
