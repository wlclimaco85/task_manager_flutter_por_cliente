import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/fiscal_error_message.dart';

void main() {
  test('extrai mensagem json do erro fiscal', () {
    expect(
      fiscalErrorMessage(404, '{"message":"XML da NF-e não encontrado"}'),
      'Erro 404: XML da NF-e não encontrado',
    );
  });

  test('mantem fallback quando corpo vem vazio', () {
    expect(fiscalErrorMessage(404, ''), 'Erro 404');
  });
}
