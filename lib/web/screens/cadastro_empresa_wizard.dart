import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/grid_colors.dart';
import 'package:http/http.dart' as http;
import '../../../models/auth_utility.dart';
import '../../../services/network_caller.dart';
import '../../../utils/api_links.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA CLASSES
// ─────────────────────────────────────────────────────────────────────────────

class _EmpresaData {
  String nome = '';
  String razaoSocial = '';
  String email = '';
  String telefone = '';
  String cnpj = '';
  int? aplicativoId;
  String aplicativoNome = '';
}

class _UsuarioData {
  String nome = '';
  String email = '';
  String senha = 'Senha@123';
  String cpfCnpj = '';
  String tipo = 'ADMIN'; // ADMIN | FINANCEIRO
  List<int> roleIds = [];
}

class _ClienteData {
  String nome = '';
  String email = '';
  String cpf = '';
  String telefone = '';
  int? roleAdminId;
}

class _ContaData {
  String descricao = '';
  double valor = 100.0;
  String tipo = 'PAGAR'; // PAGAR | RECEBER
}

class _ChamadoData {
  String titulo = '';
  String descricao = '';
  String prioridade = 'MEDIA';
}

class _FuncionarioData {
  String nome = '';
  String email = '';
  String cpf = '';
  String cargo = '';
}

// ─────────────────────────────────────────────────────────────────────────────
// LOG ENTRY
// ─────────────────────────────────────────────────────────────────────────────

enum _LogType { info, success, error, warning, section }

class _LogEntry {
  final String message;
  final _LogType type;
  _LogEntry(this.message, this.type);
}

class _CreatedEntity {
  final String url;
  final int id;
  final String label;
  _CreatedEntity(this.url, this.id, this.label);
}

class _CadastroException implements Exception {
  final String message;
  _CadastroException(this.message);
  @override
  String toString() => message;
}

// ─────────────────────────────────────────────────────────────────────────────
// WIZARD SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class CadastroEmpresaWizard extends StatefulWidget {
  const CadastroEmpresaWizard({super.key});

  @override
  State<CadastroEmpresaWizard> createState() => _CadastroEmpresaWizardState();
}

class _CadastroEmpresaWizardState extends State<CadastroEmpresaWizard> {
  int _step = 0;
  bool _running = false;
  bool _done = false;
  bool _failed = false;

  final _pageController = PageController();

  // ── dados coletados ──
  final _empresa = _EmpresaData();
  final _usuarios = [
    _UsuarioData()..tipo = 'ADMIN',
    _UsuarioData()..tipo = 'FINANCEIRO',
  ];
  final _clientes = List.generate(5, (_) => _ClienteData());
  final _contas = [
    ...List.generate(5, (i) => _ContaData()..tipo = 'PAGAR'..descricao = 'Conta Pagar ${i + 1}'),
    ...List.generate(5, (i) => _ContaData()..tipo = 'RECEBER'..descricao = 'Conta Receber ${i + 1}'),
  ];
  final _chamados = List.generate(3, (i) => _ChamadoData()..titulo = 'Chamado ${i + 1}'..descricao = 'Descrição do chamado ${i + 1}');
  final _funcionarios = List.generate(5, (_) => _FuncionarioData());

  // ── resultados ──
  int? _empresaId;
  final List<int> _usuarioIds = [];
  final List<int> _clienteIds = [];
  final List<_LogEntry> _logs = [];
  final List<_CreatedEntity> _createdEntities = [];
  List<Map<String, dynamic>> _aplicativos = [];
  List<Map<String, dynamic>> _roles = [];

  // ── form keys ──
  final _formKeys = List.generate(7, (_) => GlobalKey<FormState>());

