// lib/widgets/notificacoes_drawer.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';
import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class NotificacoesDrawer extends StatefulWidget {
  final int? empresaId;

  const NotificacoesDrawer({super.key, this.empresaId});

  @override
  State<NotificacoesDrawer> createState() => _NotificacoesDrawerState();
}

class _NotificacoesDrawerState extends State<NotificacoesDrawer> {
  List<Map<String, dynamic>> _notifs = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final param = widget.empresaId != null ? '?empresaId=${widget.empresaId}' : '';
      final resp = await TenantContext.get('${ApiLinks.baseUrl}/api/notificacoes$param');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List raw = [];
        if (body is List) {
          raw = body;
        } else if (body is Map) {
          raw = body['data'] is List
              ? body['data']
              : body['dados'] ?? body['content'] ?? body['items'] ?? [];
        }
        setState(() => _notifs =
            raw.whereType<Map>().map((n) => Map<String, dynamic>.from(n)).toList());
      } else {
        setState(() => _erro = 'Erro ${resp.statusCode} ao carregar notificações');
      }
    } catch (e) {
      setState(() => _erro = 'Falha de conexão');
    }
    setState(() => _loading = false);
  }

  // ─── Classificação de urgência ────────────────────────────────────────────

  bool _isUrgente(String? tipo) {
    final t = tipo?.toUpperCase() ?? '';
    return t == 'CP' || t == 'CR' || t == 'ALVARA' || t == 'CHAMADO';
  }

  IconData _iconeTipo(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'ALVARA':            return Icons.assignment_late_rounded;
      case 'ALVARA_CADASTRADO': return Icons.assignment_add;
      case 'ALVARA_VENDIDO':    return Icons.sell_rounded;
      case 'ALVARA_STATUS':     return Icons.sync_alt_rounded;
      case 'CP':                return Icons.credit_card_off_rounded;
      case 'CR':                return Icons.account_balance_wallet_rounded;
      case 'GED':               return Icons.attach_file_rounded;
      case 'COMUNICADO':        return Icons.campaign_rounded;
      case 'CHAMADO':           return Icons.support_agent_rounded;
      default:                  return Icons.notifications_rounded;
    }
  }

  Color _corTipo(String? tipo) {
    switch (tipo?.toUpperCase()) {
      case 'ALVARA':            return GridColors.warning;
      case 'ALVARA_CADASTRADO': return GridColors.secondaryLight;
      case 'ALVARA_VENDIDO':    return GridColors.success;
      case 'ALVARA_STATUS':     return GridColors.warningDark;
      case 'CP':                return GridColors.error;
      case 'CR':                return GridColors.info;
      case 'GED':               return GridColors.statusHoliday;
      case 'COMUNICADO':        return GridColors.statusClosed;
      case 'CHAMADO':           return GridColors.warningDark;
      default:                  return GridColors.neutral;
    }
  }

  String _labelTipo(String? tipo) {
    return switch (tipo?.toUpperCase()) {
      'ALVARA'            => 'Alvará',
      'ALVARA_CADASTRADO' => 'Alvará',
      'ALVARA_VENDIDO'    => 'Alvará Vendido',
      'ALVARA_STATUS'     => 'Status',
      'CP'                => 'Conta a Pagar',
      'CR'                => 'Conta a Receber',
      'GED'               => 'Documento',
      'COMUNICADO'        => 'Comunicado',
      'CHAMADO'           => 'Chamado',
      _                   => 'Notificação',
    };
  }

  String _formatarData(String? valor) {
    if (valor == null || valor.isEmpty) return '';
    try {
      final dt = DateTime.parse(valor).toLocal();
      final hoje = DateTime.now();
      // Normaliza para meia-noite para evitar falsos "Hoje" perto da virada do dia
      final diffDias = DateTime(hoje.year, hoje.month, hoje.day)
          .difference(DateTime(dt.year, dt.month, dt.day))
          .inDays;
      if (diffDias == 0) return 'Hoje';
      if (diffDias == 1) return 'Ontem';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return valor;
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final urgentes = _notifs.where((n) => _isUrgente(n['tipo']?.toString())).toList();
    final demais = _notifs.where((n) => !_isUrgente(n['tipo']?.toString())).toList();

    return Drawer(
      backgroundColor: GridColors.pageBackground,
      child: SafeArea(
        child: Column(
          children: [
            _buildCabecalho(context),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_erro != null)
              _buildEstadoErro()
            else if (_notifs.isEmpty)
              _buildEstadoVazio()
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (urgentes.isNotEmpty) ...[
                      _buildSecaoLabel('Requer atenção', urgentes.length, GridColors.error),
                      ...urgentes.map(_buildCard),
                    ],
                    if (demais.isNotEmpty) ...[
                      _buildSecaoLabel('Informações', demais.length, GridColors.neutral),
                      ...demais.map(_buildCard),
                    ],
                  ],
                ),
              ),
            if (!_loading && _notifs.isNotEmpty) _buildRodape(),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: GridColors.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: GridColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.notifications_rounded, color: GridColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notificações',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                if (!_loading && _notifs.isNotEmpty)
                  Text('${_notifs.length} pendente${_notifs.length > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF6B7280)),
            tooltip: 'Atualizar',
            onPressed: _carregar,
          ),
        ],
      ),
    );
  }

  Widget _buildSecaoLabel(String titulo, int count, Color cor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(titulo.toUpperCase(),
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cor, letterSpacing: 0.5)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: cor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cor)),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> n) {
    final tipo = n['tipo']?.toString();
    final cor = _corTipo(tipo);
    final mensagem = n['mensagem']?.toString() ?? '';
    final data = _formatarData(n['dataVencimento']?.toString() ?? n['createdAt']?.toString());
    final label = _labelTipo(tipo);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: cor, width: 4)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconeTipo(tipo), color: cor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(label,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: cor)),
                      ),
                      if (data.isNotEmpty) ...[
                        const Spacer(),
                        Text(data, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(mensagem,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 36, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 12),
            const Text('Tudo em dia!',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 4),
            const Text('Nenhuma notificação pendente',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoErro() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFF9CA3AF)),
              const SizedBox(height: 12),
              Text(_erro!, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Tentar novamente'),
                onPressed: _carregar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRodape() {
    final urgentes = _notifs.where((n) => _isUrgente(n['tipo']?.toString())).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: GridColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (urgentes > 0) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: GridColors.error, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text('$urgentes urgente${urgentes > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GridColors.error)),
            const SizedBox(width: 12),
          ],
          Text('${_notifs.length} total',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

// ─── Botão de sino para usar no AppBar ───────────────────────────────────────
/// Adicione ao AppBar:
///   actions: [NotificacoesSinoButton(empresaId: TenantContext.empresaId)],
/// E ao Scaffold:
///   endDrawer: NotificacoesDrawer(empresaId: TenantContext.empresaId),
class NotificacoesSinoButton extends StatefulWidget {
  final int? empresaId;
  const NotificacoesSinoButton({super.key, this.empresaId});

  @override
  State<NotificacoesSinoButton> createState() => _NotificacoesSinoButtonState();
}

class _NotificacoesSinoButtonState extends State<NotificacoesSinoButton> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _carregarContagem();
  }

  Future<void> _carregarContagem() async {
    try {
      final param = widget.empresaId != null ? '?empresaId=${widget.empresaId}' : '';
      final resp = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/notificacoes$param'),
        headers: TenantContext.headers,
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final List raw = body is List ? body : (body['data'] ?? body['dados'] ?? []);
        if (mounted) setState(() => _count = raw.length);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Notificações',
        onPressed: () => Scaffold.of(context).openEndDrawer(),
      ),
      if (_count > 0)
        Positioned(
          right: 6,
          top: 6,
          child: IgnorePointer(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: GridColors.error, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  _count > 9 ? '9+' : '$_count',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
    ]);
  }
}
