import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/manifestacao/manifestacao_status.dart';
import 'package:task_manager_flutter/utils/manifestacao_validator.dart';
import 'package:task_manager_flutter/core/exceptions/manifestacao_exceptions.dart';

void main() {
  group('ManifestacaoValidator', () {
    group('validateStatus', () {
      test('Retorna erro quando status é null', () {
        final erro = ManifestacaoValidator.validateStatus(null);
        expect(erro, isNotNull);
        expect(erro, contains('obrigatório'));
      });

      test('Retorna null quando status é válido', () {
        final erro = ManifestacaoValidator.validateStatus(ManifestacaoStatus.aceitar);
        expect(erro, isNull);
      });
    });

    group('validateObservacao', () {
      test('Retorna erro quando observação é vazia para recusa', () {
        final erro = ManifestacaoValidator.validateObservacao(
          '',
          ManifestacaoStatus.recusar,
        );
        expect(erro, isNotNull);
      });

      test('Retorna erro quando observação é muito curta para recusa', () {
        final erro = ManifestacaoValidator.validateObservacao(
          'Curta',
          ManifestacaoStatus.recusar,
        );
        expect(erro, isNotNull);
      });

      test('Retorna erro quando observação excede maxLength', () {
        final texto = 'x' * 501;
        final erro = ManifestacaoValidator.validateObservacao(
          texto,
          ManifestacaoStatus.aceitar,
        );
        expect(erro, isNotNull);
        expect(erro, contains('500'));
      });

      test('Retorna null quando observação é válida', () {
        final erro = ManifestacaoValidator.validateObservacao(
          'Observação válida com mais de 10 caracteres',
          ManifestacaoStatus.recusar,
        );
        expect(erro, isNull);
      });

      test('Retorna null quando observação é vazia e não é recusa', () {
        final erro = ManifestacaoValidator.validateObservacao(
          '',
          ManifestacaoStatus.aceitar,
        );
        expect(erro, isNull);
      });
    });

    group('validateQuantidade', () {
      test('Retorna erro quando quantidade é null ou inválida para parcial', () {
        final erro = ManifestacaoValidator.validateQuantidade(
          null,
          ManifestacaoStatus.parcial,
        );
        expect(erro, isNotNull);
      });

      test('Retorna erro quando quantidade é zero para parcial', () {
        final erro = ManifestacaoValidator.validateQuantidade(
          0,
          ManifestacaoStatus.parcial,
        );
        expect(erro, isNotNull);
      });

      test('Retorna null quando quantidade é válida para parcial', () {
        final erro = ManifestacaoValidator.validateQuantidade(
          10,
          ManifestacaoStatus.parcial,
        );
        expect(erro, isNull);
      });

      test('Retorna null quando quantidade é null e não é parcial', () {
        final erro = ManifestacaoValidator.validateQuantidade(
          null,
          ManifestacaoStatus.aceitar,
        );
        expect(erro, isNull);
      });
    });

    group('validateMotivoRecusa', () {
      test('Retorna erro quando motivo é vazio para recusa', () {
        final erro = ManifestacaoValidator.validateMotivoRecusa(
          '',
          ManifestacaoStatus.recusar,
        );
        expect(erro, isNotNull);
      });

      test('Retorna null quando motivo é válido para recusa', () {
        final erro = ManifestacaoValidator.validateMotivoRecusa(
          'Produto com defeito',
          ManifestacaoStatus.recusar,
        );
        expect(erro, isNull);
      });

      test('Retorna null quando motivo é null e não é recusa', () {
        final erro = ManifestacaoValidator.validateMotivoRecusa(
          null,
          ManifestacaoStatus.aceitar,
        );
        expect(erro, isNull);
      });
    });

    group('validateAll', () {
      test('Retorna mapa vazio quando todos os campos são válidos', () {
        final erros = ManifestacaoValidator.validateAll(
          status: ManifestacaoStatus.aceitar,
          observacao: '',
          quantidadeRecebida: null,
          motivoRecusa: null,
        );
        expect(erros, isEmpty);
      });

      test('Lança ValidationException com múltiplos erros', () {
        expect(
          () => ManifestacaoValidator.validateAll(
            status: null,
            observacao: '',
            quantidadeRecebida: 0,
            motivoRecusa: null,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('Lança ValidationException quando há erros', () {
        expect(
          () => ManifestacaoValidator.validateAll(
            status: null,
            observacao: '',
            quantidadeRecebida: null,
            motivoRecusa: null,
          ),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validarContadorObservacao', () {
      test('Retorna formato correto do contador', () {
        final contador = ManifestacaoValidator.validarContadorObservacao('Teste');
        expect(contador, equals('5/500'));
      });

      test('Retorna 0/500 para texto vazio', () {
        final contador = ManifestacaoValidator.validarContadorObservacao('');
        expect(contador, equals('0/500'));
      });

      test('Retorna 500/500 para texto máximo', () {
        final texto = 'x' * 500;
        final contador = ManifestacaoValidator.validarContadorObservacao(texto);
        expect(contador, equals('500/500'));
      });
    });
  });
}
