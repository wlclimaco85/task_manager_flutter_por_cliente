import 'package:flutter/material.dart';
import '../../services/reserva_estoque_caller.dart';

class ReservaEstoqueScreen extends StatefulWidget {
  const ReservaEstoqueScreen({super.key});

  @override
  State<ReservaEstoqueScreen> createState() => _ReservaEstoqueScreenState();
}

class _ReservaEstoqueScreenState extends State<ReservaEstoqueScreen> {
  final TextEditingController _pedidoIdCtrl = TextEditingController();
  List<Map<String, dynamic>> _reservas = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _pedidoIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarReservas() async {
    final id = int.tryParse(_pedidoIdCtrl.text);
    if (id == null) {
      setState(() => _error = 'Informe um ID de pedido válido');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    final reservas = await ReservaEstoqueCaller.fetchReservas(id);
    for (final r in reservas) {
      final prodId = r['produtoId'] ?? r['produto_id'] ?? 0;
      if (prodId is int && prodId > 0) {
        final disp = await ReservaEstoqueCaller.fetchDisponivel(prodId);
        r['saldoDisponivel'] = disp;
      }
    }
    if (mounted) {
      setState(() {
        _reservas = reservas;
        _isLoading = false;
        if (reservas.isEmpty) _error = 'Nenhuma reserva encontrada';
      });
    }
  }

  Future<void> _reservar(Map<String, dynamic> reserva) async {
    final id = int.tryParse(_pedidoIdCtrl.text);
    if (id == null) return;
    final prodId = reserva['produtoId'] ?? reserva['produto_id'] ?? 0;
    final qtd = reserva['quantidade'] ?? reserva['qtd'] ?? 0;
    final ok = await ReservaEstoqueCaller.reservar(id, {
      'produtoId': prodId,
      'quantidade': qtd,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Reserva realizada' : 'Erro ao reservar'),
      ));
      if (ok) _carregarReservas();
    }
  }

  Future<void> _liberar(Map<String, dynamic> reserva) async {
    final id = int.tryParse(_pedidoIdCtrl.text);
    if (id == null) return;
    final prodId = reserva['produtoId'] ?? reserva['produto_id'] ?? 0;
    final qtd = reserva['quantidade'] ?? reserva['qtd'] ?? 0;
    final ok = await ReservaEstoqueCaller.liberar(id, {
      'produtoId': prodId,
      'quantidade': qtd,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Reserva liberada' : 'Erro ao liberar'),
      ));
      if (ok) _carregarReservas();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reserva de Estoque por Pedido')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _pedidoIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Pedido ID',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _carregarReservas,
                  child: const Text('Carregar Reservas'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: _reservas.isEmpty
                    ? const Center(child: Text('Nenhuma reserva'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Produto')),
                            DataColumn(label: Text('Quantidade')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Saldo Disp.')),
                            DataColumn(label: Text('Ações')),
                          ],
                          rows: _reservas.map((r) {
                            final prodNome = r['produtoNome'] ?? r['produto_nome'] ?? r['produto'] ?? '-';
                            final qtd = r['quantidade'] ?? r['qtd'] ?? 0;
                            final status = r['status'] ?? '-';
                            final saldo = r['saldoDisponivel'] ?? 0;
                            return DataRow(cells: [
                              DataCell(Text('$prodNome')),
                              DataCell(Text('$qtd')),
                              DataCell(Text('$status')),
                              DataCell(Text('$saldo')),
                              DataCell(Row(
                                children: [
                                  TextButton(
                                    onPressed: () => _reservar(r),
                                    child: const Text('Reservar'),
                                  ),
                                  const SizedBox(width: 4),
                                  TextButton(
                                    onPressed: () => _liberar(r),
                                    child: const Text('Liberar'),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
