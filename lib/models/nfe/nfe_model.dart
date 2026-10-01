import 'nfe_item_model.dart';
import 'nfe_status.dart';
import 'nfe_tomador_model.dart';
import 'sefaz_protocolo_model.dart';
import 'valores_nfe_model.dart';

/// Modelo completo que representa uma Nota Fiscal Eletrônica (NFe)
class NfeModel {
  final int id;
  final int empresaId;
  final String numero;
  final int serie;
  final DateTime dataHora;
  final NfeStatus statusNfe;
  final String? protocolo;
  final DateTime? dataHoraSefaz;
  final String cnpjEmitente;
  final String uf;
  final String ambiente; // HOMOLOGACAO, PRODUCAO

  // Conteúdo
  final String? xmlNfe;
  final String? xmlNfeAssinado;

  // Relacionamentos
  final NfeTomadorModel tomador;
  final List<NfeItemModel> itens;
  final ValoresNfeModel valores;
  final SefazProtocoloModel? sefazProtocolo;

  // Auditoria
  final DateTime criadoEm;
  final DateTime? atualizadoEm;

  const NfeModel({
    required this.id,
    required this.empresaId,
    required this.numero,
    required this.serie,
    required this.dataHora,
    required this.statusNfe,
    required this.cnpjEmitente,
    required this.uf,
    required this.ambiente,
    required this.tomador,
    required this.itens,
    required this.valores,
    required this.criadoEm,
    this.protocolo,
    this.dataHoraSefaz,
    this.xmlNfe,
    this.xmlNfeAssinado,
    this.sefazProtocolo,
    this.atualizadoEm,
  });

  /// Cria instância a partir de JSON
  factory NfeModel.fromJson(Map<String, dynamic> json) {
    return NfeModel(
      id: (json['id'] ?? 0) as int,
      empresaId: (json['empresaId'] ?? 0) as int,
      numero: json['numero']?.toString() ?? '',
      serie: (json['serie'] ?? 0) as int,
      dataHora: _parseDateTime(json['dataHora']?.toString()) ?? DateTime.now(),
      statusNfe: NfeStatus.fromCode(json['statusNfe']?.toString() ?? json['status']?.toString()),
      cnpjEmitente: json['cnpjEmitente']?.toString() ?? '',
      uf: json['uf']?.toString() ?? '',
      ambiente: json['ambiente']?.toString() ?? 'HOMOLOGACAO',
      protocolo: json['protocolo']?.toString(),
      dataHoraSefaz: _parseDateTime(json['dataHoraSefaz']?.toString()),
      xmlNfe: json['xmlNfe']?.toString(),
      xmlNfeAssinado: json['xmlNfeAssinado']?.toString(),
      criadoEm: _parseDateTime(json['criadoEm']?.toString()) ?? DateTime.now(),
      atualizadoEm: _parseDateTime(json['atualizadoEm']?.toString()),
      tomador: json['tomador'] != null
          ? NfeTomadorModel.fromJson(json['tomador'] as Map<String, dynamic>)
          : _defaultTomador(),
      itens: (json['itens'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>()
              .map((item) => NfeItemModel.fromJson(item))
              .toList() ??
          [],
      valores: json['valores'] != null
          ? ValoresNfeModel.fromJson(json['valores'] as Map<String, dynamic>)
          : ValoresNfeModel(
              subtotal: 0,
              totalIcms: 0,
              totalPis: 0,
              totalCofins: 0,
              desconto: 0,
              total: 0,
            ),
      sefazProtocolo: json['sefazProtocolo'] != null
          ? SefazProtocoloModel.fromJson(json['sefazProtocolo'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'empresaId': empresaId,
    'numero': numero,
    'serie': serie,
    'dataHora': dataHora.toIso8601String(),
    'statusNfe': statusNfe.code,
    'cnpjEmitente': cnpjEmitente,
    'uf': uf,
    'ambiente': ambiente,
    'protocolo': protocolo,
    'dataHoraSefaz': dataHoraSefaz?.toIso8601String(),
    'xmlNfe': xmlNfe,
    'xmlNfeAssinado': xmlNfeAssinado,
    'criadoEm': criadoEm.toIso8601String(),
    'atualizadoEm': atualizadoEm?.toIso8601String(),
    'tomador': tomador.toJson(),
    'itens': itens.map((i) => i.toJson()).toList(),
    'valores': valores.toJson(),
    if (sefazProtocolo != null) 'sefazProtocolo': sefazProtocolo?.toJson(),
  };

  /// Retorna número formatado (série-número)
  String get numeroFormatado => '$serie-$numero';

  /// Permite download do PDF?
  bool get canDownloadPdf => statusNfe.isAutorizada && xmlNfeAssinado != null;

  /// Permite visualização do XML?
  bool get canViewXml => xmlNfeAssinado != null;

  /// Retorna ambiente formatado para exibição
  String get ambienteLabel => ambiente.toUpperCase() == 'PRODUCAO' ? 'Produção' : 'Homologação';

  /// Verifica se NFe está em ambiente de produção
  bool get isProducao => ambiente.toUpperCase() == 'PRODUCAO';

  /// Helper para parsing de data
  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (e) {
      return null;
    }
  }

  /// Cria tomador padrão vazio
  static NfeTomadorModel _defaultTomador() => const NfeTomadorModel(
    cnpjCpf: '',
    razaoSocial: '',
    endereco: '',
    numero: '',
    bairro: '',
    cep: '',
    uf: '',
    municipio: '',
  );
}
