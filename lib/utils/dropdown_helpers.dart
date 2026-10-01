import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';
import '../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType, PaginaDropdown;

/// Helper centralizado para carregar dropdowns comuns
class DropdownHelpers {
  static Future<List<Map<String, dynamic>>> load(
    String url, {
    String displayField = 'nome',
  }) async {
    try {
      final resp = await NetworkCaller().getRequest(url);
      if (!resp.isSuccess || resp.body == null) return [];
      dynamic raw = resp.body;
      List lista = [];
      if (raw is List) {
        lista = raw;
      } else if (raw is Map) {
        final d = raw['data'] ?? raw['dados'] ?? raw['items'] ?? raw['content'];
        if (d is List) {
          lista = d;
        } else if (d is Map) {
          final inner = d['content'] ?? d['dados'] ?? d['items'];
          if (inner is List) lista = inner;
        }
      }
      return lista.whereType<Map>().map((e) {
        final item = Map<String, dynamic>.from(e);
        if (item[displayField] == null ||
            item[displayField].toString().isEmpty) {
          item[displayField] = item['nome'] ??
              item['descricao'] ??
              item['codigo'] ??
              item['name'] ??
              item['id']?.toString() ??
              '';
        }
        return item;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ---- Loaders específicos ----
  static Future<List<Map<String, dynamic>>> empresas() =>
      load(ApiLinks.allEmpresas, displayField: 'nome');

  static Future<List<Map<String, dynamic>>> parceiros() =>
      load(ApiLinks.allParceiros, displayField: 'nome');

  static Future<List<Map<String, dynamic>>> parceirosMatriz(
      {dynamic empresaId}) async {
    final list = await (empresaId != null
        ? parceirosPorEmpresa(empresaId.toString())
        : parceiros());
    final matrizes = list.where((p) {
      final tipo =
          (p['tipoEstabelecimento'] ?? p['tipo_estabelecimento'] ?? 'MATRIZ')
              .toString()
              .toUpperCase();
      return tipo == 'MATRIZ';
    }).toList();
    return matrizes.isNotEmpty ? matrizes : list;
  }

  static Future<List<Map<String, dynamic>>> regimesTributarios() =>
      load(ApiLinks.allRegimetributario, displayField: 'descricao');

  static Future<List<Map<String, dynamic>>> tiposParceiro() =>
      load(ApiLinks.allTipoParceiros, displayField: 'nome');

  /// Carrega parceiros filtrados pela empresa fornecida.
  /// Se [empresaId] for nulo ou vazio, retorna todos os parceiros.
  static Future<List<Map<String, dynamic>>> parceirosPorEmpresa(
      String? empresaId) {
    if (empresaId == null || empresaId.isEmpty) return parceiros();
    return load(ApiLinks.allParceirosPorEmp(empresaId), displayField: 'nome');
  }

  /// Busca paginada + server-side (LIKE multi-campo: nome, razão social,
  /// CPF/CNPJ, email) de parceiros — usada pelo dropdown de Parceiro/
  /// Fornecedor em Contas a Pagar/Receber.
  ///
  /// Corrige bug de produção: o dropdown antes carregava só o 1º lote de 25
  /// registros (GET /api/parceiro sem parâmetros) e filtrava só client-side
  /// sobre esse lote pequeno — termos que só batiam em parceiros fora da 1ª
  /// página nunca apareciam na busca. Agora reconsulta o backend a cada
  /// termo digitado (ver `busca=` no ParceiroController) e devolve o total
  /// real para o diálogo poder paginar via scroll até esgotar os resultados.
  /// [empresaId] restringe a busca a uma empresa específica (ex.: tela GED,
  /// onde o usuário escolhe a empresa num filtro à parte antes de escolher
  /// o parceiro) — sem ele, o backend usa a empresa do tenant logado.
  /// [tipoParceiro] restringe aos parceiros com esse TipoParceiro vinculado
  /// (ex.: "Fornecedor") — usado pelo campo Fornecedor de Contas a Pagar/
  /// Receber, que não deve trazer todos os parceiros da empresa.
  static Future<PaginaDropdown> parceirosBusca({
    String? busca,
    required int pagina,
    int tamanho = 20,
    String? empresaId,
    String? tipoParceiro,
  }) async {
    final url = '${ApiLinks.allParceiros}${buildParceirosBuscaQuery(
      busca: busca,
      pagina: pagina,
      tamanho: tamanho,
      empresaId: empresaId,
      tipoParceiro: tipoParceiro,
    )}';
    try {
      final resp = await NetworkCaller().getRequest(url);
      if (!resp.isSuccess || resp.body == null) {
        // WR-01 (debito conhecido desde o card 580): erro de rede/servidor
        // nao pode parecer "busca sem resultado" -- usuario via "Nenhum
        // resultado" e nao dava pra saber se o parceiro simplesmente nao
        // existia ou se o backend tinha quebrado.
        return PaginaDropdown([], 0,
            erro: 'Erro ao buscar (status ${resp.statusCode}).');
      }
      return parsePaginaDropdown(resp.body);
    } catch (e) {
      return PaginaDropdown([], 0, erro: 'Erro ao buscar: $e');
    }
  }

  /// Monta a query string (`?pagina=...&tamanho=...[&busca=...][&empresaId=...][&tipoParceiro=...]`)
  /// de [parceirosBusca] — extraído em função pura para poder ser testado sem
  /// rede (ver dropdown_helpers_busca_test.dart).
  static String buildParceirosBuscaQuery({
    String? busca,
    required int pagina,
    int tamanho = 20,
    String? empresaId,
    String? tipoParceiro,
  }) {
    final termo = busca?.trim();
    final query = StringBuffer('?pagina=$pagina&tamanho=$tamanho');
    if (termo != null && termo.isNotEmpty) {
      query.write('&busca=${Uri.encodeQueryComponent(termo)}');
    }
    if (empresaId != null && empresaId.isNotEmpty) {
      query.write('&empresaId=${Uri.encodeQueryComponent(empresaId)}');
    }
    if (tipoParceiro != null && tipoParceiro.isNotEmpty) {
      query.write('&tipoParceiro=${Uri.encodeQueryComponent(tipoParceiro)}');
    }
    return query.toString();
  }

  /// Busca paginada + server-side (nome, via GET /api/empresa?nome=...) do
  /// dropdown de Empresa — mesma classe de bug do card 580 (Parceiro): o
  /// dropdown carregava só o 1º lote de 25 registros (sem parâmetro nenhum)
  /// e filtrava só client-side sobre esse lote fixo, escondendo empresas
  /// fora da 1ª página. `nome` (não `busca`) é o filtro real aceito por
  /// EmpresaController — já faz ILIKE server-side, sem precisar de mudança
  /// de backend.
  static Future<PaginaDropdown> empresasBusca({
    String? busca,
    required int pagina,
    int tamanho = 20,
  }) async {
    final url =
        '${ApiLinks.allEmpresas}${buildEmpresasBuscaQuery(busca: busca, pagina: pagina, tamanho: tamanho)}';
    try {
      final resp = await NetworkCaller().getRequest(url);
      if (!resp.isSuccess || resp.body == null) {
        return PaginaDropdown([], 0,
            erro: 'Erro ao buscar (status ${resp.statusCode}).');
      }
      return parsePaginaDropdown(resp.body);
    } catch (e) {
      return PaginaDropdown([], 0, erro: 'Erro ao buscar: $e');
    }
  }

  /// Monta a query string (`?pagina=...&tamanho=...[&nome=...]`) de
  /// [empresasBusca] — extraído em função pura para poder ser testado sem
  /// rede (ver dropdown_helpers_busca_test.dart).
  static String buildEmpresasBuscaQuery({
    String? busca,
    required int pagina,
    int tamanho = 20,
  }) {
    final termo = busca?.trim();
    final query = StringBuffer('?pagina=$pagina&tamanho=$tamanho');
    if (termo != null && termo.isNotEmpty) {
      query.write('&nome=${Uri.encodeQueryComponent(termo)}');
    }
    return query.toString();
  }

  /// Converte o corpo `{data: {dados: [...], totalElements: N}}` retornado
  /// pelo backend em [PaginaDropdown] — extraído em função pura para poder
  /// ser testado sem rede (ver dropdown_helpers_busca_test.dart).
  static PaginaDropdown parsePaginaDropdown(dynamic raw) {
    if (raw is! Map) return const PaginaDropdown([], 0);
    final data = raw['data'] is Map ? raw['data'] : raw;
    if (data is! Map) return const PaginaDropdown([], 0);
    final lista = (data['dados'] as List?) ?? const [];
    final total = (data['totalElements'] as num?)?.toInt() ?? lista.length;
    final items = lista.whereType<Map>().map((e) {
      final item = Map<String, dynamic>.from(e);
      if (item['nome'] == null || item['nome'].toString().isEmpty) {
        item['nome'] = item['razaoSocial'] ??
            item['email'] ??
            item['id']?.toString() ??
            '';
      }
      return item;
    }).toList();
    return PaginaDropdown(items, total);
  }

  /// Resolve o rótulo de exibição de um parceiro pelo id — usado para
  /// mostrar o valor pré-selecionado do dropdown de busca remota
  /// ([parceirosBusca]) quando o registro não está na página carregada
  /// (ex: tela de edição de Conta a Pagar/Receber já com Fornecedor/
  /// Parceiro preenchido).
  static Future<String?> parceiroLabelPorId(String id) async {
    try {
      final resp =
          await NetworkCaller().getRequest('${ApiLinks.allParceiros}/$id');
      if (!resp.isSuccess || resp.body == null) return null;
      return parseParceiroLabel(resp.body);
    } catch (_) {
      return null;
    }
  }

  /// Extrai o rótulo de exibição (nome, com fallback para razão social e
  /// email) do corpo `{data: {...}}` de `GET /api/parceiro/{id}` — extraído
  /// em função pura para poder ser testado sem rede (ver
  /// dropdown_helpers_busca_test.dart).
  static String? parseParceiroLabel(dynamic raw) {
    if (raw is! Map) return null;
    final data = raw['data'] is Map ? raw['data'] : raw;
    if (data is! Map) return null;
    final nome = data['nome']?.toString();
    if (nome != null && nome.isNotEmpty) return nome;
    final razaoSocial = data['razaoSocial']?.toString();
    if (razaoSocial != null && razaoSocial.isNotEmpty) return razaoSocial;
    return data['email']?.toString();
  }

  /// Resolve o rótulo de exibição de uma empresa pelo id — usado para
  /// mostrar o valor pré-selecionado do dropdown de busca remota
  /// ([empresasBusca]) quando o registro não está na página carregada.
  static Future<String?> empresaLabelPorId(String id) async {
    try {
      final resp =
          await NetworkCaller().getRequest('${ApiLinks.allEmpresas}/$id');
      if (!resp.isSuccess || resp.body == null) return null;
      return parseEmpresaLabel(resp.body);
    } catch (_) {
      return null;
    }
  }

  /// Extrai o rótulo de exibição (nome, com fallback para razão social e
  /// email) do corpo de `GET /api/empresa/{id}` — diferente do formato de
  /// `GET /api/parceiro/{id}`, EmpresaController devolve a entidade direto,
  /// sem envelope `{data: {...}}` (ver EmpresaController.getEmpresaById).
  static String? parseEmpresaLabel(dynamic raw) {
    if (raw is! Map) return null;
    final nome = raw['nome']?.toString();
    if (nome != null && nome.isNotEmpty) return nome;
    final razaoSocial = raw['razaoSocial']?.toString();
    if (razaoSocial != null && razaoSocial.isNotEmpty) return razaoSocial;
    return raw['email']?.toString();
  }

  /// Busca paginada + server-side (nome ou codigo, via GET /api/produto-contabil?nome=...) do
  /// dropdown de Produto — lazy loading de 20 em 20 com busca por LIKE, filtrado
  /// por empresa e parceiro do tenant para seguranca de dados.
  static Future<PaginaDropdown> produtosContabeisBusca({
    String? busca,
    required int pagina,
    int tamanho = 20,
    String? empresaId,
    String? parceiroId,
    bool isServico = false,
  }) async {
    final url =
        '${ApiLinks.baseUrl}/api/produto-contabil${buildProdutosContabeisBuscaQuery(busca: busca, pagina: pagina, tamanho: tamanho, empresaId: empresaId, parceiroId: parceiroId, isServico: isServico)}';
    try {
      final resp = await NetworkCaller().getRequest(url);
      if (!resp.isSuccess || resp.body == null) {
        return PaginaDropdown([], 0,
            erro: 'Erro ao buscar produtos (status ${resp.statusCode}).');
      }
      return parsePaginaDropdown(resp.body);
    } catch (e) {
      return PaginaDropdown([], 0, erro: 'Erro ao buscar produtos: $e');
    }
  }

  /// Monta a query string (`?pagina=...&tamanho=...[&nome=...][&empId=...][&parceiroId=...]&isServico=...`)
  /// de [produtosContabeisBusca] — extraído em função pura para poder ser testado sem rede.
  static String buildProdutosContabeisBuscaQuery({
    String? busca,
    required int pagina,
    int tamanho = 20,
    String? empresaId,
    String? parceiroId,
    bool isServico = false,
  }) {
    final termo = busca?.trim();
    final query =
        StringBuffer('?pagina=$pagina&tamanho=$tamanho&isServico=$isServico');
    if (termo != null && termo.isNotEmpty) {
      query.write('&nome=${Uri.encodeQueryComponent(termo)}');
    }
    if (empresaId != null && empresaId.isNotEmpty) {
      query.write('&empId=${Uri.encodeQueryComponent(empresaId)}');
    }
    if (parceiroId != null && parceiroId.isNotEmpty) {
      query.write('&parceiroId=${Uri.encodeQueryComponent(parceiroId)}');
    }
    return query.toString();
  }

  /// Resolve o rótulo de exibição de um produto pelo id.
  static Future<String?> produtoContabilLabelPorId(String id) async {
    try {
      final resp = await NetworkCaller()
          .getRequest('${ApiLinks.baseUrl}/api/produto-contabil/$id');
      if (!resp.isSuccess || resp.body == null) return null;
      return parseProdutoLabel(resp.body);
    } catch (_) {
      return null;
    }
  }

  /// Extrai o rótulo de exibição (nome ou codigo) de um produto.
  static String? parseProdutoLabel(dynamic raw) {
    if (raw is! Map) return null;
    final data = raw['data'] is Map ? raw['data'] : raw;
    if (data is! Map) return null;
    final nome = data['nome']?.toString();
    final codigo = data['codigo']?.toString();
    if (nome != null && nome.isNotEmpty) {
      if (codigo != null && codigo.isNotEmpty && !nome.startsWith(codigo)) {
        return '$codigo - $nome';
      }
      return nome;
    }
    return codigo;
  }

  static Future<List<Map<String, dynamic>>> aplicativos() =>
      load('${ApiLinks.baseUrl}/api/aplicativo', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> setores() =>
      load('${ApiLinks.baseUrl}/api/setor', displayField: 'descricao');

  static Future<List<Map<String, dynamic>>> regimes() =>
      load('${ApiLinks.baseUrl}/api/regime_tributario', displayField: 'codigo');

  static Future<List<Map<String, dynamic>>> formasPagamento() =>
      load('${ApiLinks.baseUrl}/api/forma_pagamento',
          displayField: 'descricao');

  static Future<List<Map<String, dynamic>>> paises() =>
      load('${ApiLinks.baseUrl}/api/pais', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> estados() =>
      load('${ApiLinks.baseUrl}/api/estados', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> cidades() =>
      load('${ApiLinks.baseUrl}/api/cidade', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> contasBancarias() async {
    final lista = await load(
      '${ApiLinks.baseUrl}/api/contas-bancaria',
      displayField: 'nome',
    );
    return lista.map(_comNomeFormatadoDeContaBancaria).toList();
  }

  /// Monta o rótulo de exibição "Descrição • Banco - Número" de uma conta
  /// bancária/caixa — extraído para ser reaproveitado por [contasBancarias]
  /// e [contasBancariasPorEmpresa].
  static Map<String, dynamic> _comNomeFormatadoDeContaBancaria(
      Map<String, dynamic> item) {
    final descricao = item['descricao']?.toString().trim() ?? '';
    final banco = item['banco']?.toString().trim() ?? '';
    final numero = item['numero']?.toString().trim() ?? '';
    final bancoNumero = [
      if (banco.isNotEmpty) banco,
      if (numero.isNotEmpty) numero,
    ].join(' - ');
    final nome = [
      if (descricao.isNotEmpty) descricao,
      if (bancoNumero.isNotEmpty) bancoNumero,
    ].join(' • ');
    if (nome.isNotEmpty) {
      item['nome'] = nome;
    }
    return item;
  }

  /// Carrega contas bancárias/caixa filtradas pela empresa informada (ao
  /// invés da empresa do login) — usado por telas de administração/config
  /// que operam fora do tenant do usuário logado (ex.: Defaults de
  /// Importação em Sistema > Config de Sistemas, onde a empresa é escolhida
  /// na própria tela). Sem [empresaId], traz todas as contas visíveis.
  /// [apenasCaixa] filtra pelo campo `tipo == 'CAIXA'`; por padrão traz as
  /// contas que NÃO são caixa (conta corrente, poupança etc.).
  static Future<List<Map<String, dynamic>>> contasBancariasPorEmpresa(
    String? empresaId, {
    bool apenasCaixa = false,
    // Pedido explicito do usuario: conta bancaria e' cadastrada por
    // PARCEIRO (ContaBancaria.parceiro_id), nao so por empresa -- ao
    // importar SINTEGRA/SPED, o combo deve trazer so as contas do parceiro
    // identificado pelo CNPJ do arquivo, nao de todos os parceiros da
    // empresa. Sem parceiroId (uso normal fora do fluxo de import), filtra
    // so por empresa como antes.
    String? parceiroId,
  }) async {
    final query = StringBuffer('?tamanho=200');
    if (empresaId != null && empresaId.isNotEmpty) {
      query.write('&empresa=$empresaId');
    }
    if (parceiroId != null && parceiroId.isNotEmpty) {
      query.write('&parceiro=$parceiroId');
    }
    final lista = await load(
      '${ApiLinks.baseUrl}/api/contas-bancaria$query',
      displayField: 'nome',
    );
    return lista.map(_comNomeFormatadoDeContaBancaria).where((item) {
      final tipo = item['tipo']?.toString().toUpperCase() ?? '';
      return apenasCaixa ? tipo == 'CAIXA' : tipo != 'CAIXA';
    }).toList();
  }

  /// Carrega centros de custo filtrados pela empresa informada — mesmo
  /// motivo de [contasBancariasPorEmpresa]. Sem [empresaId], traz todos.
  static Future<List<Map<String, dynamic>>> centrosCustoPorEmpresa(
      String? empresaId) {
    final query = StringBuffer('?tamanho=200');
    if (empresaId != null && empresaId.isNotEmpty) {
      query.write('&empId=$empresaId');
    }
    return load('${ApiLinks.allCentrosCusto}$query', displayField: 'nome');
  }

  static Future<List<Map<String, dynamic>>> gruposMusculares() =>
      load('${ApiLinks.baseUrl}/api/grupos-musculares', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> tiposExercicio() =>
      load('${ApiLinks.baseUrl}/api/tipo_exercicios', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> cargos() =>
      load('${ApiLinks.baseUrl}/api/cargo', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> departamentos() =>
      load('${ApiLinks.baseUrl}/api/departamento', displayField: 'nome');

  static Future<List<Map<String, dynamic>>> horariosFunc() =>
      load('${ApiLinks.baseUrl}/api/horarioFunc', displayField: 'nome');

  /// Carrega roles filtradas pela empresa fornecida.
  /// Se [empresaId] for nulo ou vazio, retorna todas as roles disponíveis.
  static Future<List<Map<String, dynamic>>> rolesPorEmpresa(String? empresaId) {
    if (empresaId == null || empresaId.isEmpty) {
      return load('${ApiLinks.baseUrl}/api/role/disponiveis',
          displayField: 'description');
    }
    return load('${ApiLinks.baseUrl}/api/role/disponiveis?empresaId=$empresaId',
        displayField: 'description');
  }

  // ---- FieldConfigWindows prontos ----

  /// Campo empresa: pré-selecionado e disabled quando usuário tem empresa em cache.
  /// Se não tem empresa em cache, mostra dropdown normal.
  static FieldConfigWindows empresaField({bool required = false}) {
    final cachedEmpresaId = TenantContext.empresaId;
    return FieldConfigWindows(
      label: 'Empresa', fieldName: 'empresa',
      displayFieldName: 'empresa.nome',
      fieldType: FieldType.dropdown,
      dropdownValueField: 'id', dropdownDisplayField: 'nome',
      // Se tem empresa em cache → disabled (não pode trocar)
      enabled: cachedEmpresaId == null,
      isInForm: true, isFilterable: true,
      isRequired: required,
      // Pré-seleciona com o id da empresa do usuário logado
      dropdownSelectedValue: cachedEmpresaId,
      dropdownFutureBuilder: empresas,
    );
  }

  /// Campo parceiro: só aparece no form quando usuário tem parceiro em cache.
  /// Se não tem parceiro em cache, retorna campo suprimido (isInForm: false).
  static FieldConfigWindows parceiroField({bool required = false}) {
    final cachedParceiroId = TenantContext.parceiroId;
    if (cachedParceiroId == null) {
      // Sem parceiro em cache → suprime o campo do form
      return const FieldConfigWindows(
        label: 'Parceiro',
        fieldName: 'parceiro',
        isInForm: false,
        isVisibleByDefault: false,
        enabled: false,
      );
    }
    return FieldConfigWindows(
      label: 'Parceiro', fieldName: 'parceiro',
      displayFieldName: 'parceiro.nome',
      fieldType: FieldType.dropdown,
      dropdownValueField: 'id', dropdownDisplayField: 'nome',
      // Pré-selecionado e disabled com o parceiro do usuário logado
      enabled: false,
      isInForm: true, isFilterable: true,
      isRequired: required,
      dropdownSelectedValue: cachedParceiroId,
      dropdownFutureBuilder: parceiros,
    );
  }

  /// Campo parceiro específico para cadastros financeiros.
  /// Quando o usuário já está escopado por parceiro, o campo vem travado.
  /// Quando não está escopado, filtra parceiros pela empresa selecionada
  /// (cascade automático via dependsOnField: 'empresa').
  static FieldConfigWindows parceiroFieldScopedOrSelectable({
    bool required = false,
  }) {
    final cachedParceiroId = TenantContext.parceiroId;
    return FieldConfigWindows(
      label: 'Parceiro',
      fieldName: 'parceiro',
      displayFieldName: 'parceiro.nome',
      fieldType: FieldType.dropdown,
      dropdownValueField: 'id',
      dropdownDisplayField: 'nome',
      enabled: cachedParceiroId == null,
      isInForm: true,
      isFilterable: true,
      isRequired: required,
      dropdownSelectedValue: cachedParceiroId,
      // Cascade: quando livre (sem parceiro fixo), filtra pelo campo 'empresa'
      dependsOnField: cachedParceiroId == null ? 'empresa' : null,
      dropdownFutureBuilderWithParam:
          cachedParceiroId == null ? parceirosPorEmpresa : null,
      dropdownFutureBuilder:
          cachedParceiroId != null ? parceiros : null,
    );
  }

  static FieldConfigWindows aplicativoField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Aplicativo',
        fieldName: 'aplicativo',
        displayFieldName: 'aplicativo.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: aplicativos,
      );

  static FieldConfigWindows setorField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Setor',
        fieldName: 'setor',
        displayFieldName: 'setor.descricao',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'descricao',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: setores,
      );

  static FieldConfigWindows regimeField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Regime Tributário',
        fieldName: 'regime',
        displayFieldName: 'regime.codigo',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'codigo',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: regimes,
      );

  static FieldConfigWindows formaPagamentoField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Forma de Pagamento',
        fieldName: 'formaPagamento',
        displayFieldName: 'formaPagamento.descricao',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'descricao',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: formasPagamento,
      );

  static FieldConfigWindows contaBancariaField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Conta Bancária',
        fieldName: 'contaBaixa',
        displayFieldName: 'contaBaixa.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: contasBancarias,
      );

  static FieldConfigWindows grupoMuscularField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Grupo Muscular',
        fieldName: 'grupoMuscular',
        displayFieldName: 'grupoMuscular.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: gruposMusculares,
      );

  static FieldConfigWindows codGrupoMuscularField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Grupo Muscular',
        fieldName: 'codGrupMusc',
        displayFieldName: 'codGrupMusc',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isFilterable: true,
        isRequired: required,
        dropdownFutureBuilder: gruposMusculares,
        fieldOrder: 20,
      );

  static FieldConfigWindows codTipoExercicioField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Tipo de Exercicio',
        fieldName: 'codTipoExerc',
        displayFieldName: 'codTipoExerc',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isFilterable: true,
        isRequired: required,
        dropdownFutureBuilder: tiposExercicio,
        fieldOrder: 30,
      );

  static FieldConfigWindows cargoField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Cargo',
        fieldName: 'cargo',
        displayFieldName: 'cargo.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: cargos,
      );

