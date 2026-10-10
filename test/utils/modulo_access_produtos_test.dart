import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

/// Produtos no menu: o PDV (modulo NFC-e / Notas Fiscais) vende produtos, entao
/// quem contrata so NFC-e tambem precisa ver Produtos (antes so com Comercial).
void main() {
  setUp(() => ModuloAccess.reset());

  test('produtos liberado com modulo Comercial', () {
    ModuloAccess.setContratadosParaTeste(['Comercial']);
    expect(ModuloAccess.isMenuItemAllowed('produtos'), isTrue);
  });

  test('produtos liberado com apenas NFC-e / Notas Fiscais (PDV)', () {
    ModuloAccess.setContratadosParaTeste(['Notas Fiscais']);
    expect(ModuloAccess.isMenuItemAllowed('produtos'), isTrue);

    ModuloAccess.setContratadosParaTeste(['NFC-e']);
    expect(ModuloAccess.isMenuItemAllowed('produtos'), isTrue);
  });

  test('produtos bloqueado com modulos que nao cobrem produto', () {
    ModuloAccess.setContratadosParaTeste(['Financeiro']);
    expect(ModuloAccess.isMenuItemAllowed('produtos'), isFalse);
  });

  test('sem modulos configurados nao bloqueia (RBAC decide)', () {
    ModuloAccess.setContratadosParaTeste([]);
    expect(ModuloAccess.isMenuItemAllowed('produtos'), isTrue);
  });
}
