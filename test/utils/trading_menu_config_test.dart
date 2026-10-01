import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';

void main() {
  group('MenuConfig — Trading Corretora', () {
    test('item trading_corretora existe e abre a configuração da corretora',
        () {
      final item =
          MenuConfig.allItems.firstWhere((i) => i.id == 'trading_corretora');

      expect(item.label, equals('Configuração da Corretora'));
      expect(item.screenIndex, equals(119));
      expect(item.screenIndex, isNot(equals(86)),
          reason: '86 pertence ao Portal do Colaborador');
    });

    test('item trading_corretora pertence ao grupo Bolsa de Valores', () {
      final group = MenuConfig.groupOf('trading_corretora');
      expect(group, isNotNull);
      expect(group!.id, equals('bolsa_valores'));
    });

    test('item trading_carteira abre Minha Carteira sem cair na grid Academia',
        () {
      final item =
          MenuConfig.allItems.firstWhere((i) => i.id == 'trading_carteira');

      expect(item.label, equals('Minha Carteira'));
      expect(item.screenIndex, equals(120));
      expect(item.screenIndex, isNot(equals(124)),
          reason: '124 pertence a Academia');
    });

    test('itens apos carteira mantem a sequencia correta antes de Academia',
        () {
      expect(
          MenuConfig.allItems
              .firstWhere((i) => i.id == 'cobranca_automatica')
              .screenIndex,
          equals(121));
      expect(
          MenuConfig.allItems
              .firstWhere((i) => i.id == 'kanban_pagamentos')
              .screenIndex,
          equals(122));
      expect(
          MenuConfig.allItems
              .firstWhere((i) => i.id == 'aprovacao_pagamentos_web')
              .screenIndex,
          equals(123));
      expect(
          MenuConfig.allItems
              .firstWhere((i) => i.id == 'academia')
              .screenIndex,
          equals(124));
    });
  });
}
