import 'package:flutter/material.dart';
import '../../../services/custo_medio_service.dart';
import '../../../utils/grid_colors.dart';

class CustoMedioScreen extends StatefulWidget {
  const CustoMedioScreen({super.key});
  @override
  State<CustoMedioScreen> createState() => _CustoMedioScreenState();
}

class _CustoMedioScreenState extends State<CustoMedioScreen> {
  final _produtoIdCtrl = TextEditingController();
  final _vendaIdCtrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _resultado;
  String? _error;

  Future<void> _consultar() async {
    final id = int.tryParse(_produtoIdCtrl.text);
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _resultado = null;
    });
    final res = await CustoMedioService.consultar(id);
    if (mounted) {
      setState(() {
        _loading = false;
        if (res.isSuccess && res.body != null) {
          _resultado = res.body!['data'] ?? res.body;
        } else {
          _error = 'Erro ao consultar custo médio';
        }
      });
    }
  }

  Future<void> _recalcular() async {
    final id = int.tryParse(_produtoIdCtrl.text);
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await CustoMedioService.recalcular(id);
    if (mounted) {
      setState(() => _loading = false);
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Custo médio recalculado com sucesso!')),
        );
        _consultar();
      } else {
        setState(() => _error = 'Erro ao recalcular custo médio');
      }
    }
  }

  Future<void> _historico() async {
    final id = int.tryParse(_produtoIdCtrl.text);
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _resultado = null;
    });
    final res = await CustoMedioService.historico(id);
    if (mounted) {
      setState(() {
        _loading = false;
        if (res.isSuccess && res.body != null) {
          _resultado = res.body!['data'] ?? res.body;
        } else {
          _error = 'Erro ao carregar histórico';
        }
      });
    }
  }

  Future<void> _baixarPorVenda() async {
    final id = int.tryParse(_vendaIdCtrl.text);
    if (id == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await CustoMedioService.baixarPorVenda(id);
    if (mounted) {
      setState(() => _loading = false);
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Baixa por venda executada com sucesso!')),
        );
      } else {
        setState(() => _error = 'Erro ao baixar por venda');
      }
    }
  }

  @override
  void dispose() {
    _produtoIdCtrl.dispose();
    _vendaIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Custo Médio e Baixa Automática'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _produtoIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID do Produto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _consultar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Consultar Custo Médio'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _recalcular,
                    child: const Text('Recalcular'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loading ? null : _historico,
              child: const Text('Ver Histórico'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _vendaIdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID da Venda (para baixa automática)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _baixarPorVenda,
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Baixar por Venda'),
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                  child: CircularProgressIndicator(
                      color: GridColors.primary)),
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!,
                      style: const TextStyle(color: GridColors.error)),
                ),
              ),
            if (_resultado != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resultado:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ..._resultado!.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text('${e.key}: ${e.value}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
