import 'alimento_model.dart';

class DiarioNutricionalResumo {
  final DateTime data;
  final double totalCalorias;
  final double totalProteinas;
  final double totalCarboidratos;
  final double totalGorduras;
  final List<DiarioNutricionalRefeicao> refeicoes;

  DiarioNutricionalResumo({
    required this.data,
    required this.totalCalorias,
    required this.totalProteinas,
    required this.totalCarboidratos,
    required this.totalGorduras,
    required this.refeicoes,
  });

  factory DiarioNutricionalResumo.empty(DateTime data) {
    return DiarioNutricionalResumo(
      data: data,
      totalCalorias: 0,
      totalProteinas: 0,
      totalCarboidratos: 0,
      totalGorduras: 0,
      refeicoes: const [],
    );
  }

  factory DiarioNutricionalResumo.fromJson(Map<String, dynamic> json) {
    final refeicoes = _asList(json['refeicoes'] ?? json['meals'])
        .whereType<Map>()
        .map((e) =>
            DiarioNutricionalRefeicao.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return DiarioNutricionalResumo(
      data: DateTime.tryParse('${json['data'] ?? json['dataRegistro']}') ??
          DateTime.now(),
      totalCalorias: _asDouble(json['totalCalorias'] ?? json['calorias']),
      totalProteinas: _asDouble(json['totalProteinas'] ?? json['proteinas']),
      totalCarboidratos:
          _asDouble(json['totalCarboidratos'] ?? json['carboidratos']),
      totalGorduras: _asDouble(json['totalGorduras'] ?? json['gorduras']),
      refeicoes: refeicoes,
    );
  }
}

class DiarioNutricionalRefeicao {
  final int id;
  final DateTime data;
  final String tipo;
  final String? foto;
  final double totalCalorias;
  final double totalProteinas;
  final double totalCarboidratos;
  final double totalGorduras;
  final List<DiarioNutricionalItem> itens;

  DiarioNutricionalRefeicao({
    required this.id,
    required this.data,
    required this.tipo,
    required this.foto,
    required this.totalCalorias,
    required this.totalProteinas,
    required this.totalCarboidratos,
    required this.totalGorduras,
    required this.itens,
  });

  factory DiarioNutricionalRefeicao.fromJson(Map<String, dynamic> json) {
    final itens = _asList(json['itens'] ?? json['items'])
        .whereType<Map>()
        .map(
            (e) => DiarioNutricionalItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return DiarioNutricionalRefeicao(
      id: _asInt(json['id']),
      data: DateTime.tryParse('${json['data'] ?? json['dataRegistro']}') ??
          DateTime.now(),
      tipo:
          (json['tipo'] ?? json['tipoRefeicao'] ?? '').toString().toUpperCase(),
      foto: (json['foto'] ?? json['fotoBase64'])?.toString(),
      totalCalorias: _asDouble(json['totalCalorias'] ?? json['calorias']),
      totalProteinas: _asDouble(json['totalProteinas'] ?? json['proteinas']),
      totalCarboidratos:
          _asDouble(json['totalCarboidratos'] ?? json['carboidratos']),
      totalGorduras: _asDouble(json['totalGorduras'] ?? json['gorduras']),
      itens: itens,
    );
  }
}

class DiarioNutricionalItem {
  final int id;
  final Alimento alimento;
  final double quantidadeGramas;
  final double calorias;
  final double proteinas;
  final double carboidratos;
  final double gorduras;

  DiarioNutricionalItem({
    required this.id,
    required this.alimento,
    required this.quantidadeGramas,
    required this.calorias,
    required this.proteinas,
    required this.carboidratos,
    required this.gorduras,
  });

  factory DiarioNutricionalItem.fromJson(Map<String, dynamic> json) {
    final alimentoJson = json['alimento'] is Map
        ? Map<String, dynamic>.from(json['alimento'] as Map)
        : <String, dynamic>{
            'id': json['alimentoId'],
            'nome': json['alimentoNome'],
            'calorias': json['caloriasAlimento'],
            'proteinas': json['proteinasAlimento'],
            'carboidratos': json['carboidratosAlimento'],
            'gorduras': json['gordurasAlimento'],
          };
    return DiarioNutricionalItem(
      id: _asInt(json['id']),
      alimento: Alimento.fromJson(alimentoJson),
      quantidadeGramas:
          _asDouble(json['quantidadeGramas'] ?? json['quantidade']),
      calorias: _asDouble(json['calorias'] ?? json['totalCalorias']),
      proteinas: _asDouble(json['proteinas'] ?? json['totalProteinas']),
      carboidratos:
          _asDouble(json['carboidratos'] ?? json['totalCarboidratos']),
      gorduras: _asDouble(json['gorduras'] ?? json['totalGorduras']),
    );
  }
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
}

int _asInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
