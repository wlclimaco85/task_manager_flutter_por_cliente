// lib/models/nfe_fatura_model.dart
// NF07 — modelo de fatura da NF-e

class NfeFatura {
  final int? id;
  final String? nFat;
  final double? vOrig;
  final double? vLiq;

  const NfeFatura({this.id, this.nFat, this.vOrig, this.vLiq});

  factory NfeFatura.fromJson(Map<String, dynamic> json) => NfeFatura(
        id: json['id'] as int?,
        nFat: json['nFat']?.toString() ?? json['n_fat']?.toString(),
        vOrig: ((json['vOrig'] ?? json['v_orig']) as num?)?.toDouble(),
        vLiq: ((json['vLiq'] ?? json['v_liq']) as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (nFat != null) 'nFat': nFat,
        if (vOrig != null) 'vOrig': vOrig,
        if (vLiq != null) 'vLiq': vLiq,
      };

  NfeFatura copyWith({int? id, String? nFat, double? vOrig, double? vLiq}) =>
      NfeFatura(
        id: id ?? this.id,
        nFat: nFat ?? this.nFat,
        vOrig: vOrig ?? this.vOrig,
        vLiq: vLiq ?? this.vLiq,
      );
}
