import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../models/auth_utility.dart';
import '../../models/telas_model.dart';
import '../../utils/api_links.dart';
import '../../widgets/system_test_run_panel.dart';

// ENUMS and DATA CLASSES for Test Structure
enum _HttpMethod { get, post, put, delete }

enum _LogType { info, success, error, warning, section, divider, skip }

class _LogEntry {
  final String message;
  final _LogType type;
  _LogEntry(this.message, this.type);
}

class _TestStep {
  final _HttpMethod method;
  final String path; // e.g., "/", "/{id}", "/some-action"
  final int expectedStatus;
  final String? payloadKey; // Key to get payload from _getPayload

  _TestStep(this.method, this.path, this.expectedStatus, {this.payloadKey});
}

class _CrudScenario {
  final String name;
  final String basePath;
  final List<_TestStep> steps;
  /// Map of FK field name → endpoint to prefetch (e.g. 'empresa' → '/api/empresa')
  final Map<String, String> fkPrefetch;
  String? lastCreatedId;
  /// Resolved FK ids after prefetch (field name → id)
  final Map<String, int> resolvedFkIds = {};

  _CrudScenario({
    required this.name,
    required this.basePath,
    required this.steps,
    this.fkPrefetch = const {},
  });
}

class SystemTestScreen extends StatefulWidget {
  const SystemTestScreen({super.key});

  @override
  State<SystemTestScreen> createState() => _SystemTestScreenState();
}

