import 'package:flutter/material.dart';
import '../../../models/parceiro_model.dart';
import '../../../models/empresa_model.dart';
import '../../../models/aplicativo_model.dart';
import '../../customization/generic_grid_card.dart';
import '../../../models/role_model.dart';
import '../../../utils/utils.dart';
import '../../../utils/api_links.dart';
import '../../services/network_caller.dart';

class Login {
  int? id;
  String? email;
  String? senha;
  String? nome;
  String? cpfCnpj;
  String? foto;
  bool? ativo;
  List<Role>? roles;
  LoginEnum? tipoLogin;
  Empresa? empresa;
  Parceiro? parceiro;
  Aplicativo? aplicativo;
  bool? trocarSenhaProximoLogin;
  DateTime? dhCreatedAt;
  DateTime? dhUpdatedAt;

  Login({
    this.id,
    this.email,
    this.senha,
    this.nome,
    this.cpfCnpj,
    this.foto,
    this.ativo,
    this.roles,
    this.tipoLogin,
    this.empresa,
    this.parceiro,
    this.aplicativo,
    this.trocarSenhaProximoLogin,
    this.dhCreatedAt,
    this.dhUpdatedAt,
  });

  Map<String, dynamic> toJson() {
    final tipoVal = tipoLogin?.name ?? tipoLogin?.value;
    return {
      'id': id,
      'email': email,
      'senha': senha,
      'nome': nome,
      'cpfCnpj': cpfCnpj,
      'cpf_cnpj': cpfCnpj,
      'foto': foto,
      'ativo': ativo,
      'roles': roles?.map((role) => role.toJson()).toList(),
      'tipoLogin': tipoVal,
      'tipo_login': tipoVal,
      'empresa': empresa?.toJson(),
      'empresa_id': empresa?.id,
      'parceiro': parceiro?.toJson(),
      'parceiro_id': parceiro?.id,
      'aplicativo': aplicativo?.toJson(),
      'aplicativo_id': aplicativo?.id,
      'trocarSenhaProximoLogin': trocarSenhaProximoLogin,
      'dhCreatedAt': dhCreatedAt?.toIso8601String(),
      'dhUpdatedAt': dhUpdatedAt?.toIso8601String(),
    };
  }

  Login.fromJson(Map<String, dynamic> json) {
    if (json.isNotEmpty) {
      id = json['id'] is String ? int.tryParse(json['id']) : json['id'] as int?;
      email = json['email']?.toString();
      senha = json['senha']?.toString();
      nome = json['nome']?.toString();
      cpfCnpj = (json['cpfCnpj'] ?? json['cpf_cnpj'])?.toString();
      foto = json['foto']?.toString();
      ativo = json['ativo'] is bool
          ? json['ativo'] as bool
          : (json['is_ativo'] is bool
              ? json['is_ativo'] as bool
              : (json['isAtivo'] is bool
                  ? json['isAtivo'] as bool
                  : null));

      roles = json['roles'] != null
          ? (json['roles'] as List).map((i) => Role.fromJson(i)).toList()
          : null;

      final tipoRaw = json['tipoLogin'] ?? json['tipo_login'];
      if (tipoRaw != null) {
        tipoLogin = LoginEnum.fromBackend(tipoRaw);
      } else {
        tipoLogin = LoginEnum.APP_ABRACO;
      }

      if (json['aplicativo'] is Map) {
        aplicativo = Aplicativo.fromJson(json['aplicativo']);
      } else if (json['aplicativo'] is int) {
        aplicativo = Aplicativo(id: json['aplicativo']);
      } else if (json['id_aplicativo'] is int || json['aplicativo_id'] is int) {
        aplicativo = Aplicativo(id: (json['id_aplicativo'] ?? json['aplicativo_id']) as int);
      } else {
        aplicativo = null;
      }

      if (json['empresa'] is Map) {
        empresa = Empresa.fromJson(json['empresa']);
      } else if (json['empresa'] is int) {
        empresa = Empresa(id: json['empresa']);
      } else if (json['id_empresa'] is int || json['empresa_id'] is int) {
        empresa = Empresa(id: (json['id_empresa'] ?? json['empresa_id']) as int);
      } else {
        empresa = null;
      }

      if (json['parceiro'] is Map) {
        parceiro = Parceiro.fromJson(json['parceiro']);
      } else if (json['parceiro'] is int) {
        parceiro = Parceiro(id: json['parceiro']);
      } else if (json['id_parceiro'] is int || json['parceiro_id'] is int) {
        parceiro = Parceiro(id: (json['id_parceiro'] ?? json['parceiro_id']) as int);
      } else {
        parceiro = null;
      }

      trocarSenhaProximoLogin = json['trocarSenhaProximoLogin'] == true;

      // CORRIGIDO: chaves corretas para as datas
      dhCreatedAt = json['dhCreatedAt'] != null
          ? DateTime.parse(json['dhCreatedAt'])
          : null;

      dhUpdatedAt = json['dhUpdatedAt'] != null
          ? DateTime.parse(json['dhUpdatedAt'])
          : null;
    }
  }

