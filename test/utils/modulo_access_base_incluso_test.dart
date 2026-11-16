import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

/// Conta Propria: o que "ja vem no sistema" fica liberado mesmo com so um modulo opcional contratado.
void main() {
  tearDown(ModuloAccess.reset);

  test('so Departamento Pessoal contratado: base inclusa continua liberada e o DP tambem', () {
    ModuloAccess.setContratadosParaTeste(['Departamento Pessoal']);

    for (final id in ['contas_pagar', 'contas_receber', 'dre_gerencial', 'parceiros', 'fornecedores',
      'produtos', 'importar_extrato', 'pedidos_venda', 'pdv_nfce', 'nfe_saida']) {
      expect(ModuloAccess.isMenuItemAllowed(id), isTrue, reason: id);
    }
    for (final id in ['ponto', 'funcionario', 'dashboard_dp']) {
      expect(ModuloAccess.isMenuItemAllowed(id), isTrue, reason: id);
    }
    expect(ModuloAccess.isScreenAllowed(AppScreen.contasReceber), isTrue);
  });

  test('modulo opcional nao contratado continua bloqueado', () {
    ModuloAccess.setContratadosParaTeste(['Departamento Pessoal']);

    expect(ModuloAccess.isMenuItemAllowed('conta_contabil'), isFalse);
    expect(ModuloAccess.isMenuItemAllowed('transporte_cte'), isFalse);
  });

  test('sem DP contratado as telas do DP ficam bloqueadas', () {
    ModuloAccess.setContratadosParaTeste(['NFS-e']);

    expect(ModuloAccess.isMenuItemAllowed('funcionario'), isFalse);
    expect(ModuloAccess.isMenuItemAllowed('contas_pagar'), isTrue);
  });
}
