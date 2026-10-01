import 'package:flutter/material.dart';

import '../../models/recurring_contract_model.dart';
import '../../services/recurring_contract_service.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import 'faturar_contratos_state.dart';

class FaturarContratosScreen extends StatefulWidget {
  final RecurringContractService service;

  FaturarContratosScreen({
    super.key,
    RecurringContractService? service,
  }) : service = service ?? RecurringContractService();

  @override
  State<FaturarContratosScreen> createState() => _FaturarContratosScreenState();
}

class _FaturarContratosScreenState extends State<FaturarContratosScreen> {
  List<RecurringContract> _contratos = const [];
  final Set<String> _selecionados = {};
  final Map<String, _ResultadoFaturamento> _resultados = {};
  bool _carregando = true;
  bool _processando = false;
  bool _gerarFinanceiro = true;
  bool _emitirNfse = false;
  DateTime _competencia = DateTime(DateTime.now().year, DateTime.now().month);

  List<RecurringContract> get _filtrados =>
      FaturarContratosState.contratosAteCompetencia(_contratos, _competencia);

  List<RecurringContract> get _selecionadosDetalhe => _filtrados
      .where((contrato) => _selecionados.contains(contrato.contractId))
      .toList();

  double get _totalSelecionado =>
      FaturarContratosState.totalMensal(_selecionadosDetalhe);

  @override
  void initState() {
    super.initState();
    _carregarContratos();
  }

