import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/carteira_models.dart';
import '../services/carteira_repository.dart';

class CarteiraScreen extends StatefulWidget {
  const CarteiraScreen({super.key});

  @override
  State<CarteiraScreen> createState() => _CarteiraScreenState();
}

class _CarteiraScreenState extends State<CarteiraScreen> {
  final _repo = CarteiraRepository();
  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _fmtPct = NumberFormat('+#,##0.00;-#,##0.00', 'pt_BR');

  CarteiraResumo? _carteira;
  List<OperacaoAcao> _operacoes = [];
  List<CorretoraInvestimento> _corretoras = [];
  bool _loading = true;
  String? _erro;
  int _touchedIndex = -1;

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
      final results = await Future.wait([
        _repo.fetchCarteira(),
        _repo.fetchOperacoes(),
        _repo.fetchCorretoras(),
      ]);
      setState(() {
        _carteira = results[0] as CarteiraResumo;
        _operacoes = results[1] as List<OperacaoAcao>;
        _corretoras = results[2] as List<CorretoraInvestimento>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Minha Carteira',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              onPressed: _carregar),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4FF)))
          : _erro != null
              ? _buildErro()
              : RefreshIndicator(
                  onRefresh: _carregar,
                  color: const Color(0xFF00D4FF),
                  child: _buildBody(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovaOperacao,
        backgroundColor: const Color(0xFF00D4FF),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Nova Operação',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildErro() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(_erro!,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _carregar, child: const Text('Tentar novamente')),
        ]),
      );

  Widget _buildBody() {
    final c = _carteira!;
    if (c.posicoes.isEmpty && _operacoes.isEmpty && _corretoras.isEmpty) {
      return _buildVazio();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildHeader(c),
        const SizedBox(height: 20),
        _buildCorretorasGrid(),
        const SizedBox(height: 20),
        if (c.posicoes.length > 1) ...[
          _buildGraficoPizza(c),
          const SizedBox(height: 20),
        ],
        if (c.posicoes.isNotEmpty) _buildListaPosicoes(c),
        if (_operacoes.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildListaOperacoes(),
        ],
      ],
    );
  }

