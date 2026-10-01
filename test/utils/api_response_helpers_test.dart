import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/api_response_helpers.dart';

void main() {
  group('extrairListaDeResposta', () {
    test('extrai lista de resposta no formato {"data": [...]}', () {
      final decoded = {
        'data': [
          {'id': 1, 'nome': 'Cliente A'},
          {'id': 2, 'nome': 'Cliente B'},
        ],
        'response': {'error': false, 'message': 'OK', 'status': 200},
      };

      final resultado = extrairListaDeResposta(decoded);

      expect(resultado.length, 2);
      expect(resultado.first['nome'], 'Cliente A');
    });

    test('extrai lista de resposta no formato {"content": [...]}', () {
      final decoded = {
        'content': [
          {'id': 1, 'nome': 'Cliente A'},
        ],
      };

      final resultado = extrairListaDeResposta(decoded);

      expect(resultado.length, 1);
    });

    test('extrai lista JSON crua', () {
      final decoded = [
        {'id': 1, 'nome': 'Cliente A'},
      ];

      final resultado = extrairListaDeResposta(decoded);

      expect(resultado.length, 1);
    });

    test('retorna lista vazia para formato desconhecido', () {
      expect(extrairListaDeResposta({'foo': 'bar'}), isEmpty);
      expect(extrairListaDeResposta(null), isEmpty);
      expect(extrairListaDeResposta('texto'), isEmpty);
    });

    test('regressao: bug de producao onde {"data": [...]} era ignorado '
        'porque so {"content": [...]} era checado', () {
      // Reproduz exatamente o payload real de GET /api/parceiro/empresa/{id}
      // (Response.builder().data(lista)...), que antes do fix sempre
      // resultava em lista vazia no dropdown de Cliente da tela de
      // configuracao fiscal NFC-e.
      final decoded = {
        'data': [
          {'id': 10, 'nome': 'Cliente Real'},
        ],
        'response': {'error': false, 'message': 'DADOS RETORNADO COM SUCESSO', 'status': 200},
      };

      final resultado = extrairListaDeResposta(decoded);

      expect(resultado, isNotEmpty,
          reason: 'GET /api/parceiro/empresa/{id} retorna {"data": [...]}, '
              'nao {"content": [...]} -- o dropdown de Cliente nao pode '
              'ficar vazio para esse formato.');
    });
  });

  group('extrairListaPaginada', () {
    test('extrai lista de resposta no formato {"data": {"dados": [...]}}',
        () {
      final decoded = {
        'data': {
          'dados': [
            {'id': 1, 'nome': 'Produto A', 'preco': 10.0},
          ],
          'totalElements': 1,
        },
        'response': {'error': false, 'message': 'OK', 'status': 200},
      };

      final resultado = extrairListaPaginada(decoded);

      expect(resultado.length, 1);
      expect(resultado.first['nome'], 'Produto A');
    });

    test('regressao: bug de producao onde a busca de produto do PDV NFC-e '
        'sempre retornava vazia', () {
      // Reproduz o payload real de GET /api/produto_contabil (endpoint
      // correto, paginado, usado pelo picker de produto do PDV/NFC-e).
      // Antes do fix, NfceService.buscarProdutos apontava para o endpoint
      // errado (/api/produto, que ignora nome/empresa e mapeia para a
      // entidade CatalogoProduto, de dominio nao relacionado) e o parsing
      // so verificava lista crua/{"content":[...]}, nunca {"data":{"dados":
      // [...]}} -- a busca de produto no PDV nunca encontrava nada.
      final decoded = {
        'data': {
          'dados': [
            {'id': 20005, 'nome': 'SAND HAV ALOHA', 'preco': 27.26, 'codigo': 'ALOHA3138-39'},
          ],
          'totalElements': 1,
        },
        'response': {'error': false, 'message': 'OK', 'status': 200},
      };

      final resultado = extrairListaPaginada(decoded);

      expect(resultado, isNotEmpty,
          reason: 'GET /api/produto_contabil retorna {"data": {"dados": '
              '[...]}}, formato que precisa ser reconhecido para a busca '
              'de produto no PDV NFC-e funcionar.');
      expect(resultado.first['preco'], 27.26);
    });

    test('cai para extrairListaDeResposta quando nao ha data.dados', () {
      final decoded = {
        'data': [
          {'id': 1, 'nome': 'Produto A'},
        ],
      };

      final resultado = extrairListaPaginada(decoded);

      expect(resultado.length, 1);
    });
  });
}
