class PersonalDtoModel {
  dynamic data;

  PersonalDtoModel({this.data});

  PersonalDtoModel.fromJson(Map<String, dynamic> json) {
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class PersonalDto {
  int? id;
  String? cref;
  double? vlrAula;
  dynamic data;

  PersonalDto({this.id, this.cref, this.data});

  PersonalDto.fromJson(Map<String, dynamic> json) {
    cref = json['cref'];
    id = json['id'];
    vlrAula = json['vlrAula'];
    data = json['data'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['cref'] = cref;
    data['id'] = id;
    data['vlrAula'] = vlrAula;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}
/*
class Data {
  String? email;
  String? firstName;
  String? lastName;
  String? mobile;
  String? photo;
  DadosPessoal? codDadosPessoal;

  Data(
      {this.email,
      this.firstName,
      this.lastName,
      this.mobile,
      this.photo,
      this.codDadosPessoal});

  Data.fromJson(Map<String, dynamic> json) {
    email = json['email'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    mobile = json['mobile'];
    photo = json['photo'];
    codDadosPessoal = json['codDadosPessoal'] != null
        ? DadosPessoal.fromJson(json['codDadosPessoal'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['email'] = email;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['mobile'] = mobile;
    data['photo'] = photo;
    data['codDadosPessoal'] = {
      "id": codDadosPessoal?.id,
      "nome": codDadosPessoal?.nome,
      "cpf": codDadosPessoal?.cpf,
      "telefone1": codDadosPessoal?.telefone1,
      "telefone2": codDadosPessoal?.telefone2,
      "logradouro": codDadosPessoal?.logradouro,
      "numero": codDadosPessoal?.numero,
      "cep": codDadosPessoal?.cep,
      "bairro": codDadosPessoal?.bairro,
      "cidade": codDadosPessoal?.cidade,
      "estado": codDadosPessoal?.estado,
      "pais": codDadosPessoal?.pais,
      "email": codDadosPessoal?.email,
      "fistName": codDadosPessoal?.fistName,
      "lastName": codDadosPessoal?.lastName,
      "photo": codDadosPessoal?.photo,
      "tipoAluno": codDadosPessoal?.tipoAluno,
      "parentId": codDadosPessoal?.parentId,
      "academia": codDadosPessoal?.academia
    };

    return data;
  }
}

class DadosPessoal {
  int? id;
  String? nome;
  String? cpf;
  String? telefone1;
  String? telefone2;
  String? logradouro;
  String? numero;
  String? cep;
  String? bairro;
  String? cidade;
  String? estado;
  String? pais;
  String? email;
  String? fistName;
  String? lastName;
  String? photo;
  String? tipoAluno;
  int? parentId;
  String? academia;

  DadosPessoal(
      {this.id,
      this.nome,
      this.cpf,
      this.telefone1,
      this.telefone2,
      this.logradouro,
      this.numero,
      this.cep,
      this.bairro,
      this.cidade,
      this.estado,
      this.pais,
      this.email,
      this.fistName,
      this.lastName,
      this.photo,
      this.tipoAluno,
      this.parentId,
      this.academia});

  DadosPessoal.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    cpf = json['cpf'];
    telefone1 = json['telefone1'];
    telefone2 = json['telefone2'];
    logradouro = json['logradouro'];
    numero = json['numero'];
    cep = json['cep'];
    bairro = json['bairro'];
    cidade = jsonToString(json['cidade']);
    estado = jsonToString(json['estado']);
    pais = jsonToString(json['pais']);
    email = json['email'];
    fistName = json['fistName'];
    lastName = json['lastName'];
    photo = json['photo'];
    tipoAluno = json['tipoAluno'];
    parentId = json['parentId'];
    academia = json['academia'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> codDadosPessoal = <String, dynamic>{};
    codDadosPessoal['id'] = id;
    codDadosPessoal['nome'] = nome;
    codDadosPessoal['cpf'] = cpf;
    codDadosPessoal['telefone1'] = telefone1;
    codDadosPessoal['telefone2'] = telefone2;
    codDadosPessoal['logradouro'] = logradouro;
    codDadosPessoal['numero'] = numero;
    codDadosPessoal['cep'] = cep;
    codDadosPessoal['bairro'] = bairro;
    codDadosPessoal['cidade'] = cidade;
    codDadosPessoal['estado'] = estado;
    codDadosPessoal['pais'] = pais;
    codDadosPessoal['email'] = email;
    codDadosPessoal['fistName'] = fistName;
    codDadosPessoal['lastName'] = lastName;
    codDadosPessoal['photo'] = photo;
    codDadosPessoal['tipoAluno'] = tipoAluno;
    codDadosPessoal['parentId'] = parentId;
    codDadosPessoal['academia'] = academia;
    return codDadosPessoal;
  }
}*/
