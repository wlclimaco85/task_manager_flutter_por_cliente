import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

/// Transporte e um modulo licenciavel proprio: contratar Notas Fiscais nao libera, e modulo
/// desativado (ativo=false) nao conta como contratado.
void main() {
  setUp(() => ModuloAccess.reset());

  const itens = [
    'transporte_veiculos',
    'transporte_motoristas',
    'transporte_mdfe',
    'transporte_cte'
  ];
  const telas = [
    AppScreen.transporteVeiculos,
    AppScreen.transporteMotoristas,
    AppScreen.transporteMdfe,
    AppScreen.transporteCte,
  ];

  test('com o modulo Transporte contratado os itens e telas liberam', () {
    ModuloAccess.setContratadosParaTeste(['Transporte']);
    for (final i in itens) {
      expect(ModuloAccess.isMenuItemAllowed(i), isTrue, reason: i);
    }
    for (final t in telas) {
      expect(ModuloAccess.isScreenAllowed(t), isTrue, reason: t.name);
    }
  });

  test('Notas Fiscais (ou outro modulo) sem Transporte nao libera', () {
    ModuloAccess.setContratadosParaTeste(['Notas Fiscais', 'Financeiro']);
    for (final i in itens) {
      expect(ModuloAccess.isMenuItemAllowed(i), isFalse, reason: i);
    }
    for (final t in telas) {
      expect(ModuloAccess.isScreenAllowed(t), isFalse, reason: t.name);
    }
  });

  test('modulos desativados (ativo=false) sao ignorados; sem o campo vale como ativo', () {
    final nomes = ModuloAccess.nomesDeModulosAtivos([
      {'id': 17, 'nome': 'Transporte', 'ativo': false},
      {'id': 2, 'nome': 'Financeiro', 'ativo': true},
      {'id': 3, 'nome': 'Chat'},
    ]);
    expect(nomes, {'Financeiro', 'Chat'});
  });
}
