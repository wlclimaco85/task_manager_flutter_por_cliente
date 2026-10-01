// test/models/chamado_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/chamado_model.dart';

void main() {
  group('Chamado.fromJson', () {
    // Card #451: reproduz o crash real "Nao foi possivel carregar o
    // sistema" ao clicar em Visualizar num chamado com status/prioridade/
    // empresa nulos no banco (ex.: chamado id=1 "seed", visivel com essas
    // colunas em branco no grid). Antes do fix, StatusChamadoEnum.fromString
    // e PrioridadeChamadoEnum.fromString chamavam .toUpperCase() direto no
    // valor nulo (NoSuchMethodError nao capturado), e Empresa.fromJson(null)
    // quebrava com type error.
    test('does not throw when status, prioridade and empresa are null', () {
      final json = {
        'id': 1,
        'titulo': 'seed',
        'descricao': 'seed',
        'status': null,
        'prioridade': null,
        'empresa': null,
        'dataAbertura': null,
      };

      final chamado = Chamado.fromJson(json);

      expect(chamado.status, StatusChamadoEnum.ABERTO);
      expect(chamado.prioridade, PrioridadeChamadoEnum.BAIXA);
      expect(chamado.empresa, isNotNull);
      expect(chamado.empresa.nome, isNull);
    });

    test('does not throw when titulo and descricao are null', () {
      final json = {
        'id': 2,
        'titulo': null,
        'descricao': null,
        'status': 'ABERTO',
        'prioridade': 'BAIXA',
        'empresa': {'id': 1, 'nome': 'Empresa Teste'},
      };

      final chamado = Chamado.fromJson(json);

      expect(chamado.titulo, '');
      expect(chamado.descricao, '');
    });

    test('parses a fully populated chamado normally', () {
      final json = {
        'id': 3,
        'titulo': 'Erro no boleto',
        'descricao': 'Boleto nao gera',
        'status': 'EM_ANDAMENTO',
        'prioridade': 'ALTA',
        'empresa': {'id': 1, 'nome': 'Empresa Smoke Test'},
        'dataAbertura': '2026-07-10T10:00:00',
      };

      final chamado = Chamado.fromJson(json);

      expect(chamado.status, StatusChamadoEnum.EM_ANDAMENTO);
      expect(chamado.prioridade, PrioridadeChamadoEnum.ALTA);
      expect(chamado.empresa.nome, 'Empresa Smoke Test');
      expect(chamado.titulo, 'Erro no boleto');
    });

    test('fromString falls back to ABERTO/BAIXA for unrecognized values', () {
      expect(StatusChamadoEnum.fromString('lixo'), StatusChamadoEnum.ABERTO);
      expect(PrioridadeChamadoEnum.fromString('lixo'), PrioridadeChamadoEnum.BAIXA);
      expect(StatusChamadoEnum.fromString(null), StatusChamadoEnum.ABERTO);
      expect(PrioridadeChamadoEnum.fromString(null), PrioridadeChamadoEnum.BAIXA);
    });
  });
}
