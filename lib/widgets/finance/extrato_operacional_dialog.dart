import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/conta_model.dart';
import '../../services/conta_caller.dart';
import 'financial_lookup_loader.dart';

class ExtratoOperacionalDialog extends StatefulWidget {
  const ExtratoOperacionalDialog({
    super.key,
    required this.contaId,
    required this.contaNome,
    this.initialDays = 30,
  });

  final int contaId;
  final String contaNome;
  final int initialDays;

  static Future<void> show(
    BuildContext context, {
    required int contaId,
    required String contaNome,
    int initialDays = 30,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ExtratoOperacionalDialog(
        contaId: contaId,
        contaNome: contaNome,
        initialDays: initialDays,
      ),
    );
  }

  @override
  State<ExtratoOperacionalDialog> createState() =>
      _ExtratoOperacionalDialogState();
}

class _ExtratoOperacionalDialogState extends State<ExtratoOperacionalDialog> {
  static const _periodOptions = [7, 15, 30, 60, 90];
  static const List<_FiltroOpcao> _statusOptions = [
    _FiltroOpcao(label: 'Todos os status'),
    _FiltroOpcao(label: 'Aberta', value: 'ABERTA'),
    _FiltroOpcao(label: 'Baixada', value: 'BAIXADA'),
    _FiltroOpcao(label: 'Cancelada', value: 'CANCELADA'),
    _FiltroOpcao(label: 'Parcial', value: 'PARCIAL'),
  ];
  static const List<_FiltroOpcao> _visaoOptions = [
    _FiltroOpcao(label: 'Caixa', value: 'CAIXA'),
    _FiltroOpcao(label: 'Competência', value: 'COMPETENCIA'),
  ];

  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  late int _selectedDays;
  bool _loading = true;
  String? _error;
  ContaExtratoOperacional? _extrato;
  String? _selectedStatus;
  String? _selectedCategoriaId;
  String _selectedVisao = 'CAIXA';
  List<_FiltroOpcao> _categoriaOptions = const [
    _FiltroOpcao(label: 'Todas as categorias'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialDays;
    _carregarCategorias();
    _carregar();
  }

  DateTime get _dataFim {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _dataInicio =>
      _dataFim.subtract(Duration(days: _selectedDays - 1));

  Future<void> _carregarCategorias() async {
    try {
      final categorias =
          await FinancialLookupLoader.loadCategoriasFinanceiras();
      if (!mounted) return;
      setState(() {
        _categoriaOptions = [
          const _FiltroOpcao(label: 'Todas as categorias'),
          ...categorias.map(
            (item) => _FiltroOpcao(
              label: item['label']?.toString() ?? 'Categoria',
              value: item['value']?.toString(),
            ),
          ),
        ];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoriaOptions = const [
          _FiltroOpcao(label: 'Todas as categorias'),
        ];
      });
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final extrato = await ContaApi().extratoOperacional(
        contaId: widget.contaId,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        status: _selectedStatus,
        categoriaFinanceiraId: int.tryParse(_selectedCategoriaId ?? ''),
        visao: _selectedVisao,
      );

      if (!mounted) return;
      setState(() {
        _extrato = extrato;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao carregar extrato operacional.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extrato operacional com saldo',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.contaNome,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _carregar,
                    tooltip: 'Atualizar',
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final days in _periodOptions)
                    ChoiceChip(
                      label: Text('Últimos $days dias'),
                      selected: _selectedDays == days,
                      onSelected: (selected) {
                        if (!selected || _selectedDays == days) return;
                        setState(() => _selectedDays = days);
                        _carregar();
                      },
                    ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _statusOptions
                          .map(
                            (item) => DropdownMenuItem<String?>(
                              value: item.value,
                              child: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() => _selectedStatus = value);
                        _carregar();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedVisao,
                      decoration: const InputDecoration(
                        labelText: 'Visão',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _visaoOptions
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.value!,
                              child: Text(item.label),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selectedVisao = value);
                        _carregar();
                      },
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _selectedCategoriaId,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _categoriaOptions
                          .map(
                            (item) => DropdownMenuItem<String?>(
                              value: item.value,
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        setState(() => _selectedCategoriaId = value);
                        _carregar();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Período consultado: ${_dateFormat.format(_dataInicio)} até ${_dateFormat.format(_dataFim)}. Visão ${_selectedVisao == 'COMPETENCIA' ? 'por competência' : 'por caixa'}.',
                ),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildContent(theme)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _carregar,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final extrato = _extrato;
    if (extrato == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ResumoCard(
              label: 'Saldo inicial',
              value: _currency.format(extrato.saldoInicial),
              color: const Color(0xFF1D4ED8),
            ),
            _ResumoCard(
              label: 'Entradas',
              value: _currency.format(extrato.totalEntradas),
              color: const Color(0xFF15803D),
            ),
            _ResumoCard(
              label: 'Saídas',
              value: _currency.format(extrato.totalSaidas),
              color: const Color(0xFFB91C1C),
            ),
            _ResumoCard(
              label: 'Saldo final',
              value: _currency.format(extrato.saldoFinal),
              color: extrato.saldoFinal >= 0
                  ? const Color(0xFF0F766E)
                  : const Color(0xFFB45309),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      const _HeaderCell(flex: 2, label: 'Data'),
                      const _HeaderCell(flex: 4, label: 'Histórico'),
                      const _HeaderCell(flex: 2, label: 'Entradas'),
                      const _HeaderCell(flex: 2, label: 'Saídas'),
                      _HeaderCell(
                        flex: 2,
                        label: _selectedVisao == 'COMPETENCIA'
                            ? 'Saldo proj.'
                            : 'Saldo',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: extrato.itens.isEmpty
                      ? const Center(
                          child: Text(
                            'Sem movimentações para os filtros selecionados.',
                          ),
                        )
                      : ListView.separated(
                          itemCount: extrato.itens.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                          itemBuilder: (context, index) {
                            final item = extrato.itens[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  _DataCell(
                                    flex: 2,
                                    child: Text(_dateFormat.format(item.data)),
                                  ),
                                  _DataCell(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.descricao.isNotEmpty
                                              ? item.descricao
                                              : item.tipoLancamento,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.tipoLancamento}${item.realizado ? ' • Realizado' : ' • Pendente'}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _DataCell(
                                    flex: 2,
                                    child: Text(
                                      item.entrada == 0
                                          ? '-'
                                          : _currency.format(item.entrada),
                                      style: const TextStyle(
                                        color: Color(0xFF15803D),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  _DataCell(
                                    flex: 2,
                                    child: Text(
                                      item.saida == 0
                                          ? '-'
                                          : _currency.format(item.saida),
                                      style: const TextStyle(
                                        color: Color(0xFFB91C1C),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  _DataCell(
                                    flex: 2,
                                    child: Text(
                                      _currency.format(item.saldoAcumulado),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: item.saldoAcumulado >= 0
                                            ? const Color(0xFF0F766E)
                                            : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 170),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.flex, required this.label});

  final int flex;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  const _DataCell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: child);
  }
}

class _FiltroOpcao {
  const _FiltroOpcao({required this.label, this.value});

  final String label;
  final String? value;
}
