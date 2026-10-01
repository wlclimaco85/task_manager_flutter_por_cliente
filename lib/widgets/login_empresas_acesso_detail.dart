import 'package:flutter/material.dart';

import '../models/empresa_acesso_model.dart';
import '../services/login_empresa_acesso_service.dart';

typedef LoginAcessosLoader = Future<List<EmpresaAcesso>> Function(int loginId);
typedef LoginAcessoSolicitante = Future<bool> Function(
  int loginId,
  int empresaId,
);
typedef EmpresasDropdownLoader = Future<List<Map<String, dynamic>>> Function(
  int loginId,
);

class LoginEmpresasAcessoDetail extends StatefulWidget {
  final int? loginId;
  final bool loginTemParceiro;
  final LoginAcessosLoader carregarAcessos;
  final LoginAcessoSolicitante solicitarAcesso;
  final EmpresasDropdownLoader carregarEmpresas;

  const LoginEmpresasAcessoDetail({
    super.key,
    required this.loginId,
    required this.loginTemParceiro,
    LoginAcessosLoader? carregarAcessos,
    LoginAcessoSolicitante? solicitarAcesso,
    EmpresasDropdownLoader? carregarEmpresas,
  })  : carregarAcessos = carregarAcessos ?? _carregarAcessosDefault,
        solicitarAcesso = solicitarAcesso ?? _solicitarAcessoDefault,
        carregarEmpresas = carregarEmpresas ?? _carregarEmpresasDefault;

  static Future<List<EmpresaAcesso>> _carregarAcessosDefault(int loginId) {
    return LoginEmpresaAcessoService().listarAcessosDoLogin(loginId);
  }

  static Future<bool> _solicitarAcessoDefault(int loginId, int empresaId) {
    return LoginEmpresaAcessoService()
        .solicitarAcessoParaLogin(loginId, empresaId);
  }

  static Future<List<Map<String, dynamic>>> _carregarEmpresasDefault(
    int loginId,
  ) {
    return LoginEmpresaAcessoService()
        .listarEmpresasDisponiveisParaLogin(loginId);
  }

  @override
  State<LoginEmpresasAcessoDetail> createState() =>
      _LoginEmpresasAcessoDetailState();
}

class _LoginEmpresasAcessoDetailState extends State<LoginEmpresasAcessoDetail> {
  late Future<void> _future;
  List<EmpresaAcesso> _acessos = [];
  List<Map<String, dynamic>> _empresas = [];
  int? _empresaSelecionada;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _future = _carregar();
  }

  Future<void> _carregar() async {
    final loginId = widget.loginId;
    if (loginId == null || loginId <= 0) {
      _acessos = [];
      _empresas = [];
      return;
    }
    final result = await Future.wait([
      widget.carregarAcessos(loginId),
      widget.carregarEmpresas(loginId),
    ]);
    _acessos = result[0] as List<EmpresaAcesso>;
    final empresasComAcesso = _acessos.map((a) => a.empresaId).toSet();
    _empresas = (result[1] as List<Map<String, dynamic>>).where((empresa) {
      final id = _asInt(empresa['value'] ?? empresa['id']);
      return id != null && !empresasComAcesso.contains(id);
    }).toList();
    _empresaSelecionada = _primeiraEmpresaDisponivel();
  }

  int? _primeiraEmpresaDisponivel() {
    for (final empresa in _empresas) {
      final id = _asInt(empresa['value'] ?? empresa['id']);
      if (id != null) {
        return id;
      }
    }
    return null;
  }

  Future<void> _solicitar() async {
    final loginId = widget.loginId;
    final empresaId = _empresaSelecionada;
    if (loginId == null || empresaId == null || _salvando) return;

    setState(() {
      _salvando = true;
      _erro = null;
    });
    final ok = await widget.solicitarAcesso(loginId, empresaId);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _salvando = false;
        _erro = 'Nao foi possivel solicitar o acesso.';
      });
      return;
    }
    setState(() {
      _future = _carregar();
      _salvando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _emptyMessage('Falha ao carregar empresas com acesso.');
        }
        if (widget.loginId == null || widget.loginId! <= 0) {
          return _emptyMessage('Salve o login antes de solicitar empresas.');
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Empresas com acesso',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.loginTemParceiro
                  ? 'Acesso multi-empresa restrito às filiais e matriz do parceiro.'
                  : 'Acesso multi-empresa disponível para as empresas do sistema.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            if (_acessos.isEmpty)
              const Text('Nenhuma empresa solicitada para este login.'),
            for (final acesso in _acessos) _buildAcessoTile(acesso),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 220,
                    maxWidth: 360,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<int>(
                      key: const Key('login-empresa-acesso-dropdown'),
                      value: _empresaSelecionada,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Empresa',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _empresas
                          .map((empresa) {
                            final id =
                                _asInt(empresa['value'] ?? empresa['id']);
                            final label =
                                (empresa['label'] ?? empresa['nome'] ?? '')
                                    .toString();
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(label),
                            );
                          })
                          .where((item) => item.value != null)
                          .toList(),
                      onChanged: _salvando
                          ? null
                          : (value) => setState(() {
                                _empresaSelecionada = value;
                                _erro = null;
                              }),
                    ),
                  ),
                ),
                FilledButton.icon(
                  key: const Key('login-empresa-acesso-solicitar'),
                  onPressed: _empresaSelecionada == null || _salvando
                      ? null
                      : _solicitar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_business),
                  label: const Text('Solicitar acesso a outra empresa'),
                ),
              ],
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildAcessoTile(EmpresaAcesso acesso) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD7E2DA)),
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              acesso.empresaNome,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (acesso.ativa) _badge('Ativa', const Color(0xFF00662E)),
          const SizedBox(width: 8),
          _badge(_statusLabel(acesso), _statusColor(acesso)),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  String _statusLabel(EmpresaAcesso acesso) {
    if (acesso.aprovado) return 'Aprovado';
    if (acesso.pendente) return 'Pendente';
    return acesso.status;
  }

  Color _statusColor(EmpresaAcesso acesso) {
    if (acesso.aprovado) return const Color(0xFF00662E);
    if (acesso.pendente) return const Color(0xFFFF8A00);
    return const Color(0xFF66736A);
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
