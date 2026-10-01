import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../utils/grid_colors.dart';
import 'package:http/http.dart' as http;
import '../../../../models/auth_utility.dart';
import '../../../../utils/api_links.dart';
import '../../../../widgets/generic_detail_form_screen.dart';
import '../../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;
import '../ged_arquivos_screen.dart';

class WindowsFuncionarioDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const WindowsFuncionarioDetailScreen({super.key, required this.item, required this.hasPermission});

  @override
  State<WindowsFuncionarioDetailScreen> createState() => _WebFuncionarioDetailScreenState();
}

class _WebFuncionarioDetailScreenState extends State<WindowsFuncionarioDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // H5-21: 4 abas — Dados, Ponto, Acerto, GED
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final funcId = widget.item['id'];
    final nome = widget.item['nome']?.toString() ?? 'Funcionário';
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D27),
        title: Text(nome, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GridColors.success,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.person, size: 16), text: 'Dados'),
            Tab(icon: Icon(Icons.access_time, size: 16), text: 'Ponto'),
            Tab(icon: Icon(Icons.calculate, size: 16), text: 'Acerto'),
            Tab(icon: Icon(Icons.folder_open, size: 16), text: 'GED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Dados (form genérico sem overrides — tudo do banco) ──
          GenericDetailFormScreen(
            item: widget.item,
            telaNome: 'funcionario',
            hasPermission: widget.hasPermission,
          ),
          // ── Tab 2: Ponto ──────────────────────────────────────────────
          _PontoTab(funcionarioId: funcId is int ? funcId : int.tryParse(funcId?.toString() ?? '')),
          // ── Tab 3: Acerto de Ponto ────────────────────────────────────
          _AcertoTab(funcionarioId: funcId is int ? funcId : int.tryParse(funcId?.toString() ?? ''), nomeFuncionario: nome),
          // ── Tab 4: GED — documentos do funcionário (H5-21) ───────────
          GedArquivosScreen(
            moduloOrigem: 'funcionario',
            idOrigem: funcId is int ? funcId : int.tryParse(funcId?.toString() ?? ''),
            nomeOrigem: nome,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB PONTO
// ─────────────────────────────────────────────────────────────────────────────

class _PontoTab extends StatefulWidget {
  final int? funcionarioId;
  const _PontoTab({required this.funcionarioId});

  @override
  State<_PontoTab> createState() => _PontoTabState();
}

class _PontoTabState extends State<_PontoTab> {
  DateTime _inicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _fim = DateTime.now();
  List<dynamic> _pontos = [];
  bool _loading = false;
  String? _erro;

  Future<void> _carregar() async {
    if (widget.funcionarioId == null) return;
    setState(() { _loading = true; _erro = null; });
    try {
      final token = AuthUtility.userInfo?.token;
      final url = '${ApiLinks.baseUrl}/api/funcionario/${widget.funcionarioId}/pontos'
          '?inicio=${_inicio.toIso8601String().substring(0, 10)}'
          '&fim=${_fim.toIso8601String().substring(0, 10)}';
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() => _pontos = body is List ? body : []);
      } else {
        setState(() => _erro = 'Erro ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _registrarPonto(String tipo) async {
    if (widget.funcionarioId == null) return;
    try {
      final token = AuthUtility.userInfo?.token;
      final resp = await http.post(
        Uri.parse('${ApiLinks.baseUrl}/api/funcionario/${widget.funcionarioId}/ponto'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'tipo': tipo}),
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ponto $tipo registrado!'), backgroundColor: GridColors.success),
        );
        _carregar();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${resp.body}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botões de batida
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _registrarPonto('ENTRADA'),
                icon: const Icon(Icons.login, size: 16),
                label: const Text('Entrada'),
                style: ElevatedButton.styleFrom(backgroundColor: GridColors.success),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _registrarPonto('SAIDA'),
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Saída'),
                style: ElevatedButton.styleFrom(backgroundColor: GridColors.error),
              ),
              const Spacer(),
              // Filtro de período
              _DateButton(label: 'De: ${_fmt(_inicio)}', onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _inicio,
                    firstDate: DateTime(2020), lastDate: DateTime.now());
                if (d != null) { setState(() => _inicio = d); _carregar(); }
              }),
              const SizedBox(width: 8),
              _DateButton(label: 'Até: ${_fmt(_fim)}', onTap: () async {
                final d = await showDatePicker(context: context, initialDate: _fim,
                    firstDate: DateTime(2020), lastDate: DateTime.now());
                if (d != null) { setState(() => _fim = d); _carregar(); }
              }),
              const SizedBox(width: 8),
              IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading) const Center(child: CircularProgressIndicator(color: GridColors.success)),
          if (_erro != null) Text(_erro!, style: const TextStyle(color: Colors.red)),
          if (!_loading && _erro == null)
            Expanded(
              child: _pontos.isEmpty
                  ? const Center(child: Text('Nenhum registro encontrado.', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: _pontos.length,
                      itemBuilder: (_, i) {
                        final p = _pontos[i] as Map<String, dynamic>;
                        final tipo = p['tipo']?.toString() ?? '';
                        final isEntrada = tipo == 'ENTRADA';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D27),
                            borderRadius: BorderRadius.circular(8),
                            border: Border(left: BorderSide(
                              color: isEntrada ? GridColors.success : const Color(0xFFEF5350),
                              width: 3,
                            )),
                          ),
                          child: Row(
                            children: [
                              Icon(isEntrada ? Icons.login : Icons.logout,
                                  color: isEntrada ? GridColors.success : const Color(0xFFEF5350), size: 18),
                              const SizedBox(width: 10),
                              Text(tipo, style: TextStyle(
                                color: isEntrada ? GridColors.success : const Color(0xFFEF5350),
                                fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(width: 16),
                              Text(p['dataHoraRegistro']?.toString().replaceFirst('T', ' ').substring(0, 16) ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 13)),
                              if (p['observacao'] != null && p['observacao'].toString().isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Text(p['observacao'].toString(),
                                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB ACERTO DE PONTO
// ─────────────────────────────────────────────────────────────────────────────

class _AcertoTab extends StatefulWidget {
  final int? funcionarioId;
  final String nomeFuncionario;
  const _AcertoTab({required this.funcionarioId, required this.nomeFuncionario});

  @override
  State<_AcertoTab> createState() => _AcertoTabState();
}

class _AcertoTabState extends State<_AcertoTab> {
  DateTime _mes = DateTime(DateTime.now().year, DateTime.now().month, 1);
  Map<String, dynamic>? _acerto;
  bool _loading = false;
  String? _erro;

  Future<void> _carregar() async {
    if (widget.funcionarioId == null) return;
    setState(() { _loading = true; _erro = null; _acerto = null; });
    try {
      final token = AuthUtility.userInfo?.token;
      final mesStr = '${_mes.year}-${_mes.month.toString().padLeft(2, '0')}-01';
      final url = '${ApiLinks.baseUrl}/api/funcionario/${widget.funcionarioId}/acerto-ponto?mes=$mesStr';
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (resp.statusCode == 200) {
        setState(() => _acerto = jsonDecode(resp.body) as Map<String, dynamic>);
      } else {
        setState(() => _erro = 'Erro ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _baixarPdf() async {
    if (widget.funcionarioId == null) return;
    try {
      final token = AuthUtility.userInfo?.token;
      final inicio = '${_mes.year}-${_mes.month.toString().padLeft(2, '0')}-01';
      final fim = DateTime(_mes.year, _mes.month + 1, 0);
      final fimStr = '${fim.year}-${fim.month.toString().padLeft(2, '0')}-${fim.day.toString().padLeft(2, '0')}';
      final url = '${ApiLinks.baseUrl}/api/funcionario/${widget.funcionarioId}/ponto/pdf?inicio=$inicio&fim=$fimStr';
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF gerado! (download via browser)'), backgroundColor: GridColors.success),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seletor de mês
          Row(
            children: [
              IconButton(
                onPressed: () { setState(() => _mes = DateTime(_mes.year, _mes.month - 1, 1)); _carregar(); },
                icon: const Icon(Icons.chevron_left, color: Colors.white54),
              ),
              Text('${_mesNome(_mes.month)} / ${_mes.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () { setState(() => _mes = DateTime(_mes.year, _mes.month + 1, 1)); _carregar(); },
                icon: const Icon(Icons.chevron_right, color: Colors.white54),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _baixarPdf,
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white54),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh, color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading) const Center(child: CircularProgressIndicator(color: GridColors.success)),
          if (_erro != null) Text(_erro!, style: const TextStyle(color: Colors.red)),
          if (_acerto != null) ...[
            // Cards de resumo
            _ResumoCards(acerto: _acerto!),
            const SizedBox(height: 16),
            // Tabela de detalhes
            _TabelaDetalhes(detalhes: _acerto!['detalhes'] as List? ?? []),
          ],
        ],
      ),
    );
  }

  String _mesNome(int m) => const ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'][m];
}

class _ResumoCards extends StatelessWidget {
  final Map<String, dynamic> acerto;
  const _ResumoCards({required this.acerto});

  @override
  Widget build(BuildContext context) {
    final saldo = double.tryParse(acerto['saldoBancoHoras']?.toString() ?? '0') ?? 0;
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: [
        _Card('Dias Trabalhados', acerto['totalDiasTrabalhados']?.toString() ?? '0', Icons.calendar_today, const Color(0xFF1565C0)),
        _Card('Horas Trabalhadas', '${acerto['totalHorasTrabalhadas']}h', Icons.access_time, GridColors.success),
        _Card('Horas Extras', '${acerto['totalHorasExtras']}h', Icons.add_alarm, const Color(0xFF6A1B9A)),
        _Card('Horas Falta', '${acerto['totalHorasFalta']}h', Icons.alarm_off, GridColors.error),
        _Card('Banco de Horas', '${acerto['saldoBancoHoras']}h', Icons.account_balance,
            saldo >= 0 ? GridColors.success : GridColors.error),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Card(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D27),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }
}

class _TabelaDetalhes extends StatelessWidget {
  final List detalhes;
  const _TabelaDetalhes({required this.detalhes});

  @override
  Widget build(BuildContext context) {
    if (detalhes.isEmpty) return const Text('Sem registros.', style: TextStyle(color: Colors.white54));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Detalhamento Diário', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D27),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(100),
              1: FixedColumnWidth(80),
              2: FlexColumnWidth(),
              3: FixedColumnWidth(80),
              4: FixedColumnWidth(80),
              5: FixedColumnWidth(80),
            },
            children: [
              _headerRow(),
              ...detalhes.map((d) => _dataRow(d as Map<String, dynamic>)),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _headerRow() => TableRow(
    decoration: const BoxDecoration(color: Color(0xFF252836)),
    children: ['Data', 'Dia', 'Batidas', 'Trabalhado', 'Extra', 'Falta']
        .map((h) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(h, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            ))
        .toList(),
  );

  TableRow _dataRow(Map<String, dynamic> d) {
    final fimSemana = d['fimDeSemana'] == true;
    final extra = double.tryParse(d['horasExtras']?.toString() ?? '0') ?? 0;
    final falta = double.tryParse(d['horasFalta']?.toString() ?? '0') ?? 0;
    final batidas = (d['batidas'] as List?)?.join(' | ') ?? '';
    return TableRow(
      decoration: BoxDecoration(
        color: fimSemana ? const Color(0xFF1A1D27).withValues(alpha: 0.5) : Colors.transparent,
      ),
      children: [
        _cell(d['data']?.toString() ?? '', fimSemana ? Colors.white38 : Colors.white70),
        _cell(d['diaSemana']?.toString().substring(0, 3) ?? '', fimSemana ? Colors.white38 : Colors.white54),
        _cell(batidas, Colors.white70),
        _cell('${d['horasTrabalhadas']}h', Colors.white),
        _cell('${d['horasExtras']}h', extra > 0 ? GridColors.success : Colors.white38),
        _cell('${d['horasFalta']}h', falta > 0 ? const Color(0xFFEF5350) : Colors.white38),
      ],
    );
  }

  Widget _cell(String text, Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: Text(text, style: TextStyle(color: color, fontSize: 12)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _DateButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _DateButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D27),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ),
    );
  }
}
