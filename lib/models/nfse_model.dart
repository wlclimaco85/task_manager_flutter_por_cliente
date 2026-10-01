import '../customization/generic_grid_card.dart';

/// Modelo de consulta de NFS-e (nota fiscal de serviço). Consome o grid
/// `/api/nfse` (NfseGridController). A EMISSÃO de fato é feita em outra tela/ação
/// (`/api/fiscal/nfse/emitir`); aqui é consulta/listagem read-only.
class Nfse {
  final int? id;
  final String numero;
  final String serie;
  final int? tomadorId;
  final String? tomadorNome;
  final String? dataEmissao;
  final String status;
  final double valorServicos;
  final double valorLiquido;
  final String? municipioPrestacao;
  final String? discriminacao;

  Nfse({
    this.id,
    this.numero = '',
    this.serie = '',
    this.tomadorId,
    this.tomadorNome,
    this.dataEmissao,
    this.status = '',
    this.valorServicos = 0,
    this.valorLiquido = 0,
    this.municipioPrestacao,
    this.discriminacao,
  });

  factory Nfse.fromJson(Map<String, dynamic> json) {
    final tomador = json['tomador'] as Map<String, dynamic>?;
    return Nfse(
      id: json['id'],
      numero: json['numero']?.toString() ?? '',
      serie: json['serie']?.toString() ?? '',
      tomadorId: tomador?['id'],
      tomadorNome: tomador?['nome']?.toString(),
      dataEmissao: json['dataEmissao']?.toString(),
      status: json['status']?.toString() ?? '',
      valorServicos: (json['valorServicos'] as num?)?.toDouble() ?? 0,
      valorLiquido: (json['valorLiquido'] as num?)?.toDouble() ?? 0,
      municipioPrestacao: json['municipioPrestacao']?.toString(),
      discriminacao: json['discriminacao']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'numero': numero,
        'serie': serie,
        'tomador': (tomadorId != null || tomadorNome != null)
            ? {'id': tomadorId, 'nome': tomadorNome}
            : null,
        'dataEmissao': dataEmissao,
        'status': status,
        'valorServicos': valorServicos,
        'valorLiquido': valorLiquido,
        'municipioPrestacao': municipioPrestacao,
        'discriminacao': discriminacao,
      };

  /// Campos só de exibição (consulta). isInForm:false — a criação/edição real é
  /// feita pela emissão fiscal, não por um formulário CRUD aqui.
  static final List<FieldConfig> fieldConfigs = [
    const FieldConfig(
        label: 'Número', fieldName: 'numero', isInForm: false),
    const FieldConfig(label: 'Série', fieldName: 'serie', isInForm: false),
    const FieldConfig(
        label: 'Tomador', fieldName: 'tomador.nome', isInForm: false),
    const FieldConfig(
        label: 'Emissão',
        fieldName: 'dataEmissao',
        fieldType: FieldType.date,
        isInForm: false),
    const FieldConfig(label: 'Status', fieldName: 'status', isInForm: false),
    const FieldConfig(
        label: 'Valor Serviços',
        fieldName: 'valorServicos',
        fieldType: FieldType.currency,
        isInForm: false),
    const FieldConfig(
        label: 'Valor Líquido',
        fieldName: 'valorLiquido',
        fieldType: FieldType.currency,
        isInForm: false),
    const FieldConfig(
        label: 'Município',
        fieldName: 'municipioPrestacao',
        isInForm: false),
    const FieldConfig(
        label: 'Discriminação',
        fieldName: 'discriminacao',
        isInForm: false,
        maxLines: 2),
  ];
}
