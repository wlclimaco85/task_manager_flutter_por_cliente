import '../customization/generic_grid_card.dart';

/// Série de NFS-e (numeração). CRUD via `/api/nfse_serie` (NfseSerieController).
/// A empresa é injetada pelo tenant no backend.
class NfseSerie {
  final int? id;
  final String serie;
  final String? descricao;
  final int? sequenciaInicial;
  final int? sequenciaFinal;
  final int? numeroAtual;

  NfseSerie({
    this.id,
    this.serie = '',
    this.descricao,
    this.sequenciaInicial,
    this.sequenciaFinal,
    this.numeroAtual,
  });

  factory NfseSerie.fromJson(Map<String, dynamic> json) => NfseSerie(
        id: json['id'],
        serie: json['serie']?.toString() ?? '',
        descricao: json['descricao']?.toString(),
        sequenciaInicial: (json['sequenciaInicial'] as num?)?.toInt(),
        sequenciaFinal: (json['sequenciaFinal'] as num?)?.toInt(),
        numeroAtual: (json['numeroAtual'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'serie': serie,
        'descricao': descricao,
        'sequenciaInicial': sequenciaInicial,
        'sequenciaFinal': sequenciaFinal,
        'numeroAtual': numeroAtual,
      };

  static final List<FieldConfig> fieldConfigs = [
    const FieldConfig(
        label: 'Série', fieldName: 'serie', isRequired: true),
    const FieldConfig(label: 'Descrição', fieldName: 'descricao'),
    const FieldConfig(
        label: 'Sequência Inicial',
        fieldName: 'sequenciaInicial',
        fieldType: FieldType.number),
    const FieldConfig(
        label: 'Sequência Final',
        fieldName: 'sequenciaFinal',
        fieldType: FieldType.number),
    const FieldConfig(
        label: 'Número Atual',
        fieldName: 'numeroAtual',
        fieldType: FieldType.number),
  ];
}
