import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:task_manager_flutter/models/tela_model.dart';
import 'package:task_manager_flutter/models/network_response.dart';
import 'package:task_manager_flutter/services/network_caller.dart';
import 'package:task_manager_flutter/services/tela_service.dart';

// Nota: Para rodar esses testes, seria necessario mockar NetworkCaller
// Este e um exemplo de estrutura que deveria existir no projeto

void main() {
  group('TelaService', () {
    test('listarTelas retorna lista vazia quando nenhuma tela e retornada', () async {
      // Arrange
      // TODO: Mock NetworkCaller para retornar resposta vazia

      // Act
      final telas = await TelaService.listarTelas();

      // Assert
      expect(telas, isEmpty);
    });

    test('Tela.fromJson deserializa corretamente', () {
      // Arrange
      final json = {
        'id': 1,
        'nome': 'dashboard',
        'descricao': 'Dashboard Principal',
      };

      // Act
      final tela = Tela.fromJson(json);

      // Assert
      expect(tela.id, 1);
      expect(tela.nome, 'dashboard');
      expect(tela.descricao, 'Dashboard Principal');
    });

    test('Tela.fromJson usa titulo como fallback para descricao', () {
      // Arrange
      final json = {
        'id': 2,
        'nome': 'relatorios',
        'titulo': 'Relatórios',
      };

      // Act
      final tela = Tela.fromJson(json);

      // Assert
      expect(tela.descricao, 'Relatórios');
    });

    test('Tela.toJson serializa corretamente', () {
      // Arrange
      final tela = Tela(
        id: 1,
        nome: 'dashboard',
        descricao: 'Dashboard Principal',
      );

      // Act
      final json = tela.toJson();

      // Assert
      expect(json['id'], 1);
      expect(json['nome'], 'dashboard');
      expect(json['descricao'], 'Dashboard Principal');
    });
  });
}
