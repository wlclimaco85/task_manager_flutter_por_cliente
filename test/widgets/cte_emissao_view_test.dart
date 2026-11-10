import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/utils/menu_config.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';
import 'package:task_manager_flutter/widgets/cte_emissao_view.dart';

void main() {
  const chave = '31261112345678000195550010000007771123456780';

  Map<String, dynamic> parte(String doc, String nome, String uf) => montarParteCte(
        documento: doc,
        inscricaoEstadual: '062.307.904/0081',
        nome: nome,
        telefone: '(31) 3333-4444',
        logradouro: 'Rua das Flores',
        numero: '100',
        bairro: 'Centro',
        codigoMunicipio: '3106200',
        municipio: 'Belo Horizonte',
        cep: '30110-000',
        uf: uf,
      );

  Map<String, dynamic> corpo({
    int tomadorPapel = 0,
    Map<String, dynamic>? tomadorOutro,
    Map<String, dynamic>? expedidor,
    Map<String, dynamic>? recebedor,
    String cst = '40',
    String? rntrc,
    String? info,
  }) =>
      montarCorpoEmissaoCte(
        tpAmb: 2,
        serie: 1,
        cfop: '6.353',
        naturezaOperacao: ' Prestação de serviço de transporte ',
        origem: montarLocalCte('3106200', 'Belo Horizonte', 'MG'),
        destino: montarLocalCte('3550308', 'São Paulo', 'SP'),
        indIeTomador: 1,
        tomadorPapel: tomadorPapel,
        tomadorOutro: tomadorOutro,
        remetente: parte('98.765.432/0001-98', 'Remetente SA', 'MG'),
        expedidor: expedidor,
        recebedor: recebedor,
        destinatario: parte('11.222.333/0001-81', 'Destino Ltda', 'SP'),
        valorPrestacao: 1500,
        componentes: [montarComponenteCte(' FRETE VALOR ', 1500)],
        icms: montarIcmsCte(
            cst: cst, baseCalculo: 1500, aliquota: 12, valor: 180),
        valorCarga: 25000,
        produtoPredominante: ' Material ',
        unidade: '01',
        tipoMedida: 'PESO BRUTO',
        quantidade: 12000.5,
        chavesNfe: const [chave],
        rntrc: rntrc,
        infoComplementar: info,
      );

  test('corpo de emissao nao envia emitente, numero nem data (vem do servidor)', () {
    final c = corpo();
    expect(c.containsKey('emitente'), isFalse);
    expect(c.containsKey('numero'), isFalse);
    expect(c.containsKey('emissao'), isFalse);
    expect(c['tpAmb'], 2);
    expect(c['cfop'], '6353');
    expect(c['naturezaOperacao'], 'Prestação de serviço de transporte');
    expect(c['origem'], {'codigoIbge': '3106200', 'nome': 'Belo Horizonte', 'uf': 'MG'});
    expect(c['chavesNfe'], [chave]);
    expect(c['valorPrestacao'], 1500);
    expect((c['componentes'] as List).single, {'nome': 'FRETE VALOR', 'valor': 1500});
    final carga = c['carga'] as Map;
    expect(carga['produtoPredominante'], 'Material');
    expect((carga['quantidades'] as List).single,
        {'unidade': '01', 'tipoMedida': 'PESO BRUTO', 'quantidade': 12000.5});
  });

  test('partes saem so com digitos em documento, IE, telefone e CEP', () {
    final p = parte('98.765.432/0001-98', ' Remetente SA ', 'MG');
    expect(p['cnpjCpf'], '98765432000198');
    expect(p['inscricaoEstadual'], '0623079040081');
    expect(p['telefone'], '3133334444');
    expect(p['nome'], 'Remetente SA');
    final e = p['endereco'] as Map;
    expect(e['cep'], '30110000');
    expect(e['codigoMunicipio'], '3106200');
    expect(e['uf'], 'MG');
  });

  test('campos opcionais vazios nao vao no corpo', () {
    final p = montarParteCte(
      documento: '12345678909',
      nome: 'Pessoa',
      logradouro: 'Rua A',
      numero: '1',
      bairro: 'Centro',
      codigoMunicipio: '3106200',
      municipio: 'BH',
      uf: 'MG',
      inscricaoEstadual: ' ',
      telefone: '',
      email: null,
      complemento: null,
      cep: '',
    );
    expect(p.containsKey('inscricaoEstadual'), isFalse);
    expect(p.containsKey('telefone'), isFalse);
    expect(p.containsKey('email'), isFalse);
    expect((p['endereco'] as Map).containsKey('complemento'), isFalse);
    expect((p['endereco'] as Map).containsKey('cep'), isFalse);
    final c = corpo();
    expect(c.containsKey('rntrc'), isFalse);
    expect(c.containsKey('infoComplementar'), isFalse);
    final c2 = corpo(rntrc: '1234.5678', info: ' Entrega agendada ');
    expect(c2['rntrc'], '12345678');
    expect(c2['infoComplementar'], 'Entrega agendada');
  });

  test('tomador: papel 0-3 so envia o papel; "outro" leva os dados proprios', () {
    expect(corpo()['tomador'], {'papel': 0});
    final exp = parte('55.444.333/0001-00', 'Expedidor', 'MG');
    final c1 = corpo(tomadorPapel: 1, expedidor: exp);
    expect(c1['tomador'], {'papel': 1});
    expect(c1['expedidor'], exp);
    expect(c1.containsKey('recebedor'), isFalse);
    final outro = parte('123.456.789-09', 'Tomador', 'MG');
    expect(corpo(tomadorPapel: 4, tomadorOutro: outro)['tomador'],
        {'papel': 4, 'outro': outro});
    // papel diferente de 4 ignora tomadorOutro
    expect(corpo(tomadorPapel: 3, tomadorOutro: outro)['tomador'], {'papel': 3});
  });

  test('IBS/CBS: sem CST e cClassTrib o grupo nao vai; com eles leva so codigos e aliquotas', () {
    expect(montarIbsCbsCte(), isNull);
    expect(montarIbsCbsCte(cst: ' ', cClassTrib: ''), isNull);
    expect(
        montarIbsCbsCte(
            cst: '000', cClassTrib: '000001', pIbsUf: 0.1, pIbsMun: 0, pCbs: 0.9),
        {
          'cst': '000',
          'cClassTrib': '000001',
          'pIbsUf': 0.1,
          'pIbsMun': 0,
          'pCbs': 0.9,
        });
    expect(montarIbsCbsCte(cst: '000', cClassTrib: '000001', baseCalculo: 100)!['baseCalculo'],
        100);
    // aliquotas vazias viram 0 (o backend valida as faixas)
    expect(montarIbsCbsCte(cst: '000', cClassTrib: '000001')!['pCbs'], 0);
  });

  test('ICMS: 00 leva base, aliquota e valor; isento so o CST; SN vira CST 90 + simplesNacional', () {
    expect(montarIcmsCte(cst: '00', baseCalculo: 1500, aliquota: 12, valor: 180), {
      'cst': '00',
      'simplesNacional': false,
      'baseCalculo': 1500,
      'aliquota': 12,
      'valor': 180
    });
    expect(montarIcmsCte(cst: '40', baseCalculo: 1500, aliquota: 12, valor: 180),
        {'cst': '40', 'simplesNacional': false});
    expect(montarIcmsCte(cst: 'SN'), {'cst': '90', 'simplesNacional': true});
    expect(kCteCstIcms.keys, containsAll(['00', '40', '41', '51', 'SN']));
  });

  test('carta de correcao: item opcional e textos aparados', () {
    expect(montarCorrecaoCte(grupo: ' infCarga ', campo: 'proPred', valor: ' Cimento '),
        {'grupoAlterado': 'infCarga', 'campoAlterado': 'proPred', 'valorAlterado': 'Cimento'});
    expect(montarCorrecaoCte(grupo: 'ide', campo: 'xDetRetira', valor: 'Patio B', item: 2),
        containsPair('nroItemAlterado', 2));
    expect(kCteMaxCorrecoes, 20);
    expect(kCteTamanhoMinimoJustificativa, 15);
  });

  const chaveCte = '31261012345678000195570010000000171876543212';

  Map<String, dynamic> corpoTipo(int tipo,
          {List<String> refs = const [], bool altera = false}) =>
      montarCorpoEmissaoCte(
        tpAmb: 2,
        serie: 1,
        cfop: '6353',
        naturezaOperacao: 'Prestação de serviço de transporte',
        origem: montarLocalCte('3106200', 'Belo Horizonte', 'MG'),
        destino: montarLocalCte('3550308', 'São Paulo', 'SP'),
        indIeTomador: 1,
        tomadorPapel: 0,
        remetente: parte('98.765.432/0001-98', 'Remetente SA', 'MG'),
        destinatario: parte('11.222.333/0001-81', 'Destino Ltda', 'SP'),
        valorPrestacao: 300,
        componentes: [montarComponenteCte('COMPLEMENTO', 300)],
        icms: montarIcmsCte(cst: '40'),
        tipoCte: tipo,
        chavesReferenciadas: refs,
        alteraTomador: altera,
        // carga/NF-e so no CT-e normal e no de substituicao
        valorCarga: tipo == kCteTipoComplemento ? null : 25000,
        produtoPredominante: tipo == kCteTipoComplemento ? null : 'Material',
        quantidade: tipo == kCteTipoComplemento ? null : 100,
        chavesNfe: tipo == kCteTipoComplemento ? const [] : const [chave],
      );

  test('CT-e normal nao envia tipoCte nem referencias', () {
    final c = corpoTipo(kCteTipoNormal);
    expect(c.containsKey('tipoCte'), isFalse);
    expect(c.containsKey('chavesReferenciadas'), isFalse);
    expect(c.containsKey('alteraTomador'), isFalse);
    expect(c.containsKey('carga'), isTrue);
    expect(c['chavesNfe'], [chave]);
  });

  test('complemento envia tipo 1 e referencias, sem carga nem NF-e', () {
    final c = corpoTipo(kCteTipoComplemento, refs: const [chaveCte]);
    expect(c['tipoCte'], 1);
    expect(c['chavesReferenciadas'], [chaveCte]);
    expect(c.containsKey('carga'), isFalse);
    expect(c.containsKey('chavesNfe'), isFalse);
    expect(c.containsKey('alteraTomador'), isFalse);
  });

  test('substituicao envia tipo 3, a chave substituida e alteraTomador so quando marcado', () {
    final sem = corpoTipo(kCteTipoSubstituicao, refs: const [chaveCte]);
    expect(sem['tipoCte'], 3);
    expect(sem['chavesReferenciadas'], [chaveCte]);
    expect(sem.containsKey('alteraTomador'), isFalse);
    expect(sem.containsKey('carga'), isTrue);
    final com = corpoTipo(kCteTipoSubstituicao, refs: const [chaveCte], altera: true);
    expect(com['alteraTomador'], isTrue);
    // alteraTomador nao se aplica a outros tipos
    expect(corpoTipo(kCteTipoComplemento, refs: const [chaveCte], altera: true)
        .containsKey('alteraTomador'), isFalse);
  });

  test('referencias: normal nenhuma, complemento 1 a 10, substituicao exatamente 1', () {
    expect(validarReferenciasCte(kCteTipoNormal, const []), isNull);
    expect(validarReferenciasCte(kCteTipoNormal, const [chaveCte]), isNotNull);
    expect(validarReferenciasCte(kCteTipoComplemento, const []), isNotNull);
    expect(validarReferenciasCte(kCteTipoComplemento, const [chaveCte]), isNull);
    expect(validarReferenciasCte(kCteTipoComplemento, List.filled(10, chaveCte)), isNull);
    expect(validarReferenciasCte(kCteTipoComplemento, List.filled(11, chaveCte)), isNotNull);
    expect(validarReferenciasCte(kCteTipoSubstituicao, const []), isNotNull);
    expect(validarReferenciasCte(kCteTipoSubstituicao, const [chaveCte]), isNull);
    expect(validarReferenciasCte(kCteTipoSubstituicao, const [chaveCte, chaveCte]), isNotNull);
    expect(kCteMaxComplementados, 10);
    expect(kCteTipos.keys, [0, 1, 3]);
  });

  test('RNTRC: vazio (usa o da configuracao) ou 8 digitos', () {
    expect(validarRntrcCte(null), isTrue);
    expect(validarRntrcCte('  '), isTrue);
    expect(validarRntrcCte('1234.5678'), isTrue);
    expect(validarRntrcCte('123'), isFalse);
    expect(validarRntrcCte('123456789'), isFalse);
  });

  test('referencias: chave que nao e de CT-e (modelo 57) e recusada', () {
    // chave de NF-e (modelo 55) usada por engano como CT-e referenciado
    expect(validarReferenciasCte(kCteTipoSubstituicao, const [chave]), contains('modelo 57'));
    expect(validarReferenciasCte(kCteTipoComplemento, const [chaveCte, chave]), contains('modelo 57'));
    expect(validarReferenciasCte(kCteTipoSubstituicao, const [chaveCte]), isNull);
  });

  test('complemento pode omitir remetente e destinatario (tomador "outro")', () {
    final outro = parte('123.456.789-09', 'Tomador', 'MG');
    final c = montarCorpoEmissaoCte(
      tpAmb: 2,
      serie: 1,
      cfop: '6353',
      naturezaOperacao: 'Complemento de valores',
      origem: montarLocalCte('3106200', 'Belo Horizonte', 'MG'),
      destino: montarLocalCte('3550308', 'São Paulo', 'SP'),
      indIeTomador: 9,
      tomadorPapel: 4,
      tomadorOutro: outro,
      valorPrestacao: 100,
      componentes: [montarComponenteCte('COMPLEMENTO', 100)],
      icms: montarIcmsCte(cst: '40'),
      tipoCte: kCteTipoComplemento,
      chavesReferenciadas: const [chaveCte],
    );
    expect(c.containsKey('remetente'), isFalse);
    expect(c.containsKey('destinatario'), isFalse);
    expect(c['tomador'], {'papel': 4, 'outro': outro});
    expect(c.containsKey('carga'), isFalse);
  });

  testWidgets('larguraCte limita campos e dialogos a tela estreita (celular)', (tester) async {
    late double estreito;
    late double dialogo;
    late double largo;
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(360, 640)),
        child: Builder(builder: (context) {
          estreito = larguraCte(context, 260);
          dialogo = larguraCte(context, 760, reserva: 90);
          largo = larguraCte(context, 100);
          return const SizedBox.shrink();
        }),
      ),
    ));
    expect(estreito, 220); // 360 - 140
    expect(dialogo, 270); // 360 - 90
    expect(largo, 100); // ja cabe: nao muda
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(1280, 800)),
        child: Builder(builder: (context) {
          dialogo = larguraCte(context, 760, reserva: 90);
          return const SizedBox.shrink();
        }),
      ),
    ));
    expect(dialogo, 760); // desktop mantem a largura de projeto
    await tester.binding.setSurfaceSize(null);
  });

  test('titulo do cartao conforme o tipo (ausente = normal)', () {
    expect(rotuloTipoCte(null), 'CT-e');
    expect(rotuloTipoCte(0), 'CT-e');
    expect(rotuloTipoCte(1), 'CT-e complementar');
    expect(rotuloTipoCte(3), 'CT-e de substituição');
  });

  test('documento valido: CPF (11) ou CNPJ (14) com pontuacao', () {
    expect(documentoValidoCte('123.456.789-09'), isTrue);
    expect(documentoValidoCte('98.765.432/0001-98'), isTrue);
    expect(documentoValidoCte('12345'), isFalse);
    expect(documentoValidoCte(''), isFalse);
  });

  test('localizacao e catalogos cobrem o contrato do backend', () {
    expect(montarLocalCte('3.106.200', ' Belo Horizonte ', 'MG'),
        {'codigoIbge': '3106200', 'nome': 'Belo Horizonte', 'uf': 'MG'});
    expect(kCteUfs.length, 27);
    expect(kCteTomadores.keys, [0, 1, 2, 3, 4]);
    expect(kCteIndIeTomador.keys, [1, 2, 9]);
    expect(kCteUnidades.keys, containsAll(['00', '01', '02', '03', '04', '05']));
  });

  test('endpoints de CT-e apontam para /api/cte/{id}', () {
    expect(ApiLinks.allCte, endsWith('/api/cte'));
    expect(ApiLinks.cte('9'), endsWith('/api/cte/9'));
    expect(ApiLinks.cteConsultar('9'), endsWith('/api/cte/9/consultar'));
    expect(ApiLinks.cteCancelar('9'), endsWith('/api/cte/9/cancelar'));
    expect(ApiLinks.cteCartaCorrecao('9'), endsWith('/api/cte/9/carta-correcao'));
    expect(ApiLinks.cteEventos('9'), endsWith('/api/cte/9/eventos'));
    expect(ApiLinks.cteDacte('9'), endsWith('/api/cte/9/dacte'));
  });

  test('menu e permissoes: CT-e aparece no menu e nos dois sistemas de permissao', () {
    final itens = [
      ...MenuConfig.groups.expand((g) => g.items),
      ...MenuConfig.loose,
    ];
    final cte = itens.firstWhere((i) => i.id == 'transporte_cte');
    expect(cte.label, 'CT-e');
    expect(cte.screenIndex, 209);
    final mdfe = itens.firstWhere((i) => i.id == 'transporte_mdfe');
    expect(cte.screenIndex, isNot(mdfe.screenIndex));
    expect(AppScreen.values.map((e) => e.name), contains('transporteCte'));
  });
}
