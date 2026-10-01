import 'dart:developer' as developer;

/// Serviço de logging centralizado
class LoggerService {
  static const String _prefixoManifestacao = '[MANIFESTACAO]';

  static void debug(String mensagem, {String? tag, Object? erro}) {
    final prefixo = tag != null ? '$_prefixoManifestacao[$tag]' : _prefixoManifestacao;
    developer.log('$prefixo DEBUG: $mensagem');
  }

  static void info(String mensagem, {String? tag}) {
    final prefixo = tag != null ? '$_prefixoManifestacao[$tag]' : _prefixoManifestacao;
    developer.log('$prefixo INFO: $mensagem');
  }

  static void warning(String mensagem, {String? tag, Object? erro}) {
    final prefixo = tag != null ? '$_prefixoManifestacao[$tag]' : _prefixoManifestacao;
    developer.log('$prefixo WARNING: $mensagem');
    if (erro != null) {
      developer.log('$prefixo Erro: $erro');
    }
  }

  static void error(String mensagem, {String? tag, Object? erro, StackTrace? stack}) {
    final prefixo = tag != null ? '$_prefixoManifestacao[$tag]' : _prefixoManifestacao;
    developer.log('$prefixo ERROR: $mensagem');
    if (erro != null) {
      developer.log('$prefixo Erro: $erro');
    }
    if (stack != null) {
      developer.log('$prefixo Stack: $stack');
    }
  }

  static void carregamento(String evento, {String? tag}) {
    info(evento, tag: tag ?? 'LOAD');
  }

  static void validacao(String campo, String resultado, {String? detalhes}) {
    info('Validação[$campo]: $resultado ${detalhes ?? ''}', tag: 'VALIDATION');
  }

  static void submitManifestacao(String status) {
    info('Enviando manifestação com status: $status', tag: 'SUBMIT');
  }
}
