import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../models/nfce/nfce_resultado_model.dart';
import '../models/nfce/nfce_status_model.dart';
import '../utils/api_links.dart';
import '../utils/api_response_helpers.dart';
import '../utils/tenant_context.dart';

/// Serviço responsável pelas chamadas HTTP relacionadas a NFC-e.
/// Toda regra fiscal permanece no backend — este service apenas
/// envia dados e retorna resultados.
class NfceService {
  Future<NfceResultadoModel> emitirNfce(
    int vendaId, {
    Map<String, dynamic>? vendaJson,
  }) async {
    final url = ApiLinks.emitirNfce(vendaId);
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode(TenantContext.applyToBody(vendaJson ?? {})),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return NfceResultadoModel.fromJson(body);
    }
    throw NfceException(
      _extractErrorMessage(response, 'Falha ao emitir NFC-e'),
      statusCode: response.statusCode,
    );
  }

  Future<NfceStatusModel> consultarStatus(int nfceId) async {
    final url = ApiLinks.nfceStatus(nfceId);
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return NfceStatusModel.fromJson(body);
    }
    throw NfceException(
      _extractErrorMessage(response, 'Falha ao consultar status NFC-e'),
      statusCode: response.statusCode,
    );
  }

  Future<Uint8List> baixarDanfe(int nfceId) async {
    final url = ApiLinks.nfceDanfe(nfceId);
    final token = AuthUtility.userInfo?.token;
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'application/pdf',
      },
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw NfceException(
      _extractErrorMessage(response, 'Falha ao baixar DANFE'),
      statusCode: response.statusCode,
    );
  }

  Future<Uint8List> baixarXml(int nfceId) async {
    final url = ApiLinks.nfceXml(nfceId);
    final token = AuthUtility.userInfo?.token;
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'application/xml, text/xml',
      },
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw NfceException(
      _extractErrorMessage(response, 'Falha ao baixar XML autorizado'),
      statusCode: response.statusCode,
    );
  }

  Future<Uint8List> baixarQrCodePng(int nfceId, {int size = 200}) async {
    final url = ApiLinks.nfceQrCode(nfceId, size: size);
    final token = AuthUtility.userInfo?.token;
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Accept': 'image/png',
      },
    );
    if (response.statusCode == 200) {
      return response.bodyBytes;
    }
    throw NfceException(
      _extractErrorMessage(response, 'Falha ao baixar QR Code NFC-e'),
      statusCode: response.statusCode,
    );
  }

  Future<void> reenviarContingencia(int nfceId) async {
    final url = ApiLinks.reenviarContingenciaNfce(nfceId);
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({'empresaId': TenantContext.empresaId ?? 0}),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw NfceException(
        _extractErrorMessage(response, 'Falha ao reenviar NFC-e em contingência'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> enviarEmail(int nfceId, String destinatario) async {
    final url = ApiLinks.enviarEmailNfce(nfceId);
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({'destinatario': destinatario}),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw NfceException(
        _extractErrorMessage(response, 'Falha ao enviar email da NFC-e'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> cancelarNfce(
    int nfceId,
    String justificativa, {
    required int empresaId,
  }) async {
    final url = ApiLinks.cancelarNfce(nfceId);
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        'justificativa': justificativa,
        'empresaId': empresaId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw NfceException(
        _extractErrorMessage(response, 'Falha ao cancelar NFC-e'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<bool> verificarStatusSefaz(
    String uf, {
    String ambiente = 'HOMOLOGACAO',
  }) async {
    final result = await verificarSaudeSefaz(
      empresaId: TenantContext.empresaId ?? 0,
      uf: uf,
      ambiente: ambiente,
    );
    return result.disponivel;
  }

  Future<NfceSefazHealthResult> verificarSaudeSefaz({
    required int empresaId,
    required String uf,
    String ambiente = 'HOMOLOGACAO',
  }) async {
    if (empresaId <= 0) {
      return const NfceSefazHealthResult(
        disponivel: false,
        status: 'UNAVAILABLE',
        mensagem: 'Empresa não identificada para consultar a saúde da SEFAZ.',
        uf: '',
        ambiente: 'HOMOLOGACAO',
      );
    }

    final ufNormalizada = uf.trim().toUpperCase();
    final ambienteNormalizado =
        ambiente.trim().isEmpty ? 'HOMOLOGACAO' : ambiente.trim().toUpperCase();
    final url = ApiLinks.nfceHealth(
      empresaId,
      ufNormalizada,
      ambiente: ambienteNormalizado,
    );

    try {
      final response = await http
          .get(
            Uri.parse(TenantContext.applyToUrl(url)),
            headers: TenantContext.headers,
          )
          .timeout(const Duration(seconds: 15));

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final status = body['status']?.toString().toUpperCase() ??
          (response.statusCode == 200 ? 'UP' : 'DOWN');
      final mensagem = body['mensagem']?.toString() ??
          _extractErrorMessage(response, 'Falha ao consultar a saúde da SEFAZ');

      return NfceSefazHealthResult(
        disponivel: response.statusCode == 200 && status == 'UP',
        status: status,
        mensagem: mensagem,
        uf: body['uf']?.toString() ?? ufNormalizada,
        ambiente: body['ambiente']?.toString() ?? ambienteNormalizado,
      );
    } catch (e) {
      return NfceSefazHealthResult(
        disponivel: false,
        status: 'DOWN',
        mensagem: 'Não foi possível consultar a SEFAZ: $e',
        uf: ufNormalizada,
        ambiente: ambienteNormalizado,
      );
    }
  }

  Future<void> uploadCertificado({
    required List<int> fileBytes,
    required String fileName,
    required String senha,
    required int empresaId,
    int? parceiroId,
    required String uf,
    String ambiente = 'HOMOLOGACAO',
  }) async {
    final response = await TenantContext.postMultipart(
      ApiLinks.uploadCertificadoNfce(),
      fileBytes: fileBytes,
      fileName: fileName,
      fileField: 'pfx',
      fields: {
        'senha': senha,
        'empresaId': empresaId.toString(),
        if (parceiroId != null) 'parceiroId': parceiroId.toString(),
        'uf': uf.trim().toUpperCase(),
        'ambiente': ambiente.trim().isEmpty
            ? 'HOMOLOGACAO'
            : ambiente.trim().toUpperCase(),
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NfceException(
        'Falha ao enviar certificado (status ${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> buscarConfigFiscal(
    int empresaId, {
    int? parceiroId,
  }) async {
    final url = ApiLinks.configFiscal(empresaId, parceiroId: parceiroId);
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw NfceException(
      _extractErrorMessage(response, 'Falha ao buscar configuração fiscal'),
      statusCode: response.statusCode,
    );
  }

  Future<void> salvarConfigFiscal(Map<String, dynamic> config) async {
    final configId = config['id'] as int;
    final url = ApiLinks.updateConfigFiscal(configId);
    final response = await http.put(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode(config),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw NfceException(
        _extractErrorMessage(response, 'Falha ao salvar configuração fiscal'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> criarConfigFiscal(
    Map<String, dynamic> config,
  ) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.createConfigFiscal())),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode(config),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw NfceException(
      _extractErrorMessage(response, 'Falha ao criar configuração fiscal'),
      statusCode: response.statusCode,
    );
  }

  Future<List<Map<String, dynamic>>> buscarProdutos({
    required String query,
    required int empresaId,
    int tamanho = 20,
  }) async {
    // Bug de producao: GET /api/produto ignora os parametros nome/empresa
    // (ProdutoController.listarProdutos() nao os declara) e, pior, o
    // create/list desse recurso mapeia para a entidade CatalogoProduto
    // (dominio de negociacao agricola, campos nome/preco sempre null),
    // nao para a entidade Produto real usada pelo catalogo fiscal. O
    // endpoint correto, que filtra por nome/empresa e usa a entidade
    // Produto (nome, preco, ncm, gtin, codigo), e /api/produto_contabil.
    final url =
        '${ApiLinks.baseUrl}/api/produto_contabil?nome=${Uri.encodeComponent(query)}&empresa=$empresaId&tamanho=$tamanho';
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.headers,
    );
    if (response.statusCode == 200) {
      return extrairListaPaginada(jsonDecode(response.body))
          .cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> inutilizar({
    required int empresaId,
    required String uf,
    String ambiente = 'HOMOLOGACAO',
    required int serie,
    required int numeroInicio,
    required int numeroFim,
    required String justificativa,
  }) async {
    final url = ApiLinks.inutilizarNfce();
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        'empresaId': empresaId,
        'uf': uf.trim().toUpperCase(),
        'ambiente': ambiente.trim().isEmpty
            ? 'HOMOLOGACAO'
            : ambiente.trim().toUpperCase(),
        'serie': serie,
        'numeroInicial': numeroInicio,
        'numeroFinal': numeroFim,
        'justificativa': justificativa,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw NfceException(
        _extractErrorMessage(response, 'Falha ao inutilizar numeração NFC-e'),
        statusCode: response.statusCode,
      );
    }
  }

  Future<int> criarVenda(Map<String, dynamic> vendaJson) async {
    final url = '${ApiLinks.baseUrl}/api/v1/vendas';
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode(TenantContext.applyToBody(vendaJson)),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['id'] as int;
    }
    throw NfceException(
      _extractErrorMessage(response, 'Falha ao criar venda'),
      statusCode: response.statusCode,
    );
  }

  String _extractErrorMessage(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        for (final key in ['mensagem', 'message', 'error', 'motivoRejeicao']) {
          final value = body[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }
      }
    } catch (_) {
      // Mantém fallback quando o backend não retorna JSON.
    }
    return '$fallback (status ${response.statusCode})';
  }
}

class NfceSefazHealthResult {
  final bool disponivel;
  final String status;
  final String mensagem;
  final String uf;
  final String ambiente;

  const NfceSefazHealthResult({
    required this.disponivel,
    required this.status,
    required this.mensagem,
    required this.uf,
    required this.ambiente,
  });
}

class NfceException implements Exception {
  final String message;
  final int statusCode;

  const NfceException(this.message, {this.statusCode = -1});

  @override
  String toString() => 'NfceException($statusCode): $message';
}
