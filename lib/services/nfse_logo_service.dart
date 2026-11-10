import 'dart:convert';

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/tenant_context.dart';

/// Envia, consulta e remove a logo do DANFSe (PNG/JPEG) da empresa ou do parceiro.
class NfseLogoService {
  /// Tamanho maximo da logo (espelha o limite do NfseLogoController no backend).
  static const int limiteBytes = 512 * 1024;

  /// Envia a logo. Retorna null quando o backend aceitou, ou a mensagem de erro do backend.
  static Future<String?> enviarEmpresa(int empresaId, List<int> bytes, String nomeArquivo) =>
      _enviar(ApiLinks.nfseLogoEmpresa(empresaId.toString()), bytes, nomeArquivo);

  static Future<String?> enviarParceiro(int parceiroId, List<int> bytes, String nomeArquivo) =>
      _enviar(ApiLinks.nfseLogoParceiro(parceiroId.toString()), bytes, nomeArquivo);

  /// Bytes da logo cadastrada. Null quando nao ha logo (404) ou quando a consulta falhou (logado).
  static Future<List<int>?> buscar(String url) async {
    try {
      final resposta = await TenantContext.get(url);
      if (resposta.statusCode == 200) return resposta.bodyBytes;
      if (resposta.statusCode != 404) {
        AppLogger.i.warn('[NFSE-LOGO] consulta da logo recusada (HTTP ${resposta.statusCode})');
      }
      return null;
    } catch (e, st) {
      AppLogger.i.error('[NFSE-LOGO] falha ao buscar logo: $e', st);
      return null;
    }
  }

  /// Remove a logo cadastrada. Retorna true quando o backend confirmou (204).
  static Future<bool> remover(String url) async {
    try {
      final resposta = await TenantContext.delete(url);
      return resposta.statusCode == 204;
    } catch (e, st) {
      AppLogger.i.error('[NFSE-LOGO] falha ao remover logo: $e', st);
      return false;
    }
  }

  static Future<String?> _enviar(String url, List<int> bytes, String nomeArquivo) async {
    // Limite conferido no app antes do envio (o servidor aceita arquivos maiores que a logo).
    if (bytes.length > limiteBytes) {
      return 'Logo acima de 512 KB. Reduza a imagem e tente de novo.';
    }
    try {
      final resposta = await TenantContext.postMultipart(
        url,
        fileBytes: bytes,
        fileName: nomeArquivo,
        fileField: 'arquivo',
      );
      final status = resposta.statusCode;
      if (status == 200) return null;
      AppLogger.i.warn('[NFSE-LOGO] envio recusado (HTTP $status)');
      // 413: arquivo acima do limite (o servidor responde antes de ler o corpo).
      if (status == 413) return 'Logo acima de 512 KB. Reduza a imagem e tente de novo.';
      // 5xx: detalhe interno nunca vai para a tela; so' o texto generico.
      if (status >= 500) return 'Erro no servidor ao salvar a logo. Tente novamente.';
      // 4xx: mensagem de negocio do backend (formato invalido, sem permissao etc.).
      return _mensagemDoBackend(resposta.body) ?? 'Nao foi possivel salvar a logo (PNG ou JPEG ate 512 KB).';
    } catch (e, st) {
      AppLogger.i.error('[NFSE-LOGO] falha ao enviar logo: $e', st);
      return 'Falha de conexao ao enviar a logo.';
    }
  }

  /// Primeira mensagem nao vazia do corpo de erro (message, mensagem, error). Null se nao houver.
  static String? _mensagemDoBackend(String corpo) {
    try {
      final json = jsonDecode(corpo);
      if (json is Map) {
        for (final chave in const ['message', 'mensagem', 'error']) {
          final valor = json[chave];
          if (valor is String && valor.trim().isNotEmpty) return valor;
        }
      }
    } catch (_) {
      // corpo nao e JSON: sem mensagem especifica
    }
    return null;
  }
}
