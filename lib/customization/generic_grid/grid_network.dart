// lib/data/customization/grid_network.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../models/auth_utility.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/tenant_helper.dart';

/// Estrutura de resposta simplificada
class NetworkResponse {
  final int statusCode;
  final dynamic body;
  final bool isSuccess;
  NetworkResponse(this.statusCode, this.body)
      : isSuccess = statusCode >= 200 && statusCode < 300;
}

/// ---------------------------------------------------------------------------
/// HEADERS PADRÃO (Bearer token + tenant)
/// ---------------------------------------------------------------------------

Future<Map<String, String>> _defaultHeaders({Map<String, String>? extra}) async {
  // Se a sessão ainda não foi reidratada em memória (ex.: logo após F5 no
  // Flutter Web, antes do bootstrap terminar), busca no local storage
  // (SharedPreferences — localStorage no Web) em vez de mandar sem token.
  String? token = AuthUtility.userInfo?.token;
  if (token == null) {
    final model = await AuthUtility.obterLogin();
    token = model?.token;
  }
  final tenantId = TenantHelper.isAdmin ? null : TenantContext.empresaId?.toString();
  return {
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    if (tenantId != null) 'X-Tenant-ID': tenantId,
    ...TenantHelper.tenantHeaders,
    ...?extra,
  };
}

/// ---------------------------------------------------------------------------
/// NORMALIZAÇÃO DE BODY — converte string IDs para objetos entidade
/// Spring/JPA espera {"empresa": {"id": 185}} mas o form envia {"empresa": "185"}.
/// ---------------------------------------------------------------------------
const _entityFields = [
  'empresa', 'parceiro', 'aplicativo', 'fornecedor', 'cliente',
  'contaBancaria', 'setor', 'centroCusto', 'formaPagamento',
];

Map<String, dynamic> _prepareBody(Map<String, dynamic> body) {
  // 1. injeta tenant se ausente
  final result = TenantContext.applyToBody(Map<String, dynamic>.from(body));
  // 2. converte campos de entidade de string/int para {"id": value}
  for (final field in _entityFields) {
    final value = result[field];
    if (value is String && value.isNotEmpty) {
      result[field] = {'id': int.tryParse(value) ?? value};
    } else if (value is num) {
      result[field] = {'id': value.toInt()};
    }
  }
  return result;
}

/// ---------------------------------------------------------------------------
/// REQUISIÇÕES BÁSICAS
/// ---------------------------------------------------------------------------

Future<NetworkResponse> getJson(String url,
    {Map<String, String>? headers}) async {
  final enrichedUrl = TenantHelper.applyToUrl(url) ?? url;
  L.d('[GET] $enrichedUrl');
  final resp = await http.get(
    Uri.parse(enrichedUrl),
    headers: await _defaultHeaders(extra: headers),
  );
  return _parseResponse(resp);
}

Future<NetworkResponse> postJson(String url, Map<String, dynamic> body,
    {Map<String, String>? headers}) async {
  final prepared = _prepareBody(body);
  L.d('[POST] $url | body=${jsonEncode(prepared)}');
  final resp = await http.post(
    Uri.parse(TenantContext.applyToUrl(url)),
    headers: await _defaultHeaders(extra: {'Content-Type': 'application/json', ...?headers}),
    body: jsonEncode(prepared),
  );
  return _parseResponse(resp);
}

Future<NetworkResponse> putJson(String url, Map<String, dynamic> body,
    {Map<String, String>? headers}) async {
  final prepared = _prepareBody(body);
  L.d('[PUT] $url | body=${jsonEncode(prepared)}');
  final resp = await http.put(
    Uri.parse(TenantContext.applyToUrl(url)),
    headers: await _defaultHeaders(extra: {'Content-Type': 'application/json', ...?headers}),
    body: jsonEncode(prepared),
  );
  return _parseResponse(resp);
}

