import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/financial_account_form_rules.dart';

void main() {
  group('financialAccountFormOrder', () {
    test('organiza obrigatorios, gerais, recorrencia e baixa nessa ordem', () {
      final requiredOrder = financialAccountFormOrder(
        screenName: 'conta_pagar',
        fieldName: 'descricao',
        backendOrder: 40,
        isRequired: true,
      );
      final generalOrder = financialAccountFormOrder(
        screenName: 'conta_pagar',
        fieldName: 'observacao',
        backendOrder: 10,
        isRequired: false,
      );
      final recurrenceOrder = financialAccountFormOrder(
        screenName: 'conta_pagar',
        fieldName: 'recorrencia_ativa',
        backendOrder: 5,
        isRequired: false,
      );
      final settlementOrder = financialAccountFormOrder(
        screenName: 'conta_pagar',
        fieldName: 'data_baixa',
        backendOrder: 1,
        isRequired: false,
      );

      expect(requiredOrder, lessThan(generalOrder));
      expect(generalOrder, lessThan(recurrenceOrder));
      expect(recurrenceOrder, lessThan(settlementOrder));
    });

    test('aplica a mesma regra em contas a receber', () {
      final recurrenceOrder = financialAccountFormOrder(
        screenName: 'conta_receber',
        fieldName: 'totalParcelas',
        backendOrder: 1,
        isRequired: false,
      );
      final settlementOrder = financialAccountFormOrder(
        screenName: 'conta_receber',
        fieldName: 'valorBaixa',
        backendOrder: 1,
        isRequired: false,
      );

      expect(recurrenceOrder, lessThan(settlementOrder));
    });

    test('preserva a ordem original de outras telas', () {
      expect(
        financialAccountFormOrder(
          screenName: 'parceiro',
          fieldName: 'descricao',
          backendOrder: 7,
          isRequired: true,
        ),
        7,
      );
    });
  });
}
