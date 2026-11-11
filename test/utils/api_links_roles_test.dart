import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/api_links.dart';

void main() {
  test('lista de roles pede tamanho=1000 (o backend ignora "size" e devolve so 25)', () {
    expect(ApiLinks.getAllRoles, contains('/api/role?tamanho=1000'));
    expect(ApiLinks.getAllRoles, isNot(contains('size=')));
  });
}
