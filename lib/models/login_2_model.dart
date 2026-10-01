import 'package:flutter/material.dart';
import '../../../models/parceiro_model.dart';
import '../../../models/empresa_model.dart';
import '../../../models/aplicativo_model.dart';
import '../../../widgets/generic_grid_screen.dart';
import '../../../models/role_model.dart';
import '../../../utils/utils.dart';

class Login {
  int? id;
  String? email;
  String? senha;
  String? nome;
  String? cpfCnpj;
  String? foto;
  List<Role>? roles;
  LoginEnum? tipoLogin;
  Empresa? empresa;
  Parceiro? parceiro;
  Aplicativo? aplicativo;
  DateTime? dhCreatedAt;
  DateTime? dhUpdatedAt;

  Login({
    this.id,
    this.email,
    this.senha,
    this.nome,
    this.cpfCnpj,
    this.foto,
    this.roles,
    this.tipoLogin,
    this.empresa,
    this.parceiro,
    this.aplicativo,
    this.dhCreatedAt,
    this.dhUpdatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'senha': senha,
      'nome': nome,
      'cpfCnpj': cpfCnpj,
      'foto': foto,
      'roles': roles?.map((role) => role.toJson()).toList(),
      'tipoLogin': tipoLogin?.value, // Salve o value em vez do index
      'empresa': empresa?.toJson(),
      'parceiro': parceiro?.toJson(),
      'aplicativo': aplicativo?.toJson(),
      'dhCreatedAt': dhCreatedAt?.toIso8601String(),
      'dhUpdatedAt': dhUpdatedAt?.toIso8601String(),
    };
  }

  Login.fromJson(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      id = json['id'];
      email = json['email'];
      senha = json['senha'];
      nome = json['nome'];
      cpfCnpj = json['cpfCnpj'];
      foto = json['foto'];

      roles = json['roles'] != null
          ? (json['roles'] as List).map((i) => Role.fromJson(i)).toList()
          : null;

      // Corrigido: use o value para converter
      if (json['tipoLogin'] != null) {
        final tipoLoginValue = json['tipoLogin'] is String
            ? int.tryParse(json['tipoLogin'])
            : json['tipoLogin'] as int?;

        tipoLogin = tipoLoginValue != null
            ? LoginEnum.fromValue(tipoLoginValue)
            : LoginEnum.APP_ABRACO;
      } else {
        tipoLogin = LoginEnum.APP_ABRACO;
      }

      // CORRIGIDO: estava 'endereco' em vez de 'aplicativo'
      aplicativo = json['aplicativo'] != null
          ? Aplicativo.fromJson(json['aplicativo'])
          : null;

      empresa =
          json['empresa'] != null ? Empresa.fromJson(json['empresa']) : null;

      parceiro =
          json['parceiro'] != null ? Parceiro.fromJson(json['parceiro']) : null;

      // CORRIGIDO: chaves corretas para as datas
      dhCreatedAt = json['dhCreatedAt'] != null
          ? DateTime.parse(json['dhCreatedAt'])
          : null;

      dhUpdatedAt = json['dhUpdatedAt'] != null
          ? DateTime.parse(json['dhUpdatedAt'])
          : null;
    }
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Email",
      fieldName: "email",
      icon: Icons.email,
      isFilterable: true,
      isInForm: true,
      isRequired: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email é obrigatório';
        if (!value.contains('@')) return 'Email inválido';
        return null;
      },
    ),
    FieldConfig(
      label: "Senha",
      fieldName: "senha",
      icon: Icons.lock,
      isInForm: true,
      isRequired: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Senha é obrigatória';
        if (value.length < 6) return 'Senha deve ter pelo menos 6 caracteres';
        return null;
      },
    ),
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.person,
      isFilterable: true,
      isInForm: true,
      isRequired: true,
    ),
    const FieldConfig(
      label: "CPF/CNPJ",
      fieldName: "cpfCnpj",
      icon: Icons.badge,
      isFilterable: true,
      isInForm: true,
    ),
    FieldConfig(
      label: "Tipo Login",
      fieldName: "tipoLogin",
      icon: Icons.login,
      isFilterable: false,
      isInForm: false,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return LoginEnum.values
            .map((e) => {'value': e.name, 'label': e.name})
            .toList();
      },
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
    ),
  ];
}

// Primeiro, defina o LoginEnum com valores explícitos para evitar problemas
enum LoginEnum {
  MASTER(0, 'Administrador'),
  APP_PERSONAL(1, 'Usuário'),
  APP_ACADEMIA(2, 'Parceiro'),
  APP_NUTRICIONISTA(3, 'Parceiro'),
  APP_ALUNO(4, 'Parceiro'),
  APP_ABRACO(5, 'Parceiro'),
  APP_CONTABILIDADE(6, 'Parceiro'),
  APP_AGROPECUARIA(7, 'Parceiro');

  final int value;
  final String label;
  const LoginEnum(this.value, this.label);

  // Método para converter de valor inteiro para enum
  static LoginEnum fromValue(int value) {
    return LoginEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LoginEnum.APP_ABRACO, // valor padrão se não encontrado
    );
  }
}

class LoginModel {
  String? status;
  String? token;
  Data? data;
  Login? login;

  LoginModel({this.status, this.token, this.data, this.login});

  LoginModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    token = json['token'];
    data = json['data'] != null ? Data.fromJson(json['data']) : null;
    login = json['login'] != null ? Login.fromJson(json['login']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['token'] = token;

    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }

    // CORRIGIDO: estava salvando data em vez de login
    if (login != null) {
      data['login'] = login!.toJson();
    }

    return data;
  }
}

class Data {
  int? id;
  String? email;
  String? firstName;
  String? lastName;
  String? mobile;
  String? photo;
  DadosPessoal? codDadosPessoal;
  Login? login;

  Data({
    this.id,
    this.email,
    this.firstName,
    this.lastName,
    this.mobile,
    this.photo,
    this.codDadosPessoal,
    this.login,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    mobile = json['mobile'];
    photo = json['photo'];
    codDadosPessoal = json['codDadosPessoal'] != null
        ? DadosPessoal.fromJson(json['codDadosPessoal'])
        : null;
    login = json['login'] != null ? Login.fromJson(json['login']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['email'] = email;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['mobile'] = mobile;
    data['photo'] = photo;
    data['login'] = login?.toJson();
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
      "academia": codDadosPessoal?.academia,
      "codProdutor": codDadosPessoal?.codProdutor,
      "incrMun": codDadosPessoal?.incrMun,
      "razaoSocial": codDadosPessoal?.razaoSocial,
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
  String? codProdutor;
  String? incrMun;
  String? razaoSocial;

  DadosPessoal({
    this.id,
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
    this.academia,
    this.codProdutor,
    this.incrMun,
    this.razaoSocial,
  });

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
    codProdutor = json['codProdutor'];
    incrMun = json['incrMun'];
    razaoSocial = json['razaoSocial'];
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
    codDadosPessoal['codProdutor'] = codProdutor;
    codDadosPessoal['incrMun'] = incrMun;
    codDadosPessoal['razaoSocial'] = razaoSocial;
    return codDadosPessoal;
  }
}
