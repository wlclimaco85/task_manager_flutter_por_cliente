import 'package:flutter/material.dart';
import '../../models/hidratacao_model.dart';
import '../../services/hidratacao_service.dart';

class HidratacaoScreen extends StatefulWidget {
  const HidratacaoScreen({super.key});

  @override
  State<HidratacaoScreen> createState() => _HidratacaoScreenState();
}

class _HidratacaoScreenState extends State<HidratacaoScreen> {
  final _mlController = TextEditingController(text: '200');
  final _metaController = TextEditingController();
  final _copoController = TextEditingController();
  HidratacaoResumo? _resumo;
  bool _loading = true;
  bool _saving = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _mlController.dispose();
    _metaController.dispose();
    _copoController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    final resumo = await HidratacaoService.resumo();
    if (!mounted) return;
    setState(() {
      _resumo = resumo;
      _loading = false;
      if (resumo == null) {
        _erro = 'Nao foi possivel carregar os dados de hidratacao.';
      } else {
        _metaController.text = resumo.metaDiariaMl.toString();
        _copoController.text = resumo.volumeCopoMl.toString();
      }
    });
  }

  Future<void> _registrar(int ml) async {
    if (ml <= 0 || ml > 5000) {
      _snack('Informe uma quantidade entre 1 e 5000 ml.', erro: true);
      return;
    }
    setState(() => _saving = true);
    final ok = await HidratacaoService.registrar(ml);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      await _carregar();
    } else {
      _snack('Nao foi possivel registrar a agua.', erro: true);
    }
  }

  Future<void> _salvarMeta() async {
    final meta = int.tryParse(_metaController.text.trim()) ?? 0;
    final copo = int.tryParse(_copoController.text.trim()) ?? 0;
    if (meta < 500 || meta > 10000) {
      _snack('A meta deve ficar entre 500 e 10000 ml.', erro: true);
      return;
    }
    if (copo < 50 || copo > 1000) {
      _snack('O copo deve ficar entre 50 e 1000 ml.', erro: true);
      return;
    }
    setState(() => _saving = true);
    final ok = await HidratacaoService.salvarMeta(
      metaDiariaMl: meta,
      volumeCopoMl: copo,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      await _carregar();
      _snack('Meta atualizada.');
    } else {
      _snack('Nao foi possivel salvar a meta.', erro: true);
    }
  }

  void _snack(String message, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erro!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _carregar,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final resumo = _resumo!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidratacao'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _saving ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _ResumoCard(resumo: resumo)),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: _controles(resumo)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ResumoCard(resumo: resumo),
                      const SizedBox(height: 16),
                      _controles(resumo),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _controles(HidratacaoResumo resumo) {
    final manualMl = int.tryParse(_mlController.text.trim()) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: _saving ? null : () => _registrar(200),
              icon: const Icon(Icons.add),
              label: const Text('+200 ml'),
            ),
            FilledButton.icon(
              onPressed: _saving ? null : () => _registrar(resumo.volumeCopoMl),
              icon: const Icon(Icons.local_drink_outlined),
              label: Text('+copo (${resumo.volumeCopoMl} ml)'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mlController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantidade manual (ml)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _saving ? null : () => _registrar(manualMl),
              child: const Text('Registrar'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _metaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Meta diaria (ml)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _copoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Volume do copo (ml)',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _saving ? null : _salvarMeta,
              child: const Text('Salvar meta'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Historico de 7 dias', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...resumo.historico.map(_historicoTile),
      ],
    );
  }

  Widget _historicoTile(HidratacaoDiaResumo dia) {
    final label = '${dia.data.day.toString().padLeft(2, '0')}/${dia.data.month.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.water_drop_outlined),
      title: Text(label),
      trailing: Text('${dia.totalMl} ml'),
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final HidratacaoResumo resumo;

  const _ResumoCard({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final percent = resumo.percentual.clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: percent,
                      strokeWidth: 14,
                      backgroundColor: Colors.blue.shade50,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(percent * 100).round()}%',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text('${resumo.totalMl} ml'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Meta diaria: ${resumo.metaDiariaMl} ml',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('${resumo.registros.length} registro(s) hoje'),
          ],
        ),
      ),
    );
  }
}
