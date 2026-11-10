import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/widgets/mdfe_emissao_view.dart';

void main() {
  const chave = '31261112345678000195580010000000421373465956';

  test('corpo de emissao usa cadastro (veiculoId/motoristaIds) e nao envia rodoviario',
      () {
    final corpo = montarCorpoEmissaoMdfe(
      tpAmb: 2,
      tpEmit: 1,
      serie: 1,
      ufIni: 'MG',
      ufFim: 'SP',
      municipiosCarregamento: [montarMunicipioMdfe('3106200', 'Belo Horizonte')],
      descargas: [
        montarDescargaMdfe(
            ibge: '3550308', nome: 'Sao Paulo', chavesCte: const [chave], chavesNfe: const [])
      ],
      valorCarga: 1000,
      unidadeCarga: '01',
      quantidadeCarga: 500,
      veiculoId: 11,
      motoristaIds: const [4, 5],
    );
    expect(corpo['veiculoId'], 11);
    expect(corpo['motoristaIds'], [4, 5]);
    expect(corpo.containsKey('rodoviario'), isFalse);
    expect(corpo.containsKey('emitente'), isFalse);
    expect(corpo.containsKey('infoComplementar'), isFalse);
    final desc = (corpo['descargas'] as List).single as Map;
    expect(desc['chavesCte'], [chave]);
    expect((desc['municipio'] as Map)['codigoIbge'], '3550308');
  });

  test('roteiro: varios municipios de carregamento/descarga e UFs de percurso em ordem', () {
    final corpo = montarCorpoEmissaoMdfe(
      tpAmb: 2, tpEmit: 1, serie: 1, ufIni: 'MG', ufFim: 'RS',
      municipiosCarregamento: [
        montarMunicipioMdfe(' 3106200 ', ' Belo Horizonte '),
        montarMunicipioMdfe('3170206', 'Uberlandia'),
      ],
      ufsPercurso: const ['SP', 'PR', 'SC'],
      descargas: [
        montarDescargaMdfe(
            ibge: '3550308', nome: 'Sao Paulo', chavesCte: const [chave], chavesNfe: const []),
        montarDescargaMdfe(
            ibge: '4314902', nome: 'Porto Alegre', chavesCte: const [], chavesNfe: const [chave]),
      ],
      valorCarga: 1, unidadeCarga: '01', quantidadeCarga: 1, veiculoId: 1,
      motoristaIds: const [1],
    );
    expect(corpo['ufsPercurso'], ['SP', 'PR', 'SC']);
    final carregs = corpo['municipiosCarregamento'] as List;
    expect(carregs.length, 2);
    expect((carregs.first as Map)['codigoIbge'], '3106200');
    expect((carregs.first as Map)['nome'], 'Belo Horizonte');
    final descs = corpo['descargas'] as List;
    expect(descs.length, 2);
    expect(((descs.last as Map)['municipio'] as Map)['nome'], 'Porto Alegre');
    expect((descs.last as Map)['chavesNfe'], [chave]);
    expect(kMdfeMaxMunicipiosCarregamento, 50);
    expect(kMdfeMaxUfsPercurso, 25);
  });

  test('CIOT e vale-pedagio: montagem so com digitos e campos opcionais omitidos', () {
    final ciot = montarCiotMdfe('1234.5678.9012', '123.456.789-09');
    expect(ciot, {'codigo': '123456789012', 'cnpjCpfResponsavel': '12345678909'});

    final completo = montarDispositivoValePedagioMdfe(
      fornecedor: '11.222.333/0001-81',
      pagador: '98.765.432/0001-10',
      numeroCompra: ' 123456 ',
      valor: 150.5,
      tipo: '01',
    );
    expect(completo, {
      'cnpjFornecedor': '11222333000181',
      'cnpjCpfPagador': '98765432000110',
      'numeroCompra': '123456',
      'valor': 150.5,
      'tipo': '01',
    });

    final minimo = montarDispositivoValePedagioMdfe(
        fornecedor: '11222333000181', pagador: '', numeroCompra: null, valor: 0, tipo: null);
    expect(minimo, {'cnpjFornecedor': '11222333000181', 'valor': 0});

    expect(montarValePedagioMdfe([], '06'), isNull);
    expect(montarValePedagioMdfe([minimo], null), {
      'dispositivos': [minimo]
    });
    expect(montarValePedagioMdfe([minimo], '06')!['categoriaCombinacaoVeicular'], '06');
    expect(kMdfeTiposValePedagio.keys, ['01', '04']);
    expect(kMdfeCategoriasCombinacao.length, 10);
  });

  test('corpo de emissao inclui ciots e valePedagio so quando informados', () {
    Map<String, dynamic> corpo({
      List<Map<String, dynamic>> ciots = const [],
      Map<String, dynamic>? vale,
    }) =>
        montarCorpoEmissaoMdfe(
          tpAmb: 2, tpEmit: 1, serie: 1, ufIni: 'MG', ufFim: 'SP',
          municipiosCarregamento: [montarMunicipioMdfe('3106200', 'BH')],
          descargas: [
            montarDescargaMdfe(
                ibge: '3550308', nome: 'SP', chavesCte: const [chave], chavesNfe: const [])
          ],
          valorCarga: 1, unidadeCarga: '01', quantidadeCarga: 1, veiculoId: 1,
          motoristaIds: const [1], ciots: ciots, valePedagio: vale,
        );
    final vazio = corpo();
    expect(vazio.containsKey('ciots'), isFalse);
    expect(vazio.containsKey('valePedagio'), isFalse);

    final cheio = corpo(
      ciots: [montarCiotMdfe('123456789012', '12345678909')],
      vale: montarValePedagioMdfe([
        montarDispositivoValePedagioMdfe(fornecedor: '11222333000181', valor: 10)
      ], '02'),
    );
    expect((cheio['ciots'] as List).length, 1);
    expect((cheio['valePedagio'] as Map)['categoriaCombinacaoVeicular'], '02');
  });

  test('documento: numerico vira CPF/CNPJ (so digitos), texto vira ID de estrangeiro', () {
    expect(separarDocumentoMdfe('98.765.432/0001-10').cnpjCpf, '98765432000110');
    expect(separarDocumentoMdfe('98.765.432/0001-10').idEstrangeiro, isNull);
    expect(separarDocumentoMdfe(' PASS12345 ').idEstrangeiro, 'PASS12345');
    expect(separarDocumentoMdfe(' PASS12345 ').cnpjCpf, isNull);
    expect(separarDocumentoMdfe('   ').cnpjCpf, isNull);
    expect(documentoNumericoValidoMdfe('123.456.789-09'), isTrue);
    expect(documentoNumericoValidoMdfe('12345'), isFalse);
  });

  test('contratante: so envia contrato com valor quando ha numero do contrato', () {
    expect(
      montarContratanteMdfe(nome: ' Embarcadora ', documento: '98.765.432/0001-10'),
      {'nome': 'Embarcadora', 'cnpjCpf': '98765432000110'},
    );
    expect(
      montarContratanteMdfe(
          documento: 'PASS12345', numeroContrato: 'CT-1', valorContratoGlobal: 5000),
      {
        'idEstrangeiro': 'PASS12345',
        'numeroContrato': 'CT-1',
        'valorContratoGlobal': 5000,
      },
    );
    expect(
      montarContratanteMdfe(documento: '12345678909', valorContratoGlobal: 5000)
          .containsKey('valorContratoGlobal'),
      isFalse,
    );
  });

  test('pagamento a vista ignora adiantamento e parcelas; a prazo envia ambos', () {
    final comps = [montarComponentePagamentoMdfe('04', 4000, null)];
    final banco = montarBancoMdfe(forma: kMdfeRecebimentoPix, pix: ' chave@x.com ');
    expect(banco, {'pix': 'chave@x.com'});

    final aVista = montarPagamentoMdfe(
      documento: '98765432000110', componentes: comps, valorContrato: 4000,
      indPag: 0, adiantamento: 1000, anteciparAdiantamento: true,
      parcelas: [montarParcelaMdfe('2026-12-10', 100)], banco: banco,
    );
    expect(aVista.containsKey('adiantamento'), isFalse);
    expect(aVista['anteciparAdiantamento'], isFalse);
    expect(aVista['parcelas'], isEmpty);

    final aPrazo = montarPagamentoMdfe(
      nome: 'Embarcadora', documento: '98765432000110', componentes: comps,
      valorContrato: 4000, altoDesempenho: true, indPag: 1, adiantamento: 1000,
      anteciparAdiantamento: true, tipoAntecipacao: 2,
      parcelas: [montarParcelaMdfe(' 2026-12-10 ', 1500.25)], banco: banco,
    );
    expect(aPrazo['adiantamento'], 1000);
    expect(aPrazo['anteciparAdiantamento'], isTrue);
    expect((aPrazo['parcelas'] as List).single,
        {'vencimento': '2026-12-10', 'valor': 1500.25});
    expect(aPrazo['tipoAntecipacao'], 2);
    expect(aPrazo['altoDesempenho'], isTrue);
  });

  test('banco: so o grupo da forma escolhida vai no corpo', () {
    expect(
      montarBancoMdfe(
          forma: kMdfeRecebimentoBanco, codBanco: '341', codAgencia: '1234', pix: 'x'),
      {'codBanco': '341', 'codAgencia': '1234'},
    );
    expect(
      montarBancoMdfe(forma: kMdfeRecebimentoIpef, cnpjIpef: '11.222.333/0001-81'),
      {'cnpjIpef': '11222333000181'},
    );
    expect(kMdfeTiposComponentePagamento.keys.toSet(), {'04', '01', '02', '03', '99'});
  });

  test('corpo de emissao inclui contratantes e pagamentos so quando informados', () {
    Map<String, dynamic> corpo({
      List<Map<String, dynamic>> contratantes = const [],
      Map<String, dynamic>? pagamento,
    }) =>
        montarCorpoEmissaoMdfe(
          tpAmb: 2, tpEmit: 1, serie: 1, ufIni: 'MG', ufFim: 'SP',
          municipiosCarregamento: [montarMunicipioMdfe('3106200', 'BH')],
          descargas: [
            montarDescargaMdfe(
                ibge: '3550308', nome: 'SP', chavesCte: const [chave], chavesNfe: const [])
          ],
          valorCarga: 1, unidadeCarga: '01', quantidadeCarga: 1, veiculoId: 1,
          motoristaIds: const [1], contratantes: contratantes, pagamento: pagamento,
        );
    final vazio = corpo();
    expect(vazio.containsKey('contratantes'), isFalse);
    expect(vazio.containsKey('pagamentos'), isFalse);

    final cheio = corpo(
      contratantes: [montarContratanteMdfe(documento: '98765432000110')],
      pagamento: montarPagamentoMdfe(
        documento: '98765432000110',
        componentes: [montarComponentePagamentoMdfe('04', 10, null)],
        valorContrato: 10, indPag: 0,
        banco: montarBancoMdfe(forma: kMdfeRecebimentoPix, pix: 'k@x.com'),
      ),
    );
    expect((cheio['contratantes'] as List).length, 1);
    expect((cheio['pagamentos'] as List).length, 1);
  });

  test('roteiro: sem UFs de percurso o campo nao e enviado', () {
    final corpo = montarCorpoEmissaoMdfe(
      tpAmb: 2, tpEmit: 1, serie: 1, ufIni: 'MG', ufFim: 'SP',
      municipiosCarregamento: [montarMunicipioMdfe('3106200', 'BH')],
      descargas: [
        montarDescargaMdfe(
            ibge: '3550308', nome: 'SP', chavesCte: const [chave], chavesNfe: const [])
      ],
      valorCarga: 1, unidadeCarga: '01', quantidadeCarga: 1, veiculoId: 1,
      motoristaIds: const [1],
    );
    expect(corpo.containsKey('ufsPercurso'), isFalse);
  });

  test('seguro: sem responsavel nao envia; com contratante envia documento, seguradora e averbacoes', () {
    expect(montarSeguroMdfe(respSeg: null), isNull);

    final emitente = montarSeguroMdfe(respSeg: 1, documentoContratante: '123');
    expect(emitente, {'respSeg': 1});

    final s = montarSeguroMdfe(
      respSeg: 2,
      documentoContratante: '98.765.432/0001-10',
      seguradoraNome: ' Seguradora X ',
      seguradoraCnpj: '11.222.333/0001-81',
      apolice: 'AP-1',
      averbacoes: 'AV1\n\n AV2 \r\nAV3',
    )!;
    expect(s['respSeg'], 2);
    expect(s['cnpjCpfResponsavel'], '98.765.432/0001-10');
    expect(s['seguradoraNome'], 'Seguradora X');
    expect(s['numeroApolice'], 'AP-1');
    expect(s['averbacoes'], ['AV1', 'AV2', 'AV3']);
  });

  test('corpo de emissao inclui seguros so quando informado', () {
    Map<String, dynamic> corpo(Map<String, dynamic>? seguro) => montarCorpoEmissaoMdfe(
          tpAmb: 2, tpEmit: 1, serie: 1, ufIni: 'MG', ufFim: 'SP',
          municipiosCarregamento: [montarMunicipioMdfe('3106200', 'BH')],
          descargas: [
            montarDescargaMdfe(
                ibge: '3550308', nome: 'SP', chavesCte: const [chave], chavesNfe: const [])
          ],
          valorCarga: 1,
          unidadeCarga: '01', quantidadeCarga: 1, veiculoId: 1,
          motoristaIds: const [1], seguro: seguro);
    expect(corpo(null).containsKey('reboqueIds'), isFalse);
    final comReboque = montarCorpoEmissaoMdfe(
        tpAmb: 2, tpEmit: 1, serie: 1, ufIni: 'MG', ufFim: 'SP',
        municipiosCarregamento: [montarMunicipioMdfe('3106200', 'BH')],
        descargas: [
          montarDescargaMdfe(
              ibge: '3550308', nome: 'SP', chavesCte: const [chave], chavesNfe: const [])
        ],
        valorCarga: 1,
        unidadeCarga: '01', quantidadeCarga: 1, veiculoId: 1,
        motoristaIds: const [1], reboqueIds: const [7, 8]);
    expect(comReboque['reboqueIds'], [7, 8]);
    expect(kMdfeMaxReboques, 3);
    expect(corpo(null).containsKey('seguros'), isFalse);
    expect(corpo({'respSeg': 1})['seguros'], [
      {'respSeg': 1}
    ]);
  });

  test('extrairChaves separa por linha e acusa chaves invalidas', () {
    final invalidas = <String>[];
    final chaves = extrairChaves('$chave\n123\n$chave', invalidas: invalidas);
    expect(chaves, [chave, chave]);
    expect(invalidas, ['123']);
  });

  test('endpoints de MDF-e apontam para /api/mdfe/{id}', () {
    expect(ApiLinks.mdfeDamdfe('5'), endsWith('/api/mdfe/5/damdfe'));
    expect(ApiLinks.mdfeConsultar('5'), endsWith('/api/mdfe/5/consultar'));
  });

  test('lista da API le o envelope data.dados', () {
    final lista = listaMdfeDe({
      'data': {
        'dados': [
          {'id': 1, 'status': 'AUTORIZADO'}
        ]
      }
    });
    expect(lista.single['status'], 'AUTORIZADO');
    expect(listaMdfeDe({'data': 'x'}), isEmpty);
    expect(listaMdfeDe(null), isEmpty);
  });
}
