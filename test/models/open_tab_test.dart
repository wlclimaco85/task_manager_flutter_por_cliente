// test/models/open_tab_test.dart
//
// Testes de OpenTab.openedAt e da função pura indexOfOldestTab, usada para
// decidir qual aba fechar automaticamente quando o limite de abas é
// atingido (decisão do card Trello 6a3bd688f903d71c5d0904c8: fechar a aba
// mais antiga por ordem de abertura, não por último acesso).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:task_manager_flutter/models/open_tab.dart';
import 'package:task_manager_flutter/widgets/internal_tab_strip.dart';

OpenTab _tab(String id, DateTime openedAt) => OpenTab(
      id: id,
      label: 'Aba $id',
      icon: FontAwesomeIcons.house,
      content: SizedBox.shrink(),
      screenIndex: 0,
      openedAt: openedAt,
    );

void main() {
  group('OpenTab.openedAt', () {
    test('armazena e expõe o valor passado no construtor sem alteração', () {
      final timestamp = DateTime(2026, 6, 1, 10, 30);
      final tab = _tab('screen_1', timestamp);

      expect(tab.openedAt, timestamp);
    });
  });

  group('indexOfOldestTab', () {
    test('com 3 abas de openedAt distintos retorna o índice da aba com menor openedAt', () {
      final t0 = DateTime(2026, 6, 1, 10, 0);
      final t1 = DateTime(2026, 6, 1, 10, 5);
      final t2 = DateTime(2026, 6, 1, 10, 10);

      final tabs = [_tab('a', t0), _tab('b', t1), _tab('c', t2)];

      expect(indexOfOldestTab(tabs), 0);
    });

    test('com a aba mais antiga fora do índice 0 retorna o índice correto pelo valor de openedAt', () {
      final t0 = DateTime(2026, 6, 1, 10, 0);
      final t1 = DateTime(2026, 6, 1, 10, 5);
      final t2 = DateTime(2026, 6, 1, 10, 10);

      // Lista na ordem [T2, T0, T1] — a mais antiga (T0) está no índice 1.
      final tabs = [_tab('c', t2), _tab('a', t0), _tab('b', t1)];

      expect(indexOfOldestTab(tabs), 1);
    });

    test('lança ArgumentError quando a lista é vazia', () {
      expect(() => indexOfOldestTab(<OpenTab>[]), throwsArgumentError);
    });
  });
}