  Widget _buildVazio() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          const Text('Nenhuma posição',
              style: TextStyle(color: Colors.white70, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Adicione sua primeira compra',
              style: TextStyle(color: Colors.white38)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _abrirNovaOperacao,
            icon: const Icon(Icons.add),
            label: const Text('Nova Operação'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black),
          ),
        ]),
      );

  Widget _buildCorretorasGrid() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Corretoras',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(
            onPressed: _corretoras.isEmpty ? null : _abrirMovimentoCorretora,
            icon: const Icon(Icons.swap_vert, size: 16),
            label: const Text('Aporte/Retirada'),
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: const BorderSide(color: Colors.white24)),
          ),
          ElevatedButton.icon(
            onPressed: _abrirNovaCorretora,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nova'),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black),
          ),
        ]),
      ]),
      const SizedBox(height: 12),
      if (_corretoras.isEmpty)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12)),
          child: const Text('Cadastre suas corretoras para controlar saldo.',
              style: TextStyle(color: Colors.white54)),
        )
      else
        LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final count = width >= 1100
              ? 4
              : width >= 760
                  ? 3
                  : width >= 520
                      ? 2
                      : 1;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _corretoras.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: count,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (_, i) {
              final c = _corretoras[i];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(c.nome,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 6),
                      Text(_fmt.format(c.saldo),
                          style: TextStyle(
                              color: c.saldo >= 0
                                  ? const Color(0xFF00E676)
                                  : const Color(0xFFFF5252),
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ]),
              );
            },
          );
        }),
    ]);
  }

  Widget _buildHeader(CarteiraResumo c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: c.ganhoPositivo
              ? [const Color(0xFF0A3D2E), const Color(0xFF0D5C3D)]
              : [const Color(0xFF3D0A0A), const Color(0xFF5C0D0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: c.ganhoPositivo
                ? Colors.green.withOpacity(0.3)
                : Colors.red.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Valor Atual',
            style: TextStyle(color: Colors.white60, fontSize: 13)),
        Text(_fmt.format(c.valorAtual),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          _buildStatChip(
            'Ganho Total',
            '${_fmt.format(c.ganhoPerda)} (${_fmtPct.format(c.ganhoPerdaPercent)}%)',
            c.ganhoPositivo,
          ),
          const SizedBox(width: 12),
          _buildStatChip(
            'Hoje',
            '${_fmt.format(c.variacaoDiaTotal)} (${_fmtPct.format(c.variacaoDiaTotalPercent)}%)',
            c.variacaoDiaPositiva,
          ),
        ]),
        const SizedBox(height: 8),
        Text('Investido: ${_fmt.format(c.totalInvestido)}',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }

  Widget _buildStatChip(String label, String value, bool positivo) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: positivo
                      ? const Color(0xFF00E676)
                      : const Color(0xFFFF5252),
                  fontSize: 13,
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _buildGraficoPizza(CarteiraResumo c) {
    final cores = [
      const Color(0xFF00D4FF),
      const Color(0xFF00E676),
      const Color(0xFFFFD740),
      const Color(0xFFFF7043),
      const Color(0xFFAB47BC),
      const Color(0xFF26C6DA),
      const Color(0xFFEF5350),
      const Color(0xFF66BB6A),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Alocação',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: Row(children: [
            Expanded(
              child: PieChart(PieChartData(
                pieTouchData: PieTouchData(touchCallback: (e, r) {
                  setState(() => _touchedIndex =
                      r?.touchedSection?.touchedSectionIndex ?? -1);
                }),
                sections: c.posicoes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  final isTouched = i == _touchedIndex;
                  return PieChartSectionData(
                    color: cores[i % cores.length],
                    value: p.participacaoCarteira,
                    radius: isTouched ? 80 : 65,
                    title: isTouched ? p.ticker : '',
                    titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              )),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  c.posicoes.take(6).toList().asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: cores[i % cores.length],
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                        '${p.ticker} ${p.participacaoCarteira.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ]),
                );
              }).toList(),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildListaPosicoes(CarteiraResumo c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Posições (${c.posicoes.length})',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const Text('ordenado por participação',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        ...c.posicoes.map((p) => _buildCardPosicao(p)),
      ],
    );
  }

  Widget _buildCardPosicao(PosicaoAcao p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: p.positivo
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2)),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0D1117),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Center(
                child: Text(p.ticker.substring(0, p.ticker.length.clamp(0, 4)),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(p.ticker,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                Text(p.nomeAtivo,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_fmt.format(p.valorAtual),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            Text('${p.participacaoCarteira.toStringAsFixed(1)}% da carteira',
                style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ]),
        const SizedBox(height: 12),
        const Divider(color: Colors.white12),
        const SizedBox(height: 8),
        Row(children: [
          _buildInfoCol('Preço médio', _fmt.format(p.precoMedio)),
          _buildInfoCol('Preço atual',
              p.cotacaoDisponivel ? _fmt.format(p.precoAtual) : '—',
              sub: p.cotacaoDisponivel
                  ? '${_fmtPct.format(p.variacaoDiaPercent)}% hoje'
                  : 'sem cotação',
              subColor: p.variacaoDiaPositiva
                  ? const Color(0xFF00E676)
                  : const Color(0xFFFF5252)),
          _buildInfoCol('Ganho/Perda', _fmt.format(p.ganhoPerda),
              sub: '${_fmtPct.format(p.ganhoPerdaPercent)}%',
              subColor: p.positivo
                  ? const Color(0xFF00E676)
                  : const Color(0xFFFF5252)),
          _buildInfoCol(
              'Qtd',
              p.quantidade % 1 == 0
                  ? p.quantidade.toInt().toString()
                  : p.quantidade.toStringAsFixed(2)),
        ]),
      ]),
    );
  }

  Widget _buildInfoCol(String label, String value,
      {String? sub, Color? subColor}) {
    return Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      if (sub != null)
        Text(sub,
            style: TextStyle(color: subColor ?? Colors.white54, fontSize: 11)),
    ]));
  }

  Widget _buildListaOperacoes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('MovimentaÃ§Ãµes (${_operacoes.length})',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const Text('compras e vendas',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        ..._operacoes.map(_buildCardOperacao),
      ],
    );
  }

  Widget _buildCardOperacao(OperacaoAcao op) {
    final isCompra = op.tipo.toUpperCase() == 'COMPRA';
    final cor = isCompra ? const Color(0xFF00E676) : const Color(0xFFFF5252);
    final total =
        op.custoTotal ?? (op.quantidade * op.precoUnitario + op.taxas);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cor.withOpacity(0.35)),
            ),
            child: Text(op.tipo.toUpperCase(),
                style: TextStyle(
                    color: cor, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(op.ticker,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold))),
          Text(_fmt.format(total),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _buildInfoCol(
              'Corretora',
              (op.corretora == null || op.corretora!.trim().isEmpty)
                  ? 'NÃ£o informada'
                  : op.corretora!),
          _buildInfoCol(
              'Data', DateFormat('dd/MM/yyyy').format(op.dataOperacao)),
          _buildInfoCol(
              'Quantidade',
              op.quantidade % 1 == 0
                  ? op.quantidade.toInt().toString()
                  : op.quantidade.toStringAsFixed(2)),
          _buildInfoCol('PreÃ§o comprado', _fmt.format(op.precoUnitario)),
        ]),
        if (op.taxas > 0) ...[
          const SizedBox(height: 8),
          Text('Taxas: ${_fmt.format(op.taxas)}',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ]),
    );
  }

  void _abrirNovaOperacao() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _NovaOperacaoSheet(
        corretoras: _corretoras,
        onSalvo: (_) {
          Navigator.pop(ctx);
          _carregar();
        },
        repo: _repo,
      ),
    );
  }

  void _abrirNovaCorretora() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _CorretoraSheet(
        repo: _repo,
        onSalvo: () {
          Navigator.pop(ctx);
          _carregar();
        },
      ),
    );
  }

  void _abrirMovimentoCorretora() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _MovimentoCorretoraSheet(
        repo: _repo,
        corretoras: _corretoras,
        onSalvo: () {
          Navigator.pop(ctx);
          _carregar();
        },
      ),
    );
  }
}

