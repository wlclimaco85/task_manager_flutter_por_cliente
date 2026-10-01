import '../customization/generic_grid_card.dart';

/// Cadastro de Serviços de NFS-e. CRUD via `/api/nfse_servico` (NfseServicoController).
/// A empresa é injetada pelo tenant no backend.
class NfseServico {
  final int? id;
  final String codigo;
  final String descricao;
  final double? aliquotaIss;
  final String? cnae;
  final String? codigoTributacaoMunicipal;
  final bool issRetido;
  final bool ativo;

  NfseServico({
    this.id,
    this.codigo = '',
    this.descricao = '',
    this.aliquotaIss,
    this.cnae,
    this.codigoTributacaoMunicipal,
    this.issRetido = false,
    this.ativo = true,
  });

  factory NfseServico.fromJson(Map<String, dynamic> json) => NfseServico(
        id: json['id'],
        codigo: json['codigo']?.toString() ?? '',
        descricao: json['descricao']?.toString() ?? '',
        aliquotaIss: (json['aliquotaIss'] as num?)?.toDouble(),
        cnae: json['cnae']?.toString(),
        codigoTributacaoMunicipal:
            json['codigoTributacaoMunicipal']?.toString(),
        issRetido: json['issRetido'] == true,
        ativo: json['ativo'] != false,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'codigo': codigo,
        'descricao': descricao,
        'aliquotaIss': aliquotaIss,
        'cnae': cnae,
        'codigoTributacaoMunicipal': codigoTributacaoMunicipal,
        'issRetido': issRetido,
        'ativo': ativo,
      };

  static final List<FieldConfig> fieldConfigs = [
    const FieldConfig(
        label: 'Código', fieldName: 'codigo', isRequired: true),
    const FieldConfig(
        label: 'Descrição', fieldName: 'descricao', isRequired: true),
    const FieldConfig(
        label: 'Alíquota ISS (%)',
        fieldName: 'aliquotaIss',
        fieldType: FieldType.number),
    const FieldConfig(label: 'CNAE', fieldName: 'cnae'),
    const FieldConfig(
        label: 'Cód. Tributação Municipal',
        fieldName: 'codigoTributacaoMunicipal'),
    const FieldConfig(
        label: 'ISS Retido',
        fieldName: 'issRetido',
        fieldType: FieldType.boolean),
    const FieldConfig(
        label: 'Ativo',
        fieldName: 'ativo',
        fieldType: FieldType.boolean),
  ];
}
