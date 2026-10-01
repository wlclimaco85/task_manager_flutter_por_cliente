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

  /// Remove acentos e caracteres diacríticos para buscas insensíveis a acentos.
  static String removeDiacritics(String str) {
    if (str.isEmpty) return str;
    const withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeecCdIIIIiiiiUUUUuuuuNnSsYyyZz';
    var res = str;
    for (int i = 0; i < withDia.length; i++) {
      res = res.replaceAll(withDia[i], withoutDia[i]);
    }
    return res;
  }

  /// Normaliza texto para busca: remove acentos, espaços extras e converte para minúsculas.
  static String normalizeForSearch(String text) {
    if (text.isEmpty) return '';
    return removeDiacritics(text).toLowerCase().trim();
  }
}

