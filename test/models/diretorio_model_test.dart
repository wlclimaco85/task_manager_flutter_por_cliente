import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/diretorio_model.dart';

/// Bug de producao: Diretorio.fromJson jogava TypeError
/// ("null: type 'Null' is not a subtype of type 'String'") quando 'nome'
/// ou 'descricao' vinham nulos do backend, derrubando a listagem inteira
/// de Diretorios (tela mostrava "Nenhum item encontrado" + banner de erro,
/// mesmo havendo registros).
void main() {
  group('Diretorio.fromJson', () {
    test('constroi normalmente quando nome e descricao estao presentes', () {
      final diretorio = Diretorio.fromJson({
        'id': 1,
        'nome': 'Fiscal',
        'descricao': 'Documentos fiscais',
      });

      expect(diretorio.id, 1);
      expect(diretorio.nome, 'Fiscal');
      expect(diretorio.descricao, 'Documentos fiscais');
      expect(diretorio.empresa, isNull);
    });

    test('nao lanca excecao quando nome vem nulo (regressao do bug de producao)', () {
      final diretorio = Diretorio.fromJson({
        'id': 2,
        'nome': null,
        'descricao': 'Alguma descricao',
      });

      expect(diretorio.nome, '');
      expect(diretorio.descricao, 'Alguma descricao');
    });

    test('nao lanca excecao quando descricao vem nula (regressao do bug de producao)', () {
      final diretorio = Diretorio.fromJson({
        'id': 3,
        'nome': 'Contratos',
        'descricao': null,
      });

      expect(diretorio.nome, 'Contratos');
      expect(diretorio.descricao, '');
    });

    test('nao lanca excecao quando nome e descricao vem nulos ao mesmo tempo', () {
      final diretorio = Diretorio.fromJson({
        'id': 4,
        'nome': null,
        'descricao': null,
      });

      expect(diretorio.nome, '');
      expect(diretorio.descricao, '');
    });

    test('empresa e parseada quando presente', () {
      final diretorio = Diretorio.fromJson({
        'id': 5,
        'nome': 'RH',
        'descricao': 'Documentos de RH',
        'empresa': {'id': 10, 'nome': 'Empresa X'},
      });

      expect(diretorio.empresa, isNotNull);
      expect(diretorio.empresa!.id, 10);
    });
  });
}
