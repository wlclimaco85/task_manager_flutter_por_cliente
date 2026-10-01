import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';

// ── Cores do sistema ──────────────────────────────────────────────────────────
class _K {
  static const bg = Color(0xFFF5F5F5);
  static const primary = GridColors.primary;
  static const green = GridColors.secondary;
  static const white = Colors.white;
  static const border = Color(0xFFDDDDDD);
  static const textDark = Color(0xFF212121);
  static const textGrey = Color(0xFF757575);
}

// ── Colunas do Kanban ────────────────────────────────────────────────────────
class _Col {
  final String status;
  final String label;
  final Color color;
  final IconData icon;
  const _Col(this.status, this.label, this.color, this.icon);
}

const _cols = [
  _Col('PENDENTE', 'Pendente', Color(0xFFFF9800), Icons.schedule),
  _Col('APROVADO', 'Aprovado', Color(0xFF1565C0), Icons.check_circle_outline),
  _Col('PAGO', 'Pago', GridColors.success, Icons.paid),
  _Col('CANCELADO', 'Cancelado', Color(0xFF6A1B9A), Icons.cancel_outlined),
];

// ── Valores válidos para transição ───────────────────────────────────────────
const _transicoesValidas = {
  'PENDENTE': ['APROVADO', 'CANCELADO'],
  'APROVADO': ['PAGO', 'CANCELADO'],
  'PAGO': [],
  'CANCELADO': [],
};

// ─────────────────────────────────────────────────────────────────────────────
class KanbanPagamentosScreen extends StatefulWidget {
  const KanbanPagamentosScreen({super.key});
  @override
  State<KanbanPagamentosScreen> createState() => _KanbanPagamentosScreenState();
}

class _KanbanPagamentosScreenState extends State<KanbanPagamentosScreen> {
  List<Map<String, dynamic>> _contas = [];
  bool _loading = true;
  String? _erro;
  bool _movendo = false;
  String? _filtroTipo; // PAGAR ou RECEBER

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
      // Busca contas a pagar e receber
      final respPagar = await TenantContext.get(ApiLinks.allContasPagar);
      final respReceber = await TenantContext.get(ApiLinks.allContasReceber);

      final List<Map<String, dynamic>> todas = [];

      if (respPagar.statusCode == 200) {
        final body = jsonDecode(respPagar.body);
        List lista = _extrairLista(body);
        for (final e in lista) {
          if (e is Map) {
            final m = Map<String, dynamic>.from(e);
            m['_tipo'] = 'PAGAR';
            todas.add(m);
          }
        }
      }

