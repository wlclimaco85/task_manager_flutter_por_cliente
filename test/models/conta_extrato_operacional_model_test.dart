import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/conta_model.dart';

void main() {
  test('ContaExtratoOperacionalItem preserva numero da nota do extrato', () {
    final extrato = ContaExtratoOperacional.fromJson({
      'visao': 'CAIXA',
      'dataInicio': '2026-07-01',
      'dataFim': '2026-07-31',
      'contaId': 474,
      'saldoInicial': 0,
      'totalEntradas': 0,
      'totalSaidas': 55241.67,
      'saldoFinal': -55241.67,
      'itens': [
        {
          'data': '2026-07-07',
          'tipoLancamento': 'PAGAR',
          'tituloId': 20191,
          'descricao': 'Importacao SPED - NF-e 203/001',
          'numeroNota': '203',
          'contaId': 474,
          'contaNome': 'Caixa - 0001 - 00000-0',
          'realizado': true,
          'entrada': 0,
          'saida': 55241.67,
          'saldoAcumulado': -55241.67,
        },
      ],
    });

    expect(extrato.itens, hasLength(1));
    expect(extrato.itens.single.numeroNota, '203');
    expect(extrato.itens.single.saida, 55241.67);
  });
}
