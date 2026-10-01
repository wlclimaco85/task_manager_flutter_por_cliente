class DashboardComercialMercadoriasModel {
  final double quantidadeEntrada;
  final double valorEntrada;
  final int notasEntrada;
  final double quantidadeSaida;
  final double valorSaida;
  final int notasSaida;
  final double saldoEstoque;
  final double valorEstoque;
  final int produtosEstoqueBaixo;
  final int produtosParados;
  final double variacaoCustoPercentual;
  final double giroEstoquePercentual;
  final double margemEstimadaPercentual;
  final List<SerieMercadoriaModel> serieMercadorias;
  final List<ProdutoVariacaoCustoModel> produtosVariacaoCusto;
  final List<IndiceMercadoComercialModel> indicesMercado;

  const DashboardComercialMercadoriasModel({
    required this.quantidadeEntrada,
    required this.valorEntrada,
    required this.notasEntrada,
    required this.quantidadeSaida,
    required this.valorSaida,
    required this.notasSaida,
    required this.saldoEstoque,
    required this.valorEstoque,
    required this.produtosEstoqueBaixo,
    required this.produtosParados,
    required this.variacaoCustoPercentual,
    required this.giroEstoquePercentual,
    required this.margemEstimadaPercentual,
    required this.serieMercadorias,
    required this.produtosVariacaoCusto,
    required this.indicesMercado,
  });

  factory DashboardComercialMercadoriasModel.empty() =>
      const DashboardComercialMercadoriasModel(
        quantidadeEntrada: 0,
        valorEntrada: 0,
        notasEntrada: 0,
        quantidadeSaida: 0,
        valorSaida: 0,
        notasSaida: 0,
        saldoEstoque: 0,
        valorEstoque: 0,
        produtosEstoqueBaixo: 0,
        produtosParados: 0,
        variacaoCustoPercentual: 0,
        giroEstoquePercentual: 0,
        margemEstimadaPercentual: 0,
        serieMercadorias: [],
        produtosVariacaoCusto: [],
        indicesMercado: [],
      );

  factory DashboardComercialMercadoriasModel.fromJson(
      Map<String, dynamic> json) {
    return DashboardComercialMercadoriasModel(
      quantidadeEntrada: _toDouble(json['quantidadeEntrada']),
      valorEntrada: _toDouble(json['valorEntrada']),
      notasEntrada: _toInt(json['notasEntrada']),
      quantidadeSaida: _toDouble(json['quantidadeSaida']),
      valorSaida: _toDouble(json['valorSaida']),
      notasSaida: _toInt(json['notasSaida']),
      saldoEstoque: _toDouble(json['saldoEstoque']),
      valorEstoque: _toDouble(json['valorEstoque']),
      produtosEstoqueBaixo: _toInt(json['produtosEstoqueBaixo']),
      produtosParados: _toInt(json['produtosParados']),
      variacaoCustoPercentual: _toDouble(json['variacaoCustoPercentual']),
      giroEstoquePercentual: _toDouble(json['giroEstoquePercentual']),
      margemEstimadaPercentual: _toDouble(json['margemEstimadaPercentual']),
      serieMercadorias: _list(json['serieMercadorias'])
          .map(SerieMercadoriaModel.fromJson)
          .toList(),
      produtosVariacaoCusto: _list(json['produtosVariacaoCusto'])
          .map(ProdutoVariacaoCustoModel.fromJson)
          .toList(),
      indicesMercado: _list(json['indicesMercado'])
          .map(IndiceMercadoComercialModel.fromJson)
          .toList(),
    );
  }
}

class SerieMercadoriaModel {
  final String periodo;
  final double quantidadeEntrada;
  final double valorEntrada;
  final double quantidadeSaida;
  final double valorSaida;

  const SerieMercadoriaModel({
    required this.periodo,
    required this.quantidadeEntrada,
    required this.valorEntrada,
    required this.quantidadeSaida,
    required this.valorSaida,
  });

  factory SerieMercadoriaModel.fromJson(Map<String, dynamic> json) =>
      SerieMercadoriaModel(
        periodo: json['periodo']?.toString() ?? '',
        quantidadeEntrada: _toDouble(json['quantidadeEntrada']),
        valorEntrada: _toDouble(json['valorEntrada']),
        quantidadeSaida: _toDouble(json['quantidadeSaida']),
        valorSaida: _toDouble(json['valorSaida']),
      );
}

class ProdutoVariacaoCustoModel {
  final int produtoId;
  final String nome;
  final String ncm;
  final double estoque;
  final double custoAtual;
  final double custoAnterior;
  final double variacaoPercentual;

  const ProdutoVariacaoCustoModel({
    required this.produtoId,
    required this.nome,
    required this.ncm,
    required this.estoque,
    required this.custoAtual,
    required this.custoAnterior,
    required this.variacaoPercentual,
  });

  factory ProdutoVariacaoCustoModel.fromJson(Map<String, dynamic> json) =>
      ProdutoVariacaoCustoModel(
        produtoId: _toInt(json['produtoId']),
        nome: json['nome']?.toString() ?? '',
        ncm: json['ncm']?.toString() ?? '',
        estoque: _toDouble(json['estoque']),
        custoAtual: _toDouble(json['custoAtual']),
        custoAnterior: _toDouble(json['custoAnterior']),
        variacaoPercentual: _toDouble(json['variacaoPercentual']),
      );
}

class IndiceMercadoComercialModel {
  final String nome;
  final String descricao;
  final double mensalPercentual;
  final double acumulado12mPercentual;
  final String referencia;
  final String leitura;

  const IndiceMercadoComercialModel({
    required this.nome,
    required this.descricao,
    required this.mensalPercentual,
    required this.acumulado12mPercentual,
    required this.referencia,
    required this.leitura,
  });

  factory IndiceMercadoComercialModel.fromJson(Map<String, dynamic> json) =>
      IndiceMercadoComercialModel(
        nome: json['nome']?.toString() ?? '',
        descricao: json['descricao']?.toString() ?? '',
        mensalPercentual: _toDouble(json['mensalPercentual']),
        acumulado12mPercentual: _toDouble(json['acumulado12mPercentual']),
        referencia: json['referencia']?.toString() ?? '',
        leitura: json['leitura']?.toString() ?? '',
      );
}

List<Map<String, dynamic>> _list(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  return const [];
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
