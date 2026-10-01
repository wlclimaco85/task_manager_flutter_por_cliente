import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/query_builder_caller.dart';

void main() {
  test('extrai metadados do envelope Response usado pelo backend', () {
    final body = <String, dynamic>{
      'data': <String, dynamic>{
        'data': <Map<String, dynamic>>[
          {'schema_name': 'public'},
        ],
      },
      'response': <String, dynamic>{'error': false, 'status': 200},
    };

    final schemas = QueryBuilderCaller.extrairLista(body);

    expect(schemas, hasLength(1));
    expect(QueryBuilderCaller.nomeSchema(schemas.single), 'public');
  });

  test('identifica nome e schema da tabela retornada pelo backend', () {
    final tabela = <String, dynamic>{
      'table_schema': 'public',
      'table_name': 'login',
      'table_type': 'TABLE',
    };

    expect(QueryBuilderCaller.nomeTabela(tabela), 'login');
    expect(
      QueryBuilderCaller.tabelaPertenceAoSchema(tabela, 'public'),
      isTrue,
    );
    expect(
      QueryBuilderCaller.tabelaPertenceAoSchema(tabela, 'auditoria'),
      isFalse,
    );
  });
}