class _SystemTestScreenState extends State<SystemTestScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D27),
        title: const Text('Testes de Integração', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GridColors.success,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.play_circle_outline, size: 16), text: 'Fluxo real'),
            Tab(icon: Icon(Icons.api, size: 16), text: 'Endpoints CRUD'),
            Tab(icon: Icon(Icons.table_chart, size: 16), text: 'Telas Dinâmicas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CrudTestTab(),
          _TelasTestTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 1 — CRUD manual (endpoints hardcoded)
// ─────────────────────────────────────────────────────────────
class _CrudTestTab extends StatefulWidget {
  const _CrudTestTab();
  @override
  State<_CrudTestTab> createState() => _CrudTestTabState();
}

class _CrudTestTabState extends State<_CrudTestTab> {
  final List<_LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isRunning = false;
  double _progress = 0.0;
  String _progressLabel = '';
  int _totalTests = 0;
  int _testsRun = 0;
  int _successCount = 0;
  int _failCount = 0;
  int _skipCount = 0;
  final StringBuffer _errorReport = StringBuffer();

  void _addLog(_LogEntry entry) {
    setState(() => _logs.add(entry));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _updateProgress(String label) {
    setState(() {
      if (_totalTests > 0) {
        _testsRun++;
        _progress = _testsRun / _totalTests;
        _progressLabel = label;
      }
    });
  }
  
  void _addToErrorReport({
    required String scenarioName,
    required String stepName,
    required int expectedStatus,
    required int actualStatus,
    String? payload,
    String? responseBody,
  }) {
    _errorReport.writeln('---');
    _errorReport.writeln('## Falha no Teste: $scenarioName');
    _errorReport.writeln('- **Endpoint:** `$stepName`');
    if (payload != null && payload.isNotEmpty) {
      _errorReport.writeln('- **Payload Enviado:**');
      _errorReport.writeln('```json\n$payload\n```');
    }
    _errorReport.writeln('- **Status Esperado:** `$expectedStatus`');
    _errorReport.writeln('- **Status Recebido:** `$actualStatus`');
    if (responseBody != null && responseBody.isNotEmpty) {
      final truncated = responseBody.length > 300 ? '${responseBody.substring(0, 300)}...(truncado)' : responseBody;
      _errorReport.writeln('- **Corpo da Resposta:**');
      _errorReport.writeln('```\n$truncated\n```');
    }
    _errorReport.writeln('---\n');
  }


  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
      _errorReport.clear();
      _progress = 0.0;
      _progressLabel = 'Iniciando...';
      _testsRun = 0;
      _successCount = 0;
      _failCount = 0;
      _skipCount = 0;
    });

    _addLog(_LogEntry('🔵 INICIANDO TESTES DE INTEGRAÇÃO (CRUD)...', _LogType.info));

    final token = AuthUtility.userInfo?.token;
    if (token == null) {
      _addLog(_LogEntry('❌ Token não encontrado. Faça login primeiro.', _LogType.error));
      setState(() => _isRunning = false);
      return;
    }
    _addLog(_LogEntry('🔑 Token obtido com sucesso.', _LogType.success));

    final headers = {
      'Content-Type': 'application/json;charset=UTF-8',
      'Authorization': 'Bearer $token',
    };

    final base = ApiLinks.baseUrl;
    final scenarios = _buildScenarios();
    _totalTests = scenarios.fold<int>(0, (prev, s) => prev + s.steps.length);

    for (final s in scenarios) {
      s.lastCreatedId = null; // Reset ID for each scenario
      s.resolvedFkIds.clear();
      _addLog(_LogEntry('', _LogType.divider));
      _addLog(_LogEntry('📋 ${s.name}', _LogType.section));

      // Prefetch FK ids if needed
      for (final entry in s.fkPrefetch.entries) {
        try {
          final fkRes = await http.get(Uri.parse(base + entry.value), headers: headers)
              .timeout(const Duration(seconds: 10));
          if (fkRes.statusCode == 200) {
            final data = jsonDecode(fkRes.body);
            int? fkId;
            // Try common response shapes: list, {data: list}, {content: list}
            if (data is List && data.isNotEmpty) {
              fkId = data.first['id'] as int?;
            } else if (data is Map) {
              final inner = data['data'] ?? data['content'] ?? data['items'];
              if (inner is List && inner.isNotEmpty) {
                fkId = inner.first['id'] as int?;
              }
            }
            if (fkId != null) {
              s.resolvedFkIds[entry.key] = fkId;
              _addLog(_LogEntry('  🔗 FK "${entry.key}" resolvida → id=$fkId', _LogType.info));
            } else {
              _addLog(_LogEntry('  ⚠️ FK "${entry.key}": não foi possível extrair ID de ${entry.value}', _LogType.warning));
            }
          }
        } catch (_) {
          _addLog(_LogEntry('  ⚠️ FK "${entry.key}": falha ao buscar ${entry.value}', _LogType.warning));
        }
      }

      for (final step in s.steps) {
        final stepName = '${step.method.name.toUpperCase()} ${s.basePath}${step.path}';
        _updateProgress(s.name);

        bool requiresId = step.path.contains('{id}');
        if (s.lastCreatedId == null && requiresId) {
          _addLog(_LogEntry('  ⚠️ SKIP $stepName → ID da entidade não foi criado na etapa anterior.', _LogType.skip));
          _skipCount++;
          continue;
        }

        String finalPath = (s.basePath + step.path).replaceAll('{id}', s.lastCreatedId ?? '');
        Uri url = Uri.parse(base + finalPath);
        http.Response res;
        String body = '';
        
        try {
          if (step.payloadKey != null) {
            final isUpdate = step.method == _HttpMethod.put;
            final payload = _getPayload(step.payloadKey!, isUpdate, s.lastCreatedId, s.resolvedFkIds);
            if (payload != null) {
              body = jsonEncode(payload);
            }
          }

          final _HttpMethod methodToRun = step.method;

          switch (methodToRun) {
            case _HttpMethod.post:
              res = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
              break;
            case _HttpMethod.put:
              res = await http.put(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
              break;
            case _HttpMethod.delete:
              res = await http.delete(url, headers: headers).timeout(const Duration(seconds: 15));
              break;
            default: // get
              res = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
          }

          if (res.statusCode == step.expectedStatus) {
            _addLog(_LogEntry('  ✅ $stepName → ${res.statusCode}', _LogType.success));
            _successCount++;
            
            if (step.method == _HttpMethod.post) {
               try {
                final data = jsonDecode(res.body);
                if (data is Map && data.containsKey('id')) {
                  s.lastCreatedId = data['id'].toString();
                  _addLog(_LogEntry('    → ID extraído: ${s.lastCreatedId}', _LogType.info));
                } else {
                   _addLog(_LogEntry('    ⚠️ Resposta de criação não continha um "id".', _LogType.warning));
                }
              } catch (e) {
                 _addLog(_LogEntry('    ⚠️ Não foi possível extrair o ID da resposta: ${res.body}', _LogType.warning));
              }
            }
          } else {
            _addLog(_LogEntry('  ❌ $stepName → Esperado ${step.expectedStatus}, Recebido ${res.statusCode}', _LogType.error));
             String responseBody = res.body;
             try {
               // Try to pretty-print if it's JSON
               responseBody = const JsonEncoder.withIndent('  ').convert(jsonDecode(res.body));
             } catch(e) {
                // Not a JSON, use as is
             }
             _addLog(_LogEntry('     Corpo: ${res.body}', _LogType.error));
             _addToErrorReport(
                scenarioName: s.name,
                stepName: stepName,
                expectedStatus: step.expectedStatus,
                actualStatus: res.statusCode,
                payload: body,
                responseBody: responseBody,
             );
            _failCount++;
          }
        } catch (e) {
          _addLog(_LogEntry('  ❌ $stepName → ERRO: $e', _LogType.error));
           _addToErrorReport(
              scenarioName: s.name,
              stepName: stepName,
              expectedStatus: step.expectedStatus,
              actualStatus: 0, // No status code from exception
              payload: body,
              responseBody: e.toString(),
           );
          _failCount++;
        }
      }
    }

    _addLog(_LogEntry('', _LogType.divider));
    _addLog(_LogEntry(
      '🏁 CONCLUÍDO — ✅ $_successCount sucesso  ❌ $_failCount falha  ⚠️ $_skipCount ignorado',
      _LogType.info,
    ));

    setState(() {
      _isRunning = false;
      _progressLabel = 'Concluído';
      _progress = 1.0;
    });
  }

  Map<String, dynamic>? _getPayload(String key, bool isUpdate, String? id, [Map<String, int> resolvedFkIds = const {}]) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    String suffix = isUpdate ? " (Atualizado)" : "";

    // Base payloads
    final Map<String, Map<String, dynamic>> payloads = {
      'noticias': {'titulo': 'Notícia de Teste $ts $suffix', 'noticia': 'Conteúdo da notícia de teste.', 'resumo': 'Resumo da notícia.', 'fonte': 'Fonte de Teste', 'autor': 'Tester', 'codApp': {'id': 1}},
      'comunicados': {'titulo': 'Comunicado $ts $suffix', 'conteudo': 'Conteúdo do comunicado.', 'autor': 'Tester', 'dataPublicacao': DateTime.now().toIso8601String(), 'empresa': {'id': 1}, 'aplicativo': {'id': 1}, 'setor': {'id': 1}},
      'chamados': {'titulo': 'Chamado de Teste $ts $suffix', 'descricao': 'Descrição detalhada do chamado.', 'audit': {'userLogadoId': 1}},
      'alimentos': {'nome': 'Alimento Teste $ts $suffix', 'calorias': 100, 'proteinas': 10.5, 'carboidratos': 20.2, 'gorduras': 5.0},
      'cargo': {'nome': 'Cargo Teste $ts $suffix', 'descricao': 'Desc'},
      'login': {'nome': 'Login Teste $ts', 'login': 'login$ts', 'senha': '123', 'email': 'teste$ts@email.com'},
      'departamento': {'nome': 'Departamento Teste $ts $suffix'},
      'centro_custo': {'nome': 'Centro Custo Teste $ts $suffix'},
      'exercicio': {'nome': 'Exercicio Teste $ts $suffix'},
      'modalidade': {'nome': 'Modalidade Teste $ts $suffix', 'codAcademia': {'id': resolvedFkIds['codAcademia'] ?? 1}},
      'objetivo': {'nome': 'Objetivo Teste $ts $suffix', 'codAluno': {'id': resolvedFkIds['codAluno'] ?? 1}},
      'parceiro': {'nome': 'Parceiro Teste $ts $suffix', 'tipo': 'J', 'cpfCnpj': '12345678000195'},
      'conta_bancaria': {'nomeBanco': 'Banco Teste $ts', 'agencia': '1234', 'conta': '56789-0', 'empresa': {'id': resolvedFkIds['empresa'] ?? 1}},
      'conta_pagar': {'descricao': 'Conta Pagar Teste $ts $suffix', 'valor': 100.50, 'dataVencimento': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'empresa': {'id': resolvedFkIds['empresa'] ?? 1}},
      'conta_receber': {'descricao': 'Conta Receber Teste $ts $suffix', 'valor': 250.75, 'dataVencimento': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'empresa': {'id': resolvedFkIds['empresa'] ?? 1}},
      'cotacao': {'ativo': 'TESTE3', 'valor': 5.25, 'dtCotacao': DateTime.now().toIso8601String()},
      'role': {'name': 'ROLE_TESTE_$ts', 'description': 'Role de teste', 'aplicativo': {'id': resolvedFkIds['aplicativo'] ?? 1}},
      'aplicativo': {'nome': 'Aplicativo Teste $ts $suffix'},
      'ponto': {'observacao': 'Ponto de teste $ts', 'login': {'id': resolvedFkIds['login'] ?? 1}},
      'default_nome': {'nome': 'Teste $ts $suffix'},
      'default_titulo': {'titulo': 'Teste $ts $suffix'},
      'default': {'name': 'Teste $ts $suffix', 'description': 'Descrição de teste.'},
    };
    
    var payload = Map<String, dynamic>.from(payloads[key] ?? payloads['default_nome']!);
    if (isUpdate && id != null) {
      try {
        payload['id'] = int.parse(id);
      } catch (e) {
        payload['id'] = id;
      }
    }
    return payload;
  }
  
  List<_CrudScenario> _buildScenarios() {
    // Helper to create a standard RESTful CRUD test sequence
    _CrudScenario createStandardCrud(String name, String path, String payloadKey, {int createStatus = 201, int delStatus = 204}) {
        return _CrudScenario(
            name: name,
            basePath: path,
            steps: [
                _TestStep(_HttpMethod.get, '', 200),
                _TestStep(_HttpMethod.post, '', createStatus, payloadKey: payloadKey),
                _TestStep(_HttpMethod.get, '/{id}', 200),
                _TestStep(_HttpMethod.put, '/{id}', 200, payloadKey: payloadKey),
                _TestStep(_HttpMethod.delete, '/{id}', delStatus),
                _TestStep(_HttpMethod.get, '/{id}', 404),
            ],
        );
    }
    
    // Helper for endpoints that only have GET list
    _CrudScenario createGetList(String name, String path) {
        return _CrudScenario(name: name, basePath: path, steps: [_TestStep(_HttpMethod.get, '', 200)]);
    }

    // Normalized paths from controller scan
    return [
      // ================= Standard RESTful CRUD =================
      // Login: sem DELETE HTTP
      _CrudScenario(
        name: 'Login', basePath: '/api/login',
        steps: [
          _TestStep(_HttpMethod.get, '', 200),
          _TestStep(_HttpMethod.post, '', 200, payloadKey: 'login'),
          _TestStep(_HttpMethod.get, '/{id}', 200),
          _TestStep(_HttpMethod.put, '/{id}', 200, payloadKey: 'login'),
        ]),
      createStandardCrud('Noticias', '/api/noticias', 'noticias', createStatus: 200, delStatus: 200),
      createStandardCrud('Comunicados', '/api/comunicado', 'comunicados', createStatus: 200, delStatus: 200),
      createStandardCrud('Chamados', '/api/chamados', 'chamados', createStatus: 201, delStatus: 200),
      createStandardCrud('Alimentos', '/api/alimentos', 'alimentos', createStatus: 201, delStatus: 200),
      _CrudScenario(
        name: 'Conta a Pagar', basePath: '/api/conta_pagar',
        fkPrefetch: {'empresa': '/api/empresa'},
        steps: [
          _TestStep(_HttpMethod.get, '', 200),
          _TestStep(_HttpMethod.post, '', 200, payloadKey: 'conta_pagar'),
          _TestStep(_HttpMethod.get, '/{id}', 200),
          _TestStep(_HttpMethod.put, '/{id}', 200, payloadKey: 'conta_pagar'),
          _TestStep(_HttpMethod.delete, '/{id}', 200),
          _TestStep(_HttpMethod.get, '/{id}', 404),
        ],
      ),
      _CrudScenario(
        name: 'Conta a Receber', basePath: '/api/conta_receber',
        fkPrefetch: {'empresa': '/api/empresa'},
        steps: [
          _TestStep(_HttpMethod.get, '', 200),
          _TestStep(_HttpMethod.post, '', 200, payloadKey: 'conta_receber'),
          _TestStep(_HttpMethod.get, '/{id}', 200),
          _TestStep(_HttpMethod.put, '/{id}', 200, payloadKey: 'conta_receber'),
          _TestStep(_HttpMethod.delete, '/{id}', 200),
          _TestStep(_HttpMethod.get, '/{id}', 404),
        ],
      ),
      createStandardCrud('Cotações', '/api/cotacoes', 'cotacao', createStatus: 200, delStatus: 200),
      _CrudScenario(
        name: 'Roles', basePath: '/api/role',
        fkPrefetch: {'aplicativo': '/api/aplicativo'},
        steps: [
          _TestStep(_HttpMethod.get, '', 200),
          _TestStep(_HttpMethod.post, '', 201, payloadKey: 'role'),
          _TestStep(_HttpMethod.get, '/{id}', 200),
          _TestStep(_HttpMethod.put, '/{id}', 200, payloadKey: 'role'),
          _TestStep(_HttpMethod.delete, '/{id}', 200),
          _TestStep(_HttpMethod.get, '/{id}', 404),
        ],
      ),
      _CrudScenario(
        name: 'Contas Bancárias', basePath: '/api/contas-bancaria',
        fkPrefetch: {'empresa': '/api/empresa'},
        steps: [
          _TestStep(_HttpMethod.get, '', 200),
          _TestStep(_HttpMethod.post, '', 200, payloadKey: 'conta_bancaria'),
          _TestStep(_HttpMethod.get, '/{id}', 200),
          _TestStep(_HttpMethod.put, '/{id}', 200, payloadKey: 'conta_bancaria'),
          _TestStep(_HttpMethod.delete, '/{id}', 200),
          _TestStep(_HttpMethod.get, '/{id}', 404),
        ],
      ),
      createStandardCrud('Aplicativos', '/api/aplicativo', 'aplicativo', createStatus: 200, delStatus: 200),

      // ================= Custom/Partial CRUD Endpoints =================
      _CrudScenario(
        name: 'Parceiros', basePath: '/api/parceiro',
        steps: [
          _TestStep(_HttpMethod.get, '', 200),
          _TestStep(_HttpMethod.post, '/insert', 200, payloadKey: 'parceiro'),
          _TestStep(_HttpMethod.post, '/update', 200, payloadKey: 'parceiro'),
        ]),

      // ================= GET-only Endpoints =================
      createGetList('Alertas', '/api/alert'),
      createGetList('Cargos', '/api/cargo'),
      createGetList('Centro de Custo', '/api/centro-custo'),
      createGetList('Classificações', '/api/classificacoes'),
      createGetList('Departamentos', '/api/departamento'),
      createGetList('Endereços', '/api/endereco'),
      createGetList('Exercícios', '/api/exercicios'),
      createGetList('Feriados', '/api/feriado'),
      createGetList('Formas de Pagamento', '/api/forma_pagamento'),
      createGetList('Grupos Musculares', '/api/grupos-musculares'),
      createGetList('Horário Funcionário', '/api/horarioFunc'),
      createGetList('Obrigações Fiscais', '/api/obrigacao_fiscal'),
      createGetList('Países', '/api/pais'),
      createGetList('Pedidos', '/api/pedidos'),
      createGetList('Produtos', '/api/produtos'),
      createGetList('Regime Tributário', '/api/regime_tributario'),
      createGetList('Setores', '/api/setor'),
      createGetList('Tickets', '/api/ticket'),
      createGetList('Tipos de Produto', '/api/tipoProdutos'),
      createGetList('Mensalidades', '/api/mensalidades'),

      // ================= Dashboard (requer empresaId=1) =================
      createGetList('Dashboard - Finance Series', '/api/dashboard/finance/series?empresaId=1'),
      createGetList('Dashboard - Chat Daily', '/api/dashboard/chats/dailys?empresaId=1'),
      createGetList('Dashboard - Tickets Trend', '/api/dashboard/tickets/trend?empresaId=1'),
      createGetList('Dashboard - Finance Fluxo', '/api/dashboard/finance/fluxo-diario?empresaId=1'),

      // ================= Other =================
      _CrudScenario(
        name: 'Empresa (Leitura)', basePath: '/api/empresa',
        steps: [ _TestStep(_HttpMethod.get, '', 200), _TestStep(_HttpMethod.get, '/1', 200) ],
      ),
      _CrudScenario(
        name: 'Registrar Ponto', basePath: '/api/pontos',
        steps: [ _TestStep(_HttpMethod.post, '/registrar', 200, payloadKey: 'ponto') ],
      ),
    ];
  }


  // ── Teste dinâmico de todos os endpoints ──────────────────────

  Future<void> _fetchAndRunAllTests() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
      _errorReport.clear();
      _progress = 0.0;
      _progressLabel = 'Carregando endpoints...';
      _testsRun = 0;
      _successCount = 0;
      _failCount = 0;
      _skipCount = 0;
    });

    _addLog(_LogEntry('🔵 CARREGANDO TODOS OS ENDPOINTS DO SISTEMA...', _LogType.info));

    final token = AuthUtility.userInfo?.token;
    if (token == null) {
      _addLog(_LogEntry('❌ Token não encontrado.', _LogType.error));
      setState(() => _isRunning = false);
      return;
    }

    final headers = {
      'Content-Type': 'application/json;charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
    final base = ApiLinks.baseUrl;

    List<dynamic> endpoints;
    try {
      final res = await http
          .get(Uri.parse('$base/api/admin/endpoints'), headers: headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        _addLog(_LogEntry('❌ Falha ao carregar endpoints (${res.statusCode})', _LogType.error));
        setState(() => _isRunning = false);
        return;
      }
      final body = jsonDecode(res.body);
      final data = body['data'] as Map? ?? body;
      endpoints = data['endpoints'] as List? ?? [];
    } catch (e) {
      _addLog(_LogEntry('❌ Erro ao carregar endpoints: $e', _LogType.error));
      setState(() => _isRunning = false);
      return;
    }

    _addLog(_LogEntry('📦 ${endpoints.length} endpoints carregados.', _LogType.success));

    // Agrupa por controller
    final Map<String, List<Map<String, dynamic>>> byController = {};
    for (final ep in endpoints) {
      final ctrl = ep['controller']?.toString() ?? 'Desconhecido';
      byController.putIfAbsent(ctrl, () => []).add(Map<String, dynamic>.from(ep));
    }

    _addLog(_LogEntry('📋 ${byController.length} controllers encontrados.', _LogType.info));
    _totalTests = byController.entries.fold<int>(0, (sum, e) => sum + e.value.length);

    for (final entry in byController.entries) {
      final ctrlName = entry.key;
      final eps = entry.value;

      _addLog(_LogEntry('', _LogType.divider));
      _addLog(_LogEntry('📁 $ctrlName (${eps.length} endpoints)', _LogType.section));

      for (final ep in eps) {
        final paths = (ep['paths'] as List?)?.map((p) => p.toString()).toList() ?? [];
        final httpMethods = (ep['httpMethods'] as List?)?.map((m) => m.toString()).toList() ?? ['GET'];
        final methodName = ep['metodo']?.toString() ?? '?';

        for (final path in paths) {
          for (final httpMethod in httpMethods) {
            final stepName = '$httpMethod $path ($methodName)';
            _updateProgress('$ctrlName → $stepName');

            final uri = Uri.parse('$base$path');
            http.Response res;

            try {
              switch (httpMethod) {
                case 'POST':
                  final payload = _buildDynamicPayload(path, ctrlName);
                  res = await http.post(uri, headers: headers, body: jsonEncode(payload))
                      .timeout(const Duration(seconds: 15));
                  break;
                case 'PUT':
                  res = await http.put(uri, headers: headers)
                      .timeout(const Duration(seconds: 15));
                  break;
                case 'DELETE':
                  res = await http.delete(uri, headers: headers)
                      .timeout(const Duration(seconds: 15));
                  break;
                default:
                  res = await http.get(uri, headers: headers)
                      .timeout(const Duration(seconds: 15));
              }

              if (res.statusCode >= 200 && res.statusCode < 300) {
                _addLog(_LogEntry('  ✅ $stepName → ${res.statusCode}', _LogType.success));
                _successCount++;
              } else {
                _addLog(_LogEntry('  ❌ $stepName → ${res.statusCode}', _LogType.error));
                _addToErrorReport(
                  scenarioName: ctrlName,
                  stepName: stepName,
                  expectedStatus: 200,
                  actualStatus: res.statusCode,
                  responseBody: res.body.length > 300 ? '${res.body.substring(0, 300)}...' : res.body,
                );
                _failCount++;
              }
            } catch (e) {
              _addLog(_LogEntry('  ❌ $stepName → ERRO: $e', _LogType.error));
              _failCount++;
            }
          }
        }
      }
    }

    _addLog(_LogEntry('', _LogType.divider));
    _addLog(_LogEntry(
      '🏁 CONCLUÍDO — ✅ $_successCount sucesso  ❌ $_failCount falha  ⚠️ $_skipCount ignorado',
      _LogType.info,
    ));

    setState(() {
      _isRunning = false;
      _progressLabel = 'Concluído';
      _progress = 1.0;
    });
  }

  Map<String, dynamic> _buildDynamicPayload(String path, String controllerName) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final ctrl = controllerName.replaceAll('Controller', '').toLowerCase();
    final nomeEntity = ctrl.endsWith('s') ? ctrl : '${ctrl}teste$ts';

    // Tenta inferir o nome do campo principal baseado no controller
    final Map<String, String> fieldMap = {
      'login': 'login',
      'noticia': 'titulo',
      'comunicado': 'titulo',
      'chamado': 'titulo',
      'alimento': 'nome',
      'cargo': 'nome',
      'departamento': 'nome',
      'centro_custo': 'nome',
      'exercicio': 'nome',
      'modalidade': 'nome',
      'objetivo': 'nome',
      'parceiro': 'nome',
      'produto': 'nome',
      'categoria': 'nome',
      'role': 'name',
    };
    final campoNome = fieldMap.entries.firstWhere(
      (e) => ctrl.contains(e.key),
      orElse: () => const MapEntry('nome', 'nome'),
    ).value;

    return {
      campoNome: '$nomeEntity $ts',
      'descricao': 'Criado por teste automático $ts',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // action buttons row
        if (_errorReport.isNotEmpty || (!_isRunning && _logs.isNotEmpty))
          Container(
            color: const Color(0xFF1A1D27),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_errorReport.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.error_outline, color: Colors.amber),
                    tooltip: 'Ver Relatório de Erros',
                    onPressed: () => _showErrorDialog(context),
                  ),
                if (!_isRunning && _logs.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white54),
                    tooltip: 'Limpar logs',
                    onPressed: () => setState(() {
                      _logs.clear();
                      _errorReport.clear();
                      _progress = 0;
                      _progressLabel = '';
                      _testsRun = 0;
                      _successCount = 0;
                      _failCount = 0;
                      _skipCount = 0;
                    }),
                  ),
              ],
            ),
          ),
        _buildHeader(context),
        if (_isRunning || _progress > 0) _buildProgressBar(),
        if (_logs.isNotEmpty) _buildSummaryBar(),
        Expanded(child: _buildLogList()),
      ],
    );
  }
  
  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool copied = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF1A1D27),
            title: const Text('Relatório de Falhas', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 600,
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _errorReport.toString(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                icon: Icon(
                  copied ? Icons.check : Icons.copy,
                  size: 16,
                  color: copied ? GridColors.success : Colors.white70,
                ),
                label: Text(
                  copied ? 'Copiado!' : 'Copiar tudo',
                  style: TextStyle(
                    color: copied ? GridColors.success : Colors.white70,
                  ),
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _errorReport.toString()));
                  setDialogState(() => copied = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (ctx.mounted) setDialogState(() => copied = false);
                  });
                },
              ),
              TextButton(
                child: const Text('Fechar'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scenarios = _buildScenarios();
    final totalEndpoints = scenarios.length;
    final totalTests = scenarios.fold<int>(0, (prev, s) => prev + s.steps.length);

    return Container(
      color: const Color(0xFF1A1D27),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          const SystemTestRunPanel(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verificação de saúde da API (CRUD)',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalTests testes em $totalEndpoints cenários.',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _runTests,
                icon: _isRunning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow, size: 18),
                label: Text(_isRunning ? 'Executando...' : 'Iniciar Testes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRunning ? Colors.grey[700] : GridColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _fetchAndRunAllTests,
                icon: const Icon(Icons.playlist_add_check, size: 18),
                label: const Text('Testar Todos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      color: const Color(0xFF1A1D27),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                _progress >= 1.0 ? GridColors.success : const Color(0xFF2196F3),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _progressLabel,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(_progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      color: const Color(0xFF13151F),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _chip('✅ $_successCount', GridColors.success),
              const SizedBox(width: 8),
              _chip('❌ $_failCount', const Color(0xFFF44336)),
              const SizedBox(width: 8),
              _chip('⚠️ $_skipCount', const Color(0xFFFF9800)),
            ],
          ),
          Text(
            '$_testsRun / $_totalTests',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildLogList() {
    if (_logs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.terminal, size: 48, color: Colors.white12),
            SizedBox(height: 12),
            Text('Pressione "Iniciar Testes" para começar', style: TextStyle(color: Colors.white24)),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFF0F1117),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _logs.length,
        itemBuilder: (context, i) {
          final log = _logs[i];
          if (log.type == _LogType.divider) {
            return const Divider(color: Colors.white12, height: 16);
          }
          if (log.type == _LogType.section) {
            return Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Text(
                log.message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: SelectableText(
              log.message,
              style: TextStyle(
                color: _colorFor(log.type),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          );
        },
      ),
    );
  }

  Color _colorFor(_LogType type) {
    switch (type) {
      case _LogType.success:
        return const Color(0xFF66BB6A);
      case _LogType.error:
        return const Color(0xFFEF5350);
      case _LogType.warning:
        return const Color(0xFFFFB74D);
      case _LogType.info:
        return const Color(0xFF42A5F5);
       case _LogType.skip:
        return Colors.white54;
      default:
        return Colors.white54;
    }
  }
}

// ─────────────────────────────────────────────────────────────
// TAB 2 — Telas dinâmicas (fetch all telas → testa cada uma)
// ─────────────────────────────────────────────────────────────
class _TelasTestTab extends StatefulWidget {
  const _TelasTestTab();
  @override
  State<_TelasTestTab> createState() => _TelasTestTabState();
}

class _TelasTestTabState extends State<_TelasTestTab> {
  final List<_LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  final StringBuffer _errorReport = StringBuffer();
  bool _isRunning = false;
  double _progress = 0.0;
  int _successCount = 0;
  int _failCount = 0;
  int _skipCount = 0;
  int _testsRun = 0;
  int _totalTests = 0;

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool copied = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF1A1D27),
            title: const Text('Relatório de Falhas — Telas', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: 620,
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _errorReport.toString(),
                    style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                icon: Icon(copied ? Icons.check : Icons.copy, size: 16,
                    color: copied ? GridColors.success : Colors.white70),
                label: Text(copied ? 'Copiado!' : 'Copiar tudo',
                    style: TextStyle(color: copied ? GridColors.success : Colors.white70)),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: _errorReport.toString()));
                  setDialogState(() => copied = true);
                  Future.delayed(const Duration(seconds: 2), () {
                    if (ctx.mounted) setDialogState(() => copied = false);
                  });
                },
              ),
              TextButton(
                child: const Text('Fechar'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _log(String msg, _LogType type) {
    setState(() => _logs.add(_LogEntry(msg, type)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _reportError({
    required String tela,
    required String step,
    required int expected,
    required int actual,
    String? payload,
    String? body,
  }) {
    _errorReport.writeln('---');
    _errorReport.writeln('## Tela: $tela | $step');
    if (payload != null && payload.isNotEmpty) {
      _errorReport.writeln('- **Payload:** ```json\n$payload\n```');
    }
    _errorReport.writeln('- **Esperado:** $expected | **Recebido:** $actual');
    if (body != null && body.isNotEmpty) {
      final truncated = body.length > 300 ? '${body.substring(0, 300)}...(truncado)' : body;
      _errorReport.writeln('- **Resposta:** ```\n$truncated\n```');
    }
    _errorReport.writeln('---\n');
  }

  Future<void> _runTelaTests() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
      _errorReport.clear();
      _progress = 0;
      _successCount = 0;
      _failCount = 0;
      _skipCount = 0;
      _testsRun = 0;
      _totalTests = 0;
    });

    final token = AuthUtility.userInfo?.token;
    if (token == null) {
      _log('❌ Token não encontrado. Faça login primeiro.', _LogType.error);
      setState(() => _isRunning = false);
      return;
    }

    final headers = {
      'Content-Type': 'application/json;charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
    final base = ApiLinks.baseUrl;

    // 1. Busca todas as telas via endpoint individual (evita lazy-load 500)
    // Primeiro busca a lista paginada para obter os nomes, depois carrega cada tela
    _log('🔍 Buscando lista de telas em $base/api/telas...', _LogType.info);
    List<TelaConfig> telas = [];
    try {
      final res = await http
          .get(Uri.parse('$base/api/telas?tamanho=500&pagina=0'), headers: headers)
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        _log('❌ Falha ao buscar telas: ${res.statusCode} — ${res.body}', _LogType.error);
        _reportError(tela: 'GET /api/telas', step: 'Listar telas', expected: 200, actual: res.statusCode, body: res.body);
        setState(() => _isRunning = false);
        return;
      }

      // Estrutura: { data: { dados: [...], totalElements: N }, response: {...} }
      final decoded = jsonDecode(res.body);
      List<dynamic> rawList = [];
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map) {
        final inner = decoded['data'] ?? decoded;
        if (inner is List) {
          rawList = inner;
        } else if (inner is Map) {
          // ComunicadosResponseDTO usa "dados"
          final content = inner['dados'] ?? inner['content'] ?? inner['data'];
          if (content is List) rawList = content;
        }
      }

      // Carrega cada tela individualmente pelo nome (endpoint /{nome} retorna objeto completo sem lazy issues)
      final nomes = rawList
          .whereType<Map>()
          .map((e) => e['nome']?.toString())
          .whereType<String>()
          .toList();

      _log('📦 ${nomes.length} telas na lista. Carregando detalhes...', _LogType.info);

      for (final nome in nomes) {
        try {
          final telaRes = await http
              .get(Uri.parse('$base/api/telas/$nome'), headers: headers)
              .timeout(const Duration(seconds: 10));
          if (telaRes.statusCode == 200) {
            final telaJson = jsonDecode(telaRes.body);
            if (telaJson is Map) {
              telas.add(TelaConfig.fromJson(Map<String, dynamic>.from(telaJson)));
            }
          } else {
            _log('  ⚠️ Tela "$nome" retornou ${telaRes.statusCode}', _LogType.warning);
          }
        } catch (e) {
          _log('  ⚠️ Erro ao carregar tela "$nome": $e', _LogType.warning);
        }
      }

      _log('✅ ${telas.length} telas carregadas com sucesso.', _LogType.success);
    } catch (e) {
      _log('❌ Erro ao buscar telas: $e', _LogType.error);
      _reportError(tela: 'GET /api/telas', step: 'Listar telas', expected: 200, actual: 0, body: e.toString());
      setState(() => _isRunning = false);
      return;
    }

    if (telas.isEmpty) {
      _log('⚠️ Nenhuma tela retornada.', _LogType.warning);
      setState(() => _isRunning = false);
      return;
    }

    // cada tela tem até 4 steps: fetch, create, update, delete
    _totalTests = telas.length * 4;
    setState(() {});

    for (final tela in telas) {
      _log('', _LogType.divider);
      _log('📋 ${tela.titulo} (${tela.nome})', _LogType.section);

      String? createdId;

      // ── STEP 1: FETCH ──────────────────────────────────────
      await _testStep(
        label: 'GET ${tela.fetchEndpoint}',
        run: () => http
            .get(Uri.parse(base + tela.fetchEndpoint), headers: headers)
            .timeout(const Duration(seconds: 15)),
        expectedStatus: 200,
        telaName: tela.titulo,
        onSuccess: (_) {},
        onFail: (s, b) => _reportError(
          tela: tela.titulo,
          step: 'GET ${tela.fetchEndpoint}',
          expected: 200,
          actual: s,
          body: b,
        ),
      );

      // ── STEP 2: CREATE ─────────────────────────────────────
      final payload = await _buildPayload(tela, base, headers);
      final payloadJson = jsonEncode(payload);
      await _testStep(
        label: 'POST ${tela.createEndpoint}',
        run: () => http
            .post(Uri.parse(base + tela.createEndpoint),
                headers: headers, body: payloadJson)
            .timeout(const Duration(seconds: 15)),
        expectedStatus: null, // aceita 200 ou 201
        telaName: tela.titulo,
        onSuccess: (res) {
          try {
            final data = jsonDecode(res.body);
            final id = data is Map ? (data['id'] ?? data['data']?['id']) : null;
            if (id != null) {
              createdId = id.toString();
              _log('    → ID criado: $createdId', _LogType.info);
            } else {
              _log('    ⚠️ Resposta sem "id" — update/delete serão pulados.', _LogType.warning);
            }
          } catch (_) {}
        },
        onFail: (s, b) => _reportError(
          tela: tela.titulo,
          step: 'POST ${tela.createEndpoint}',
          expected: 200,
          actual: s,
          payload: payloadJson,
          body: b,
        ),
      );

      // ── STEP 3: UPDATE ─────────────────────────────────────
      if (createdId == null) {
        _log('  ⚠️ SKIP PUT — ID não disponível.', _LogType.skip);
        _skipCount++;
        _testsRun++;
        setState(() => _progress = _testsRun / _totalTests);
      } else {
        final updateEndpoint = tela.updateEndpoint.replaceAll(':id', createdId!);
        final updatePayload = {...payload, 'id': int.tryParse(createdId!) ?? createdId};
        final updateJson = jsonEncode(updatePayload);
        await _testStep(
          label: 'PUT $updateEndpoint',
          run: () => http
              .put(Uri.parse(base + updateEndpoint),
                  headers: headers, body: updateJson)
              .timeout(const Duration(seconds: 15)),
          expectedStatus: 200,
          telaName: tela.titulo,
          onSuccess: (_) {},
          onFail: (s, b) => _reportError(
            tela: tela.titulo,
            step: 'PUT $updateEndpoint',
            expected: 200,
            actual: s,
            payload: updateJson,
            body: b,
          ),
        );
      }

      // ── STEP 4: DELETE ─────────────────────────────────────
      if (createdId == null) {
        _log('  ⚠️ SKIP DELETE — ID não disponível.', _LogType.skip);
        _skipCount++;
        _testsRun++;
        setState(() => _progress = _testsRun / _totalTests);
      } else {
        final deleteEndpoint = tela.deleteEndpoint.replaceAll(':id', createdId!);
        await _testStep(
          label: 'DELETE $deleteEndpoint',
          run: () => http
              .delete(Uri.parse(base + deleteEndpoint), headers: headers)
              .timeout(const Duration(seconds: 15)),
          expectedStatus: null, // aceita 200 ou 204
          telaName: tela.titulo,
          onSuccess: (_) {},
          onFail: (s, b) => _reportError(
            tela: tela.titulo,
            step: 'DELETE $deleteEndpoint',
            expected: 200,
            actual: s,
            body: b,
          ),
        );
      }
    }

    _log('', _LogType.divider);
    _log(
      '🏁 CONCLUÍDO — ✅ $_successCount  ❌ $_failCount  ⚠️ $_skipCount',
      _LogType.info,
    );
    setState(() {
      _isRunning = false;
      _progress = 1.0;
    });
  }

  Future<void> _testStep({
    required String label,
    required Future<http.Response> Function() run,
    required int? expectedStatus, // null = aceita 200 ou 201 ou 204
    required String telaName,
    required void Function(http.Response) onSuccess,
    required void Function(int, String) onFail,
  }) async {
    _testsRun++;
    setState(() => _progress = _testsRun / _totalTests);
    try {
      final res = await run();
      final ok = expectedStatus != null
          ? res.statusCode == expectedStatus
          : (res.statusCode >= 200 && res.statusCode < 300);
      if (ok) {
        _log('  ✅ $label → ${res.statusCode}', _LogType.success);
        _successCount++;
        onSuccess(res);
      } else {
        _log('  ❌ $label → ${res.statusCode}', _LogType.error);
        _failCount++;
        onFail(res.statusCode, res.body);
      }
    } catch (e) {
      _log('  ❌ $label → ERRO: $e', _LogType.error);
      _failCount++;
      onFail(0, e.toString());
    }
  }

  /// Cache de ids reais resolvidos por endpoint de dropdown (evita GETs repetidos).
  final Map<String, int?> _fkIdCache = {};

  /// Resolve um id REAL existente consultando o endpoint do dropdown/FK,
  /// em vez de cravar id=1 (que pode não existir no banco).
  Future<int?> _resolveFkId(
      String endpoint, String base, Map<String, String> headers) async {
    if (_fkIdCache.containsKey(endpoint)) return _fkIdCache[endpoint];
    int? id;
    try {
      final url = endpoint.startsWith('http') ? endpoint : base + endpoint;
      final res = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List? lista;
        if (data is List) {
          lista = data;
        } else if (data is Map) {
          final inner = data['data'] ?? data['content'] ?? data['items'];
          if (inner is List) {
            lista = inner;
          } else if (inner is Map) {
            lista = (inner['dados'] ?? inner['content'] ?? inner['items']) as List?;
          }
        }
        if (lista != null && lista.isNotEmpty) {
          final first = lista.first;
          if (first is Map && first['id'] is int) id = first['id'] as int;
        }
      }
    } catch (_) {}
    _fkIdCache[endpoint] = id;
    return id;
  }

  /// Gera um payload mínimo baseado nos campos da tela.
  /// Para dropdowns/FKs, resolve um id REAL existente (não crava id=1).
  Future<Map<String, dynamic>> _buildPayload(
      TelaConfig tela, String base, Map<String, String> headers) async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final Map<String, dynamic> payload = {};

    for (final f in tela.fields) {
      if (!f.showInInsert) continue;
      final fn = f.fieldName;
      if (fn == 'id' || fn == 'dh_created_at' || fn == 'dh_updated_at') continue;

      switch (f.fieldType) {
        case TelaFieldType.number:
        case TelaFieldType.currency:
        case TelaFieldType.percentage:
          payload[fn] = 1;
          break;
        case TelaFieldType.boolean:
          payload[fn] = true;
          break;
        case TelaFieldType.date:
          payload[fn] = DateTime.now().toIso8601String();
          break;
        case TelaFieldType.dropdown:
          // resolve um id REAL do endpoint do dropdown; fallback id=1
          int fkId = 1;
          final ep = f.dropdownEndpoint;
          if (ep != null && ep.isNotEmpty) {
            final real = await _resolveFkId(ep, base, headers);
            if (real != null) fkId = real;
          }
          payload[fn] = {'id': fkId};
          break;
        case TelaFieldType.email:
          payload[fn] = 'teste$ts@teste.com';
          break;
        case TelaFieldType.phone:
          payload[fn] = '11999999999';
          break;
        case TelaFieldType.cpf:
          payload[fn] = '00000000000';
          break;
        case TelaFieldType.cnpj:
          payload[fn] = '00000000000000';
          break;
        case TelaFieldType.password:
          payload[fn] = 'Teste@123';
          break;
        case TelaFieldType.multiline:
        case TelaFieldType.text:
        default:
          payload[fn] = 'Teste $ts';
          break;
      }
    }
    return payload;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // header
        Container(
          color: const Color(0xFF1A1D27),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Testa fetch/create/update/delete de cada tela cadastrada.',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    SizedBox(height: 2),
                    Text('Os endpoints e campos vêm direto do backend.',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
              if (_errorReport.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.error_outline, color: Colors.amber),
                  tooltip: 'Ver Relatório de Erros',
                  onPressed: () => _showErrorDialog(context),
                ),
              if (!_isRunning && _logs.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white54),
                  tooltip: 'Limpar',
                  onPressed: () => setState(() {
                    _logs.clear();
                    _errorReport.clear();
                    _progress = 0;
                    _successCount = 0;
                    _failCount = 0;
                    _skipCount = 0;
                    _testsRun = 0;
                  }),
                ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _runTelaTests,
                icon: _isRunning
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.play_arrow, size: 18),
                label: Text(_isRunning ? 'Executando...' : 'Testar Telas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isRunning ? Colors.grey[700] : const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        // progress
        if (_isRunning || _progress > 0)
          Container(
            color: const Color(0xFF1A1D27),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _progress >= 1.0
                          ? GridColors.success
                          : const Color(0xFF2196F3),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      _statChip('✅ $_successCount', GridColors.success),
                      const SizedBox(width: 6),
                      _statChip('❌ $_failCount', const Color(0xFFF44336)),
                      const SizedBox(width: 6),
                      _statChip('⚠️ $_skipCount', const Color(0xFFFF9800)),
                    ]),
                    Text('$_testsRun / $_totalTests',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        // log list
        Expanded(
          child: _logs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.table_chart, size: 48, color: Colors.white12),
                      SizedBox(height: 12),
                      Text('Pressione "Testar Telas" para começar',
                          style: TextStyle(color: Colors.white24)),
                    ],
                  ),
                )
              : Container(
                  color: const Color(0xFF0F1117),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: _logs.length,
                    itemBuilder: (context, i) {
                      final log = _logs[i];
                      if (log.type == _LogType.divider) {
                        return const Divider(color: Colors.white12, height: 16);
                      }
                      if (log.type == _LogType.section) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 2),
                          child: Text(log.message,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: SelectableText(
                          log.message,
                          style: TextStyle(
                            color: _logColor(log.type),
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _logColor(_LogType type) {
    switch (type) {
      case _LogType.success:
        return const Color(0xFF66BB6A);
      case _LogType.error:
        return const Color(0xFFEF5350);
      case _LogType.warning:
        return const Color(0xFFFFB74D);
      case _LogType.info:
        return const Color(0xFF42A5F5);
      default:
        return Colors.white54;
    }
  }
}
