import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/diretorio_busca.dart';

void main() {
  final lista = <Map<String, dynamic>>[
    {'id': 1, 'nome': 'RESCISÕES'},
    {'id': 2, 'nome': 'admissões'},
    {'id': 3, 'nome': 'DEMISSÕES'},
    {'id': 4, 'nome': 'Alvara'},
    {'id': 5, 'nome': null},
  ];

  group('ordenarDiretoriosPorNome', () {
    test('ordem alfabetica ignorando acento e caixa; sem nome vem primeiro', () {
      final nomes = ordenarDiretoriosPorNome(lista).map((d) => d['nome']).toList();

      expect(nomes, [null, 'admissões', 'Alvara', 'DEMISSÕES', 'RESCISÕES']);
    });

    test('nao altera a lista original', () {
      ordenarDiretoriosPorNome(lista);

      expect(lista.first['id'], 1);
    });
  });

  group('filtrarDiretoriosPorNome', () {
    test('busca vazia ou nula devolve tudo', () {
      expect(filtrarDiretoriosPorNome(lista, null), hasLength(5));
      expect(filtrarDiretoriosPorNome(lista, '  '), hasLength(5));
    });

    test('acha sem acento e sem diferenciar caixa', () {
      final ids = filtrarDiretoriosPorNome(lista, 'rescisoes').map((d) => d['id']);

      expect(ids, [1]);
    });

    test('termo parcial em varios resultados', () {
      final ids = filtrarDiretoriosPorNome(lista, 'ss').map((d) => d['id']).toList();

      expect(ids, [2, 3]);
    });

    test('sem resultado devolve lista vazia', () {
      expect(filtrarDiretoriosPorNome(lista, 'zzz'), isEmpty);
    });
  });
}
