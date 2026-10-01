import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/alimento_model.dart';
import '../../models/diario_nutricional_model.dart';
import '../../services/diario_nutricional_service.dart';
import '../../utils/grid_colors.dart';

class DiarioNutricionalScreen extends StatefulWidget {
  const DiarioNutricionalScreen({super.key});

  @override
  State<DiarioNutricionalScreen> createState() =>
      _DiarioNutricionalScreenState();
}

class _DiarioNutricionalScreenState extends State<DiarioNutricionalScreen> {
  static const _tipos = <String, String>{
    'CAFE': 'Cafe da manha',
    'ALMOCO': 'Almoco',
    'JANTAR': 'Jantar',
    'LANCHE': 'Lanche',
  };

  DiarioNutricionalResumo? _resumo;
  DateTime _data = DateTime.now();
  bool _loading = true;
  bool _saving = false;
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
    final resumo = await DiarioNutricionalService.resumo(_data);
    if (!mounted) return;
    setState(() {
      _resumo = resumo ?? DiarioNutricionalResumo.empty(_data);
      _loading = false;
      if (resumo == null) {
        _erro = 'Nao foi possivel carregar o diario nutricional.';
      }
    });
  }

  Future<void> _selecionarData() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (selected == null) return;
    setState(() => _data = selected);
    await _carregar();
  }

  Future<void> _abrirRegistro(String tipo) async {
    final result = await showDialog<_RegistroDiarioResult>(
      context: context,
      builder: (_) => _RegistroDiarioDialog(tipoLabel: _tipos[tipo] ?? tipo),
    );
    if (result == null) return;
    final alimentoId = int.tryParse(result.alimento.id ?? '');
    if (alimentoId == null || alimentoId <= 0) {
      _snack('Selecione um alimento valido.', erro: true);
      return;
    }
    if (result.quantidadeGramas <= 0 || result.quantidadeGramas > 5000) {
      _snack('Informe uma quantidade entre 1 e 5000 g.', erro: true);
      return;
    }

    setState(() => _saving = true);
    var refeicao = _refeicaoPorTipo(tipo);
    refeicao ??= await DiarioNutricionalService.registrarRefeicao(
      data: _data,
      tipo: tipo,
      fotoBase64: result.fotoBase64,
    );
    final ok = refeicao != null &&
        await DiarioNutricionalService.registrarItem(
          refeicaoId: refeicao.id,
          alimentoId: alimentoId,
          quantidadeGramas: result.quantidadeGramas,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      await _carregar();
      _snack('Alimento registrado.');
    } else {
      _snack('Nao foi possivel registrar o alimento.', erro: true);
    }
  }

  Future<void> _removerItem(DiarioNutricionalItem item) async {
    setState(() => _saving = true);
    final ok = await DiarioNutricionalService.removerItem(item.id);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      await _carregar();
    } else {
      _snack('Nao foi possivel remover o item.', erro: true);
    }
  }

  DiarioNutricionalRefeicao? _refeicaoPorTipo(String tipo) {
    for (final refeicao
        in _resumo?.refeicoes ?? const <DiarioNutricionalRefeicao>[]) {
      if (refeicao.tipo.toUpperCase() == tipo) return refeicao;
    }
    return null;
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
        title: const Text('Diario nutricional'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _selecionarData,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_formatDateBr(_data)),
          ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _saving ? null : _carregar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;
          final content = [
            _ResumoMacrosCard(resumo: resumo),
            const SizedBox(height: 16),
            if (resumo.refeicoes.isEmpty)
              _EmptyDiarioCard(onAdd: () => _abrirRegistro('CAFE')),
            ..._tipos.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RefeicaoCard(
                  tipo: entry.key,
                  label: entry.value,
                  refeicao: _refeicaoPorTipo(entry.key),
                  saving: _saving,
                  onAdd: () => _abrirRegistro(entry.key),
                  onRemove: _removerItem,
                ),
              );
            }),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 320, child: content.first),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(children: content.skip(2).toList())),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: content),
          );
        },
      ),
    );
  }

  String _formatDateBr(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _RegistroDiarioDialog extends StatefulWidget {
  final String tipoLabel;

  const _RegistroDiarioDialog({required this.tipoLabel});

  @override
  State<_RegistroDiarioDialog> createState() => _RegistroDiarioDialogState();
}

class _RegistroDiarioDialogState extends State<_RegistroDiarioDialog> {
  final _quantidadeController = TextEditingController(text: '100');
  final _buscaController = TextEditingController();
  List<Alimento> _alimentos = const [];
  Alimento? _selecionado;
  String? _fotoBase64;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() => _loading = true);
    final alimentos = await DiarioNutricionalService.listarAlimentos(
        busca: _buscaController.text);
    if (!mounted) return;
    setState(() {
      _alimentos = alimentos;
      _selecionado = alimentos.contains(_selecionado) ? _selecionado : null;
      _loading = false;
    });
  }

  Future<void> _selecionarFoto() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _fotoBase64 = base64Encode(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adicionar em ${widget.tipoLabel}'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                labelText: 'Buscar alimento',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Buscar',
                  onPressed: _buscar,
                  icon: const Icon(Icons.search),
                ),
              ),
              onSubmitted: (_) => _buscar(),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              )
            else if (_alimentos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum alimento encontrado.'),
              )
            else
              DropdownButtonFormField<Alimento>(
                value: _selecionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Alimento',
                  border: OutlineInputBorder(),
                ),
                items: _alimentos.take(80).map((alimento) {
                  return DropdownMenuItem(
                    value: alimento,
                    child: Text(alimento.nome ?? 'Alimento sem nome'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selecionado = value),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantidadeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade (g)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selecionarFoto,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: Text(_fotoBase64 == null
                        ? 'Foto da refeicao'
                        : 'Foto selecionada'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selecionado == null
              ? null
              : () {
                  Navigator.pop(
                    context,
                    _RegistroDiarioResult(
                      alimento: _selecionado!,
                      quantidadeGramas: double.tryParse(
                            _quantidadeController.text
                                .trim()
                                .replaceAll(',', '.'),
                          ) ??
                          0,
                      fotoBase64: _fotoBase64,
                    ),
                  );
                },
          child: const Text('Registrar'),
        ),
      ],
    );
  }
}