class _NovaOperacaoSheet extends StatefulWidget {
  final Function(OperacaoAcao) onSalvo;
  final CarteiraRepository repo;
  final List<CorretoraInvestimento> corretoras;
  const _NovaOperacaoSheet({
    required this.onSalvo,
    required this.repo,
    required this.corretoras,
  });

  @override
  State<_NovaOperacaoSheet> createState() => _NovaOperacaoSheetState();
}

class _NovaOperacaoSheetState extends State<_NovaOperacaoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _tickerCtrl = TextEditingController();
  final _qtdCtrl = TextEditingController();
  final _precoCtrl = TextEditingController();
  final _taxasCtrl = TextEditingController(text: '0');
  CorretoraInvestimento? _corretoraSelecionada;
  String _tipo = 'COMPRA';
  DateTime _data = DateTime.now();
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _corretoraSelecionada =
        widget.corretoras.isNotEmpty ? widget.corretoras.first : null;
  }

  double get _custoTotal {
    final qtd = double.tryParse(_qtdCtrl.text.replaceAll(',', '.')) ?? 0;
    final preco = double.tryParse(_precoCtrl.text.replaceAll(',', '.')) ?? 0;
    final taxas = double.tryParse(_taxasCtrl.text.replaceAll(',', '.')) ?? 0;
    return qtd * preco + taxas;
  }

  @override
  void dispose() {
    _tickerCtrl.dispose();
    _qtdCtrl.dispose();
    _precoCtrl.dispose();
    _taxasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nova Operação',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context)),
                    ]),
                const SizedBox(height: 16),
                // Tipo
                Row(children: [
                  _tipoBtn('COMPRA', Colors.green),
                  const SizedBox(width: 12),
                  _tipoBtn('VENDA', Colors.red),
                ]),
                const SizedBox(height: 16),
                // Ticker
                _campo('Ticker (ex: PETR4)', _tickerCtrl,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Obrigatório' : null,
                    onChanged: (v) => _tickerCtrl.value = _tickerCtrl.value
                        .copyWith(
                            text: v.toUpperCase(),
                            selection:
                                TextSelection.collapsed(offset: v.length))),
                const SizedBox(height: 12),
                // Data
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: _data,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now());
                    if (d != null) setState(() => _data = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd/MM/yyyy').format(_data),
                          style: const TextStyle(color: Colors.white70)),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _campo('Quantidade', _qtdCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Obrigatório' : null)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _campo('Preço (R\$)', _precoCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Obrigatório' : null)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _corretoraDropdown()),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _campo('Taxas (R\$)', _taxasCtrl,
                          keyboardType: TextInputType.number)),
                ]),
                const SizedBox(height: 16),
                // Custo total
                ListenableBuilder(
                  listenable:
                      Listenable.merge([_qtdCtrl, _precoCtrl, _taxasCtrl]),
                  builder: (_, __) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFF0D1117),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Custo Total',
                              style: TextStyle(color: Colors.white60)),
                          Text(
                              NumberFormat.currency(
                                      locale: 'pt_BR', symbol: 'R\$')
                                  .format(_custoTotal),
                              style: const TextStyle(
                                  color: Color(0xFF00D4FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ]),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _salvando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Salvar Operação',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  Widget _tipoBtn(String tipo, Color cor) {
    final sel = _tipo == tipo;
    return Expanded(
        child: GestureDetector(
      onTap: () => setState(() => _tipo = tipo),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
            color: sel ? cor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: sel ? cor : Colors.white24, width: sel ? 2 : 1)),
        child: Center(
            child: Text(tipo,
                style: TextStyle(
                    color: sel ? cor : Colors.white54,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal))),
      ),
    ));
  }

  Widget _corretoraDropdown() {
    return DropdownButtonFormField<CorretoraInvestimento>(
      value: _corretoraSelecionada,
      dropdownColor: const Color(0xFF161B22),
      style: const TextStyle(color: Colors.white),
      validator: (_) =>
          widget.corretoras.isEmpty ? 'Cadastre uma corretora antes' : null,
      decoration: InputDecoration(
        labelText: 'Corretora',
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00D4FF))),
      ),
      items: widget.corretoras
          .map((c) => DropdownMenuItem(
                value: c,
                child: Text(
                  '${c.nome} - ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(c.saldo)}',
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (v) => setState(() => _corretoraSelecionada = v),
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00D4FF))),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final op = await widget.repo.adicionarOperacao({
        'ticker': _tickerCtrl.text.toUpperCase().trim(),
        'tipo': _tipo,
        'quantidade': double.parse(_qtdCtrl.text.replaceAll(',', '.')),
        'precoUnitario': double.parse(_precoCtrl.text.replaceAll(',', '.')),
        'dataOperacao': DateFormat('yyyy-MM-dd').format(_data),
        'corretora': _corretoraSelecionada?.nome,
        'taxas': double.tryParse(_taxasCtrl.text.replaceAll(',', '.')) ?? 0,
      });
      widget.onSalvo(op);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}

