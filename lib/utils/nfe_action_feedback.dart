class NfeActionFeedback {
  static const recusaStatus = 'REJEITADA';

  static String cancelamentoErrorMessage(int statusCode, String body) {
    final normalized = body.toLowerCase();
    final cancelamentoIndisponivel = normalized.contains('soap') ||
        normalized.contains('nao implementado') ||
        normalized.contains('não implementado') ||
        normalized.contains('not implemented');

    if (cancelamentoIndisponivel) {
      return 'Cancelamento da NF-e indisponivel no backend neste momento. Tente novamente quando o servico estiver habilitado.';
    }

    return 'Erro $statusCode. Tente novamente.';
  }
}
