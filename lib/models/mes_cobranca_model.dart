class MesCobranca {
  String mes;
  int quantidade;
  double valor;

  MesCobranca({
    required this.mes,
    required this.quantidade,
    required this.valor,
  });

  MesCobranca.fromJson(Map<String, dynamic> json)
      : mes = json['mes'] ?? '',
        quantidade = (json['quantidade'] as num?)?.toInt() ?? 0,
        valor = (json['valor'] as num?)?.toDouble() ?? 0.0;

  Map<String, dynamic> toJson() => {
        'mes': mes,
        'quantidade': quantidade,
        'valor': valor,
      };
}
