/// Exceções customizadas para Manifestação NFe

/// Exceção base para Manifestação
class ManifestacaoException implements Exception {
  final String mensagem;
  final dynamic erro;
  final StackTrace? stackTrace;

  ManifestacaoException({
    required this.mensagem,
    this.erro,
    this.stackTrace,
  });

  @override
  String toString() => mensagem;
}

/// NFe não encontrada
class NfeNaoEncontradaException extends ManifestacaoException {
  NfeNaoEncontradaException({
    required String nfeId,
    dynamic erro,
    StackTrace? stackTrace,
  }) : super(
    mensagem: 'NFe $nfeId não encontrada nas pendências',
    erro: erro,
    stackTrace: stackTrace,
  );
}

/// Erro de validação
class ValidationException extends ManifestacaoException {
  final Map<String, String> erros;

  ValidationException({
    required this.erros,
    dynamic erro,
    StackTrace? stackTrace,
  }) : super(
    mensagem: 'Validação falhou: ${erros.values.join(", ")}',
    erro: erro,
    stackTrace: stackTrace,
  );
}

/// Erro no envio
class SubmissaoException extends ManifestacaoException {
  SubmissaoException({
    required String mensagem,
    dynamic erro,
    StackTrace? stackTrace,
  }) : super(
    mensagem: mensagem,
    erro: erro,
    stackTrace: stackTrace,
  );
}

/// Erro de rede
class ErroRedeException extends ManifestacaoException {
  ErroRedeException({
    required String mensagem,
    dynamic erro,
    StackTrace? stackTrace,
  }) : super(
    mensagem: 'Erro de rede: $mensagem',
    erro: erro,
    stackTrace: stackTrace,
  );
}

/// Formato inesperado na resposta
class FormatoInvalidoException extends ManifestacaoException {
  FormatoInvalidoException({
    required String mensagem,
    dynamic erro,
    StackTrace? stackTrace,
  }) : super(
    mensagem: 'Formato inválido: $mensagem',
    erro: erro,
    stackTrace: stackTrace,
  );
}
