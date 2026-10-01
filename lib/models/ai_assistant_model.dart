class ChatSummaryResult {
  final String tenantId;
  final String? chatId;
  final String summary;
  final List<String> actionItems;
  final String sentiment;
  final String priority;

  const ChatSummaryResult({
    required this.tenantId,
    this.chatId,
    required this.summary,
    required this.actionItems,
    required this.sentiment,
    required this.priority,
  });

  factory ChatSummaryResult.fromJson(Map<String, dynamic> json) {
    return ChatSummaryResult(
      tenantId: json['tenantId']?.toString() ?? '',
      chatId: json['chatId']?.toString(),
      summary: json['summary']?.toString() ?? '',
      actionItems: (json['actionItems'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      sentiment: json['sentiment']?.toString() ?? 'NEUTRO',
      priority: json['priority']?.toString() ?? 'NORMAL',
    );
  }
}

class TextCorrectionResult {
  final String tenantId;
  final String originalText;
  final String correctedText;
  final String tone;

  const TextCorrectionResult({
    required this.tenantId,
    required this.originalText,
    required this.correctedText,
    required this.tone,
  });

  factory TextCorrectionResult.fromJson(Map<String, dynamic> json) {
    return TextCorrectionResult(
      tenantId: json['tenantId']?.toString() ?? '',
      originalText: json['originalText']?.toString() ?? '',
      correctedText: json['correctedText']?.toString() ?? '',
      tone: json['tone']?.toString() ?? 'profissional',
    );
  }
}

class DocumentClassificationResult {
  final String tenantId;
  final String category;
  final String confidence;
  final List<String> tags;
  final String suggestedStatus;

  const DocumentClassificationResult({
    required this.tenantId,
    required this.category,
    required this.confidence,
    required this.tags,
    required this.suggestedStatus,
  });

  factory DocumentClassificationResult.fromJson(Map<String, dynamic> json) {
    return DocumentClassificationResult(
      tenantId: json['tenantId']?.toString() ?? '',
      category: json['category']?.toString() ?? 'OUTROS',
      confidence: json['confidence']?.toString() ?? 'BAIXA',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      suggestedStatus: json['suggestedStatus']?.toString() ?? 'REVISAO_MANUAL',
    );
  }
}