      if (respReceber.statusCode == 200) {
        final body = jsonDecode(respReceber.body);
        List lista = _extrairLista(body);
        for (final e in lista) {
          if (e is Map) {
            final m = Map<String, dynamic>.from(e);
            m['_tipo'] = 'RECEBER';
            todas.add(m);
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _contas = todas;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.toString();
        _loading = false;
      });
    }
  }

  List _extrairLista(dynamic body) {
    if (body is Map) {
      final d = body['data'];
      if (d is List) return d;
      if (d is Map) return d['dados'] ?? d['content'] ?? [];
      return body['content'] ?? body['dados'] ?? [];
    }
    if (body is List) return body;
    return [];
  }

  List<Map<String, dynamic>> get _contasFiltradas {
    if (_filtroTipo == null) return _contas;
    return _contas.where((c) => c['_tipo'] == _filtroTipo).toList();
  }

  List<Map<String, dynamic>> _porStatus(String status) {
    return _contasFiltradas.where((c) {
      final s = (c['status'] ?? '').toString().toUpperCase();
      return s == status;
    }).toList();
  }

  Future<void> _moverConta(Map<String, dynamic> conta, String novoStatus) async {
    if (_movendo) return;

    // Valida transição
    final statusAtual = (conta['status'] ?? '').toString().toUpperCase();
    final permitidos = _transicoesValidas[statusAtual] ?? [];
    if (!permitidos.contains(novoStatus)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Transição de $statusAtual para $novoStatus não permitida'),
          backgroundColor: GridColors.error,
        ));
      }
      return;
    }

    // Se movendo para PAGO, mostra dialog para dataPagamento
    String? dataPagamento;
    if (novoStatus == 'PAGO') {
      dataPagamento = await _showDataPagamentoDialog();
      if (dataPagamento == null) return; // Cancelou
    }

    setState(() => _movendo = true);
    try {
      final id = conta['id'];
      final tipo = conta['_tipo'];
      final url = tipo == 'PAGAR'
          ? ApiLinks.contaPagarStatus('$id')
          : ApiLinks.contaReceberStatus('$id');

      final payload = <String, dynamic>{
        'status': novoStatus,
        if (dataPagamento != null) 'dataPagamento': dataPagamento,
      };

      final resp = await TenantContext.put(url, payload);
      if (!mounted) return;

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _carregar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Conta movida para ${_cols.firstWhere((c) => c.status == novoStatus).label}'),
          backgroundColor: GridColors.success,
          duration: const Duration(seconds: 2),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao mover: ${resp.statusCode}'),
          backgroundColor: GridColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: GridColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _movendo = false);
    }
  }

  Future<String?> _showDataPagamentoDialog() async {
    DateTime dataSelecionada = DateTime.now();
    final result = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data do Pagamento'),
        content: CalendarDatePicker(
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
          onDateChanged: (d) => dataSelecionada = d,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, dataSelecionada),
            style: ElevatedButton.styleFrom(backgroundColor: GridColors.success),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (result == null) return null;
    return '${result.year}-${result.month.toString().padLeft(2, '0')}-${result.day.toString().padLeft(2, '0')}';
  }

  String _fmtData(String? d) {
    if (d == null || d.length < 10) return '-';
    return d.substring(0, 10);
  }

  String _fmtValor(dynamic v) {
    final valor = (v is num) ? v.toDouble() : 0.0;
    return 'R\$${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _K.bg,
      appBar: AppBar(
        backgroundColor: _K.primary,
        foregroundColor: _K.white,
        elevation: 2,
        title: const Row(children: [
          Icon(Icons.view_kanban, size: 20),
          SizedBox(width: 8),
          Text('Kanban — Pagamentos', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          if (_movendo)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            ),
          // Filtro tipo
          PopupMenuButton<String?>(
            tooltip: 'Filtrar por tipo',
            onSelected: (v) => setState(() => _filtroTipo = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('Todos')),
              const PopupMenuItem(value: 'PAGAR', child: Text('Contas a Pagar')),
              const PopupMenuItem(value: 'RECEBER', child: Text('Contas a Receber')),
            ],
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.filter_list, size: 18),
                const SizedBox(width: 4),
                Text(_filtroTipo ?? 'Todos', style: const TextStyle(fontSize: 12)),
              ]),
            ),
          ),
          IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh), tooltip: 'Recarregar'),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(children: [
        Column(children: [
          _buildBadges(),
          if (_loading) LinearProgressIndicator(color: _K.primary, backgroundColor: _K.primary.withValues(alpha: 0.2)),
          if (_erro != null)
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(8),
              child: Text(_erro!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(child: _buildBoard()),
        ]),
        if (_movendo)
          Container(
            color: Colors.black.withValues(alpha: 0.15),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(color: _K.primary),
                    SizedBox(height: 12),
                    Text('Movendo conta...', style: TextStyle(color: _K.textDark)),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildBadges() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: _K.white,
        border: Border(bottom: BorderSide(color: _K.border)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: _K.primary, borderRadius: BorderRadius.circular(4)),
          child: const Text('KANBAN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        const SizedBox(width: 12),
        ..._cols.map((col) {
          final count = _porStatus(col.status).length;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _badge(col.label, count, col.color),
          );
        }),
        const Spacer(),
        Text('Total: ${_contasFiltradas.length}', style: const TextStyle(color: _K.textGrey, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _badge(String label, int count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$count $label', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );

  Widget _buildBoard() {
    if (_contasFiltradas.isEmpty && !_loading) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_outlined, size: 64, color: _K.textGrey.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          const Text('Nenhum pagamento encontrado', style: TextStyle(color: _K.textGrey, fontSize: 16)),
        ]),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _cols.map((col) => _buildColuna(col)).toList(),
      ),
    );
  }

  Widget _buildColuna(_Col col) {
    final itens = _porStatus(col.status);
    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (d) => _moverConta(d.data, col.status),
      builder: (ctx, candidatos, _) {
        final hover = candidatos.isNotEmpty;
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 12),
          constraints: const BoxConstraints(minHeight: 200),
          decoration: BoxDecoration(
            color: hover ? col.color.withValues(alpha: 0.06) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hover ? col.color : _K.border,
              width: hover ? 1.5 : 1,
            ),
          ),
          child: Column(children: [
            // Header coluna
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: col.color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                ),
                border: Border(bottom: BorderSide(color: col.color.withValues(alpha: 0.3))),
              ),
              child: Row(children: [
                Icon(col.icon, size: 16, color: col.color),
                const SizedBox(width: 6),
                Text(col.label, style: TextStyle(color: col.color, fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: col.color, borderRadius: BorderRadius.circular(10)),
                  child: Text('${itens.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            // Cards
            if (itens.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Vazio', style: TextStyle(color: _K.textGrey.withValues(alpha: 0.5), fontSize: 12)),
              )
            else
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: itens.map((conta) => _PagamentoCard(
                    conta: conta,
                    accentColor: col.color,
                    onMoved: () => _carregar(),
                  )).toList(),
                ),
              ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARD DE PAGAMENTO
// ─────────────────────────────────────────────────────────────────────────────
class _PagamentoCard extends StatelessWidget {
  final Map<String, dynamic> conta;
  final Color accentColor;
  final VoidCallback onMoved;

  const _PagamentoCard({
    required this.conta,
    required this.accentColor,
    required this.onMoved,
  });

  String get _descricao => conta['descricao']?.toString() ?? 'Sem descrição';
  String get _tipo => conta['_tipo']?.toString() ?? 'PAGAR';
  String get _vencimento => conta['dataVencimento']?.toString().substring(0, 10) ?? '-';
  dynamic get _valor => conta['valor'] ?? 0;
  String get _status => (conta['status'] ?? '').toString();
  int? get _id => conta['id'] is int ? conta['id'] as int : int.tryParse('${conta['id']}');
  String? get _parceiro {
    final p = conta['parceiro'];
    if (p is Map) return p['nome']?.toString();
    return conta['parceiroNome']?.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<Map<String, dynamic>>(
      data: conta,
      feedback: Material(color: Colors.transparent, child: SizedBox(width: 264, child: _card(dragging: true))),
      childWhenDragging: Opacity(opacity: 0.3, child: _card()),
      child: _card(),
    );
  }

  Widget _card({bool dragging = false}) {
    final tipoColor = _tipo == 'PAGAR' ? GridColors.error : GridColors.success;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: dragging ? const Color(0xFFF0F0F0) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border(left: BorderSide(color: accentColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: dragging ? Colors.black26 : Colors.black.withValues(alpha: 0.06),
            blurRadius: dragging ? 8 : 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Linha 1: ID + Tipo
        Row(children: [
          if (_id != null)
            Text('#$_id', style: const TextStyle(color: _K.textGrey, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: tipoColor, borderRadius: BorderRadius.circular(3)),
            child: Text(_tipo, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          if (_status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Text(_status, style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.w600)),
            ),
        ]),
        const SizedBox(height: 6),
        // Descrição
        Text(
          _descricao,
          style: const TextStyle(color: _K.textDark, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        // Parceiro
        if (_parceiro != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.person_outline, size: 10, color: _K.textGrey),
            const SizedBox(width: 3),
            Expanded(child: Text(_parceiro!, style: const TextStyle(color: _K.textGrey, fontSize: 10), overflow: TextOverflow.ellipsis)),
          ]),
        ],
        const SizedBox(height: 6),
        // Valor + Vencimento
        Row(children: [
          const Icon(Icons.attach_money, size: 12, color: GridColors.success),
          const SizedBox(width: 2),
          Text(
            'R\$${(_valor is num ? _valor.toDouble() : 0.0).toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(color: tipoColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          const Icon(Icons.calendar_today, size: 10, color: _K.textGrey),
          const SizedBox(width: 2),
          Text(_vencimento, style: const TextStyle(color: _K.textGrey, fontSize: 10)),
        ]),
      ]),
    );
  }
}
