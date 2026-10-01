// lib/utils/permissao_helper.dart

import 'security_matrix.dart';

/// Helper de UI gating — simplifica verificação de permissão para widgets.
/// Combina SecurityMatrix.canActionInModulo com fallback legado.
class PermissaoHelper {
  PermissaoHelper._();

  /// Retorna true se a ação pode ser exibida (widget visível).
  /// Prioriza busca por módulo; fallback para enum AppScreen legado.
  ///
  /// Parâmetros:
  ///   - acao: ação a verificar (view, insert, update, delete, baixar)
  ///   - modulo: nome do módulo (ex. "Financeiro", "Notas Fiscais")
  ///   - matrix: instância de SecurityMatrix (padrão: SecurityMatrix.current())
  ///
  /// Retorna false se:
  ///   - módulo não existe
  ///   - usuário não tem permissão para a ação no módulo
  static bool canShow(
    AppAction acao,
    String modulo, {
    SecurityMatrix? matrix,
  }) {
    matrix ??= SecurityMatrix.current();
    return matrix.canActionInModulo(acao, modulo);
  }

  /// Retorna true se o botão/campo deve estar DESABILITADO (cinzento, não clicável).
  /// Inverso de canShow — útil para campos opcionais que devem aparecer mas cinzentos.
  ///
  /// Parâmetros:
  ///   - acao: ação a verificar
  ///   - modulo: nome do módulo
  ///   - matrix: instância de SecurityMatrix (padrão: SecurityMatrix.current())
  ///
  /// Retorna true se sem permissão.
  static bool isDisabled(
    AppAction acao,
    String modulo, {
    SecurityMatrix? matrix,
  }) {
    return !canShow(acao, modulo, matrix: matrix);
  }

  /// Conveniência: verifica VIEW em um módulo (canShow com AppAction.view).
  static bool canViewModulo(String modulo, {SecurityMatrix? matrix}) {
    return canShow(AppAction.view, modulo, matrix: matrix);
  }

  /// Conveniência: verifica INSERT em um módulo.
  static bool canInsertModulo(String modulo, {SecurityMatrix? matrix}) {
    return canShow(AppAction.insert, modulo, matrix: matrix);
  }

  /// Conveniência: verifica UPDATE em um módulo.
  static bool canUpdateModulo(String modulo, {SecurityMatrix? matrix}) {
    return canShow(AppAction.update, modulo, matrix: matrix);
  }

  /// Conveniência: verifica DELETE em um módulo.
  static bool canDeleteModulo(String modulo, {SecurityMatrix? matrix}) {
    return canShow(AppAction.delete, modulo, matrix: matrix);
  }

  /// Conveniência: verifica BAIXAR em um módulo.
  static bool canBaixarModulo(String modulo, {SecurityMatrix? matrix}) {
    return canShow(AppAction.baixar, modulo, matrix: matrix);
  }
}
