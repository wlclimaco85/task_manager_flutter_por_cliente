import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/ged_upload_scope.dart';

void main() {
  test('upload aberto pelo GED envia modulo ged explicitamente', () {
    expect(resolveGedUploadModule(null), 'ged');
    expect(resolveGedUploadModule(''), 'ged');
  });

  test('upload contextual preserva o modulo de origem', () {
    expect(resolveGedUploadModule('financeiro'), 'financeiro');
    expect(resolveGedUploadModule(' parceiro '), 'parceiro');
  });
}
