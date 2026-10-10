import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/nfce_service.dart';

void main() {
  test('busca de produtos do PDV: 200 devolve os itens', () async {
    final client = MockClient((_) async => http.Response(
        '{"content":[{"id":1,"nome":"Arroz"}],"totalElements":1,"last":true}', 200,
        headers: {'content-type': 'application/json'}));
    final res = await http.runWithClient(
      () => NfceService().buscarProdutosPaginado(query: 'arroz', empresaId: 20001),
      () => client,
    );
    expect(res.itens, hasLength(1));
  });

  test('busca de produtos do PDV: 403 NAO vira lista vazia (lanca NfceException)', () async {
    final client = MockClient((_) async => http.Response(
        '{"status":403,"message":"Acesso negado: Access Denied"}', 403,
        headers: {'content-type': 'application/json'}));
    await expectLater(
      http.runWithClient(
        () => NfceService().buscarProdutosPaginado(query: 'arroz', empresaId: 20001),
        () => client,
      ),
      throwsA(isA<NfceException>()
          .having((e) => e.statusCode, 'statusCode', 403)
          .having((e) => e.message, 'message', contains('Sem permissao'))),
    );
  });
}
