import 'package:hive/hive.dart';

class NfceConfigFiscalCacheModel {
  final int configId;
  final int empresaId;
  final int? parceiroId;
  final String escopo;
  final String uf;
  final String ambiente;
  final String idCsc;
  final String csc;
  final String serieNfce;
  final bool contingenciaHabilitada;
  final bool temCertificado;
  final DateTime cacheadoEm;

  const NfceConfigFiscalCacheModel({
    required this.configId,
    required this.empresaId,
    this.parceiroId,
    required this.escopo,
    required this.uf,
    required this.ambiente,
    required this.idCsc,
    required this.csc,
    required this.serieNfce,
    this.contingenciaHabilitada = false,
    this.temCertificado = false,
    required this.cacheadoEm,
  });

  static String chave({required int empresaId, int? parceiroId}) =>
      'emp' + empresaId.toString() + '_par' + (parceiroId?.toString() ?? '-');

  String get chaveInstancia =>
      chave(empresaId: empresaId, parceiroId: parceiroId);

  factory NfceConfigFiscalCacheModel.fromJson(Map<String, dynamic> json) {
    return NfceConfigFiscalCacheModel(
      configId: (json['configId'] as num?)?.toInt() ?? 0,
      empresaId: (json['empresaId'] as num?)?.toInt() ?? 0,
      parceiroId: (json['parceiroId'] as num?)?.toInt(),
      escopo: json['escopo']?.toString() ?? 'EMPRESA',
      uf: json['uf']?.toString() ?? '',
      ambiente: json['ambiente']?.toString() ?? 'HOMOLOGACAO',
      idCsc: json['idCsc']?.toString() ?? '',
      csc: json['csc']?.toString() ?? '',
      serieNfce: json['serieNfce']?.toString() ?? '001',
      contingenciaHabilitada: json['contingenciaHabilitada'] == true,
      temCertificado: json['temCertificado'] == true,
      cacheadoEm: DateTime.tryParse(json['cacheadoEm']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'configId': configId,
        'empresaId': empresaId,
        if (parceiroId != null) 'parceiroId': parceiroId,
        'escopo': escopo,
        'uf': uf,
        'ambiente': ambiente,
        'idCsc': idCsc,
        'csc': csc,
        'serieNfce': serieNfce,
        'contingenciaHabilitada': contingenciaHabilitada,
        'temCertificado': temCertificado,
        'cacheadoEm': cacheadoEm.toIso8601String(),
      };
}

class NfceConfigFiscalCacheModelAdapter
    extends TypeAdapter<NfceConfigFiscalCacheModel> {
  @override
  final int typeId = 43;

  @override
  NfceConfigFiscalCacheModel read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return NfceConfigFiscalCacheModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, NfceConfigFiscalCacheModel obj) {
    writer.writeMap(obj.toJson());
  }
}