  static Future<List<Map<String, dynamic>>> _loadEmpresas() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allEmpresas);
    if (response.isSuccess && response.body != null) {
      final lista = response.body!['data']['dados'] as List;
      return lista
          .map((e) => {'value': e['id'].toString(), 'label': e['nome']})
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> _loadParceiros() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allParceiros);
    if (response.isSuccess && response.body != null) {
      final lista = response.body!['data']['dados'] as List;
      return lista
          .map((e) => {'value': e['id'].toString(), 'label': e['nome']})
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> _loadAplicativos() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allAplicativos);
    if (response.isSuccess && response.body != null) {
      final lista = response.body!['data']['dados'] as List;
      return lista
          .map((e) => {'value': e['id'].toString(), 'label': e['nome']})
          .toList();
    }
    return [];
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
      isInForm: true,
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
    const FieldConfig(
      label: "Empresa",
      fieldName: "empresa",
      displayFieldName: "empresa.nome",
      icon: Icons.business,
      isFilterable: true,
      isInForm: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: _loadEmpresas,
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    const FieldConfig(
      label: "Parceiro",
      fieldName: "parceiro",
      displayFieldName: "parceiro.nome",
      icon: Icons.person_outline,
      isFilterable: true,
      isInForm: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: _loadParceiros,
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    const FieldConfig(
      label: "Aplicativo",
      fieldName: "aplicativo",
      displayFieldName: "aplicativo.nome",
      icon: Icons.apps,
      isFilterable: true,
      isInForm: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: _loadAplicativos,
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
    ),
  ];
}

// Primeiro, defina o LoginEnum com valores explícitos para evitar problemas
enum LoginEnum {
  MASTER(1, 'Administrador'),
  APP_PERSONAL(2, 'Usuário'),
  APP_ACADEMIA(3, 'Parceiro'),
  APP_NUTRICIONISTA(4, 'Parceiro'),
  APP_ALUNO(5, 'Parceiro'),
  APP_ABRACO(6, 'Parceiro'),
  APP_CONTABILIDADE(7, 'Parceiro'),
  APP_SITE_JOAO(8, 'Site Joao'),
  APP_AGROPECUARIA(9, 'Parceiro');

  final int value;
  final String label;
  const LoginEnum(this.value, this.label);

  // Método para converter de valor inteiro para enum
  static LoginEnum fromValue(int value) {
    if (value == 0) return LoginEnum.MASTER;
    return LoginEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => LoginEnum.APP_ABRACO, // valor padrão se não encontrado
    );
  }

  static LoginEnum fromBackend(dynamic value) {
    if (value is int) return fromValue(value);
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return LoginEnum.APP_ABRACO;
    final numeric = int.tryParse(raw);
    if (numeric != null) return fromValue(numeric);
    return LoginEnum.values.firstWhere(
      (e) => e.name.toUpperCase() == raw.toUpperCase(),
      orElse: () => LoginEnum.APP_ABRACO,
    );
  }
}

