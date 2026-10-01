// lib/models/nfe_duplicata_model.dart
// NF07 — modelo de duplicata da NF-e

class NfeDuplicata {
  final int? id;
  final String? nDup;
  final String? dVenc;
  final double? vDup;

  const NfeDuplicata({this.id, this.nDup, this.dVenc, this.vDup});

  factory NfeDuplicata.fromJson(Map<String, dynamic> json) => NfeDuplicata(
        id: json['id'] as int?,
        nDup: json['nDup']?.toString() ?? json['n_dup']?.toString(),
        dVenc: json['dVenc']?.toString() ?? json['d_venc']?.toString(),
        vDup: ((json['vDup'] ?? json['v_dup']) as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (nDup != null) 'nDup': nDup,
        if (dVenc != null) 'dVenc': dVenc,
        if (vDup != null) 'vDup': vDup,
      };

  NfeDuplicata copyWith({
    int? id,
    String? nDup,
    String? dVenc,
    double? vDup,
  }) =>
      NfeDuplicata(
        id: id ?? this.id,
        nDup: nDup ?? this.nDup,
        dVenc: dVenc ?? this.dVenc,
        vDup: vDup ?? this.vDup,
      );
}