  static const _steps = [
    'Empresa',
    'Usuários',
    'Clientes',
    'Contas',
    'Chamados',
    'Funcionários',
    'Executar',
  ];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    _prefillDefaults();
  }

  void _prefillDefaults() {
    // usuários
    _usuarios[0].nome = 'Admin Principal';
    _usuarios[0].email = 'admin@empresa.com';
    _usuarios[1].nome = 'Financeiro';
    _usuarios[1].email = 'financeiro@empresa.com';
    // clientes
    for (int i = 0; i < 5; i++) {
      _clientes[i].nome = 'Cliente ${i + 1}';
      _clientes[i].email = 'cliente${i + 1}@empresa.com';
      _clientes[i].cpf = '000.000.000-0$i';
    }
    // funcionários
    for (int i = 0; i < 5; i++) {
      _funcionarios[i].nome = 'Funcionário ${i + 1}';
      _funcionarios[i].email = 'func${i + 1}@empresa.com';
      _funcionarios[i].cargo = 'Cargo ${i + 1}';
    }
  }

  Future<void> _loadDropdowns() async {
    final aps = await _fetchList('${ApiLinks.baseUrl}/api/aplicativo');
    final rls = await _fetchList('${ApiLinks.baseUrl}/api/role?size=200');
    setState(() { _aplicativos = aps; _roles = rls; });
  }

  Future<List<Map<String, dynamic>>> _fetchList(String url) async {
    final nc = NetworkCaller();
    final r = await nc.getRequest(url);
    if (!r.isSuccess || r.body == null) return [];
    final raw = r.body!;
    // raw is Map<String, dynamic> — extract list from various response shapes
    List lista = [];
    final d1 = raw['data'];
    final d2 = raw['dados'];
    final d3 = raw['content'];
    final top = d1 ?? d2 ?? d3;
    if (top is List) {
      lista = top;
    } else if (top is Map) {
      final inner = top['content'] ?? top['dados'] ?? top['items'];
      if (inner is List) lista = inner;
    } else if (raw.values.any((v) => v is List)) {
      lista = raw.values.firstWhere((v) => v is List, orElse: () => []) as List;
    }
    return lista.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NAVIGATION
  // ─────────────────────────────────────────────────────────────────────────

  void _next() {
    if (_formKeys[_step].currentState?.validate() == false) return;
    _formKeys[_step].currentState?.save();
    if (_step < _steps.length - 1) {
      setState(() => _step++);
      _pageController.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.animateToPage(_step, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXECUTION
  // ─────────────────────────────────────────────────────────────────────────

  void _log(String msg, _LogType type) {
    setState(() => _logs.add(_LogEntry(msg, type)));
  }

  Future<int?> _post(String url, Map<String, dynamic> body, String label) async {
    try {
      final token = AuthUtility.userInfo?.token;
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final id = _extractId(decoded);
        _log('✅ $label → id=$id', _LogType.success);
        return id;
      } else {
        _log('❌ $label → HTTP ${response.statusCode}: ${response.body.length > 120 ? response.body.substring(0, 120) : response.body}', _LogType.error);
        return null;
      }
    } catch (e) {
      _log('❌ $label → $e', _LogType.error);
      return null;
    }
  }
  int? _extractId(dynamic body) {
    if (body is Map) {
      return body['id']
          ?? body['data']?['id']
          ?? body['data']?['parceiro']?['id']
          ?? body['data']?['login']?['id'];
    }
    return null;
  }

  Future<void> _delete(String url, int id, String label) async {
    try {
      final token = AuthUtility.userInfo?.token;
      final response = await http.delete(
        Uri.parse('$url/$id'),
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log('↩ Rollback: $label → removido (id=$id)', _LogType.warning);
      } else {
        _log('↩ Rollback: $label → falha HTTP ${response.statusCode}', _LogType.error);
      }
    } catch (e) {
      _log('↩ Rollback: $label → $e', _LogType.error);
    }
  }

  Future<void> _rollback() async {
    if (_createdEntities.isEmpty) return;
    _log('═══ ROLLBACK: removendo dados criados ═══', _LogType.section);
    for (final entity in _createdEntities.reversed) {
      await _delete(entity.url, entity.id, entity.label);
    }
    _createdEntities.clear();
    _usuarioIds.clear();
    _clienteIds.clear();
    _empresaId = null;
  }

  Future<void> _execute() async {
    setState(() { _running = true; _done = false; _failed = false; _logs.clear(); _createdEntities.clear(); });
    _usuarioIds.clear();
    _clienteIds.clear();
    _empresaId = null;

    try {
      final now = DateTime.now().toIso8601String();
      final aplicativoPayload = _empresa.aplicativoId != null ? {'id': _empresa.aplicativoId} : null;

      // ── 1. EMPRESA ──────────────────────────────────────────────────────────
      _log('═══ CADASTRANDO EMPRESA ═══', _LogType.section);
      _empresaId = await _post('${ApiLinks.baseUrl}/api/empresa', {
        'nome': _empresa.nome,
        'razaoSocial': _empresa.razaoSocial.isNotEmpty ? _empresa.razaoSocial : _empresa.nome,
        'email': _empresa.email,
        'telefone': _empresa.telefone,
        'cnpj': _empresa.cnpj,
        if (aplicativoPayload != null) 'aplicativo': aplicativoPayload,
      }, 'Empresa: ${_empresa.nome}');

      if (_empresaId == null) throw _CadastroException('Falha ao criar empresa');
      _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/empresa', _empresaId!, 'Empresa'));

      final empresaRef = {'id': _empresaId};

      // ── 2. USUÁRIOS ─────────────────────────────────────────────────────────
      _log('═══ CADASTRANDO USUÁRIOS ═══', _LogType.section);
      for (final u in _usuarios) {
        final roles = u.roleIds.map((id) => {'id': id}).toList();
        final id = await _post('${ApiLinks.baseUrl}/api/login', {
          'nome': u.nome,
          'email': u.email,
          'senha': u.senha,
          'cpfCnpj': u.cpfCnpj.isNotEmpty ? u.cpfCnpj : null,
          'empresa': empresaRef,
          if (aplicativoPayload != null) 'aplicativo': aplicativoPayload,
          if (roles.isNotEmpty) 'roles': roles,
          'tipoLogin': 1,
        }, 'Usuário: ${u.nome} (${u.tipo})');
        if (id == null) throw _CadastroException('Falha ao criar usuário ${u.nome}');
        _usuarioIds.add(id);
        _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/login', id, 'Usuário ${u.nome}'));
      }

      // ── 3. CLIENTES (PARCEIROS) ─────────────────────────────────────────────
      _log('═══ CADASTRANDO CLIENTES ═══', _LogType.section);
      for (final c in _clientes) {
        final id = await _post('${ApiLinks.baseUrl}/api/parceiro', {
          'nome': c.nome,
          'email': c.email,
          'cpf': c.cpf.isNotEmpty ? c.cpf : null,
          'telefone': c.telefone.isNotEmpty ? c.telefone : null,
          'empresa': empresaRef,
          if (aplicativoPayload != null) 'aplicativo': aplicativoPayload,
        }, 'Cliente: ${c.nome}');
        if (id == null) throw _CadastroException('Falha ao criar cliente ${c.nome}');
        _clienteIds.add(id);
        _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/parceiro', id, 'Cliente ${c.nome}'));

        // login do cliente com role admin
        final rolePayload = c.roleAdminId != null ? [{'id': c.roleAdminId}] : <Map>[];
        final loginId = await _post('${ApiLinks.baseUrl}/api/login', {
          'nome': c.nome,
          'email': c.email,
          'senha': 'Senha@123',
          'empresa': empresaRef,
          'parceiro': {'id': id},
          if (aplicativoPayload != null) 'aplicativo': aplicativoPayload,
          if (rolePayload.isNotEmpty) 'roles': rolePayload,
          'tipoLogin': 2,
        }, 'Login cliente: ${c.nome}');
        if (loginId == null) throw _CadastroException('Falha ao criar login do cliente ${c.nome}');
        _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/login', loginId, 'Login cliente ${c.nome}'));
      }

      // ── 4. CONTAS A PAGAR ───────────────────────────────────────────────────
      _log('═══ CADASTRANDO CONTAS A PAGAR ═══', _LogType.section);
      final parceiroRef = _clienteIds.isNotEmpty ? {'id': _clienteIds.first} : null;
      for (int i = 0; i < 5; i++) {
        final c = _contas[i];
        final id = await _post('${ApiLinks.baseUrl}/api/conta_pagar', {
          'descricao': c.descricao,
          'valor': c.valor,
          'dataVencimento': DateTime.now().add(Duration(days: 30 + i * 7)).toIso8601String(),
          'status': 'ABERTA',
          'empresa': empresaRef,
          if (parceiroRef != null) 'parceiro': parceiroRef,
        }, 'Conta Pagar: ${c.descricao}');
        if (id == null) throw _CadastroException('Falha ao criar conta a pagar ${c.descricao}');
        _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/conta_pagar', id, 'Conta Pagar ${c.descricao}'));
      }

      // ── 5. CONTAS A RECEBER ─────────────────────────────────────────────────
      _log('═══ CADASTRANDO CONTAS A RECEBER ═══', _LogType.section);
      for (int i = 5; i < 10; i++) {
        final c = _contas[i];
        final id = await _post('${ApiLinks.baseUrl}/api/conta_receber', {
          'descricao': c.descricao,
          'valor': c.valor,
          'dataVencimento': DateTime.now().add(Duration(days: 30 + (i - 5) * 7)).toIso8601String(),
          'status': 'ABERTA',
          'empresa': empresaRef,
          if (parceiroRef != null) 'cliente': parceiroRef,
        }, 'Conta Receber: ${c.descricao}');
        if (id == null) throw _CadastroException('Falha ao criar conta a receber ${c.descricao}');
        _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/conta_receber', id, 'Conta Receber ${c.descricao}'));
      }

      // ── 6. NOTA FISCAL ──────────────────────────────────────────────────────
      _log('═══ CADASTRANDO NOTA FISCAL ═══', _LogType.section);
      final nfId = await _post('${ApiLinks.baseUrl}/api/nfe', {
        'numero': 'NF-$_empresaId-001',
        'dhEmi': now,
        'valorTotal': 1000.0,
        'status': 'CRIADA',
        'empresa': empresaRef,
      }, 'Nota Fiscal Entrada');
      if (nfId == null) throw _CadastroException('Falha ao criar nota fiscal');
      _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/nfe', nfId, 'Nota Fiscal'));

      // ── 7. CHAMADOS ─────────────────────────────────────────────────────────
      _log('═══ CADASTRANDO CHAMADOS ═══', _LogType.section);
      for (final ch in _chamados) {
        final id = await _post('${ApiLinks.baseUrl}/api/chamados', {
          'titulo': ch.titulo,
          'descricao': ch.descricao,
          'status': 'ABERTO',
          'prioridade': ch.prioridade,
          'empresa': empresaRef,
          if (parceiroRef != null) 'parceiro': parceiroRef,
          'dataAbertura': now,
        }, 'Chamado: ${ch.titulo}');
        if (id == null) throw _CadastroException('Falha ao criar chamado ${ch.titulo}');
        _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/chamados', id, 'Chamado ${ch.titulo}'));
      }

      // ── 8. CHAT ─────────────────────────────────────────────────────────────
      _log('═══ INICIANDO CHAT ═══', _LogType.section);
      if (_clienteIds.isNotEmpty) {
        final clienteId = _clienteIds.first;
        final chatId = await _post('${ApiLinks.baseUrl}/api/chat', {
          'empId': _empresaId,
          'empresaId': _empresaId,
          'parceiroId': clienteId,
          'chatId': 'empresa-$_empresaId-parceiro-$clienteId',
          'sector': 'Abertura Firma',
          'status': 'ABERTO',
          'text': 'Chat inicial criado automaticamente para ${_empresa.nome}.',
          'titulo': 'Chat inicial - ${_empresa.nome}',
        }, 'Chat inicial');
        if (chatId == null) throw _CadastroException('Falha ao criar chat inicial');
        _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/chat', chatId, 'Chat inicial'));
      }

      // ── 9. FUNCIONÁRIOS ─────────────────────────────────────────────────────
      _log('═══ CADASTRANDO FUNCIONÁRIOS ═══', _LogType.section);
      for (final f in _funcionarios) {
        final id = await _post('${ApiLinks.baseUrl}/api/parceiro', {
          'nome': f.nome,
          'email': f.email,
          'cpf': f.cpf.isNotEmpty ? f.cpf : null,
          'empresa': empresaRef,
          if (aplicativoPayload != null) 'aplicativo': aplicativoPayload,
          'tipoAluno': 'FUNCIONARIO',
        }, 'Funcionário: ${f.nome}');
        if (id == null) throw _CadastroException('Falha ao criar funcionário ${f.nome}');
        _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/parceiro', id, 'Funcionário ${f.nome}'));

        final loginId = await _post('${ApiLinks.baseUrl}/api/login', {
          'nome': f.nome,
          'email': f.email,
          'senha': 'Senha@123',
          'empresa': empresaRef,
          'parceiro': {'id': id},
          if (aplicativoPayload != null) 'aplicativo': aplicativoPayload,
          'tipoLogin': 3,
        }, 'Login funcionário: ${f.nome}');
        if (loginId == null) throw _CadastroException('Falha ao criar login do funcionário ${f.nome}');
        _createdEntities.add(_CreatedEntity('${ApiLinks.baseUrl}/api/login', loginId, 'Login funcionário ${f.nome}'));
      }

      _log('═══ CONCLUÍDO ═══', _LogType.section);
      _log('Empresa ID: $_empresaId | Usuários: ${_usuarioIds.length} | Clientes: ${_clienteIds.length}', _LogType.info);
      setState(() { _running = false; _done = true; });
    } on _CadastroException catch (e) {
      _log('❌ Cadastro interrompido: $e', _LogType.error);
      _log('▶ Iniciando rollback...', _LogType.warning);
      await _rollback();
      setState(() { _running = false; _failed = true; });
    } catch (e) {
      _log('❌ Erro inesperado: $e', _LogType.error);
      _log('▶ Iniciando rollback...', _LogType.warning);
      await _rollback();
      setState(() { _running = false; _failed = true; });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D27),
        title: const Text('Cadastro de Empresa', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildStepper(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepEmpresa(data: _empresa, formKey: _formKeys[0], aplicativos: _aplicativos),
                _StepUsuarios(usuarios: _usuarios, formKey: _formKeys[1], roles: _roles),
                _StepClientes(clientes: _clientes, formKey: _formKeys[2], roles: _roles),
                _StepContas(contas: _contas, formKey: _formKeys[3]),
                _StepChamados(chamados: _chamados, formKey: _formKeys[4]),
                _StepFuncionarios(funcionarios: _funcionarios, formKey: _formKeys[5]),
                _StepExecutar(
                  empresa: _empresa,
                  usuarios: _usuarios,
                  clientes: _clientes,
                  chamados: _chamados,
                  funcionarios: _funcionarios,
                  formKey: _formKeys[6],
                  running: _running,
                  done: _done,
                  failed: _failed,
                  logs: _logs,
                  onExecute: _execute,
                ),
              ],
            ),
          ),
          _buildNavButtons(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      color: const Color(0xFF1A1D27),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_steps.length, (i) {
            final active = i == _step;
            final done = i < _step;
            return Row(
              children: [
                if (i > 0)
                  Container(width: 24, height: 2,
                    color: done ? GridColors.success : Colors.white12),
                GestureDetector(
                  onTap: () {
                    if (i < _step) {
                      setState(() => _step = i);
                      _pageController.jumpToPage(i);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? GridColors.success : done ? GridColors.success : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_steps[i],
                      style: TextStyle(
                        color: active || done ? Colors.white : Colors.white54,
                        fontSize: 12,
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
                      )),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNavButtons() {
    final isLast = _step == _steps.length - 1;
    return Container(
      color: const Color(0xFF1A1D27),
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_step > 0)
            OutlinedButton.icon(
              onPressed: _running ? null : _back,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Voltar'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.white54),
            )
          else
            const SizedBox(),
          if (!isLast)
            ElevatedButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Próximo'),
              style: ElevatedButton.styleFrom(backgroundColor: GridColors.success),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1 — EMPRESA
// ─────────────────────────────────────────────────────────────────────────────

class _StepEmpresa extends StatelessWidget {
  final _EmpresaData data;
  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>> aplicativos;

  const _StepEmpresa({required this.data, required this.formKey, required this.aplicativos});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Dados da Empresa',
      icon: Icons.business,
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _field('Nome *', Icons.business, (v) => data.nome = v ?? '', initial: data.nome, required: true),
            _field('Razão Social', Icons.description, (v) => data.razaoSocial = v ?? '', initial: data.razaoSocial),
            _field('E-mail', Icons.email, (v) => data.email = v ?? '', initial: data.email, keyboard: TextInputType.emailAddress),
            _field('Telefone', Icons.phone, (v) => data.telefone = v ?? '', initial: data.telefone, keyboard: TextInputType.phone),
            _field('CNPJ', Icons.badge, (v) => data.cnpj = v ?? '', initial: data.cnpj),
            const SizedBox(height: 12),
            _WizDropdown(
              label: 'Aplicativo',
              icon: Icons.apps,
              items: aplicativos,
              displayField: 'nome',
              valueField: 'id',
              value: data.aplicativoId,
              onChanged: (v) {
                data.aplicativoId = v;
                final ap = aplicativos.firstWhere((e) => e['id'] == v, orElse: () => {});
                data.aplicativoNome = ap['nome']?.toString() ?? '';
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 2 — USUÁRIOS
// ─────────────────────────────────────────────────────────────────────────────

class _StepUsuarios extends StatefulWidget {
  final List<_UsuarioData> usuarios;
  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>> roles;

  const _StepUsuarios({required this.usuarios, required this.formKey, required this.roles});

  @override
  State<_StepUsuarios> createState() => _StepUsuariosState();
}

class _StepUsuariosState extends State<_StepUsuarios> {
  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '2 Usuários',
      icon: Icons.people,
      child: Form(
        key: widget.formKey,
        child: Column(
          children: widget.usuarios.asMap().entries.map((entry) {
            final i = entry.key;
            final u = entry.value;
            return _WizCard(
              title: 'Usuário ${i + 1} — ${u.tipo}',
              color: i == 0 ? const Color(0xFF1565C0) : const Color(0xFF6A1B9A),
              child: Column(
                children: [
                  _field('Nome *', Icons.person, (v) => u.nome = v ?? '', initial: u.nome, required: true),
                  _field('E-mail *', Icons.email, (v) => u.email = v ?? '', initial: u.email, required: true, keyboard: TextInputType.emailAddress),
                  _field('Senha', Icons.lock, (v) => u.senha = v ?? 'Senha@123', initial: u.senha),
                  _field('CPF/CNPJ', Icons.badge, (v) => u.cpfCnpj = v ?? '', initial: u.cpfCnpj),
                  const SizedBox(height: 8),
                  _WizMultiSelect(
                    label: 'Roles',
                    items: widget.roles,
                    displayField: 'description',
                    valueField: 'id',
                    selected: u.roleIds,
                    hint: i == 0 ? 'Selecione todas as roles' : 'Selecione roles financeiras',
                    onChanged: (ids) => setState(() => u.roleIds = ids),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 3 — CLIENTES
// ─────────────────────────────────────────────────────────────────────────────

class _StepClientes extends StatefulWidget {
  final List<_ClienteData> clientes;
  final GlobalKey<FormState> formKey;
  final List<Map<String, dynamic>> roles;

  const _StepClientes({required this.clientes, required this.formKey, required this.roles});

  @override
  State<_StepClientes> createState() => _StepClientesState();
}

class _StepClientesState extends State<_StepClientes> {
  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '5 Clientes',
      icon: Icons.group,
      child: Form(
        key: widget.formKey,
        child: Column(
          children: widget.clientes.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return _WizCard(
              title: 'Cliente ${i + 1}',
              color: const Color(0xFF00695C),
              child: Column(
                children: [
                  _field('Nome *', Icons.person, (v) => c.nome = v ?? '', initial: c.nome, required: true),
                  _field('E-mail', Icons.email, (v) => c.email = v ?? '', initial: c.email, keyboard: TextInputType.emailAddress),
                  _field('CPF', Icons.badge, (v) => c.cpf = v ?? '', initial: c.cpf),
                  _field('Telefone', Icons.phone, (v) => c.telefone = v ?? '', initial: c.telefone),
                  const SizedBox(height: 8),
                  _WizDropdown(
                    label: 'Role Admin',
                    icon: Icons.security,
                    items: widget.roles,
                    displayField: 'description',
                    valueField: 'id',
                    value: c.roleAdminId,
                    onChanged: (v) => setState(() => c.roleAdminId = v),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 4 — CONTAS
// ─────────────────────────────────────────────────────────────────────────────

class _StepContas extends StatelessWidget {
  final List<_ContaData> contas;
  final GlobalKey<FormState> formKey;

  const _StepContas({required this.contas, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '5 Contas a Pagar + 5 a Receber',
      icon: Icons.account_balance_wallet,
      child: Form(
        key: formKey,
        child: Column(
          children: contas.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final isPagar = c.tipo == 'PAGAR';
            return _WizCard(
              title: '${isPagar ? "Pagar" : "Receber"} ${isPagar ? i + 1 : i - 4}',
              color: isPagar ? GridColors.error : GridColors.success,
              child: Row(
                children: [
                  Expanded(child: _field('Descrição', Icons.description, (v) => c.descricao = v ?? '', initial: c.descricao)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: _field('Valor', Icons.attach_money, (v) => c.valor = double.tryParse(v ?? '') ?? 100.0,
                      initial: c.valor.toString(), keyboard: TextInputType.number),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 5 — CHAMADOS
// ─────────────────────────────────────────────────────────────────────────────

class _StepChamados extends StatelessWidget {
  final List<_ChamadoData> chamados;
  final GlobalKey<FormState> formKey;

  const _StepChamados({required this.chamados, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Chamados + Chat',
      icon: Icons.support_agent,
      child: Form(
        key: formKey,
        child: Column(
          children: [
            ...chamados.asMap().entries.map((entry) {
              final i = entry.key;
              final ch = entry.value;
              return _WizCard(
                title: 'Chamado ${i + 1}',
                color: const Color(0xFFE65100),
                child: Column(
                  children: [
                    _field('Título *', Icons.title, (v) => ch.titulo = v ?? '', initial: ch.titulo, required: true),
                    _field('Descrição', Icons.description, (v) => ch.descricao = v ?? '', initial: ch.descricao, maxLines: 2),
                    const SizedBox(height: 8),
                    _WizDropdown(
                      label: 'Prioridade',
                      icon: Icons.priority_high,
                      items: const [
                        {'id': 'BAIXA', 'nome': 'Baixa'},
                        {'id': 'MEDIA', 'nome': 'Média'},
                        {'id': 'ALTA', 'nome': 'Alta'},
                        {'id': 'URGENTE', 'nome': 'Urgente'},
                      ],
                      displayField: 'nome',
                      valueField: 'id',
                      value: ch.prioridade,
                      onChanged: (v) => ch.prioridade = v?.toString() ?? 'MEDIA',
                    ),
                  ],
                ),
              );
            }),
            const _WizCard(
              title: 'Chat',
              color: Color(0xFF1565C0),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(Icons.chat, color: Colors.white54, size: 20),
                    SizedBox(width: 8),
                    Text('Um chat será iniciado com o primeiro cliente cadastrado.',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 6 — FUNCIONÁRIOS
// ─────────────────────────────────────────────────────────────────────────────

class _StepFuncionarios extends StatelessWidget {
  final List<_FuncionarioData> funcionarios;
  final GlobalKey<FormState> formKey;

  const _StepFuncionarios({required this.funcionarios, required this.formKey});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: '5 Funcionários',
      icon: Icons.badge,
      child: Form(
        key: formKey,
        child: Column(
          children: funcionarios.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            return _WizCard(
              title: 'Funcionário ${i + 1}',
              color: const Color(0xFF4527A0),
              child: Column(
                children: [
                  _field('Nome *', Icons.person, (v) => f.nome = v ?? '', initial: f.nome, required: true),
                  _field('E-mail', Icons.email, (v) => f.email = v ?? '', initial: f.email, keyboard: TextInputType.emailAddress),
                  _field('CPF', Icons.badge, (v) => f.cpf = v ?? '', initial: f.cpf),
                  _field('Cargo', Icons.work, (v) => f.cargo = v ?? '', initial: f.cargo),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP 7 — EXECUTAR
// ─────────────────────────────────────────────────────────────────────────────

class _StepExecutar extends StatelessWidget {
  final _EmpresaData empresa;
  final List<_UsuarioData> usuarios;
  final List<_ClienteData> clientes;
  final List<_ChamadoData> chamados;
  final List<_FuncionarioData> funcionarios;
  final GlobalKey<FormState> formKey;
  final bool running;
  final bool done;
  final bool failed;
  final List<_LogEntry> logs;
  final VoidCallback onExecute;

  const _StepExecutar({
    required this.empresa, required this.usuarios, required this.clientes,
    required this.chamados, required this.funcionarios, required this.formKey,
    required this.running, required this.done, required this.failed,
    required this.logs, required this.onExecute,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Resumo e Execução',
      icon: Icons.rocket_launch,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo
            _WizCard(
              title: 'Resumo',
              color: const Color(0xFF1A237E),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryRow(Icons.business, 'Empresa', empresa.nome.isNotEmpty ? empresa.nome : '(não preenchido)'),
                  _summaryRow(Icons.people, 'Usuários', '${usuarios.length} (Admin + Financeiro)'),
                  _summaryRow(Icons.group, 'Clientes', '${clientes.length} parceiros com login'),
                  _summaryRow(Icons.account_balance_wallet, 'Contas', '5 a pagar + 5 a receber'),
                  _summaryRow(Icons.receipt, 'Nota Fiscal', '1 nota fiscal de entrada'),
                  _summaryRow(Icons.support_agent, 'Chamados', '${chamados.length} chamados + 1 chat'),
                  _summaryRow(Icons.badge, 'Funcionários', '${funcionarios.length} funcionários com login'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Botão executar
            if (!running && !done)
              Center(
                child: ElevatedButton.icon(
                  onPressed: onExecute,
                  icon: const Icon(Icons.rocket_launch),
                  label: const Text('Executar Cadastro Completo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.success,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            if (running)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(children: [
                  CircularProgressIndicator(color: GridColors.success),
                  SizedBox(height: 8),
                  Text('Executando...', style: TextStyle(color: Colors.white70)),
                ]),
              )),
            if (done)
              const Center(child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle, color: GridColors.success, size: 28),
                  SizedBox(width: 8),
                  Text('Concluído!', style: TextStyle(color: GridColors.success, fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
              )),
            if (failed)
              const Center(child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.error, color: Color(0xFFEF5350), size: 28),
                  SizedBox(width: 8),
                  Text('Falha na execução!', style: TextStyle(color: Color(0xFFEF5350), fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
              )),
            const SizedBox(height: 12),
            // Log
            if (logs.isNotEmpty) ...[
              Row(
                children: [
                  const Text('Log de Execução', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (logs.any((l) => l.type == _LogType.error))
                    SizedBox(
                      height: 32,
                      child: TextButton.icon(
                        onPressed: () {
                          final errorText = logs
                              .where((l) => l.type == _LogType.error)
                              .map((l) => l.message)
                              .join('\n');
                          Clipboard.setData(ClipboardData(text: errorText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Erros copiados para a área de transferência'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 14),
                        label: const Text('Copiar Erros', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFEF5350),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0D14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: logs.length,
                  itemBuilder: (_, i) {
                    final log = logs[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Text(log.message, style: TextStyle(
                        color: _logColor(log.type),
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: log.type == _LogType.section ? FontWeight.bold : FontWeight.normal,
                      )),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _logColor(_LogType t) {
    switch (t) {
      case _LogType.success: return GridColors.success;
      case _LogType.error: return const Color(0xFFEF5350);
      case _LogType.warning: return const Color(0xFFFFB300);
      case _LogType.section: return const Color(0xFF42A5F5);
      default: return Colors.white70;
    }
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white54),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _StepScaffold extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _StepScaffold({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: GridColors.success, size: 22),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _WizCard extends StatelessWidget {
  final String title;
  final Color color;
  final Widget child;

  const _WizCard({required this.title, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
            ),
            child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          Padding(padding: const EdgeInsets.all(12), child: child),
        ],
      ),
    );
  }
}

Widget _field(
  String label,
  IconData icon,
  void Function(String?) onSaved, {
  String initial = '',
  bool required = false,
  TextInputType keyboard = TextInputType.text,
  int maxLines = 1,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      initialValue: initial,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: Icon(icon, size: 16, color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF0F1117),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: GridColors.success)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      validator: required ? (v) => (v == null || v.isEmpty) ? '$label é obrigatório' : null : null,
      onSaved: onSaved,
    ),
  );
}

class _WizDropdown extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final String displayField;
  final String valueField;
  final dynamic value;
  final void Function(dynamic) onChanged;

  const _WizDropdown({
    required this.label, required this.icon, required this.items,
    required this.displayField, required this.valueField,
    required this.value, required this.onChanged,
  });

  @override
  State<_WizDropdown> createState() => _WizDropdownState();
}

class _WizDropdownState extends State<_WizDropdown> {
  dynamic _val;

  @override
  void initState() {
    super.initState();
    _val = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<dynamic>(
        initialValue: _val,
        dropdownColor: const Color(0xFF1A1D27),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
          prefixIcon: Icon(widget.icon, size: 16, color: Colors.white38),
          filled: true,
          fillColor: const Color(0xFF0F1117),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.white12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('— Selecione —', style: TextStyle(color: Colors.white38))),
          ...widget.items.map((item) => DropdownMenuItem(
            value: item[widget.valueField],
            child: Text(item[widget.displayField]?.toString() ?? '', style: const TextStyle(color: Colors.white)),
          )),
        ],
        onChanged: (v) {
          setState(() => _val = v);
          widget.onChanged(v);
        },
      ),
    );
  }
}

class _WizMultiSelect extends StatefulWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final String displayField;
  final String valueField;
  final List<int> selected;
  final String hint;
  final void Function(List<int>) onChanged;

  const _WizMultiSelect({
    required this.label, required this.items, required this.displayField,
    required this.valueField, required this.selected, required this.hint,
    required this.onChanged,
  });

  @override
  State<_WizMultiSelect> createState() => _WizMultiSelectState();
}

class _WizMultiSelectState extends State<_WizMultiSelect> {
  late List<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  void _openDialog() async {
    final result = await showDialog<List<int>>(
      context: context,
      builder: (ctx) => _MultiSelectDialog(
        items: widget.items,
        displayField: widget.displayField,
        valueField: widget.valueField,
        selected: _selected,
      ),
    );
    if (result != null) {
      setState(() => _selected = result);
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1117),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.security, size: 16, color: Colors.white38),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selected.isEmpty ? widget.hint : '${_selected.length} role(s) selecionada(s)',
                style: TextStyle(color: _selected.isEmpty ? Colors.white38 : Colors.white70, fontSize: 13),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String displayField;
  final String valueField;
  final List<int> selected;

  const _MultiSelectDialog({required this.items, required this.displayField, required this.valueField, required this.selected});

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1D27),
      title: const Text('Selecionar Roles', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 400,
        height: 400,
        child: ListView(
          children: widget.items.map((item) {
            final id = item[widget.valueField] as int?;
            if (id == null) return const SizedBox();
            return CheckboxListTile(
              value: _selected.contains(id),
              title: Text(item[widget.displayField]?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
              activeColor: GridColors.success,
              onChanged: (v) => setState(() => v == true ? _selected.add(id) : _selected.remove(id)),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selected.toList()),
          style: ElevatedButton.styleFrom(backgroundColor: GridColors.success),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
