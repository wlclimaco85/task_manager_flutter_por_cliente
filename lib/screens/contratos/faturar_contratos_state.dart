import '../../models/recurring_contract_model.dart';

class FaturarContratosState {
  static List<RecurringContract> contratosAteCompetencia(
    List<RecurringContract> contratos,
    DateTime competencia,
  ) {
    final limite = DateTime(competencia.year, competencia.month + 1, 0);
    return contratos.where((contrato) {
      final vencimento = DateTime(
        contrato.nextDueDate.year,
        contrato.nextDueDate.month,
        contrato.nextDueDate.day,
      );
      return !vencimento.isAfter(limite) &&
          contrato.status.toUpperCase() == 'ACTIVE';
    }).toList();
  }

  static double totalMensal(List<RecurringContract> contratos) {
    return contratos.fold<double>(
      0,
      (total, contrato) => total + contrato.monthlyValue,
    );
  }
}
