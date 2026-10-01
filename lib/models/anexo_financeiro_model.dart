class AnexoFinanceiro {
  final int? id;
  final int lancamentoId;
  final String lancamentoTipo;
  final String fileName;
  final String? fileUrl;
  final String? contentType;
  final int? tamanhoBytes;
  final String? createdAt;

  const AnexoFinanceiro({
    this.id,
    required this.lancamentoId,
    required this.lancamentoTipo,
    required this.fileName,
    this.fileUrl,
    this.contentType,
    this.tamanhoBytes,
    this.createdAt,
  });

  factory AnexoFinanceiro.fromJson(Map<String, dynamic> json) {
    return AnexoFinanceiro(
      id: json['id'] as int?,
      lancamentoId: json['lancamentoId'] as int,
      lancamentoTipo: json['lancamentoTipo'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String?,
      contentType: json['contentType'] as String?,
      tamanhoBytes: json['tamanhoBytes'] as int?,
      createdAt: json['createdAt'] as String?,
    );
  }

  String get tamanhoFormatado {
    if (tamanhoBytes == null) return '';
    if (tamanhoBytes! < 1024) return '${tamanhoBytes}B';
    if (tamanhoBytes! < 1024 * 1024) return '${(tamanhoBytes! / 1024).toStringAsFixed(1)}KB';
    return '${(tamanhoBytes! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  bool get isPdf => contentType == 'application/pdf' || fileName.toLowerCase().endsWith('.pdf');
  bool get isImage => contentType?.startsWith('image/') == true ||
      RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false).hasMatch(fileName);
}