class LoginModel {
  String? status;
  String? token;
  Data? data;
  Login? login;

  /// Permissões retornadas pelo backend no login — substitui security_matrix.dart
  List<RolePermissaoItem>? permissoes;

  /// Retorna lista de roles (ou nomes) para compatibilidade
  List<dynamic> get roles => login?.roles?.map((r) => r.role).toList() ?? [];

  LoginModel({this.status, this.token, this.data, this.login, this.permissoes});

  LoginModel.fromJson(Map<String, dynamic> json) {
    // envelope: { data: { access_token, login, permissoes }, response: {...} }
    final dataMap = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : null;
    bool hasPayloadValue(String key) =>
        dataMap?[key] != null &&
        (dataMap![key] is! String || (dataMap[key] as String).isNotEmpty);
    final isBackendEnvelope = dataMap != null &&
        (hasPayloadValue('access_token') ||
            hasPayloadValue('token') ||
            hasPayloadValue('login') ||
            hasPayloadValue('permissoes'));
    final inner = isBackendEnvelope ? dataMap : json;

    status = (json['response']?['status'] ?? json['status'])?.toString();
    token = inner['access_token'] ??
        inner['token'] ??
        json['access_token'] ??
        json['token'];
    final dataJson = inner['data'] ?? inner['login'];
    data = dataJson != null ? Data.fromJson(dataJson) : null;
    login = inner['login'] != null ? Login.fromJson(inner['login']) : null;

    final permList = inner['permissoes'] ?? json['permissoes'];
    if (permList is List) {
      permissoes = permList
          .whereType<Map>()
          .map((e) => RolePermissaoItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
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

    if (permissoes != null) {
      data['permissoes'] = permissoes!.map((p) => p.toJson()).toList();
    }

    return data;
  }
}

/// Permissão de uma tela para uma role específica
class RolePermissaoItem {
  final int? id;
  final int? roleId;
  final String? roleKey;
  final String? roleDescription;
  final String telaNome;
  final bool podeVer;
  final bool podeInserir;
  final bool podeEditar;
  final bool podeDeletar;
  final bool podeBaixar;

  const RolePermissaoItem({
    this.id,
    this.roleId,
    this.roleKey,
    this.roleDescription,
    required this.telaNome,
    required this.podeVer,
    required this.podeInserir,
    required this.podeEditar,
    required this.podeDeletar,
    this.podeBaixar = false,
  });

  factory RolePermissaoItem.fromJson(Map<String, dynamic> json) =>
      RolePermissaoItem(
        id: json['id'] as int?,
        roleId: json['roleId'] as int?,
        roleKey: json['roleKey'] as String?,
        roleDescription: json['roleDescription'] as String?,
        telaNome: json['telaNome']?.toString() ?? '',
        podeVer: json['podeVer'] == true,
        podeInserir: json['podeInserir'] == true,
        podeEditar: json['podeEditar'] == true,
        podeDeletar: json['podeDeletar'] == true,
        podeBaixar: json['podeBaixar'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'roleId': roleId,
        'roleKey': roleKey,
        'roleDescription': roleDescription,
        'telaNome': telaNome,
        'podeVer': podeVer,
        'podeInserir': podeInserir,
        'podeEditar': podeEditar,
        'podeDeletar': podeDeletar,
        'podeBaixar': podeBaixar,
      };
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
    id = int.tryParse(json['id'].toString()) ?? 0;
    email = json['email'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    mobile = json['mobile'];
    photo = (json['photo'] != null && json['photo'].toString().trim().isNotEmpty)
        ? json['photo']
        : json['foto'];
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
