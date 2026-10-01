/// Modelo que representa os dados do tomador (cliente) de uma NFe
class NfeTomadorModel {
  final String cnpjCpf;
  final String razaoSocial;
  final String endereco;
  final String numero;
  final String? complemento;
  final String bairro;
  final String cep;
  final String uf;
  final String municipio;
  final String? email;
  final String? telefone;

  const NfeTomadorModel({
    required this.cnpjCpf,
    required this.razaoSocial,
    required this.endereco,
    required this.numero,
    this.complemento,
    required this.bairro,
    required this.cep,
    required this.uf,
    required this.municipio,
    this.email,
    this.telefone,
  });

  /// Cria instância a partir de JSON
  factory NfeTomadorModel.fromJson(Map<String, dynamic> json) {
    return NfeTomadorModel(
      cnpjCpf: json['cnpjCpf']?.toString() ?? json['cpf']?.toString() ?? '',
      razaoSocial: json['razaoSocial']?.toString() ?? json['nome']?.toString() ?? '',
      endereco: json['endereco']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      complemento: json['complemento']?.toString(),
      bairro: json['bairro']?.toString() ?? '',
      cep: json['cep']?.toString() ?? '',
      uf: json['uf']?.toString() ?? '',
      municipio: json['municipio']?.toString() ?? '',
      email: json['email']?.toString(),
      telefone: json['telefone']?.toString(),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'cnpjCpf': cnpjCpf,
    'razaoSocial': razaoSocial,
    'endereco': endereco,
    'numero': numero,
    if (complemento != null && complemento!.isNotEmpty) 'complemento': complemento,
    'bairro': bairro,
    'cep': cep,
    'uf': uf,
    'municipio': municipio,
    if (email != null && email!.isNotEmpty) 'email': email,
    if (telefone != null && telefone!.isNotEmpty) 'telefone': telefone,
  };

  /// Retorna endereço formatado completo
  String get enderecoCompleto {
    final parts = <String>[
      endereco,
      numero,
      if (complemento != null && complemento!.isNotEmpty) complemento!,
      bairro,
      municipio,
      uf,
    ];
    return parts.join(', ');
  }

  /// Formata CNPJ/CPF para exibição
  String get cnpjCpfFormatado {
    final clean = cnpjCpf.replaceAll(RegExp(r'\D'), '');
    if (clean.length == 11) {
      // CPF
      return clean.replaceAllMapped(
        RegExp(r'(\d{3})(\d{3})(\d{3})(\d{2})'),
        (m) => '${m[1]}.${m[2]}.${m[3]}-${m[4]}',
      );
    } else if (clean.length == 14) {
      // CNPJ
      return clean.replaceAllMapped(
        RegExp(r'(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})'),
        (m) => '${m[1]}.${m[2]}.${m[3]}/${m[4]}-${m[5]}',
      );
    }
    return cnpjCpf;
  }

  /// Verifica se é pessoa jurídica (CNPJ com 14 dígitos)
  bool get isPj => cnpjCpf.replaceAll(RegExp(r'\D'), '').length == 14;

  /// Verifica se é pessoa física (CPF com 11 dígitos)
  bool get isPf => cnpjCpf.replaceAll(RegExp(r'\D'), '').length == 11;
}
