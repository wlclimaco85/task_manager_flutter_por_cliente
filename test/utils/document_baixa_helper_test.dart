import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/document_baixa_helper.dart';

void main() {
  group('DocumentoBaixaHelper', () {
    group('parseContaBody', () {
      test('Retorna null quando body é null', () {
        expect(DocumentoBaixaHelper.parseContaBody(null), isNull);
      });

      test('Retorna o Map vazio quando body é {}', () {
        final result = DocumentoBaixaHelper.parseContaBody({});
        expect(result, isNotNull);
        expect(result, isEmpty);
      });

      test('Unwraps um nível de {"data": {...}}', () {
        final body = {
          'data': {'id': 1, 'nome': 'Conta A'}
        };
        final result = DocumentoBaixaHelper.parseContaBody(body);
        expect(result, isNotNull);
        expect(result!['id'], 1);
        expect(result['nome'], 'Conta A');
      });

      test('Unwraps múltiplos níveis de {"data": {"data": {...}}}', () {
        final body = {
          'data': {
            'data': {'id': 2, 'nome': 'Conta B'}
          }
        };
        final result = DocumentoBaixaHelper.parseContaBody(body);
        expect(result, isNotNull);
        expect(result!['id'], 2);
        expect(result['nome'], 'Conta B');
      });

      test('Para de unwrap quando encontra {"data": []} (List)', () {
        final body = {
          'data': [
            {'id': 1},
            {'id': 2}
          ]
        };
        final result = DocumentoBaixaHelper.parseContaBody(body);
        expect(result, isNull);
      });

      test('Para de unwrap quando encontra {"data": null}', () {
        final body = {'data': null};
        final result = DocumentoBaixaHelper.parseContaBody(body);
        expect(result, isNull);
      });

      test('Retorna Map quando cursor é Map (sem wrappers)', () {
        final body = {'id': 3, 'descricao': 'Conta C'};
        final result = DocumentoBaixaHelper.parseContaBody(body);
        expect(result, isNotNull);
        expect(result!['id'], 3);
        expect(result['descricao'], 'Conta C');
      });
    });

    group('itemIdValido', () {
      test('Retorna false quando id é null', () {
        expect(DocumentoBaixaHelper.itemIdValido(null), isFalse);
      });

      test('Retorna false quando id é string vazia', () {
        expect(DocumentoBaixaHelper.itemIdValido(''), isFalse);
      });

      test('Retorna false quando id é whitespace', () {
        expect(DocumentoBaixaHelper.itemIdValido('   '), isFalse);
      });

      test('Retorna true quando id é string não vazia', () {
        expect(DocumentoBaixaHelper.itemIdValido('123'), isTrue);
      });

      test('Retorna true quando id é inteiro', () {
        expect(DocumentoBaixaHelper.itemIdValido(456), isTrue);
      });

      test('Retorna true quando id é zero (inteiro)', () {
        expect(DocumentoBaixaHelper.itemIdValido(0), isTrue);
      });
    });

    group('tipoConta', () {
      test('Retorna "PAGAR" quando isPagar é true', () {
        expect(DocumentoBaixaHelper.tipoConta(true), equals('PAGAR'));
      });

      test('Retorna "RECEBER" quando isPagar é false', () {
        expect(DocumentoBaixaHelper.tipoConta(false), equals('RECEBER'));
      });
    });
  });
}
