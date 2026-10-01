import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_status.dart';
import 'package:task_manager_flutter/models/nfe/nfe_tomador_model.dart';
import 'package:task_manager_flutter/models/nfe/valores_nfe_model.dart';

/// Mocks de dados para testes
class NfeMocks {
  static final mockTomador = const NfeTomadorModel(
    cnpjCpf: '12.345.678/0001-90',
    razaoSocial: 'ACME Ltda',
    endereco: 'Rua Principal',
    numero: '123',
    bairro: 'Centro',
    cep: '01310-100',
    uf: 'SP',
    municipio: 'São Paulo',
  );

  static final mockValores = ValoresNfeModel(
    subtotal: 1000.00,
    totalIcms: 180.00,
    totalPis: 30.00,
    totalCofins: 60.00,
    desconto: 0.00,
    total: 1270.00,
  );

  static final mockItem1 = const NfeItemModel(
    sequencial: 1,
    codigoProduto: '001',
    descricao: 'Serviço de Consultoria',
    ncm: '92110000',
    cfop: '5123',
    cstIcms: '90',
    quantidade: 1.0,
    unidade: 'un',
    precoUnitario: 500.00,
    precoTotal: 500.00,
    aliqIcms: 18.0,
    vlIcms: 90.00,
    aliqPis: 3.0,
    vlPis: 15.00,
    aliqCofins: 6.0,
    vlCofins: 30.00,
  );

  static final mockItem2 = const NfeItemModel(
    sequencial: 2,
    codigoProduto: '002',
    descricao: 'Licença de Software',
    ncm: '92110000',
    cfop: '5124',
    cstIcms: '90',
    quantidade: 1.0,
    unidade: 'un',
    precoUnitario: 500.00,
    precoTotal: 500.00,
    aliqIcms: 18.0,
    vlIcms: 90.00,
    aliqPis: 3.0,
    vlPis: 15.00,
    aliqCofins: 6.0,
    vlCofins: 30.00,
  );

  static NfeModel mockNfe({
    int id = 1,
    String numero = '123',
    int serie = 1,
    NfeStatus status = NfeStatus.autorizada,
    List<NfeItemModel>? itens,
  }) {
    return NfeModel(
      id: id,
      empresaId: 200001,
      numero: numero,
      serie: serie,
      dataHora: DateTime.now(),
      statusNfe: status,
      cnpjEmitente: '11.222.333/0001-44',
      uf: 'SP',
      ambiente: 'HOMOLOGACAO',
      tomador: mockTomador,
      itens: itens ?? [mockItem1, mockItem2],
      valores: mockValores,
      criadoEm: DateTime.now(),
    );
  }

  static List<NfeModel> mockNfeList({int count = 5}) {
    return List.generate(
      count,
      (index) => mockNfe(
        id: index + 1,
        numero: '${123 + index}',
        status: [
          NfeStatus.autorizada,
          NfeStatus.pendente,
          NfeStatus.contingencia,
          NfeStatus.cancelada,
          NfeStatus.rejeitada,
        ][index % 5],
      ),
    );
  }
}
