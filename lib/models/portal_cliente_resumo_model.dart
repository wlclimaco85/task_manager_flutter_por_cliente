// lib/models/portal_cliente_resumo_model.dart

/// Model para resumo do Portal do Cliente
/// Espelha PortalClienteResumoDto do backend
class PortalClienteResumo {
  double? saldo;
  int? docsPendentes;
  int? alertas;

  PortalClienteResumo({
    this.saldo,
    this.docsPendentes,
    this.alertas,
  });

  /// Desserializa a resposta do endpoint /api/portal-cliente/resumo
  factory PortalClienteResumo.fromJson(Map<String, dynamic> json) {
    return PortalClienteResumo(
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      docsPendentes: json['docsPendentes'] as int? ?? 0,
      alertas: json['alertas'] as int? ?? 0,
    );
  }

  /// Serializa para mapa
  Map<String, dynamic> toJson() => {
    'saldo': saldo,
    'docsPendentes': docsPendentes,
    'alertas': alertas,
  };

  /// Formata saldo em moeda brasileira
  String get saldoFormatado {
    final formatter = _CurrencyFormatter();
    return formatter.format(saldo ?? 0.0);
  }
}

/// Utilitário para formatação de moeda
class _CurrencyFormatter {
  String format(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',').replaceAll(RegExp(r'\B(?=(\d{3})+(?!\d))'), '.')}';
  }
}