Future<NetworkResponse> deleteJson(String url,
    {Map<String, String>? headers}) async {
  final enrichedUrl = TenantHelper.applyToUrl(url) ?? url;
  L.d('[DELETE] $enrichedUrl');
  final resp = await http.delete(
    Uri.parse(enrichedUrl),
    headers: await _defaultHeaders(extra: headers),
  );
  return _parseResponse(resp);
}

/// executa método arbitrário (para ações de servidor)
Future<NetworkResponse> runServerAction(String method, String url,
    {Map<String, dynamic>? payload}) async {
  final m = method.toUpperCase();
  switch (m) {
    case 'GET':
      return getJson(url);
    case 'POST':
      return postJson(url, payload ?? {});
    case 'PUT':
      return putJson(url, payload ?? {});
    case 'DELETE':
      return deleteJson(url);
    default:
      throw Exception('Método HTTP não suportado: $method');
  }
}

/// ---------------------------------------------------------------------------
/// MULTIPART UPLOAD
/// ---------------------------------------------------------------------------

class MultipartFieldFile {
  final String fieldName;
  final dynamic file; // PlatformFile
  MultipartFieldFile({required this.fieldName, required this.file});
}

Future<NetworkResponse> sendMultipart({
  required String endpoint,
  required bool isUpdate,
  required Map<String, String> fields,
  required List<MultipartFieldFile> files,
  String? baseUrlForMultipart,
  Future<Map<String, String>> Function()? authHeadersProvider,
}) async {
  try {
    final url = baseUrlForMultipart != null
        ? Uri.parse('$baseUrlForMultipart$endpoint')
        : Uri.parse(endpoint);
    final req = http.MultipartRequest(isUpdate ? 'PUT' : 'POST', url);
    req.fields.addAll(fields);
    // Sem authHeadersProvider explícito, usa os headers padrão (Bearer token +
    // X-Tenant-ID). Sem isso o upload multipart (ex.: salvar arquivo no GED)
    // ia sem Authorization e o backend respondia 401 "Nao autenticado".
    if (authHeadersProvider != null) {
      req.headers.addAll(await authHeadersProvider());
    } else {
      req.headers.addAll(await _defaultHeaders());
    }

    for (final f in files) {
      final file = f.file;
      if (file.bytes == null) continue;
      final stream = http.ByteStream.fromBytes(file.bytes!);
      final multipartFile = http.MultipartFile(
        f.fieldName,
        stream,
        file.bytes!.length,
        filename: file.name,
        contentType: _mimeFromName(file.name),
      );
      req.files.add(multipartFile);
    }

    final streamed = await req.send();
    final respStr = await streamed.stream.bytesToString();
    final parsedBody = _tryDecode(respStr);
    return NetworkResponse(streamed.statusCode, parsedBody);
  } catch (e, st) {
    L.e('[MULTIPART] error: $e', st);
    return NetworkResponse(500, {'error': e.toString()});
  }
}

/// ---------------------------------------------------------------------------
/// UTILS
/// ---------------------------------------------------------------------------

NetworkResponse _parseResponse(http.Response resp) {
  final parsed = _tryDecode(resp.body);
  return NetworkResponse(resp.statusCode, parsed);
}

dynamic _tryDecode(String body) {
  try {
    return jsonDecode(body);
  } catch (_) {
    return body;
  }
}

String respStatus(NetworkResponse resp) => resp.statusCode.toString();
dynamic respBody(NetworkResponse resp) => resp.body;
bool respSuccess(NetworkResponse resp) => resp.isSuccess;

MediaType _mimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
    return MediaType('image', 'jpeg');
  } else if (lower.endsWith('.png')) {
    return MediaType('image', 'png');
  } else if (lower.endsWith('.pdf')) {
    return MediaType('application', 'pdf');
  } else if (lower.endsWith('.doc')) {
    return MediaType('application', 'msword');
  } else if (lower.endsWith('.docx')) {
    return MediaType('application',
        'vnd.openxmlformats-officedocument.wordprocessingml.document');
  }
  return MediaType('application', 'octet-stream');
}
