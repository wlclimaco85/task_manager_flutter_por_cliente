/// Utilitários de manipulação de strings.
class StringUtils {
  /// Converte snake_case para camelCase.
  ///
  /// Exemplo: 'nfe_entrada' → 'nfeEntrada'
  ///          'config_fiscal' → 'configFiscal'
  ///          'balancete' → 'balancete' (sem underscore, retorna igual)
  static String snakeToCamelCase(String snakeCase) {
    if (snakeCase.isEmpty) return snakeCase;

    final parts = snakeCase.split('_');
    // Primeira parte fica como está, resto capitalize
    return parts.first +
        parts.skip(1).map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1)).join();
  }
}
