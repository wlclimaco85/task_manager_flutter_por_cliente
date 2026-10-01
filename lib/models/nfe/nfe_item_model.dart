/// Modelo que representa um item/linha dentro de uma NFe
class NfeItemModel {
  final int sequencial;
  final String codigoProduto;
  final String descricao;
  final String ncm;
  final String cfop;
  final String cstIcms;
  final double quantidade;
  final String unidade;
  final double precoUnitario;
  final double precoTotal;
  final double aliqIcms;
  final double vlIcms;
  final double aliqPis;
  final double vlPis;
  final double aliqCofins;
  final double vlCofins;

  const NfeItemModel({
    required this.sequencial,
    required this.codigoProduto,
    required this.descricao,
    required this.ncm,
    required this.cfop,
    required this.cstIcms,
    required this.quantidade,
    required this.unidade,
    required this.precoUnitario,
    required this.precoTotal,
    required this.aliqIcms,
    required this.vlIcms,
    required this.aliqPis,
    required this.vlPis,
    required this.aliqCofins,
    required this.vlCofins,
  });

  /// Cria instância a partir de JSON
  factory NfeItemModel.fromJson(Map<String, dynamic> json) {
    return NfeItemModel(
      sequencial: (json['sequencial'] ?? json['seq'] ?? 0) as int,
      codigoProduto: json['codigoProduto']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      ncm: json['ncm']?.toString() ?? '',
      cfop: json['cfop']?.toString() ?? '',
      cstIcms: json['cstIcms']?.toString() ?? '',
      quantidade: _toDouble(json['quantidade']),
      unidade: json['unidade']?.toString() ?? '',
      precoUnitario: _toDouble(json['precoUnitario']),
      precoTotal: _toDouble(json['precoTotal']),
      aliqIcms: _toDouble(json['aliqIcms']),
      vlIcms: _toDouble(json['vlIcms']),
      aliqPis: _toDouble(json['aliqPis']),
      vlPis: _toDouble(json['vlPis']),
      aliqCofins: _toDouble(json['aliqCofins']),
      vlCofins: _toDouble(json['vlCofins']),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'sequencial': sequencial,
    'codigoProduto': codigoProduto,
    'descricao': descricao,
    'ncm': ncm,
    'cfop': cfop,
    'cstIcms': cstIcms,
    'quantidade': quantidade,
    'unidade': unidade,
    'precoUnitario': precoUnitario,
    'precoTotal': precoTotal,
    'aliqIcms': aliqIcms,
    'vlIcms': vlIcms,
    'aliqPis': aliqPis,
    'vlPis': vlPis,
    'aliqCofins': aliqCofins,
    'vlCofins': vlCofins,
  };

  /// Calcula impostos totais do item
  double get totalImpostos => vlIcms + vlPis + vlCofins;

  /// Helper para converter valor para double com segurança
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
