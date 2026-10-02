import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/automacao_fiscal_screen.dart';

/// Card automacao-fiscal-pastas (2026-09-10) -- tela Sistema > Automacao
/// Fiscal. NetworkCaller usa as funcoes top-level de package:http
/// diretamente (sem client injetavel), entao a chamada de rede em si nao e
/// testavel aqui sem infraestrutura adicional (mesmo padrao documentado em
/// produto_impostos_tab_test.dart) -- por isso os mapeamentos de rotulo
/// (origem/tipo de documento) foram extraidos em funcoes puras e sao
/// testados diretamente.
void main() {
  group('origemLabel', () {
    test('mapeia os valores conhecidos do backend', () {
      expect(origemLabel('BOLETO'), 'Boletos');
      expect(origemLabel('SPED'), 'SPED');
      expect(origemLabel('SINTEGRA'), 'Sintegra');
      expect(origemLabel('XML'), 'XML');
    });

    test('valor desconhecido ou nulo cai no fallback', () {
      expect(origemLabel('OUTRO'), 'OUTRO');
      expect(origemLabel(null), '-');
    });
  });

  group('tipoDocumentoLabel', () {
    test('mapeia todos os tipos reconhecidos pelo classificador do backend',
        () {
      expect(tipoDocumentoLabel('BOLETO_FORNECEDOR'), 'Boleto Fornecedor');
      expect(tipoDocumentoLabel('FGTS'), 'FGTS');
      expect(tipoDocumentoLabel('DAE_ICMS'), 'DAE ICMS');
      expect(tipoDocumentoLabel('DARF_FEDERAL'), 'DARF Federal');
      expect(tipoDocumentoLabel('GUIA_ISS_MUNICIPAL'), 'Guia ISS');
      expect(tipoDocumentoLabel('COMPROVANTE_PAGAMENTO'),
          'Comprovante de Pagamento');
      expect(tipoDocumentoLabel('CTE'), 'CT-e (Transporte)');
      expect(tipoDocumentoLabel('NFE'), 'NF-e (Entrada)');
      expect(tipoDocumentoLabel('NFCE'), 'NFC-e (Consumidor)');
      expect(tipoDocumentoLabel('NFSE'), 'NFS-e (Serviço)');
      expect(tipoDocumentoLabel('JA_IMPORTADO'), 'Já importado');
    });

    test('nulo vira traco, tipo desconhecido vira "Não identificado"', () {
      expect(tipoDocumentoLabel(null), '-');
      expect(tipoDocumentoLabel('DESCONHECIDO'), 'Não identificado');
    });
  });

  group('extrairCnpj', () {
    test('extrai CNPJ formatado ou 14 digitos de mensagem de erro', () {
      expect(
        extrairCnpj(
            'CNPJ do arquivo SINTEGRA (38504938000626) nao corresponde a empresa'),
        '38504938000626',
      );
      expect(
        extrairCnpj(
            'Nenhum parceiro cadastrado para o CNPJ 11.222.333/0001-81 na base.'),
        '11.222.333/0001-81',
      );
      expect(extrairCnpj('Erro desconhecido sem documento'), isNull);
      expect(extrairCnpj(null), isNull);
      expect(extrairCnpj(''), isNull);
    });
  });

  group('formatarEntidadeRastreabilidade', () {
    test(
        'mantem empresa ou parceiro quando apenas nome ou id estiver disponivel',
        () {
      expect(
        formatarEntidadeRastreabilidade(
            id: 1, nome: 'Empresa Teste', fallback: '-'),
        '[ID: 1] Empresa Teste',
      );
      expect(
        formatarEntidadeRastreabilidade(
            id: null, nome: 'Parceiro Teste', fallback: '-'),
        'Parceiro Teste',
      );
      expect(
        formatarEntidadeRastreabilidade(id: 42, nome: null, fallback: '-'),
        '[ID: 42]',
      );
      expect(
        formatarEntidadeRastreabilidade(
            id: null, nome: '  ', fallback: 'Não informado'),
        'Não informado',
      );
    });
  });

  test('payload de parceiro mantem cidade textual fora de endereco', () {
    final payload = montarPayloadParceiroAutomacaoFiscal({
      'cidade': 'UBERABA',
      'estado': 'MG',
      'rua': 'Rua Teste',
      'endereco': {'cidade': 'UBERABA'},
    });
    expect(payload['cidade'], 'UBERABA');
    expect(payload['tipoEstabelecimento'], 'MATRIZ');
    expect(payload.containsKey('endereco'), isFalse);
  });

  group('formatarRelatorioErrosParaClipboard', () {
    test('formata lista de erros consolidada com detalhes para clipboard', () {
      final logs = [
        {
          'status': 'ERRO',
          'arquivo': 'nfe_1066.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFE',
          'mensagem':
              'Falha ao parsear XML da NF-e: Invalid byte 2 of 2-byte UTF-8 sequence.',
        },
        {
          'status': 'SUCESSO',
          'arquivo': 'nfe_1067.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFE',
          'mensagem': 'Sucesso',
        },
        {
          'status': 'ERRO',
          'arquivo': 'nfce_26.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFCE',
          'mensagem':
              'NF-e já importada. Chave: 31260919364209000162650010000000251758778562',
        },
      ];

      final texto = formatarRelatorioErrosParaClipboard(
        logs: logs,
        dataHora: DateTime(2026, 9, 30, 15, 23),
        pastaRaiz: 'C:\\AutomacaoFiscal',
        ultimoResultado: '1 sucesso, 1 erro (1 já importados)',
      );

      expect(texto, contains('RELATÓRIO DE ERROS / EXCEPTIONS'));
      expect(texto, contains('Data/Hora: 30/09/2026 15:23:00'));
      expect(texto, contains('Pasta Raiz: C:\\AutomacaoFiscal'));
      // Arquivos já importados NÃO contam como erro!
      expect(texto, contains('Total de arquivos com erro: 1'));
      expect(texto, contains('Arquivo: nfe_1066.xml'));
      expect(texto, contains('Invalid byte 2 of 2-byte UTF-8 sequence'));
      // Não deve incluir arquivos com sucesso nem arquivos já importados
      expect(texto, isNot(contains('nfe_1067.xml')));
      expect(texto, isNot(contains('nfce_26.xml')));
    });

    test('quando ha apenas ja importados ou sucesso retorna mensagem amigavel',
        () {
      final texto = formatarRelatorioErrosParaClipboard(
        logs: [
          {
            'status': 'JA_IMPORTADO',
            'arquivo': 'nfce_26.xml',
            'origem': 'XML',
            'tipoDocumento': 'JA_IMPORTADO',
            'mensagem':
                'NF-e já importada. Chave: 31260919364209000162650010000000251758778562',
          },
        ],
        ultimoResultado: '0 sucesso, 0 erro (1 já importados)',
      );
      expect(texto,
          contains('Última execução: 0 sucesso, 0 erro (1 já importados)'));
    });

    test('quando nao ha erros retorna mensagem amigavel', () {
      final texto = formatarRelatorioErrosParaClipboard(
        logs: [],
        ultimoResultado: '5 sucesso, 0 erro',
      );
      expect(texto, contains('Última execução: 5 sucesso, 0 erro'));
    });
  });

  group('extrairPendenciasCadastro', () {
    test(
        'extrai pendencias de sacado e fornecedor a partir de tags estruturadas do backend',
        () {
      final logs = [
        {
          'status': 'ERRO',
          'arquivo': 'nfe_1066.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFE',
          'mensagem':
              '[FORNECEDOR: 12.345.678/0001-99] [SACADO: 98.765.432/0001-88] Falha ao importar: Parceiro não cadastrado',
        },
        {
          'status': 'ERRO',
          'arquivo': 'guia_icms.pdf',
          'origem': 'BOLETO',
          'tipoDocumento': 'DAE_ICMS',
          'mensagem':
              '[SACADO: 98765432000188] Parceiro do documento não encontrado no tenant.',
        },
        {
          'status': 'SUCESSO',
          'arquivo': 'nfe_ok.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFE',
          'mensagem': '[FORNECEDOR: 11111111000111] Sucesso',
        },
      ];

      final pendencias = extrairPendenciasCadastro(logs);

      // Deve ter exatamente 2 pendências (1 fornecedor e 1 sacado), pois o sacado do segundo log é duplicado
      expect(pendencias.length, 2);

      final forn =
          pendencias.firstWhere((p) => p.papel == PapelCadastro.fornecedor);
      expect(forn.cnpj, '12345678000199');
      expect(forn.cnpjFormatado, '12.345.678/0001-99');
      expect(forn.papelBadge, 'RECEBEDOR');
      expect(forn.papelTitulo, contains('Recebedor (Fornecedor)'));
      expect(forn.arquivo, 'nfe_1066.xml');

      final sac = pendencias.firstWhere((p) => p.papel == PapelCadastro.sacado);
      expect(sac.cnpj, '98765432000188');
      expect(sac.cnpjFormatado, '98.765.432/0001-88');
      expect(sac.papelBadge, 'SACADO');
      expect(sac.papelTitulo, contains('Sacado (Parceiro / Cliente)'));
    });

    test('extrai pendencia quando ha CNPJ no texto do erro sem tag especifica',
        () {
      final logs = [
        {
          'status': 'ERRO',
          'arquivo': 'boleto_123.pdf',
          'origem': 'BOLETO',
          'tipoDocumento': 'BOLETO_FORNECEDOR',
          'mensagem':
              'Nenhum fornecedor cadastrado para o CNPJ 11.222.333/0001-81 na base.',
        },
        {
          'status': 'ERRO',
          'arquivo': 'tomador_servico.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFSE',
          'mensagem':
              'Nenhum parceiro destinatario/tomador encontrado com CNPJ 55.666.777/0001-44.',
        },
      ];

      final pendencias = extrairPendenciasCadastro(logs);
      expect(pendencias.length, 2);

      expect(pendencias[0].papel, PapelCadastro.fornecedor);
      expect(pendencias[0].cnpj, '11222333000181');

      expect(pendencias[1].papel, PapelCadastro.sacado);
      expect(pendencias[1].cnpj, '55666777000144');
    });

    test('retorna lista vazia se nao houver erros com CNPJ', () {
      final logs = [
        {
          'status': 'SUCESSO',
          'arquivo': 'arquivo.xml',
          'mensagem': 'Processado com sucesso',
        },
        {
          'status': 'ERRO',
          'arquivo': 'arquivo_corrompido.xml',
          'mensagem': 'Arquivo corrompido sem nenhum documento presente',
        },
      ];

      final pendencias = extrairPendenciasCadastro(logs);
      expect(pendencias, isEmpty);
    });

    test(
        'ignora erros que nao sao de falta de cadastro (ja importada, duplicado, etc)',
        () {
      final logs = [
        {
          'status': 'ERRO',
          'arquivo': 'nfce_26.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFCE',
          'mensagem':
              '[FORNECEDOR: 19364209000162] NF-e já importada. Chave: 31260919364209000162650010000000251758778562',
        },
        {
          'status': 'ERRO',
          'arquivo': 'NFSe_1.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFSE',
          'mensagem': '[FORNECEDOR: 29911035000164] NFS-e ja importada.',
        },
      ];

      final pendencias = extrairPendenciasCadastro(logs);
      expect(pendencias, isEmpty);
    });

    test('ignora CNPJs passados no conjunto de aprovados na sessao', () {
      final logs = [
        {
          'status': 'ERRO',
          'arquivo': 'nfe_1066.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFE',
          'mensagem':
              '[FORNECEDOR: 12.345.678/0001-99] Parceiro não cadastrado',
        },
      ];

      expect(extrairPendenciasCadastro(logs).length, 1);

      final pendencias = extrairPendenciasCadastro(logs, {'12345678000199'});
      expect(pendencias, isEmpty);
    });
  });

  group('Remoção de erros do histórico', () {
    test('remover todos os erros limpa apenas logs com status ERRO', () {
      final logs = [
        {'id': 1, 'status': 'ERRO', 'arquivo': 'nfe_1066.xml'},
        {'id': 2, 'status': 'SUCESSO', 'arquivo': 'nfe_1067.xml'},
        {'id': 3, 'status': 'ERRO', 'arquivo': 'nfce_26.xml'},
      ];

      final errosCount = logs.where((l) => l['status'] == 'ERRO').length;
      expect(errosCount, 2);

      logs.removeWhere((l) => l['status'] == 'ERRO');

      expect(logs.length, 1);
      expect(logs.first['status'], 'SUCESSO');
      expect(logs.first['arquivo'], 'nfe_1067.xml');
      expect(logs.where((l) => l['status'] == 'ERRO').length, 0);
    });

    test('remover erro individual remove apenas o registro especificado', () {
      final logs = [
        {'id': 10, 'status': 'ERRO', 'arquivo': 'nfe_1066.xml'},
        {'id': 11, 'status': 'ERRO', 'arquivo': 'nfce_26.xml'},
      ];

      final logARemover = logs.first;
      logs.removeWhere((l) => l['id'] == logARemover['id']);

      expect(logs.length, 1);
      expect(logs.first['id'], 11);
      expect(logs.first['arquivo'], 'nfce_26.xml');
    });
  });

  group('Rastreabilidade e Auditoria Fiscal', () {
    testWidgets('mantem tabela compacta e abre rastreabilidade no popup',
        (tester) async {
      final logsFixture = [
        {
          'id': 140,
          'dhCreatedAt': '2026-09-30T19:25:39.56647',
          'arquivo': 'nfe_1066.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFE_ENTRADA',
          'status': 'JA_IMPORTADO',
          'mensagem':
              'NF-e já importada. Chave: 35260619364209000162550010000006511000045703',
          'empresaId': 1,
          'empresaNome': 'Empresa Demonstração',
          'fornecedorId': 1751,
          'fornecedorNome': 'BRASIL MODA SURF LTDA',
          'parceiroId': 1751,
          'parceiroNome': 'BRASIL MODA SURF LTDA',
          'documentoId': 1108,
          'documentoNumero': '651',
          'produtosInfo': '[ID 55] Camiseta Surf; [ID 56] Bermuda Água',
          'detalhesRastreabilidade':
              'NF-e Entrada #651 importada previamente com sucesso.',
        },
      ];

      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomacaoFiscalScreen(
              logsPrecarregados: logsFixture,
              showAppBar: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Os dados extensos não ocupam colunas; ficam no popup.
      expect(find.text('Data/Hora'), findsOneWidget);
      expect(find.text('Empresa'), findsNothing);
      expect(find.text('Fornecedor / Parceiro'), findsNothing);
      expect(find.text('Doc / Produtos'), findsNothing);
      expect(find.text('Empresa Demonstração'), findsNothing);
      expect(find.text('Ver detalhes'), findsOneWidget);

      // Clica no botão de rastreabilidade da linha
      final btnRastreabilidade =
          find.byKey(const Key('btn_rastreabilidade_140'));
      expect(btnRastreabilidade, findsOneWidget);
      await tester.ensureVisible(btnRastreabilidade);
      await tester.tap(btnRastreabilidade);
      await tester.pumpAndSettle();

      // Modal de Auditoria e Rastreabilidade abre com detalhes
      expect(find.text('Rastreabilidade & Auditoria Fiscal'), findsOneWidget);
      expect(find.text('Empresa e Parceiro'), findsOneWidget);
      expect(
          find.textContaining('Empresa:', findRichText: true), findsOneWidget);
      expect(
          find.textContaining('Parceiro:', findRichText: true), findsOneWidget);
      expect(find.text('Documento Gerado no Sistema'), findsOneWidget);
      expect(find.text('Produtos Cadastrados / Vinculados'), findsOneWidget);
      expect(
          find.textContaining('[ID: 1] Empresa Demonstração'), findsOneWidget);
      expect(find.textContaining('[ID 55] Camiseta Surf'), findsOneWidget);
      expect(find.textContaining('Data do Import: 30/09/2026'), findsOneWidget);
      expect(find.text('Fechar'), findsOneWidget);

      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
    });

    testWidgets('mantem card mobile compacto e abre detalhes no popup',
        (tester) async {
      final logsFixture = [
        {
          'id': 140,
          'dhCreatedAt': '2026-09-30T19:25:39.56647',
          'arquivo': 'nfe_1066.xml',
          'origem': 'XML',
          'tipoDocumento': 'NFE_ENTRADA',
          'status': 'JA_IMPORTADO',
          'mensagem': 'NF-e já importada.',
          'empresaId': 1,
          'empresaNome': 'Empresa Demonstração',
          'fornecedorId': 1751,
          'fornecedorNome': 'BRASIL MODA SURF LTDA',
          'parceiroNome': 'Parceiro sem ID',
          'documentoId': 1108,
          'documentoNumero': '651',
          'produtosInfo': '[ID 55] Camiseta Surf',
        },
      ];

      // Tamanho mobile (< 680px)
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomacaoFiscalScreen(
              logsPrecarregados: logsFixture,
              showAppBar: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifica resumo sem os metadados extensos.
      expect(find.textContaining('Importado em:'), findsOneWidget);
      expect(find.textContaining('[ID 1] Empresa Demonstração'), findsNothing);
      expect(
          find.textContaining('[ID 1751] BRASIL MODA SURF LTDA'), findsNothing);
      expect(find.textContaining('ID: 1108'), findsNothing);
      expect(find.text('Ver detalhes'), findsOneWidget);

      // Clica em "Ver Rastreabilidade Completa"
      final btnCard = find.byKey(const Key('btn_card_rastreabilidade_140'));
      await tester.ensureVisible(btnCard);
      await tester.tap(btnCard);
      await tester.pumpAndSettle();

      expect(find.text('Rastreabilidade & Auditoria Fiscal'), findsOneWidget);
      expect(
          find.textContaining('[ID: 1] Empresa Demonstração'), findsOneWidget);
      expect(
          find.textContaining('Empresa:', findRichText: true), findsOneWidget);
      expect(
          find.textContaining('Parceiro:', findRichText: true), findsOneWidget);
      expect(
        find.textContaining('Parceiro sem ID', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Fechar'), findsOneWidget);
      await tester.tap(find.text('Fechar'));
      await tester.pumpAndSettle();
    });
  });

  group('Envio de arquivos em lote para ambiente em nuvem', () {
    testWidgets('exibe botao para enviar arquivos da maquina no card de configuracao', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AutomacaoFiscalScreen(showAppBar: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_enviar_arquivos_locais')), findsOneWidget);
      expect(find.text('Enviar arquivos da minha máquina'), findsOneWidget);
    });
  });
}
