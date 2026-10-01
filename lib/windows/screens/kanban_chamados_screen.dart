import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../../models/chamado_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../utils/grid_texts.dart';

// ── Cores do sistema ──────────────────────────────────────────────────────────
class _K {
  static const bg       = Color(0xFFF5F5F5);
  static const primary  = GridColors.primary;
  static const green    = GridColors.secondary;
  static const white    = Colors.white;
  static const border   = Color(0xFFDDDDDD);
  static const textDark = Color(0xFF212121);
  static const textGrey = Color(0xFF757575);
  static const sectorBg = Color(0xFFEEEEEE);
}

// ── Colunas ───────────────────────────────────────────────────────────────────
class _Col {
  final String status, label;
  final Color color;
  const _Col(this.status, this.label, this.color);
}
const _cols = [
  _Col('ABERTO',       'Aberto',       Color(0xFF1565C0)),
  _Col('EM_ANDAMENTO', 'Em Andamento', Color(0xFFE65100)),
  _Col('FECHADO',      'Fechado',      GridColors.success),
  _Col('CANCELADO',    'Cancelado',    Color(0xFF6A1B9A)),
];

// ── Modelo interno com dados extras do JSON bruto ─────────────────────────────
class _ChamadoRaw {
  final Chamado chamado;
  final String? usuarioId;
  final String? usuarioNome;
  final String? setorId;
  final String? setorNome;
  _ChamadoRaw({required this.chamado, this.usuarioId, this.usuarioNome, this.setorId, this.setorNome});
}

// ─────────────────────────────────────────────────────────────────────────────
class KanbanChamadosScreen extends StatefulWidget {
  const KanbanChamadosScreen({super.key});
  @override
  State<KanbanChamadosScreen> createState() => _KanbanChamadosScreenState();
}

class _KanbanChamadosScreenState extends State<KanbanChamadosScreen> {
  List<_ChamadoRaw> _todos = [];
  bool _loading = true;
  String? _erro;
  String? _filtroUsuario;
  String? _filtroSetor;
  String? _filtroPrioridade;
  bool _movendo = false;
  // setores colapsados — vazio = todos abertos
  final Set<String> _colapsados = {};

  @override
  void initState() { super.initState(); _carregar(); }

