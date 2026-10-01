import '../../models/aluno_model.dart';

class LoginModel {
  final int? id;
  final String? nome;
  final String? email;
  final String? token;
  final String? role;
  final int? empresaId;
  final int? parceiroId;
  final bool? trocarSenhaProximoLogin;
  final AlunoModel? aluno;

  LoginModel({
    this.id,
    this.nome,
    this.email,
    this.token,
    this.role,
    this.empresaId,
    this.parceiroId,
    this.trocarSenhaProximoLogin,
    this.aluno,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      id: json['id'] as int?,
      nome: json['nome'] as String?,
      email: json['email'] as String?,
      token: json['token'] as String?,
      role: json['role'] as String?,
      empresaId: json['empresaId'] as int?,
      parceiroId: json['parceiroId'] as int?,
      trocarSenhaProximoLogin: json['trocarSenhaProximoLogin'] as bool?,
      aluno: json['aluno'] != null ? AlunoModel.fromJson(json['aluno']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (id != null) map['id'] = id;
    if (nome != null) map['nome'] = nome;
    if (email != null) map['email'] = email;
    if (token != null) map['token'] = token;
    if (role != null) map['role'] = role;
    if (empresaId != null) map['empresaId'] = empresaId;
    if (parceiroId != null) map['parceiroId'] = parceiroId;
    if (trocarSenhaProximoLogin != null) {
      map['trocarSenhaProximoLogin'] = trocarSenhaProximoLogin;
    }
    if (aluno != null) map['aluno'] = aluno!.toJson();
    return map;
  }
}