  Future<void> _carregarContratos() async {
    setState(() => _carregando = true);
    try {
      final contratos = await widget.service.listContracts(
        empresaId: TenantContext.empresaId,
      );
      if (!mounted) return;
      setState(() {
        _contratos = contratos;
        _selecionados.clear();
        _resultados.clear();
      });
    } catch (e) {
      if (!mounted) return;
      _mostrarMensagem(e.toString(), erro: true);
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _selecionarCompetencia() async {
    final escolhido = await showDatePicker(
      context: context,
      initialDate: _competencia,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Competencia',
    );
    if (escolhido == null) return;
    setState(() {
      _competencia = DateTime(escolhido.year, escolhido.month);
      _selecionados.clear();
      _resultados.clear();
    });
  }

  Future<void> _faturarSelecionados() async {
    final contratos = _selecionadosDetalhe;
    if (contratos.isEmpty || _processando) return;
    final confirmado = await _confirmarFaturamento(contratos.length);
    if (confirmado != true) return;

    setState(() {
      _processando = true;
      _resultados.clear();
    });

    for (final contrato in contratos) {
      try {
        final invoice = await widget.service.generateInvoice(
          contractId: contrato.contractId,
          empresaId: contrato.empresaId,
          amount: contrato.monthlyValue,
          dueDate: contrato.nextDueDate,
          generateReceivable: _gerarFinanceiro,
          issueNfse: _emitirNfse,
        );
        if (!mounted) return;
        setState(() {
          _resultados[contrato.contractId] = _ResultadoFaturamento.sucesso(
            invoice.message ?? 'Faturado com sucesso',
          );
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _resultados[contrato.contractId] =
              _ResultadoFaturamento.erro(e.toString());
        });
      }
    }

    if (!mounted) return;
    setState(() => _processando = false);
    _mostrarMensagem('Faturamento processado.');
    await _carregarContratos();
  }

  Future<bool?> _confirmarFaturamento(int quantidade) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar faturamento'),
        content: Text(
          'Gerar faturamento para $quantidade contrato(s) selecionado(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Faturar Contratos'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _carregando ? null : _carregarContratos,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarContratos,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFiltros(),
                  const SizedBox(height: 12),
                  _buildResumo(),
                  const SizedBox(height: 12),
                  _buildTabela(),
                ],
              ),
            ),
    );
  }

  Widget _buildFiltros() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GridColors.card,
        border: Border.all(color: GridColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _selecionarCompetencia,
              icon: const Icon(Icons.calendar_month),
              label: Text(_formatarCompetencia(_competencia)),
            ),
            FilterChip(
              selected: _gerarFinanceiro,
              avatar: const Icon(Icons.payments, size: 18),
              label: const Text('Gerar financeiro'),
              onSelected: (value) => setState(() => _gerarFinanceiro = value),
            ),
            FilterChip(
              selected: _emitirNfse,
              avatar: const Icon(Icons.description, size: 18),
              label: const Text('Emitir NFS-e'),
              onSelected: (value) => setState(() => _emitirNfse = value),
            ),
            FilledButton.icon(
              onPressed: _selecionados.isEmpty || _processando
                  ? null
                  : _faturarSelecionados,
              icon: _processando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long),
              label: Text(_processando ? 'Faturando...' : 'Gerar faturamento'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final cards = [
          _ResumoCard(
            titulo: 'A faturar',
            valor: _filtrados.length.toString(),
            subtitulo: 'contratos ate a competencia',
            icone: Icons.event_available,
          ),
          _ResumoCard(
            titulo: 'Selecionados',
            valor: _selecionados.length.toString(),
            subtitulo: 'prontos para gerar',
            icone: Icons.checklist,
          ),
          _ResumoCard(
            titulo: 'Total previsto',
            valor: _formatarMoeda(_totalSelecionado),
            subtitulo: 'receita recorrente',
            icone: Icons.trending_up,
          ),
        ];
        if (compact) {
          return Column(
            children: cards
                .map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: card,
                    ))
                .toList(),
          );
        }
        return Row(
          children: cards
              .map((card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: card,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildTabela() {
    if (_filtrados.isEmpty) {
      return const _EmptyState();
    }

    final todosSelecionados = _selecionados.length == _filtrados.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GridColors.card,
        border: Border.all(color: GridColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(GridColors.gridHeader),
          columns: [
            DataColumn(
              label: Checkbox(
                value: todosSelecionados,
                onChanged: (value) => setState(() {
                  _selecionados.clear();
                  if (value == true) {
                    _selecionados.addAll(
                      _filtrados.map((contrato) => contrato.contractId),
                    );
                  }
                }),
              ),
            ),
            const DataColumn(label: Text('Contrato')),
            const DataColumn(label: Text('Cliente')),
            const DataColumn(label: Text('Plano')),
            const DataColumn(label: Text('Vencimento')),
            const DataColumn(label: Text('Valor')),
            const DataColumn(label: Text('Status')),
            const DataColumn(label: Text('Resultado')),
          ],
          rows: _filtrados.map(_buildRow).toList(),
        ),
      ),
    );
  }

  DataRow _buildRow(RecurringContract contrato) {
    final selecionado = _selecionados.contains(contrato.contractId);
    final resultado = _resultados[contrato.contractId];
    return DataRow(
      selected: selecionado,
      cells: [
        DataCell(Checkbox(
          value: selecionado,
          onChanged: (value) => setState(() {
            if (value == true) {
              _selecionados.add(contrato.contractId);
            } else {
              _selecionados.remove(contrato.contractId);
            }
          }),
        )),
        DataCell(Text(contrato.contractId)),
        DataCell(Text(contrato.customerName)),
        DataCell(Text(contrato.planName)),
        DataCell(Text(_formatarData(contrato.nextDueDate))),
        DataCell(Text(_formatarMoeda(contrato.monthlyValue))),
        DataCell(_StatusBadge(texto: contrato.status)),
        DataCell(_ResultadoBadge(resultado: resultado)),
      ],
    );
  }

  void _mostrarMensagem(String mensagem, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? GridColors.error : GridColors.success,
      ),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icone;

  const _ResumoCard({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GridColors.card,
        border: Border.all(color: GridColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: GridColors.secondarySoft,
              foregroundColor: GridColors.secondary,
              child: Icon(icone, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 12)),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: const TextStyle(
                      color: GridColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String texto;

  const _StatusBadge({required this.texto});

  @override
  Widget build(BuildContext context) {
    final ativo = texto.toUpperCase() == 'ACTIVE';
    return Chip(
      label: Text(ativo ? 'Ativo' : texto),
      backgroundColor:
          ativo ? GridColors.successLight : GridColors.surfaceMuted,
      side: BorderSide(
        color: ativo ? GridColors.success : GridColors.divider,
      ),
    );
  }
}

class _ResultadoBadge extends StatelessWidget {
  final _ResultadoFaturamento? resultado;

  const _ResultadoBadge({required this.resultado});

  @override
  Widget build(BuildContext context) {
    if (resultado == null) {
      return const Text('Pendente');
    }
    return Tooltip(
      message: resultado!.mensagem,
      child: Chip(
        label: Text(resultado!.sucesso ? 'Gerado' : 'Erro'),
        backgroundColor: resultado!.sucesso
            ? GridColors.successLight
            : GridColors.errorLight,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GridColors.card,
        border: Border.all(color: GridColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(28),
        child: Center(
          child: Text('Nenhum contrato ativo para faturar nesta competencia.'),
        ),
      ),
    );
  }
}

class _ResultadoFaturamento {
  final bool sucesso;
  final String mensagem;

  const _ResultadoFaturamento._(this.sucesso, this.mensagem);

  factory _ResultadoFaturamento.sucesso(String mensagem) =>
      _ResultadoFaturamento._(true, mensagem);

  factory _ResultadoFaturamento.erro(String mensagem) =>
      _ResultadoFaturamento._(false, mensagem);
}

String _formatarCompetencia(DateTime data) {
  return '${data.month.toString().padLeft(2, '0')}/${data.year}';
}

String _formatarData(DateTime data) {
  return '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/${data.year}';
}

String _formatarMoeda(double valor) {
  final fixo = valor.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $fixo';
}
