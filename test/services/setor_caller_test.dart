import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/setor_model.dart';
import 'package:task_manager_flutter/services/setor_caller.dart';

void main() {
  group('SetorCaller - Parse robusto de setores (List e Map)', () {
    test('Setor.fromJson deve ler descricao como nome e novos campos responsavel e ramal', () {
      final json = {
        'id': 10,
        'descricao': 'Departamento Pessoal',
        'responsavel': 'João Silva',
        'ramal': '205',
      };

      final setor = Setor.fromJson(json);

      expect(setor.id, equals(10));
      expect(setor.nome, equals('Departamento Pessoal'));
      expect(setor.responsavel, equals('João Silva'));
      expect(setor.ramal, equals('205'));
    });

    test('Setor.fromJson aceita chave nome caso descricao venha nula', () {
      final json = {
        'id': 11,
        'nome': 'Fiscal',
      };

      final setor = Setor.fromJson(json);

      expect(setor.id, equals(11));
      expect(setor.nome, equals('Fiscal'));
      expect(setor.responsavel, isNull);
      expect(setor.ramal, isNull);
    });

    test('deve instanciar SetorCaller com sucesso', () {
      final caller = SetorCaller();
      expect(caller, isNotNull);
    });
  });
}
