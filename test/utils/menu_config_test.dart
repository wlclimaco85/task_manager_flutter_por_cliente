import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';

void main() {
  group('MenuConfig', () {
    test('allItems contém todos os itens dos grupos e os itens soltos', () {
      final allItems = MenuConfig.allItems;
      expect(allItems, isNotEmpty);
      expect(allItems.any((item) => item.id == 'chat'), isTrue);
      expect(allItems.any((item) => item.id == 'dashboard'), isTrue);
      expect(allItems.map((item) => item.id).toSet().length,
          equals(allItems.length),
          reason: 'Todos os IDs de item devem ser únicos');
    });

    test('search retorna resultados case-insensitive e ordenados', () {
      final results = MenuConfig.search('com');
      expect(results, isNotEmpty);
      expect(results.every((item) => item.label.toLowerCase().contains('com')),
          isTrue);
      for (var i = 1; i < results.length; i++) {
        expect(results[i - 1].label.compareTo(results[i].label) <= 0, isTrue);
      }
    });

    test('search retorna lista vazia quando query é somente espaços', () {
      expect(MenuConfig.search('   '), isEmpty);
    });

    test('groupOf retorna o grupo correto para um item existente', () {
      final group = MenuConfig.groupOf('chamados');
      expect(group, isNotNull);
      expect(group?.id, equals('suporte_comunicacao'));
    });

    test('groupOf retorna null para item inexistente', () {
      expect(MenuConfig.groupOf('nao_existe'), isNull);
    });

    test('certificado_digital esta no grupo sistema com screenIndex 188', () {
      final group = MenuConfig.groupOf('certificado_digital');
      expect(group, isNotNull);
      expect(group?.id, equals('sistema'),
          reason: 'Certificado Digital deve estar no grupo Sistema');

      final item = group?.items.firstWhere((i) => i.id == 'certificado_digital');
      expect(item?.screenIndex, equals(188),
          reason: 'Certificado Digital deve apontar para a tela MeuCertificadoDigitalScreen (188)');

      final comercialGroup = MenuConfig.groups.firstWhere((g) => g.id == 'comercial');
      expect(comercialGroup.items.any((i) => i.id == 'certificado_digital'), isFalse,
          reason: 'Certificado Digital nao deve estar no grupo Comercial');
    });

    test('importacao_fiscal_automacao esta no grupo sistema com screenIndex 184', () {
      final group = MenuConfig.groupOf('importacao_fiscal_automacao');
      expect(group, isNotNull);
      expect(group?.id, equals('sistema'));

      final item = group?.items.firstWhere((i) => i.id == 'importacao_fiscal_automacao');
      expect(item?.screenIndex, equals(184),
          reason: 'Importacao Fiscal / Automacao deve apontar para screenIndex 184');
    });
  });
}
