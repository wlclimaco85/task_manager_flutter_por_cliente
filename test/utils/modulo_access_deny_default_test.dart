import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/parceiro_model.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

/// Testes para o fix do card #217: deny-by-default quando lista de modulos vazia.
///
/// Bug original: quando nenhum modulo era retornado pela API (empresaModulos e
/// parceiroModulos vazios), o sistema concedia acesso a TODOS os modulos.
///
/// Comportamento correto (pos-fix):
/// - Lista vazia de modulos contratados = acesso NEGADO a telas que pertencem a modulos.
/// - Telas que NAO pertencem a nenhum modulo continuam acessiveis (ex: perfil, logins).
/// - MASTER continua com acesso total.
void main() {
  LoginModel buildCliente({
    required List<String> modulosContratados,
    List<RolePermissaoItem> permissoes = const [],
    LoginEnum tipoLogin = LoginEnum.APP_ABRACO,
    String roleKey = 'ROLE_ESCRITORIO',
  }) {
    final userInfo = LoginModel(
      token: 'tok',
      login: Login(
        id: 99,
        tipoLogin: tipoLogin,
        roles: [Role(id: 1, key: roleKey, description: 'Teste')],
        parceiro: Parceiro(id: 5, nome: 'Cliente Teste'),
      ),
      permissoes: permissoes,
    );
    ModuloAccess.setContratadosParaTeste(modulosContratados);
    return userInfo;
  }

  setUp(() => ModuloAccess.reset());

  // ========================================================================
  // ModuloAccess.isScreenAllowed — deny-by-default com lista vazia
  // ========================================================================

  group('ModuloAccess.isScreenAllowed — lista vazia = deny', () {
    test('tela de modulo (contasPagar/Financeiro) NEGADA quando lista vazia', () {
      ModuloAccess.setContratadosParaTeste([]);
      expect(ModuloAccess.isScreenAllowed(AppScreen.contasPagar), isFalse);
    });

    test('tela de modulo (chamados/Chamados) NEGADA quando lista vazia', () {
      ModuloAccess.setContratadosParaTeste([]);
      expect(ModuloAccess.isScreenAllowed(AppScreen.chamados), isFalse);
    });

    test('tela de modulo (nfeSaida/Notas Fiscais) NEGADA quando lista vazia', () {
      ModuloAccess.setContratadosParaTeste([]);
      expect(ModuloAccess.isScreenAllowed(AppScreen.nfeSaida), isFalse);
    });

    test('tela de modulo (ponto/DP) NEGADA quando lista vazia', () {
      ModuloAccess.setContratadosParaTeste([]);
      expect(ModuloAccess.isScreenAllowed(AppScreen.ponto), isFalse);
    });

    test('tela SEM modulo (logins) PERMITIDA mesmo com lista vazia', () {
      ModuloAccess.setContratadosParaTeste([]);
      // logins nao pertence a nenhum modulo, entao deve ser permitida
      expect(ModuloAccess.isScreenAllowed(AppScreen.logins), isTrue);
    });

    test('tela SEM modulo (perfil) PERMITIDA mesmo com lista vazia', () {
      ModuloAccess.setContratadosParaTeste([]);
      expect(ModuloAccess.isScreenAllowed(AppScreen.perfil), isTrue);
    });

    test('tela SEM modulo (noticias) PERMITIDA mesmo com lista vazia', () {
      ModuloAccess.setContratadosParaTeste([]);
      expect(ModuloAccess.isScreenAllowed(AppScreen.noticias), isTrue);
    });
  });

  // ========================================================================
  // ModuloAccess.isScreenAllowed — com modulo contratado funciona normalmente
  // ========================================================================

  group('ModuloAccess.isScreenAllowed — com modulos contratados', () {
    test('tela de Financeiro PERMITIDA quando Financeiro contratado', () {
      ModuloAccess.setContratadosParaTeste(['Financeiro']);
      expect(ModuloAccess.isScreenAllowed(AppScreen.contasPagar), isTrue);
    });

    test('tela de Chamados NEGADA quando so Financeiro contratado', () {
      ModuloAccess.setContratadosParaTeste(['Financeiro']);
      expect(ModuloAccess.isScreenAllowed(AppScreen.chamados), isFalse);
    });
  });

  // ========================================================================
  // SecurityMatrix.allowedTelaIds — deny-by-default (sem anti-lockout)
  // ========================================================================

  group('SecurityMatrix.allowedTelaIds — deny-by-default', () {
    test('usuario sem permissoes backend usa fallback hardcoded, nao mostra tudo', () {
      final info = buildCliente(
        modulosContratados: ['Financeiro'],
        permissoes: [], // sem permissoes do backend
      );
      final matrix = SecurityMatrix.of(info);
      final allIds = {'contasPagar', 'chamados', 'logins', 'perfil'};
      final allowed = matrix.allowedTelaIds(allIds);

      // NAO deve retornar null (que significava "mostrar tudo")
      expect(allowed, isNotNull);
      // Deve usar fallback hardcoded para ESCRITORIO
      // contasPagar deve estar permitido (modulo Financeiro + role ESCRITORIO)
      expect(allowed!.contains('contasPagar'), isTrue);
    });

    test('MASTER retorna null (acesso total)', () {
      final info = buildCliente(
        modulosContratados: ['Financeiro'],
        tipoLogin: LoginEnum.MASTER,
      );
      final matrix = SecurityMatrix.of(info);
      final allIds = {'contasPagar', 'chamados', 'logins'};
      final allowed = matrix.allowedTelaIds(allIds);

      expect(allowed, isNull); // MASTER = sem filtro
    });

    test('usuario com permissoes backend retorna apenas telas permitidas', () {
      final info = buildCliente(
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
      final allIds = {'contasPagar', 'chamados', 'logins'};
      final allowed = matrix.allowedTelaIds(allIds);

      expect(allowed, isNotNull);
      expect(allowed!.contains('contasPagar'), isTrue);
      expect(allowed.contains('chamados'), isFalse);
    });
  });

  // ========================================================================
  // SecurityMatrix._can — deny com lista vazia de modulos
  // ========================================================================

  group('SecurityMatrix._can — deny com modulos vazios', () {
    test('usuario nao-MASTER sem modulos NAO pode ver contasPagar', () {
      final info = buildCliente(
        modulosContratados: [],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'contasPagar',
            podeVer: true,
            podeInserir: true,
            podeEditar: true,
            podeDeletar: true,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);
      // Mesmo com permissao no backend, ModuloAccess nega porque nenhum modulo contratado
      expect(matrix.canView(AppScreen.contasPagar), isFalse);
    });

    test('usuario nao-MASTER sem modulos PODE ver tela livre (roles)', () {
      final info = buildCliente(
        modulosContratados: [],
        permissoes: [
          RolePermissaoItem(
            telaNome: 'roles',
            podeVer: true,
            podeInserir: false,
            podeEditar: false,
            podeDeletar: false,
          ),
        ],
      );
      final matrix = SecurityMatrix.of(info);
      // roles nao pertence a nenhum modulo, entao ModuloAccess permite
      expect(matrix.canView(AppScreen.roles), isTrue);
    });
  });
}
