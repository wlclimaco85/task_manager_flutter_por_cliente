import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/localizacao_ponto.dart';

void main() {
  testWidgets('localizacao sem resposta falha depois do limite', (t) async {
    final original = LocalizacaoPonto.provedor;
    addTearDown(() => LocalizacaoPonto.provedor = original);
    LocalizacaoPonto.provedor = () => Completer<CoordenadaPonto>().future;

    Object? erro;
    LocalizacaoPonto.obter().then((_) {}, onError: (Object e) {
      erro = e;
    });
    await t.pump(LocalizacaoPonto.limite - const Duration(seconds: 1));
    expect(erro, isNull);
    await t.pump(const Duration(seconds: 2));
    expect(erro, isA<LocalizacaoIndisponivelException>());
  });
}