class _CorretoraSheet extends StatefulWidget {
  final CarteiraRepository repo;
  final VoidCallback onSalvo;
  const _CorretoraSheet({required this.repo, required this.onSalvo});

  @override
  State<_CorretoraSheet> createState() => _CorretoraSheetState();
}

class _CorretoraSheetState extends State<_CorretoraSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _saldoCtrl = TextEditingController(text: '0');
  final _obsCtrl = TextEditingController();
  bool _salvando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _saldoCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Nova Corretora',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context)),
                    ]),
                const SizedBox(height: 16),
                _campo('Nome da corretora', _nomeCtrl,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Obrigatorio' : null),
                const SizedBox(height: 12),
                _campo('Saldo inicial (R\$)', _saldoCtrl,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _campo('Observacao', _obsCtrl),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Salvar Corretora',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0D1117),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00D4FF))),
      ),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      await widget.repo.salvarCorretora(
        nome: _nomeCtrl.text.trim(),
        saldoInicial:
            double.tryParse(_saldoCtrl.text.replaceAll(',', '.')) ?? 0,
        observacao: _obsCtrl.text.trim(),
      );
      widget.onSalvo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}

class _MovimentoCorretoraSheet extends StatefulWidget {
  final CarteiraRepository repo;
  final List<CorretoraInvestimento> corretoras;
  final VoidCallback onSalvo;
  const _MovimentoCorretoraSheet({
    required this.repo,
    required this.corretoras,
    required this.onSalvo,
  });

  @override
  State<_MovimentoCorretoraSheet> createState() =>
      _MovimentoCorretoraSheetState();
}

class _MovimentoCorretoraSheetState extends State<_MovimentoCorretoraSheet> {
  final _formKey = GlobalKey<FormState>();
  final _valorCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  CorretoraInvestimento? _corretora;
  String _tipo = 'APORTE';
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _corretora = widget.corretoras.isNotEmpty ? widget.corretoras.first : null;
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Movimentar Saldo',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context)),
                    ]),
                const SizedBox(height: 16),
                DropdownButtonFormField<CorretoraInvestimento>(
                  value: _corretora,
                  dropdownColor: const Color(0xFF161B22),
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoracao('Corretora'),
                  items: widget.corretoras
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.nome)))
                      .toList(),
                  onChanged: (v) => setState(() => _corretora = v),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _tipoBtn('APORTE', Colors.green),
                  const SizedBox(width: 12),
                  _tipoBtn('RETIRADA', Colors.red),
                ]),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valorCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obrigatorio' : null,
                  decoration: _decoracao('Valor (R\$)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoracao('Descricao'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D4FF),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Salvar Movimento',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ]),
        ),
      ),
    );
  }

  Widget _tipoBtn(String tipo, Color cor) {
    final sel = _tipo == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipo = tipo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: sel ? cor.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: sel ? cor : Colors.white24, width: sel ? 2 : 1)),
          child: Center(
              child: Text(tipo,
                  style: TextStyle(
                      color: sel ? cor : Colors.white54,
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal))),
        ),
      ),
    );
  }

  InputDecoration _decoracao(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0D1117),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF00D4FF))),
      );

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _corretora?.id == null) return;
    setState(() => _salvando = true);
    try {
      await widget.repo.movimentarCorretora(
        corretoraId: _corretora!.id!,
        tipo: _tipo,
        valor: double.parse(_valorCtrl.text.replaceAll(',', '.')),
        descricao: _descCtrl.text.trim(),
      );
      widget.onSalvo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }
}
