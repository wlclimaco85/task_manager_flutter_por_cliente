import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/utils/permissao_helper.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

/// Testes para PermissaoHelper — engine de UI gating simplificado (Card #218).
void main() {
  LoginModel buildUserInfo({
    required List<String> modulosContratados,
    List<RolePermissaoItem> permissoes = const [],
  }) {
    final userInfo = LoginModel(
      token: 'tok',
      login: Login(
        id: 1,
        tipoLogin: LoginEnum.APP_ABRACO,
        roles: [Role(id: 1, key: 'ROLE_FINANCEIRO', description: 'Financeiro')],
        parceiro: Parceiro(id: 5, nome: 'Teste'),
      ),
      permissoes: permissoes,
    );
    ModuloAccess.setContratadosParaTeste(modulosContratados);
    return userInfo;
  }

  setUp(() => ModuloAccess.reset());

  // ── Fase 1: canActionInModulo ──────────────────────────────────────────

  group('SecurityMatrix.canActionInModulo', () {
    test('retorna false se módulo não existe', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: false,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      // "ModuloFantasma" não existe em _moduloToScreens
      expect(matrix.canActionInModulo(AppAction.view, 'ModuloFantasma'), isFalse);
    });

    test('retorna false se módulo existe mas sem a ação', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: false,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      // Tem VIEW em Financeiro mas testa INSERT
      expect(matrix.canActionInModulo(AppAction.insert, 'Financeiro'), isFalse);
    });

    test('retorna true se módulo existe e tem a ação', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: true,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      // Tem VIEW e INSERT em Financeiro
      expect(matrix.canActionInModulo(AppAction.view, 'Financeiro'), isTrue);
      expect(matrix.canActionInModulo(AppAction.insert, 'Financeiro'), isTrue);
    });

    test('MASTER tem acesso total em qualquer módulo', () {
      final info = LoginModel(
        token: 'tok',
        login: Login(
          id: 1,
          tipoLogin: LoginEnum.MASTER,
          roles: [],
        ),
      );
      ModuloAccess.setContratadosParaTeste([]);
      final matrix = SecurityMatrix.of(info);

      expect(matrix.canActionInModulo(AppAction.view, 'Financeiro'), isTrue);
      expect(matrix.canActionInModulo(AppAction.insert, 'Financeiro'), isTrue);
      expect(matrix.canActionInModulo(AppAction.update, 'Financeiro'), isTrue);
      expect(matrix.canActionInModulo(AppAction.delete, 'Financeiro'), isTrue);
      expect(matrix.canActionInModulo(AppAction.baixar, 'Financeiro'), isTrue);
    });

    test('respeita bloqueio por módulo não contratado (mesmo com permissão)', () {
      final info = buildUserInfo(
        modulosContratados: ['Chamados'], // Sem Financeiro
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: true,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      // Tem permissão mas módulo não contratado
      expect(matrix.canActionInModulo(AppAction.view, 'Financeiro'), isFalse);
    });
  });

  // ── Fase 2: PermissaoHelper ────────────────────────────────────────────

  group('PermissaoHelper.canShow', () {
    test('retorna true se pode exibir', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: true,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      expect(PermissaoHelper.canShow(AppAction.insert, 'Financeiro', matrix: matrix), isTrue);
    });

    test('retorna false se não pode exibir', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: false,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      expect(PermissaoHelper.canShow(AppAction.delete, 'Financeiro', matrix: matrix), isFalse);
    });
  });

  group('PermissaoHelper.isDisabled', () {
    test('retorna true se desabilitado (não pode)', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: false,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      expect(PermissaoHelper.isDisabled(AppAction.insert, 'Financeiro', matrix: matrix), isTrue);
    });

    test('retorna false se habilitado (pode)', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: true,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      expect(PermissaoHelper.isDisabled(AppAction.insert, 'Financeiro', matrix: matrix), isFalse);
    });
  });

  group('PermissaoHelper — conveniências', () {
    test('canViewModulo — verifica VIEW', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: false,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      expect(PermissaoHelper.canViewModulo('Financeiro', matrix: matrix), isTrue);
    });

    test('canInsertModulo — verifica INSERT', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: true,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      expect(PermissaoHelper.canInsertModulo('Financeiro', matrix: matrix), isTrue);
    });

    test('canUpdateModulo — verifica UPDATE', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: false,
            podeEditar: true,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      expect(PermissaoHelper.canUpdateModulo('Financeiro', matrix: matrix), isTrue);
    });

    test('canDeleteModulo — verifica DELETE', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: false,
            podeEditar: false,
            podeDeletar: true,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      expect(PermissaoHelper.canDeleteModulo('Financeiro', matrix: matrix), isTrue);
    });

    test('canBaixarModulo — verifica BAIXAR', () {
      final info = buildUserInfo(
        modulosContratados: ['Financeiro'],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: false,
            podeEditar: false,
            podeDeletar: false,
            podeBaixar: true,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);

      expect(PermissaoHelper.canBaixarModulo('Financeiro', matrix: matrix), isTrue);
    });
  });
}
