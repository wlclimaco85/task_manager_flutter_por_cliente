import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/telas_model.dart';
import 'package:task_manager_flutter/services/dicionario_campo_service.dart';
import 'package:task_manager_flutter/utils/tela_personalizacao.dart';

TelaConfig _tela() => TelaConfig(
      id: 1,
      nome: 'produto',
      titulo: 'Produtos',
      fetchEndpoint: '/api/produto',
      createEndpoint: '/api/produto',
      updateEndpoint: '/api/produto/:id',
      deleteEndpoint: '/api/produto/:id',
      fields: [
        TelaField(label: 'Nome', fieldName: 'nome', isRequired: true, fieldOrder: 1),
        TelaField(label: 'Parceiro', fieldName: 'codParceiro', fieldType: TelaFieldType.number, fieldOrder: 2),
      ],
    );

void main() {
  test('rotulo personalizado troca so o label; tipo e nome continuam iguais e a tela original nao muda', () {
    final original = _tela();
    final nova = aplicarPersonalizacaoTela(original, const PersonalizacaoTela(labels: {'nome': 'Descrição do produto'}));

    expect(nova.fields[0].label, 'Descrição do produto');
    expect(nova.fields[0].fieldName, 'nome');
    expect(nova.fields[0].isRequired, isTrue, reason: 'demais propriedades preservadas');
    expect(nova.fields[0].fieldType, TelaFieldType.text);
    expect(nova.fields[1].label, 'Parceiro');
    expect(original.fields[0].label, 'Nome', reason: 'a tela compartilhada nao e alterada');
    expect(nova.nome, 'produto');
    expect(nova.fetchEndpoint, '/api/produto');
  });

  test('ligacao transforma o campo em dropdown no endpoint informado (sem diferenciar caixa do campo)', () {
    final nova = aplicarPersonalizacaoTela(
        _tela(),
        const PersonalizacaoTela(ligacoes: [
          LigacaoCampo(
              campo: 'CODPARCEIRO',
              tabelaDestino: 'parceiro',
              endpoint: '/api/parceiro',
              campoChave: 'id',
              campoExibicao: 'razaoSocial'),
        ]));

    final f = nova.fields[1];
    expect(f.fieldType, TelaFieldType.dropdown);
    expect(f.dropdownEndpoint, '/api/parceiro');
    expect(f.dropdownValueField, 'id');
    expect(f.dropdownDisplayField, 'razaoSocial');
    expect(nova.fields[0].fieldType, TelaFieldType.text);
  });

  test('sem personalizacao devolve a mesma tela', () {
    final t = _tela();
    expect(identical(aplicarPersonalizacaoTela(t, const PersonalizacaoTela()), t), isTrue);
  });

  test('falha ao buscar a personalizacao nunca derruba a grid: volta a tela original', () async {
    final t = _tela();
    expect(identical(await telaComPersonalizacao(t, (_) async => throw Exception('rede fora')), t), isTrue);
    final ok = await telaComPersonalizacao(
        t, (n) async => PersonalizacaoTela.fromJson({'labels': {'Nome': 'X'}, 'ligacoes': []}));
    expect(ok.fields[0].label, 'X');
  });

  test('PersonalizacaoTela le o contrato do backend (chaves em minusculas)', () {
    final p = PersonalizacaoTela.fromJson({
      'labels': {'Nome': 'Descrição'},
      'ligacoes': [
        {
          'campo': 'codParceiro',
          'tabelaDestino': 'parceiro',
          'endpoint': '/api/parceiro',
          'campoChave': 'id',
          'campoExibicao': 'nome'
        },
      ],
    });
    expect(p.labels['nome'], 'Descrição');
    expect(p.ligacoes.single.tabelaDestino, 'parceiro');
    expect(p.vazia, isFalse);
  });
}
