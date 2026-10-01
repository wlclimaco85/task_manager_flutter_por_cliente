import 'package:hive/hive.dart';

/// Cache local de METADADO do certificado A1 configurado no backend
/// (card W3R3, item B).
///
/// IMPORTANTE — decisão de escopo documentada no card: este cache guarda
/// apenas metadado para exibição de status offline (nome do arquivo, CNPJ,
/// validade, status de validade, se está ativo). NUNCA guarda o arquivo
/// .pfx/.p12, a senha do certificado, nem qualquer material de chave
/// privada. A assinatura digital fiscal da NFe continua acontecendo
/// inteiramente no backend (`CertificadoA1Manager`/`CertificadoA1UploadService`
/// em `AppAcademia`) — nenhuma operação de assinatura ICP-Brasil é feita no
/// dispositivo. Ver investigação completa registrada no comentário do card
/// no Trello.
class CertificadoLocalCacheModel {
  final int id;
  final int? empresaId;
  final int? parceiroId;
  final String nomeArquivo;
  final String cnpjCert;
  final String validade;
  final String statusValidade;
  final int diasParaVencer;
  final bool ativo;
  final DateTime cacheadoEm;

  const CertificadoLocalCacheModel({
    required this.id,
    this.empresaId,
    this.parceiroId,
    required this.nomeArquivo,
    required this.cnpjCert,
    required this.validade,
    required this.statusValidade,
    required this.diasParaVencer,
    required this.ativo,
    required this.cacheadoEm,
  });

  factory CertificadoLocalCacheModel.fromCertificadoApi(
    Map<String, dynamic> cert, {
    int? empresaId,
    int? parceiroId,
  }) {
    return CertificadoLocalCacheModel(
      id: cert['id'] as int,
      empresaId: empresaId,
      parceiroId: parceiroId,
      nomeArquivo: cert['nomeArquivo']?.toString() ?? 'certificado.pfx',
      cnpjCert: cert['cnpjCert']?.toString() ?? '',
      validade: cert['validade']?.toString() ?? '',
      statusValidade: cert['statusValidade']?.toString() ?? 'DESCONHECIDO',
      diasParaVencer: (cert['diasParaVencer'] as num?)?.toInt() ?? 0,
      ativo: cert['ativo'] as bool? ?? false,
      cacheadoEm: DateTime.now(),
    );
  }

  factory CertificadoLocalCacheModel.fromJson(Map<String, dynamic> json) {
    return CertificadoLocalCacheModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      empresaId: (json['empresaId'] as num?)?.toInt(),
      parceiroId: (json['parceiroId'] as num?)?.toInt(),
      nomeArquivo: json['nomeArquivo']?.toString() ?? '',
      cnpjCert: json['cnpjCert']?.toString() ?? '',
      validade: json['validade']?.toString() ?? '',
      statusValidade: json['statusValidade']?.toString() ?? 'DESCONHECIDO',
      diasParaVencer: (json['diasParaVencer'] as num?)?.toInt() ?? 0,
      ativo: json['ativo'] as bool? ?? false,
      cacheadoEm:
          DateTime.tryParse(json['cacheadoEm']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (empresaId != null) 'empresaId': empresaId,
        if (parceiroId != null) 'parceiroId': parceiroId,
        'nomeArquivo': nomeArquivo,
        'cnpjCert': cnpjCert,
        'validade': validade,
        'statusValidade': statusValidade,
        'diasParaVencer': diasParaVencer,
        'ativo': ativo,
        'cacheadoEm': cacheadoEm.toIso8601String(),
      };
}

/// Adapter Hive para [CertificadoLocalCacheModel]. typeId 42 (livre — 40 é
/// usado por AgendamentoModel, 41 por NfeDraftModel deste mesmo card).
class CertificadoLocalCacheModelAdapter
    extends TypeAdapter<CertificadoLocalCacheModel> {
  @override
  final int typeId = 42;

  @override
  CertificadoLocalCacheModel read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return CertificadoLocalCacheModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, CertificadoLocalCacheModel obj) {
    writer.writeMap(obj.toJson());
  }
}
