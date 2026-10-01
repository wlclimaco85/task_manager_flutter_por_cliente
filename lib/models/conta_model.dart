// lib/data/models/conta_models.dart
class ContaBancariaModel {
  final int id;
  final String nome; // ex: "Itaú 1234-56789"
  final double saldo;

  ContaBancariaModel({
    required this.id,
    required this.nome,
    required this.saldo,
  });

  factory ContaBancariaModel.fromJson(Map<String, dynamic> j) {
    final nomeConta = (j['nomeConta'] ?? '').toString().trim();
    final fallback = [j['banco'], j['agencia'], j['numero']]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString().trim())
        .join(' ');

    return ContaBancariaModel(
      id: _toInt(j['contaId'] ?? j['id']),
      nome: nomeConta.isNotEmpty
          ? nomeConta
          : (fallback.isNotEmpty ? fallback : 'Conta bancária'),
      saldo: _toDouble(j['saldo']),
    );
  }
}

class ContaSaldoDia {
  final DateTime day;
  final double saldo;

  ContaSaldoDia(this.day, this.saldo);

  factory ContaSaldoDia.fromJson(Map<String, dynamic> j) {
    return ContaSaldoDia(
      _toDate(j['day']),
      _toDouble(j['saldo']),
    );
  }
}

class ContaExtratoOperacional {
  final String visao;
  final DateTime dataInicio;
  final DateTime dataFim;
  final int? contaId;
  final double saldoInicial;
  final double totalEntradas;
  final double totalSaidas;
  final double saldoFinal;
  final List<ContaExtratoOperacionalItem> itens;

  const ContaExtratoOperacional({
    required this.visao,
    required this.dataInicio,
    required this.dataFim,
    required this.contaId,
    required this.saldoInicial,
    required this.totalEntradas,
    required this.totalSaidas,
    required this.saldoFinal,
    required this.itens,
  });

  factory ContaExtratoOperacional.fromJson(Map<String, dynamic> j) {
    final rawItens = j['itens'];
    return ContaExtratoOperacional(
      visao: _toStringValue(j['visao'], 'CAIXA'),
      dataInicio: _toDate(j['dataInicio']),
      dataFim: _toDate(j['dataFim']),
      contaId: _toNullableInt(j['contaId']),
      saldoInicial: _toDouble(j['saldoInicial']),
      totalEntradas: _toDouble(j['totalEntradas']),
      totalSaidas: _toDouble(j['totalSaidas']),
      saldoFinal: _toDouble(j['saldoFinal']),
      itens: rawItens is List
          ? rawItens
              .whereType<Map>()
              .map((e) => ContaExtratoOperacionalItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList(growable: false)
          : const [],
    );
  }

  factory ContaExtratoOperacional.empty({
    required String visao,
    int? contaId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) {
    final inicio = dataInicio ?? DateTime.now();
    final fim = dataFim ?? inicio;
    return ContaExtratoOperacional(
      visao: visao,
      dataInicio: inicio,
      dataFim: fim,
      contaId: contaId,
      saldoInicial: 0,
      totalEntradas: 0,
      totalSaidas: 0,
      saldoFinal: 0,
      itens: const [],
    );
  }
}

class ContaExtratoOperacionalItem {
  final DateTime data;
  final String tipoLancamento;
  final int? tituloId;
  final String descricao;
  final String? numeroNota;
  final int? contaId;
  final String contaNome;
  final bool realizado;
  final double entrada;
  final double saida;
  final double saldoAcumulado;

  const ContaExtratoOperacionalItem({
    required this.data,
    required this.tipoLancamento,
    required this.tituloId,
    required this.descricao,
    this.numeroNota,
    required this.contaId,
    required this.contaNome,
    required this.realizado,
    required this.entrada,
    required this.saida,
    required this.saldoAcumulado,
  });

  factory ContaExtratoOperacionalItem.fromJson(Map<String, dynamic> j) {
    return ContaExtratoOperacionalItem(
      data: _toDate(j['data']),
      tipoLancamento: _toStringValue(j['tipoLancamento']),
      tituloId: _toNullableInt(j['tituloId']),
      descricao: _toStringValue(j['descricao']),
      numeroNota: _toNullableString(j['numeroNota']),
      contaId: _toNullableInt(j['contaId']),
      contaNome: _toStringValue(j['contaNome']),
      realizado: _toBool(j['realizado']),
      entrada: _toDouble(j['entrada']),
      saida: _toDouble(j['saida']),
      saldoAcumulado: _toDouble(j['saldoAcumulado']),
    );
  }
}


int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  final normalized = value.toString().trim().replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0.0;
}

DateTime _toDate(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'sim';
}

String _toStringValue(dynamic value, [String fallback = '']) {
  final text = value?.toString();
  return text ?? fallback;
}

String? _toNullableString(dynamic value) {
  final text = value?.toString();
  return (text == null || text.trim().isEmpty) ? null : text.trim();
}

