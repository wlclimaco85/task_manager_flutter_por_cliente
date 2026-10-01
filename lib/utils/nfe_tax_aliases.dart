class NfeTaxAliases {
  static void recalcularItem(Map<String, dynamic> item) {
    final quantidade = _asDouble(item['q_com'] ?? item['qCom']) ?? 1;
    final valorUnitario = _asDouble(item['v_un_com'] ?? item['vUnCom']) ?? 0;
    final total = quantidade * valorUnitario;
    item['q_com'] = _valorDecimal(item['q_com'] ?? item['qCom'] ?? quantidade);
    item['qCom'] = item['q_com'];
    item['v_un_com'] =
        _valorDecimal(item['v_un_com'] ?? item['vUnCom'] ?? valorUnitario);
    item['vUnCom'] = item['v_un_com'];
    item['v_prod'] = _valorMonetario(total);
    item['vProd'] = item['v_prod'];

    final baseCalculo = total;

    // ICMS — sempre calcula (flag temIcms tratada no backend)
    _setValor(item, 'v_bc_icms', 'vBcIcms', baseCalculo);
    _setValor(
        item,
        'v_icms',
        'vIcms',
        baseCalculo *
            ((_asDouble(item['aliq_icms'] ?? item['aliqIcms']) ?? 0) / 100));

    // PIS — respeita flag tem_pis
    if (_flagFalse(item, 'tem_pis', 'temPis')) {
      _setValor(item, 'v_bc_pis', 'vBcPis', 0);
      _setValor(item, 'v_pis', 'vPis', 0);
    } else {
      _setValor(item, 'v_bc_pis', 'vBcPis', baseCalculo);
      _setValor(item, 'v_pis', 'vPis',
          baseCalculo * ((_asDouble(item['p_pis'] ?? item['pPis']) ?? 0) / 100));
    }

    // COFINS — respeita flag tem_cofins
    if (_flagFalse(item, 'tem_cofins', 'temCofins')) {
      _setValor(item, 'v_bc_cofins', 'vBcCofins', 0);
      _setValor(item, 'v_cofins', 'vCofins', 0);
    } else {
      _setValor(item, 'v_bc_cofins', 'vBcCofins', baseCalculo);
      _setValor(
          item,
          'v_cofins',
          'vCofins',
          baseCalculo *
              ((_asDouble(item['p_cofins'] ?? item['pCofins']) ?? 0) / 100));
    }

    // IPI — respeita flag tem_ipi
    if (_flagFalse(item, 'tem_ipi', 'temIpi')) {
      _setValor(item, 'v_bc_ipi', 'vBcIpi', 0);
      _setValor(item, 'v_ipi', 'vIpi', 0);
    } else {
      _setValor(item, 'v_bc_ipi', 'vBcIpi', baseCalculo);
      _setValor(
          item,
          'v_ipi',
          'vIpi',
          baseCalculo *
              ((_asDouble(item['aliq_ipi'] ?? item['aliqIpi']) ?? 0) / 100));
    }

    // IBS/CBS — respeita flag tem_ibs_cbs
    if (_flagFalse(item, 'tem_ibs_cbs', 'temIbsCbs')) {
      _setValor(item, 'v_bc_ibs_cbs', 'vBcIbsCbs', 0);
      _setValor(item, 'v_cbs', 'vCbs', 0);
      _setValor(item, 'v_ibs', 'vIbs', 0);
    } else {
      final pCbs = _asDouble(item['p_cbs'] ?? item['pCbs']) ?? 0;
      final pIbsUf = _asDouble(item['p_ibs_uf'] ?? item['pIbsUf']) ?? 0;
      final pIbsMun = _asDouble(item['p_ibs_mun'] ?? item['pIbsMun']) ?? 0;
      _setValor(item, 'v_bc_ibs_cbs', 'vBcIbsCbs', baseCalculo);
      _setValor(item, 'v_cbs', 'vCbs', baseCalculo * (pCbs / 100));
      _setValor(item, 'v_ibs', 'vIbs', baseCalculo * ((pIbsUf + pIbsMun) / 100));
    }

    final totTrib = (_asDouble(item['v_icms'] ?? item['vIcms']) ?? 0) +
        (_asDouble(item['v_pis'] ?? item['vPis']) ?? 0) +
        (_asDouble(item['v_cofins'] ?? item['vCofins']) ?? 0) +
        (_asDouble(item['v_ipi'] ?? item['vIpi']) ?? 0) +
        (_asDouble(item['v_cbs'] ?? item['vCbs']) ?? 0) +
        (_asDouble(item['v_ibs'] ?? item['vIbs']) ?? 0);
    _setValor(item, 'v_tot_trib', 'vTotTrib', totTrib);
  }

  static void applyProdutoSelecionado(
    Map<String, dynamic> item,
    Map<String, dynamic> selected,
  ) {
    _setAliases(
        item, 'cst_pis', 'cstPis', _first(selected, ['cst_pis', 'cstPis']));
    _setAliases(
        item,
        'p_pis',
        'pPis',
        _first(selected, [
          'p_pis',
          'pPis',
          'aliquota_pis',
          'aliquotaPis',
          'pisAliquota',
        ]));
    _setAliases(item, 'cst_cofins', 'cstCofins',
        _first(selected, ['cst_cofins', 'cstCofins']));
    _setAliases(
      item,
      'p_cofins',
      'pCofins',
      _first(selected, [
        'p_cofins',
        'pCofins',
        'aliquota_cofins',
        'aliquotaCofins',
        'cofinsAliquota',
      ]),
    );
    _setAliases(
        item,
        'p_cbs',
        'pCbs',
        _first(selected, [
          'p_cbs',
          'pCbs',
          'aliquota_cbs',
          'aliquotaCbs',
          'cbsAliquota',
        ]));
    _setAliases(
      item,
      'p_ibs_uf',
      'pIbsUf',
      _first(selected, [
        'p_ibs_uf',
        'pIbsUf',
        'aliquota_ibs_uf',
        'aliquotaIbsUf',
        'ibsUfAliquota',
      ]),
    );
    _setAliases(
      item,
      'p_ibs_mun',
      'pIbsMun',
      _first(selected, [
        'p_ibs_mun',
        'pIbsMun',
        'pIbsMunicipio',
        'aliquota_ibs_mun',
        'aliquotaIbsMun',
        'ibsMunAliquota',
      ]),
    );
  }

  static void applyProdutoImpostoUf(
    Map<String, dynamic> item,
    Map<String, dynamic> imposto,
  ) {
    _setAliases(
        item, 'cst_pis', 'cstPis', _first(imposto, ['cstPis', 'cst_pis']));
    _setAliases(
        item,
        'p_pis',
        'pPis',
        _first(imposto, [
          'pPis',
          'p_pis',
          'aliquotaPis',
          'aliquota_pis',
          'pisAliquota',
        ]));
    _setAliases(item, 'cst_cofins', 'cstCofins',
        _first(imposto, ['cstCofins', 'cst_cofins']));
    _setAliases(
      item,
      'p_cofins',
      'pCofins',
      _first(imposto, [
        'pCofins',
        'p_cofins',
        'aliquotaCofins',
        'aliquota_cofins',
        'cofinsAliquota',
      ]),
    );
    _setAliases(
        item,
        'p_cbs',
        'pCbs',
        _first(imposto, [
          'pCbs',
          'p_cbs',
          'aliquotaCbs',
          'aliquota_cbs',
          'cbsAliquota',
        ]));
    _setAliases(
      item,
      'p_ibs_uf',
      'pIbsUf',
      _first(imposto, [
        'pIbsUf',
        'p_ibs_uf',
        'aliquotaIbsUf',
        'aliquota_ibs_uf',
        'ibsUfAliquota',
      ]),
    );
    _setAliases(
      item,
      'p_ibs_mun',
      'pIbsMun',
      _first(imposto, [
        'pIbsMun',
        'p_ibs_mun',
        'pIbsMunicipio',
        'aliquotaIbsMun',
        'aliquota_ibs_mun',
        'ibsMunAliquota',
      ]),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final normalized = text.contains(',')
        ? text.replaceAll('.', '').replaceAll(',', '.')
        : text;
    return double.tryParse(normalized);
  }

  static String _valorDecimal(dynamic value) {
    if (value == null) return '';
    if (value is num) return value.toString();
    final text = value.toString().trim();
    return text.contains(',')
        ? text.replaceAll('.', '').replaceAll(',', '.')
        : text;
  }

  static String _valorMonetario(double value) => value.toStringAsFixed(2);

  static void _setValor(
    Map<String, dynamic> item,
    String snakeKey,
    String camelKey,
    double value,
  ) {
    item[snakeKey] = _valorMonetario(value);
    item[camelKey] = item[snakeKey];
  }

  static dynamic _first(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }
    return null;
  }

  static void _setAliases(
    Map<String, dynamic> item,
    String snakeKey,
    String camelKey,
    dynamic value,
  ) {
    if (value == null) return;
    final normalized = value.toString();
    item[snakeKey] = normalized;
    item[camelKey] = normalized;
  }

  /// Retorna true se a flag do produto indica que o imposto NÃO se aplica.
  static bool _flagFalse(
      Map<String, dynamic> item, String snake, String camel) {
    final v = item[snake] ?? item[camel];
    return v == false || v == 'false';
  }
}
