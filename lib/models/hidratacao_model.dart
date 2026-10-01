class HidratacaoRegistro {
  final int id;
  final int quantidadeMl;
  final DateTime dataRegistro;
  final DateTime registradoEm;

  HidratacaoRegistro({
    required this.id,
    required this.quantidadeMl,
    required this.dataRegistro,
    required this.registradoEm,
  });

  factory HidratacaoRegistro.fromJson(Map<String, dynamic> json) {
    return HidratacaoRegistro(
      id: (json['id'] as num?)?.toInt() ?? 0,
      quantidadeMl: (json['quantidadeMl'] as num?)?.toInt() ?? 0,
      dataRegistro: DateTime.tryParse('${json['dataRegistro']}') ?? DateTime.now(),
      registradoEm: DateTime.tryParse('${json['registradoEm']}') ?? DateTime.now(),
    );
  }
}

class HidratacaoDiaResumo {
  final DateTime data;
  final int totalMl;

  HidratacaoDiaResumo({required this.data, required this.totalMl});

  factory HidratacaoDiaResumo.fromJson(Map<String, dynamic> json) {
    return HidratacaoDiaResumo(
      data: DateTime.tryParse('${json['data']}') ?? DateTime.now(),
      totalMl: (json['totalMl'] as num?)?.toInt() ?? 0,
    );
  }
}

class HidratacaoResumo {
  final DateTime data;
  final int totalMl;
  final int metaDiariaMl;
  final int volumeCopoMl;
  final double percentual;
  final List<HidratacaoRegistro> registros;
  final List<HidratacaoDiaResumo> historico;

  HidratacaoResumo({
    required this.data,
    required this.totalMl,
    required this.metaDiariaMl,
    required this.volumeCopoMl,
    required this.percentual,
    required this.registros,
    required this.historico,
  });

  factory HidratacaoResumo.fromJson(Map<String, dynamic> json) {
    final registros = (json['registros'] as List? ?? [])
        .whereType<Map>()
        .map((e) => HidratacaoRegistro.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final historico = (json['historico'] as List? ?? [])
        .whereType<Map>()
        .map((e) => HidratacaoDiaResumo.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return HidratacaoResumo(
      data: DateTime.tryParse('${json['data']}') ?? DateTime.now(),
      totalMl: (json['totalMl'] as num?)?.toInt() ?? 0,
      metaDiariaMl: (json['metaDiariaMl'] as num?)?.toInt() ?? 2000,
      volumeCopoMl: (json['volumeCopoMl'] as num?)?.toInt() ?? 250,
      percentual: ((json['percentual'] as num?)?.toDouble() ?? 0).clamp(0, 1),
      registros: registros,
      historico: historico,
    );
  }
}
