/// Modelo de Série NF-e / NFC-e.
///
/// Campos adicionados no EPICO 1 de infraestrutura fiscal:
///   - [modelo] : "55" = NF-e, "65" = NFC-e (default "55")
///   - [uf]     : UF de emissão (nullable)
class NfeSerie {
  final int? id;
  final String? numero;
  final String? descricao;
  final bool? ativo;
  final Map<String, dynamic>? empresa;
  final Map<String, dynamic>? parceiro;

  /// Modelo fiscal: "55" = NF-e, "65" = NFC-e.
  final String modelo;

  /// UF de emissão (nullable).
  final String? uf;

  const NfeSerie({
    this.id,
    this.numero,
    this.descricao,
    this.ativo,
    this.empresa,
    this.parceiro,
    this.modelo = '55',
    this.uf,
  });

  factory NfeSerie.fromJson(Map<String, dynamic> json) {
    return NfeSerie(
      id: json['id'] as int?,
      numero: json['numero']?.toString(),
      descricao: json['descricao']?.toString(),
      ativo: json['ativo'] as bool?,
      empresa: json['empresa'] is Map
          ? Map<String, dynamic>.from(json['empresa'] as Map)
          : null,
      parceiro: json['parceiro'] is Map
          ? Map<String, dynamic>.from(json['parceiro'] as Map)
          : null,
      modelo: json['modelo']?.toString() ?? '55',
      uf: json['uf']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (numero != null) 'numero': numero,
      if (descricao != null) 'descricao': descricao,
      if (ativo != null) 'ativo': ativo,
      if (empresa != null) 'empresa': empresa,
      if (parceiro != null) 'parceiro': parceiro,
      'modelo': modelo,
      if (uf != null) 'uf': uf,
    };
  }

  NfeSerie copyWith({
    int? id,
    String? numero,
    String? descricao,
    bool? ativo,
    Map<String, dynamic>? empresa,
    Map<String, dynamic>? parceiro,
    String? modelo,
    String? uf,
  }) {
    return NfeSerie(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      descricao: descricao ?? this.descricao,
      ativo: ativo ?? this.ativo,
      empresa: empresa ?? this.empresa,
      parceiro: parceiro ?? this.parceiro,
      modelo: modelo ?? this.modelo,
      uf: uf ?? this.uf,
    );
  }

  static List<NfeSerie> fromJsonList(List<dynamic> list) {
    return list
        .whereType<Map>()
        .map((e) => NfeSerie.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
