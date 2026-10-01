import 'package:hive/hive.dart';
import 'nfe_draft_status.dart';

/// Rascunho local de uma NFe salva quando o dispositivo está sem conexão
/// (card W3R3 — Offline Queue). Usa uma box própria (`nfe_drafts_offline`)
/// para isolar o payload de formulário pendente de qualquer cache legado.
///
/// [dadosFormulario] guarda o payload bruto que seria enviado ao backend
/// (mesmo Map usado por `TenantContext.post(ApiLinks.emitirNfe(id), body)`),
/// não dados sensíveis — por isso não usa `flutter_secure_storage` (regra do
/// card: só criptografar o que for sensível; formulário de NFe não é).
class NfeDraftModel {
  /// Identificador local do rascunho (uuid simples baseado em timestamp).
  final String id;

  /// Id da NFe no servidor à qual este rascunho se refere (ex.: emissão de
  /// uma NFe já criada como PENDENTE que falhou ao tentar "Emitir" offline).
  /// Usado na resolução de conflito: nunca reenviar/sobrescrever se o
  /// servidor já tiver essa NFe com status autorizada/transmitida.
  final String nfeIdReferencia;

  /// Corpo exato que será reenviado ao backend quando a conexão voltar —
  /// precisa ser FIEL ao que a ação original enviaria (ex.: para 'emitir',
  /// isso é sempre `{}`, pois `TenantContext.post(ApiLinks.emitirNfe(id), {})`
  /// não manda corpo; a NFe já existe no servidor, só falta emitir). Nunca
  /// usar isso para guardar dado de exibição — ver [contextoExibicao].
  final Map<String, dynamic> dadosFormulario;

  /// Dados só para exibição na UI do rascunho (ex.: número, destinatário,
  /// valor da linha da grid no momento da falha). NÃO é reenviado ao
  /// backend — só [dadosFormulario] é.
  final Map<String, dynamic> contextoExibicao;

  /// Ação original que falhou por falta de conexão (ex.: 'emitir').
  final String acao;

  final NfeDraftStatus status;
  final DateTime criadoEm;
  final DateTime atualizadoEm;
  final String? mensagemErro;

  const NfeDraftModel({
    required this.id,
    required this.nfeIdReferencia,
    required this.dadosFormulario,
    this.contextoExibicao = const {},
    required this.acao,
    required this.status,
    required this.criadoEm,
    required this.atualizadoEm,
    this.mensagemErro,
  });

  NfeDraftModel copyWith({
    NfeDraftStatus? status,
    DateTime? atualizadoEm,
    String? mensagemErro,
    bool clearMensagemErro = false,
  }) {
    return NfeDraftModel(
      id: id,
      nfeIdReferencia: nfeIdReferencia,
      dadosFormulario: dadosFormulario,
      contextoExibicao: contextoExibicao,
      acao: acao,
      status: status ?? this.status,
      criadoEm: criadoEm,
      atualizadoEm: atualizadoEm ?? DateTime.now(),
      mensagemErro:
          clearMensagemErro ? null : (mensagemErro ?? this.mensagemErro),
    );
  }

  factory NfeDraftModel.fromJson(Map<String, dynamic> json) {
    return NfeDraftModel(
      id: json['id']?.toString() ?? '',
      nfeIdReferencia: json['nfeIdReferencia']?.toString() ?? '',
      dadosFormulario: json['dadosFormulario'] != null
          ? Map<String, dynamic>.from(json['dadosFormulario'] as Map)
          : <String, dynamic>{},
      contextoExibicao: json['contextoExibicao'] != null
          ? Map<String, dynamic>.from(json['contextoExibicao'] as Map)
          : <String, dynamic>{},
      acao: json['acao']?.toString() ?? 'emitir',
      status: NfeDraftStatus.fromCode(json['status']?.toString()),
      criadoEm: DateTime.tryParse(json['criadoEm']?.toString() ?? '') ??
          DateTime.now(),
      atualizadoEm: DateTime.tryParse(json['atualizadoEm']?.toString() ?? '') ??
          DateTime.now(),
      mensagemErro: json['mensagemErro']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nfeIdReferencia': nfeIdReferencia,
        'dadosFormulario': dadosFormulario,
        'contextoExibicao': contextoExibicao,
        'acao': acao,
        'status': status.code,
        'criadoEm': criadoEm.toIso8601String(),
        'atualizadoEm': atualizadoEm.toIso8601String(),
        if (mensagemErro != null) 'mensagemErro': mensagemErro,
      };
}

/// Adapter Hive para [NfeDraftModel]. Segue o mesmo padrão já usado no
/// projeto (`AgendamentoModelAdapter`, typeId 40): serializa via
/// toJson/fromJson, sem depender de build_runner/hive_generator (nenhum dos
/// dois está no pubspec.yaml do projeto).
///
/// typeId 41 — reservado para rascunhos NFe e sem colisão com adapters
/// existentes no projeto.
class NfeDraftModelAdapter extends TypeAdapter<NfeDraftModel> {
  @override
  final int typeId = 41;

  @override
  NfeDraftModel read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return NfeDraftModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, NfeDraftModel obj) {
    writer.writeMap(obj.toJson());
  }
}
