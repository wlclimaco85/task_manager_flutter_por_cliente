import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/auth_utility.dart';
import '../../services/ponto_service.dart';
import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';

class DpPortalColaboradorScreen extends StatefulWidget {
  const DpPortalColaboradorScreen({super.key});

  @override
  State<DpPortalColaboradorScreen> createState() => _DpPortalColaboradorScreenState();
}

class _DpPortalColaboradorScreenState extends State<DpPortalColaboradorScreen> {
  bool _loading = true;
  bool _registering = false;
  Map<String, dynamic>? _funcionario;
  Map<String, dynamic> _portal = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  int? get _loginId =>
      AuthUtility.userInfo?.login?.id ??
      AuthUtility.userInfo?.data?.login?.id ??
      AuthUtility.userInfo?.data?.id;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final loginId = _loginId;
      if (loginId == null) return;
      final funcResp = await TenantContext.get('${ApiLinks.baseUrl}/api/funcionario/por-login?loginId=$loginId');
      if (funcResp.statusCode == 200 && funcResp.bodyBytes.isNotEmpty) {
        final decoded = jsonDecode(utf8.decode(funcResp.bodyBytes));
        if (decoded is Map) {
          _funcionario = Map<String, dynamic>.from(decoded);
          final id = _funcionario?['id'];
          final portalResp = await TenantContext.get(ApiLinks.dpPortal(id.toString()));
          if (portalResp.statusCode == 200 && portalResp.bodyBytes.isNotEmpty) {
            final body = jsonDecode(utf8.decode(portalResp.bodyBytes));
            if (body is Map) _portal = Map<String, dynamic>.from(body);
          }
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _registrarPonto() async {
    final loginId = _loginId;
    if (loginId == null) return;
    setState(() => _registering = true);
    final ok = await PontoService.registrarPonto(loginId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'Ponto registrado.' : 'Nao foi possivel registrar o ponto.')),
      );
      setState(() => _registering = false);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = _funcionario?['nome']?.toString() ?? 'Colaborador';
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F1),
      appBar: AppBar(title: const Text('Portal do Colaborador')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _funcionario == null
              ? const Center(child: Text('Nenhum funcionario vinculado ao login atual.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                          ),
                          ElevatedButton.icon(
                            onPressed: _registering ? null : _registrarPonto,
                            icon: const Icon(Icons.fingerprint),
                            label: Text(_registering ? 'Registrando...' : 'Bater ponto'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _PortalSection(title: 'Pontos recentes', items: _asList(_portal['pontos']), primaryField: 'dataHoraRegistro', secondaryField: 'tipo'),
                      const SizedBox(height: 12),
                      _PortalSection(title: 'Ferias', items: _asList(_portal['ferias']), primaryField: 'dataInicio', secondaryField: 'status'),
                      const SizedBox(height: 12),
                      _PortalSection(title: 'Beneficios', items: _asList(_portal['beneficios']), primaryField: 'descricao', secondaryField: 'tipo'),
                      const SizedBox(height: 12),
                      _PortalSection(title: 'Eventos de folha', items: _asList(_portal['eventosFolha']), primaryField: 'competencia', secondaryField: 'valor'),
                      const SizedBox(height: 12),
                      _HoleritesSection(funcionarioId: _funcionario?['id']),
                    ],
                  ),
                ),
    );
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
}

class _PortalSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final String primaryField;
  final String secondaryField;

  const _PortalSection({
    required this.title,
    required this.items,
    required this.primaryField,
    required this.secondaryField,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7DED4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('Sem registros.', style: TextStyle(color: Color(0xFF6B7280)))
            else
              ...items.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item[primaryField]?.toString() ?? 'Registro'),
                  subtitle: Text(item[secondaryField]?.toString() ?? ''),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HoleritesSection extends StatelessWidget {
  final dynamic funcionarioId;

  const _HoleritesSection({required this.funcionarioId});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFD7DED4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Holerites e Comprovantes Salariais', style: TextStyle(fontWeight: FontWeight.w800)),
                Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.receipt, color: Colors.green)),
              title: const Text('Holerite Mensal - Competência Atual', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Disponível para visualização e download em PDF'),
              trailing: ElevatedButton.icon(
                onPressed: () {
                  final url = '${ApiLinks.baseUrl}/api/dp/folha/holerite/1/pdf';
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Download do Holerite PDF iniciado...'), backgroundColor: Colors.green),
                  );
                },
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Baixar PDF'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
