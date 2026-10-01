import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/string_utils.dart';

void main() {
  group('StringUtils.snakeToCamelCase', () {
    test('converte snake_case simples para camelCase', () {
      expect(StringUtils.snakeToCamelCase('nfe_entrada'), equals('nfeEntrada'));
    });

    test('converte multiple underscores', () {
      expect(StringUtils.snakeToCamelCase('conta_contabil'), equals('contaContabil'));
      expect(StringUtils.snakeToCamelCase('lancamento_contabil'), equals('lancamentoContabil'));
    });

    test('preserva palavra única (sem underscore)', () {
      expect(StringUtils.snakeToCamelCase('balancete'), equals('balancete'));
      expect(StringUtils.snakeToCamelCase('chat'), equals('chat'));
    });

    test('converte config_fiscal para configFiscal', () {
      expect(StringUtils.snakeToCamelCase('config_fiscal'), equals('configFiscal'));
    });

    test('converte pdv_nfce para pdvNfce', () {
      expect(StringUtils.snakeToCamelCase('pdv_nfce'), equals('pdvNfce'));
    });

    test('converte dashboard_comercial para dashboardComercial', () {
      expect(StringUtils.snakeToCamelCase('dashboard_comercial'), equals('dashboardComercial'));
    });

    test('retorna string vazia se entrada vazia', () {
      expect(StringUtils.snakeToCamelCase(''), equals(''));
    });

    test('converte com 3 palavras', () {
      expect(StringUtils.snakeToCamelCase('tipo_de_operacao'), equals('tipoDeOperacao'));
    });
  });
}