  static FieldConfigWindows departamentoField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Departamento',
        fieldName: 'departamento',
        displayFieldName: 'departamento.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: departamentos,
      );

  static FieldConfigWindows horarioFuncField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Horário',
        fieldName: 'horarioFunc',
        displayFieldName: 'horarioFunc.nome',
        fieldType: FieldType.dropdown,
        dropdownValueField: 'id',
        dropdownDisplayField: 'nome',
        enabled: true,
        isInForm: true,
        isRequired: required,
        dropdownFutureBuilder: horariosFunc,
      );

  /// Campo Roles com cascade automático por empresa.
  /// Quando o usuário muda a empresa selecionada, o campo de Roles recarrega
  /// mostrando apenas as roles compatíveis com aquela empresa.
  static FieldConfigWindows rolesField({bool required = false}) =>
      FieldConfigWindows(
        label: 'Roles',
        fieldName: 'roles',
        fieldType: FieldType.multiselect,
        dropdownValueField: 'id',
        dropdownDisplayField: 'description',
        enabled: true,
        isInForm: true,
        isFilterable: true,
        isRequired: required,
        // Cascade: filtra roles pela empresa selecionada
        dependsOnField: 'empresa',
        dropdownFutureBuilderWithParam: rolesPorEmpresa,
      );
}
