import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/ponto_rep_p_service.dart';

PontoRepPService _svc(MockClient c) =>
    PontoRepPService(client: c, baseUrl: 'http://x', token: () => 'tok');

void main() {
  final ini = DateTime(2026, 11, 1);
  final fim = DateTime(2026, 11, 30);

  test('AFD: monta URL com empresa/periodo, envia Bearer e devolve bytes', () async {
    late http.Request visto;
    final s = _svc(MockClient((r) async {
      visto = r;
      return http.Response('AFD', 200);
    }));
    final r = await s.baixarAfd(7, ini, fim);
    expect(r.ok, isTrue);
    expect(visto.url.toString(), 'http://x/api/ponto-rep-p/afd?empresaId=7&inicio=2026-11-01&fim=2026-11-30');
    expect(visto.headers['Authorization'], 'Bearer tok');
    expect(r.dado!.nome, 'AFD_7_2026-11-01_2026-11-30');
    expect(r.dado!.extensao, 'txt');
  });

  test('Comprovante: detecta PDF assinado pelo header', () async {
    final s = _svc(MockClient((r) async => http.Response('%PDF', 200, headers: {'x-comprovante-assinado': 'true'})));
    final r = await s.baixarComprovante(7, 60);
    expect(r.dado!.assinado, isTrue);
    expect(r.dado!.extensao, 'pdf');
  });

  test('403 de outro tenant vira mensagem util (nao falha em silencio)', () async {
    final s = _svc(MockClient((r) async => http.Response(jsonEncode({'erro': 'Batida nao encontrada nesta empresa'}), 403)));
    final r = await s.baixarComprovante(8, 60);
    expect(r.ok, isFalse);
    expect(r.erro, 'Batida nao encontrada nesta empresa');
  });

  test('412 sem certificado e 500 sem corpo JSON tem mensagem padrao', () async {
    expect(PontoRepPService.mensagemErro(412, utf8.encode('x')), contains('Certificado'));
    expect(PontoRepPService.mensagemErro(500, utf8.encode('x')), contains('500'));
  });

  test('erro de rede retorna falha amigavel', () async {
    final s = _svc(MockClient((r) async => throw Exception('offline')));
    final r = await s.baixarAej(7, ini, fim);
    expect(r.ok, isFalse);
    expect(r.erro, contains('conexao'));
  });

  test('Espelho monta URL com funcionario, mes e ano', () {
    final s = _svc(MockClient((r) async => http.Response('', 200)));
    expect(s.uriEspelho(7, 3, 11, 2026).toString(),
        'http://x/api/ponto-rep-p/espelho?empresaId=7&funcionarioId=3&mes=11&ano=2026');
  });
}
