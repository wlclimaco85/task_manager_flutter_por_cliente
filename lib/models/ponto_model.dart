import 'package:intl/intl.dart';

enum TipoRegistro { entrada, saida }

extension TipoRegistroApi on TipoRegistro {
  String get apiValue => this == TipoRegistro.entrada ? 'ENTRADA' : 'SAIDA';

  static TipoRegistro fromApi(String value) {
    final v = value.toUpperCase();
    if (v == 'ENTRADA') return TipoRegistro.entrada;
    return TipoRegistro.saida;
  }

  String get label => this == TipoRegistro.entrada ? 'Entrada' : 'Saída';
}

class PontoModel {
  final int id;
  final DateTime dataHora;
  final TipoRegistro tipo;
  final int? empresaId;
  final int? parceiroId;
  final int? loginId;
  final String? observacao;
  final bool ajustado;

  PontoModel({
    required this.id,
    required this.dataHora,
    required this.tipo,
    this.empresaId,
    this.parceiroId,
    this.loginId,
    this.observacao,
    required this.ajustado,
  });

  factory PontoModel.fromJson(Map<String, dynamic> json) {
    return PontoModel(
      id: json['id'] as int,
      dataHora: DateTime.parse(json['dataHoraRegistro']),
      tipo: TipoRegistroApi.fromApi(json['tipo']),
      empresaId: json['empresa']?['id'] as int?,
      parceiroId: json['parceiro']?['id'] as int?,
      loginId: (() {
        final login = json['login'];
        if (login == null) return null;
        if (login is int) return login;
        if (login is Map && login['id'] is int) return login['id'];
        return null;
      })(),
      observacao: json['observacao'] as String?,
      ajustado: json['ajustado'] == true,
    );
  }

  String get horaFormatada => DateFormat.Hm().format(dataHora);
}