  // ── Carrega chamados preservando dados brutos do JSON ─────────────────────
  Future<void> _carregar() async {
    setState(() { _loading = true; _erro = null; });
    try {
      var url = '${ApiLinks.baseUrl}/api/chamados?tamanho=500';
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body is Map) {
          final d = body['data'];
          if (d is List) { lista = d; }
          else if (d is Map) { lista = d['dados'] ?? d['content'] ?? []; }
        }
        final raws = <_ChamadoRaw>[];
        for (final e in lista.whereType<Map>()) {
          try {
            final m = Map<String, dynamic>.from(e);
            final c = Chamado.fromJson(m);
            // Extrai usuário e setor do JSON bruto (podem vir como objeto ou null)
            final uRaw = m['usuarioAbertura'];
            final sRaw = m['setor'];
            final uid = uRaw is Map ? uRaw['id']?.toString() : c.usuarioAbertura?.id?.toString();
            final unome = uRaw is Map ? (uRaw['nome'] ?? uRaw['email'])?.toString() : c.usuarioAbertura?.nome;
            final sid = sRaw is Map ? sRaw['id']?.toString() : c.setor?.id?.toString();
            final snome = sRaw is Map ? (sRaw['nome'] ?? sRaw['descricao'])?.toString() : c.setor?.nome;
            raws.add(_ChamadoRaw(chamado: c, usuarioId: uid, usuarioNome: unome, setorId: sid, setorNome: snome));
          } catch (_) {}
        }
        setState(() {
          _todos = raws;
          if (_filtroUsuario != null && !_usuariosComChamados.any((u) => u['id'] == _filtroUsuario)) _filtroUsuario = null;
          if (_filtroSetor != null && !_setoresComChamados.any((s) => s['id'] == _filtroSetor)) _filtroSetor = null;
        });
      } else {
        setState(() => _erro = 'Erro ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Filtros derivados dos dados brutos ────────────────────────────────────
  List<Map<String, String>> get _usuariosComChamados {
    final seen = <String>{};
    final result = <Map<String, String>>[];
    for (final r in _todos) {
      if (r.usuarioId != null && seen.add(r.usuarioId!)) {
        result.add({'id': r.usuarioId!, 'nome': r.usuarioNome ?? r.usuarioId!});
      }
    }
    result.sort((a, b) => a['nome']!.compareTo(b['nome']!));
    return result;
  }

  List<Map<String, String>> get _setoresComChamados {
    final seen = <String>{};
    final result = <Map<String, String>>[];
    for (final r in _todos) {
      if (r.setorId != null && seen.add(r.setorId!)) {
        result.add({'id': r.setorId!, 'nome': r.setorNome ?? r.setorId!});
      }
    }
    result.sort((a, b) => a['nome']!.compareTo(b['nome']!));
    return result;
  }

  List<_ChamadoRaw> get _filtrados => _todos.where((r) {
    if (_filtroUsuario != null && r.usuarioId != _filtroUsuario) return false;
    if (_filtroSetor != null && r.setorId != _filtroSetor) return false;
    if (_filtroPrioridade != null && r.chamado.prioridade.name != _filtroPrioridade) return false;
    return true;
  }).toList();

  List<Map<String, String>> get _setoresFiltrados {
    final seen = <String>{};
    final result = <Map<String, String>>[];
    for (final r in _filtrados) {
      final id = r.setorId ?? '__sem_setor__';
      final nome = r.setorNome ?? 'Sem Setor';
      if (seen.add(id)) result.add({'id': id, 'nome': nome});
    }
    result.sort((a, b) => a['nome']!.compareTo(b['nome']!));
    return result;
  }

  List<_ChamadoRaw> _porSetorEStatus(String setorId, String status) =>
      _filtrados.where((r) {
        final sid = r.setorId ?? '__sem_setor__';
        return sid == setorId && r.chamado.status.name == status;
      }).toList();

  // ── Move chamado (drag & drop) ────────────────────────────────────────────
  Future<void> _moverChamado(_ChamadoRaw raw, String novoStatus) async {
    if (_movendo) return;
    setState(() => _movendo = true);
    try {
      final c = raw.chamado;
      final payload = <String, dynamic>{
        'id': c.id,
        'titulo': c.titulo,
        'descricao': c.descricao,
        'status': novoStatus,
        'prioridade': c.prioridade.name,
        'empresa': {'id': c.empresa.id},
        'dataAbertura': c.dataAbertura.toIso8601String(),
        if (raw.setorId != null && raw.setorId!.isNotEmpty && raw.setorId != '__sem_setor__')
          'setor': {'id': int.tryParse(raw.setorId!) ?? raw.setorId},
        if (c.parceiro?.id != null) 'parceiro': {'id': c.parceiro!.id},
        if (c.usuarioAbertura?.id != null) 'usuarioAbertura': {'id': c.usuarioAbertura!.id},
      };
      final resp = await TenantContext.put('${ApiLinks.baseUrl}/api/chamados/${c.id}', payload);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _carregar();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Chamado #${c.id} movido para ${_cols.firstWhere((col) => col.status == novoStatus).label}'),
            backgroundColor: _K.green,
            duration: const Duration(seconds: 2),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao mover: ${resp.statusCode}'), backgroundColor: _K.primary));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: _K.primary));
      }
    } finally {
      setState(() => _movendo = false);
    }
  }

  // ── Abre dialog de edição rápida ──────────────────────────────────────────
  void _editarChamado(_ChamadoRaw raw) {
    showDialog(
      context: context,
      builder: (_) => _EditDialog(
        raw: raw,
        onSaved: () {
          // Mostra loading e recarrega
          setState(() => _loading = true);
          _carregar();
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
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
          Text('Kanban — Chamados', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          if (_movendo) const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
          IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh), tooltip: 'Recarregar'),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(children: [
        Column(children: [
          _buildFiltros(),
          if (_loading) LinearProgressIndicator(color: _K.primary, backgroundColor: _K.primary.withValues(alpha: 0.2)),
          if (_erro != null) Container(color: Colors.red.shade50, padding: const EdgeInsets.all(8),
              child: Text(_erro!, style: const TextStyle(color: Colors.red))),
          Expanded(child: _buildBoard()),
        ]),
        // Loading overlay durante movimentação
        if (_movendo) Container(
          color: Colors.black.withValues(alpha: 0.15),
          child: const Center(child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: _K.primary),
                SizedBox(height: 12),
                Text('Movendo chamado...', style: TextStyle(color: _K.textDark)),
              ]),
            ),
          )),
        ),
      ]),
    );
  }

  // ── Filtros ───────────────────────────────────────────────────────────────
  Widget _buildFiltros() {
    final total = _filtrados.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: _K.white,
        border: Border(bottom: BorderSide(color: _K.border)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: _K.primary, borderRadius: BorderRadius.circular(4)),
          child: const Text('FILTROS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        _filterBtn(Icons.person_outline, 'Usuário', _filtroUsuario, _usuariosComChamados, (v) => setState(() => _filtroUsuario = v)),
        _filterBtn(Icons.business_outlined, 'Setor', _filtroSetor, _setoresComChamados, (v) => setState(() => _filtroSetor = v)),
        _filterBtn(Icons.flag_outlined, 'Prioridade', _filtroPrioridade,
          PrioridadeChamadoEnum.values.map((e) => {'id': e.name, 'nome': e.label}).toList(),
          (v) => setState(() => _filtroPrioridade = v)),
        if (_filtroUsuario != null || _filtroSetor != null || _filtroPrioridade != null)
          TextButton.icon(
            onPressed: () => setState(() { _filtroUsuario = null; _filtroSetor = null; _filtroPrioridade = null; }),
            icon: const Icon(Icons.clear, size: 14),
            label: const Text('Limpar', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: _K.primary),
          ),
        ..._cols.map((col) {
          final count = _filtrados.where((r) => r.chamado.status.name == col.status).length;
          return _badge(col.label, count, col.color);
        }),
        Text('Total: $total', style: const TextStyle(color: _K.textGrey, fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _filterBtn(IconData icon, String label, String? value, List<Map<String, dynamic>> items, void Function(String?) cb) {
    final active = value != null;
    final display = active ? (items.firstWhere((i) => i['id']?.toString() == value, orElse: () => {'nome': label})['nome'] ?? label) : label;
    return PopupMenuButton<String>(
      tooltip: label, color: Colors.white, elevation: 4, offset: const Offset(0, 36),
      onSelected: (v) => cb(v.isEmpty ? null : v),
      itemBuilder: (_) => [
        const PopupMenuItem(value: '', child: Text('Todos', style: TextStyle(color: _K.textGrey, fontSize: 13))),
        const PopupMenuDivider(),
        ...items.map((i) => PopupMenuItem(value: i['id']?.toString() ?? '', child: Text(i['nome']?.toString() ?? '', style: const TextStyle(color: _K.textDark, fontSize: 13)))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? _K.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? _K.primary : _K.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? _K.primary : _K.textGrey),
          const SizedBox(width: 5),
          Text(display.toString(), style: TextStyle(color: active ? _K.primary : _K.textGrey, fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
          const SizedBox(width: 3),
          Icon(Icons.arrow_drop_down, size: 16, color: active ? _K.primary : _K.textGrey),
        ]),
      ),
    );
  }

  Widget _badge(String label, int count, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text('$count $label', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );

  // ── Board ─────────────────────────────────────────────────────────────────
  Widget _buildBoard() {
    final setores = _setoresFiltrados;
    if (setores.isEmpty && !_loading) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.inbox_outlined, size: 64, color: _K.textGrey.withValues(alpha: 0.4)),
      const SizedBox(height: 12),
      const Text('Nenhum chamado encontrado', style: TextStyle(color: _K.textGrey, fontSize: 16)),
    ]));
    }
    return SingleChildScrollView(child: Column(children: setores.map(_buildSetorRow).toList()));
  }

  Widget _buildSetorRow(Map<String, String> setor) {
    final setorId = setor['id']!;
    final setorNome = setor['nome']!;
    final total = _filtrados.where((r) => (r.setorId ?? '__sem_setor__') == setorId).length;
    final colapsado = _colapsados.contains(setorId);
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(color: _K.white, border: Border(bottom: BorderSide(color: _K.border))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header setor — clicável para colapsar/expandir
        InkWell(
          onTap: () => setState(() {
            if (colapsado) {
              _colapsados.remove(setorId);
            } else {
              _colapsados.add(setorId);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _K.sectorBg,
            child: Row(children: [
              Container(width: 4, height: 16, decoration: BoxDecoration(color: _K.green, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Text(setorNome, style: const TextStyle(color: _K.green, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: _K.green, borderRadius: BorderRadius.circular(10)),
                child: Text('$total', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              Icon(
                colapsado ? Icons.expand_more : Icons.expand_less,
                size: 18,
                color: _K.green,
              ),
            ]),
          ),
        ),
        // Colunas — visíveis só quando expandido
        if (!colapsado)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: _cols.map((col) => _buildColuna(col, setorId)).toList()),
          ),
      ]),
    );
  }

  Widget _buildColuna(_Col col, String setorId) {
    final raws = _porSetorEStatus(setorId, col.status);
    return DragTarget<_ChamadoRaw>(
      onAcceptWithDetails: (d) => _moverChamado(d.data, col.status),
      builder: (ctx, candidatos, _) {
        final hover = candidatos.isNotEmpty;
        return Container(
          width: 230,
          margin: const EdgeInsets.only(right: 8),
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            color: hover ? col.color.withValues(alpha: 0.06) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: hover ? col.color : _K.border, width: hover ? 1.5 : 1),
          ),
          child: Column(children: [
            // Header coluna
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: col.color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                border: Border(bottom: BorderSide(color: col.color.withValues(alpha: 0.3))),
              ),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: col.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(col.label, style: TextStyle(color: col.color, fontWeight: FontWeight.w600, fontSize: 12)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: col.color, borderRadius: BorderRadius.circular(10)),
                  child: Text('${raws.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            // Cards
            if (raws.isEmpty)
              Padding(padding: const EdgeInsets.all(12),
                child: Text('Vazio', style: TextStyle(color: _K.textGrey.withValues(alpha: 0.5), fontSize: 11)))
            else
              Padding(padding: const EdgeInsets.all(6),
                child: Column(children: raws.map((r) => _KanbanCard(raw: r, accentColor: col.color, onEdit: () => _editarChamado(r))).toList())),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KANBAN CARD
// ─────────────────────────────────────────────────────────────────────────────
class _KanbanCard extends StatelessWidget {
  final _ChamadoRaw raw;
  final Color accentColor;
  final VoidCallback onEdit;
  const _KanbanCard({required this.raw, required this.accentColor, required this.onEdit});

  Color get _priorCor {
    switch (raw.chamado.prioridade) {
      case PrioridadeChamadoEnum.URGENTE: return GridColors.error;
      case PrioridadeChamadoEnum.ALTA:    return const Color(0xFFE64A19);
      case PrioridadeChamadoEnum.MEDIA:   return const Color(0xFFF9A825);
      default:                            return const Color(0xFF388E3C);
    }
  }

  String get _tempo {
    final diff = DateTime.now().difference(raw.chamado.dataAbertura);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    return '${diff.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<_ChamadoRaw>(
      data: raw,
      feedback: Material(color: Colors.transparent, child: SizedBox(width: 218, child: _card(dragging: true))),
      childWhenDragging: Opacity(opacity: 0.3, child: _card()),
      child: _card(),
    );
  }

  Widget _card({bool dragging = false}) {
    final c = raw.chamado;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: dragging ? const Color(0xFFF0F0F0) : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border(left: BorderSide(color: _priorCor, width: 3)),
        boxShadow: [BoxShadow(color: dragging ? Colors.black26 : Colors.black.withValues(alpha: 0.06), blurRadius: dragging ? 8 : 2, offset: const Offset(0, 1))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Linha 1: ID + prioridade + tempo + editar
        Row(children: [
          Text('#${c.id}', style: const TextStyle(color: _K.textGrey, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(color: _priorCor, borderRadius: BorderRadius.circular(3)),
            child: Text(c.prioridade.label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          const Icon(Icons.access_time, size: 10, color: _K.textGrey),
          const SizedBox(width: 2),
          Text(_tempo, style: const TextStyle(color: _K.textGrey, fontSize: 10)),
          const SizedBox(width: 4),
          // Botão editar
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: _K.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(3)),
              child: const Icon(Icons.edit, size: 11, color: _K.primary),
            ),
          ),
        ]),
        const SizedBox(height: 5),
        // Título
        Text(c.titulo, style: const TextStyle(color: _K.textDark, fontSize: 12, fontWeight: FontWeight.w500, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
        // Parceiro
        if (raw.chamado.parceiro?.nome != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.person_outline, size: 10, color: _K.textGrey),
            const SizedBox(width: 3),
            Expanded(child: Text(raw.chamado.parceiro!.nome!, style: const TextStyle(color: _K.textGrey, fontSize: 10), overflow: TextOverflow.ellipsis)),
          ]),
        ],
        // Usuário responsável (do JSON bruto)
        if (raw.usuarioNome != null) ...[
          const SizedBox(height: 4),
          Row(children: [
            CircleAvatar(radius: 8, backgroundColor: accentColor.withValues(alpha: 0.2),
              child: Text(raw.usuarioNome!.substring(0, 1).toUpperCase(), style: TextStyle(color: accentColor, fontSize: 8, fontWeight: FontWeight.bold))),
            const SizedBox(width: 4),
            Expanded(child: Text(raw.usuarioNome!, style: const TextStyle(color: _K.textGrey, fontSize: 10), overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG DE EDIÇÃO RÁPIDA
// ─────────────────────────────────────────────────────────────────────────────
class _EditDialog extends StatefulWidget {
  final _ChamadoRaw raw;
  final VoidCallback onSaved;
  const _EditDialog({required this.raw, required this.onSaved});
  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late String _status;
  late String _prioridade;
  late TextEditingController _tituloCtrl;
  late TextEditingController _descCtrl;
  bool _saving = false;
  List<Map<String, dynamic>> _setores = [];
  String? _setorId;

  @override
  void initState() {
    super.initState();
    _status = widget.raw.chamado.status.name;
    _prioridade = widget.raw.chamado.prioridade.name;
    _setorId = widget.raw.setorId;
    _tituloCtrl = TextEditingController(text: widget.raw.chamado.titulo);
    _descCtrl = TextEditingController(text: widget.raw.chamado.descricao);
    _carregarSetores();
  }

  Future<void> _carregarSetores() async {
    try {
      final resp = await TenantContext.get('${ApiLinks.baseUrl}/api/setor?tamanho=200');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body is Map) {
          final d = body['data'];
          if (d is List) { lista = d; }
          else if (d is Map) { lista = d['dados'] ?? d['content'] ?? []; }
        }
        setState(() => _setores = lista.whereType<Map>()
            .map((e) => {'id': e['id']?.toString() ?? '', 'nome': e['descricao']?.toString() ?? e['nome']?.toString() ?? ''})
            .where((e) => e['id']!.isNotEmpty)
            .toList());
      }
    } catch (_) {}
  }

  Future<void> _salvar() async {
    setState(() => _saving = true);
    try {
      final c = widget.raw.chamado;
      final payload = <String, dynamic>{
        'id': c.id, 'titulo': _tituloCtrl.text, 'descricao': _descCtrl.text,
        'status': _status, 'prioridade': _prioridade,
        'empresa': {'id': c.empresa.id},
        'dataAbertura': c.dataAbertura.toIso8601String(),
        if (_setorId != null && _setorId!.isNotEmpty) 'setor': {'id': int.tryParse(_setorId!) ?? _setorId},
        if (c.parceiro?.id != null) 'parceiro': {'id': c.parceiro!.id},
        if (c.usuarioAbertura?.id != null) 'usuarioAbertura': {'id': c.usuarioAbertura!.id},
      };
      final resp = await TenantContext.put('${ApiLinks.baseUrl}/api/chamados/${c.id}', payload);
      if (!mounted) return;
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        // Fecha o dialog primeiro
        Navigator.pop(context);
        // Depois recarrega e mostra snackbar
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Chamado #${c.id} atualizado com sucesso!'),
          backgroundColor: _K.green,
          duration: const Duration(seconds: 2),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao salvar: ${resp.statusCode} — ${resp.body.length > 100 ? resp.body.substring(0, 100) : resp.body}'),
          backgroundColor: _K.primary,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _K.primary));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: _K.primary, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text('Chamado #${widget.raw.chamado.id}', style: const TextStyle(color: _K.primary, fontSize: 16, fontWeight: FontWeight.bold)),
      ]),
      content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Título
        TextField(controller: _tituloCtrl, decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
        const SizedBox(height: 12),
        // Descrição
        TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10))),
        const SizedBox(height: 12),
        // Status + Prioridade
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            items: _cols.map((c) => DropdownMenuItem(value: c.status, child: Text(c.label))).toList(),
            onChanged: (v) => setState(() => _status = v!),
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<String>(
            initialValue: _prioridade,
            decoration: const InputDecoration(labelText: 'Prioridade', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
            items: PrioridadeChamadoEnum.values.map((e) => DropdownMenuItem(value: e.name, child: Text(e.label))).toList(),
            onChanged: (v) => setState(() => _prioridade = v!),
          )),
        ]),
        const SizedBox(height: 12),
        // Setor
        DropdownButtonFormField<String>(
          initialValue: _setores.any((s) => s['id'] == _setorId) ? _setorId : null,
          decoration: const InputDecoration(labelText: 'Setor', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
          hint: _setores.isEmpty ? const Text('Carregando...') : const Text('Selecione o setor'),
          items: [
            const DropdownMenuItem<String>(value: null, child: Text('— Sem setor —')),
            ..._setores.map((s) => DropdownMenuItem<String>(value: s['id'], child: Text(s['nome'] ?? ''))),
          ],
          onChanged: (v) => setState(() => _setorId = v),
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(GridTexts.cancel)),
        ElevatedButton.icon(
          onPressed: _saving ? null : _salvar,
          icon: _saving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save, size: 14),
          label: Text(_saving ? 'Salvando...' : 'Salvar'),
          style: ElevatedButton.styleFrom(backgroundColor: _K.primary, foregroundColor: Colors.white),
        ),
      ],
    );
  }
}