class _RegistroDiarioResult {
  final Alimento alimento;
  final double quantidadeGramas;
  final String? fotoBase64;

  const _RegistroDiarioResult({
    required this.alimento,
    required this.quantidadeGramas,
    required this.fotoBase64,
  });
}

class _ResumoMacrosCard extends StatelessWidget {
  final DiarioNutricionalResumo resumo;

  const _ResumoMacrosCard({required this.resumo});

  static const _metaCalorias = 2000.0;
  static const _metaProteinas = 150.0;
  static const _metaCarboidratos = 250.0;
  static const _metaGorduras = 65.0;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo do dia',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text(
              '${resumo.totalCalorias.toStringAsFixed(0)} kcal',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _BarraProgresso(
                label: 'Calorias',
                valor: resumo.totalCalorias,
                meta: _metaCalorias,
                unidade: 'kcal',
                cor: Colors.red),
            const SizedBox(height: 12),
            _BarraProgresso(
                label: 'Proteinas',
                valor: resumo.totalProteinas,
                meta: _metaProteinas,
                unidade: 'g',
                cor: Colors.blue),
            const SizedBox(height: 12),
            _BarraProgresso(
                label: 'Carboidratos',
                valor: resumo.totalCarboidratos,
                meta: _metaCarboidratos,
                unidade: 'g',
                cor: Colors.orange),
            const SizedBox(height: 12),
            _BarraProgresso(
                label: 'Gorduras',
                valor: resumo.totalGorduras,
                meta: _metaGorduras,
                unidade: 'g',
                cor: Colors.purple),
          ],
        ),
      ),
    );
  }
}

class _BarraProgresso extends StatelessWidget {
  final String label;
  final double valor;
  final double meta;
  final String unidade;
  final Color cor;

  const _BarraProgresso({
    required this.label,
    required this.valor,
    required this.meta,
    required this.unidade,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final progresso = (valor / meta).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: GridColors.textMuted)),
            Text(
              '${valor.toStringAsFixed(1)} / ${meta.toStringAsFixed(0)} $unidade',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progresso,
          backgroundColor: GridColors.secondarySoft,
          color: cor,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}

class _EmptyDiarioCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyDiarioCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.restaurant_menu_outlined),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('Nenhuma refeicao registrada para este dia.')),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefeicaoCard extends StatelessWidget {
  final String tipo;
  final String label;
  final DiarioNutricionalRefeicao? refeicao;
  final bool saving;
  final VoidCallback onAdd;
  final ValueChanged<DiarioNutricionalItem> onRemove;

  const _RefeicaoCard({
    required this.tipo,
    required this.label,
    required this.refeicao,
    required this.saving,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final itens = refeicao?.itens ?? const <DiarioNutricionalItem>[];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _MealPhoto(foto: refeicao?.foto),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        '${(refeicao?.totalCalorias ?? 0).toStringAsFixed(0)} kcal | '
                        'P ${(refeicao?.totalProteinas ?? 0).toStringAsFixed(1)}g | '
                        'C ${(refeicao?.totalCarboidratos ?? 0).toStringAsFixed(1)}g | '
                        'G ${(refeicao?.totalGorduras ?? 0).toStringAsFixed(1)}g',
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Alimento'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (itens.isEmpty)
              const Text('Sem alimentos registrados nesta refeicao.')
            else
              ...itens.map((item) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.alimento.nome ?? 'Alimento'),
                  subtitle:
                      Text('${item.quantidadeGramas.toStringAsFixed(0)} g'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${item.calorias.toStringAsFixed(0)} kcal'),
                      IconButton(
                        tooltip: 'Remover',
                        onPressed: saving ? null : () => onRemove(item),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MealPhoto extends StatelessWidget {
  final String? foto;

  const _MealPhoto({required this.foto});

  @override
  Widget build(BuildContext context) {
    final bytes = _decode(foto);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 56,
        height: 56,
        color: Colors.green.shade50,
        child: bytes == null
            ? const Icon(Icons.restaurant_outlined)
            : Image.memory(bytes, fit: BoxFit.cover),
      ),
    );
  }

  Uint8List? _decode(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    try {
      final normalized = value.contains(',') ? value.split(',').last : value;
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }
}
