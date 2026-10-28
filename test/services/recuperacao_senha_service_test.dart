import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/recuperacao_senha_service.dart';

http.Response _json(Map<String, dynamic> corpo, int status) => http.Response(
      jsonEncode(corpo),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('solicitarCodigo chama /rest/auth/recuperar-senha com o e-mail e nao exige token', () async {
    late http.Request enviado;
    final cliente = MockClient((req) async {
      enviado = req;
      return _json({'message': 'Se o e-mail estiver cadastrado, você receberá em instantes um código'}, 200);
    });

    final r = await http.runWithClient(
        () => RecuperacaoSenhaService.solicitarCodigo('  maria@exemplo.com '), () => cliente);

    expect(r.ok, isTrue);
    expect(enviado.method, 'POST');
    expect(enviado.url.path, endsWith('/rest/auth/recuperar-senha'));
    expect(jsonDecode(enviado.body), {'email': 'maria@exemplo.com'});
    expect(enviado.headers.containsKey('Authorization'), isFalse);
  });

  test('validarCodigo envia email+codigo e devolve a mensagem do servidor quando o codigo e invalido', () async {
    late http.Request enviado;
    final cliente = MockClient((req) async {
      enviado = req;
      return _json({'valido': false, 'message': 'Código inválido ou expirado.'}, 400);
    });

    final r = await http.runWithClient(
        () => RecuperacaoSenhaService.validarCodigo('maria@exemplo.com', ' 123456 '), () => cliente);

    expect(r.ok, isFalse);
    expect(r.mensagem, 'Código inválido ou expirado.');
    expect(enviado.url.path, endsWith('/rest/auth/validar-codigo'));
    expect(jsonDecode(enviado.body), {'email': 'maria@exemplo.com', 'codigo': '123456'});
  });

  test('redefinirSenha envia email, codigo e novaSenha; sucesso devolve ok', () async {
    late http.Request enviado;
    final cliente = MockClient((req) async {
      enviado = req;
      return _json({'message': 'Senha alterada com sucesso.'}, 200);
    });

    final r = await http.runWithClient(
        () => RecuperacaoSenhaService.redefinirSenha('maria@exemplo.com', '123456', 'NovaSenha123'), () => cliente);

    expect(r.ok, isTrue);
    expect(enviado.url.path, endsWith('/rest/auth/redefinir-senha'));
    expect(jsonDecode(enviado.body), {'email': 'maria@exemplo.com', 'codigo': '123456', 'novaSenha': 'NovaSenha123'});
  });

  test('senha fraca: mostra a mensagem do servidor; erro de rede e resposta sem corpo viram mensagem util', () async {
    final fraca = MockClient((_) async => _json({'message': 'A senha precisa ter pelo menos 8 caracteres.'}, 400));
    final semCorpo = MockClient((_) async => http.Response('', 500));
    final semRede = MockClient((_) async => throw http.ClientException('sem rede'));

    final r1 = await http.runWithClient(() => RecuperacaoSenhaService.redefinirSenha('a@x.com', '111111', 'x'), () => fraca);
    final r2 = await http.runWithClient(() => RecuperacaoSenhaService.validarCodigo('a@x.com', '111111'), () => semCorpo);
    final r3 = await http.runWithClient(() => RecuperacaoSenhaService.solicitarCodigo('a@x.com'), () => semRede);

    expect(r1.mensagem, contains('8 caracteres'));
    expect(r2.ok, isFalse);
    expect(r2.mensagem, 'Código inválido ou expirado.');
    expect(r3.ok, isFalse);
    expect(r3.mensagem, contains('conectar'));
  });

  test('senhaValida: minimo 8, com letra e numero', () {
    expect(RecuperacaoSenhaService.senhaValida('Abcdefg1'), isTrue);
    expect(RecuperacaoSenhaService.senhaValida('abcdefgh'), isFalse);
    expect(RecuperacaoSenhaService.senhaValida('12345678'), isFalse);
    expect(RecuperacaoSenhaService.senhaValida('Ab1'), isFalse);
  });

  test('telas de recuperacao usam o service (e nao mais o servidor de exemplo teamrabbil)', () {
    final links = File('lib/utils/api_links.dart').readAsStringSync();
    expect(links, isNot(contains('recoverVerifyEmail')));
    for (final tela in ['email_verification_screeen', 'otp_varification', 'reset_screen']) {
      final fonte = File('lib/auth_screens/$tela.dart').readAsStringSync();
      expect(fonte, contains('RecuperacaoSenhaService.'), reason: tela);
      expect(fonte, isNot(contains('NetworkCaller')), reason: tela);
    }
  });
}
