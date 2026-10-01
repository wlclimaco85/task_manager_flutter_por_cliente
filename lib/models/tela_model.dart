/// Modelo simples para representar uma Tela retornada por /api/telas
class Tela {
  final int id;
  final String nome;
  final String descricao;

  Tela({
    required this.id,
    required this.nome,
    required this.descricao,
  });

  factory Tela.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    if (idRaw == null) {
      throw FormatException('Tela requires non-null id');
    }

    late int id;
    if (idRaw is int) {
      id = idRaw;
    } else if (idRaw is String) {
      id = int.tryParse(idRaw) ?? 0;
      if (id <= 0) {
        throw FormatException('Tela id must be a positive integer');
      }
    } else {
      throw FormatException('Tela id must be int or String');
    }

    return Tela(
      id: id,
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? json['titulo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'descricao': descricao,
  };

  @override
  String toString() => 'Tela(id: $id, nome: $nome, descricao: $descricao)';
}
