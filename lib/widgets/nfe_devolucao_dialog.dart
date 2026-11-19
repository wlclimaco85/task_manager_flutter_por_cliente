import 'dart:convert';

import 'package:flutter/material.dart';

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/tenant_context.dart';

/// Resultado do dialogo de devolucao: motivo e os itens escolhidos (id do item da nota + quantidade devolvida).
class NfeDevolucaoEscolha {
  final String motivo;
  final List<Map<String, dynamic>> itens;
  const NfeDevolucaoEscolha(this.motivo, this.itens);
}

/// Dialogo "Devolver NF-e de Entrada": traz TODOS os itens da nota (todos marcados) para o usuario desmarcar o que nao
/// vai devolver ou reduzir a quantidade. Nota importada da SEFAZ sem itens oferece "Buscar XML SEFAZ" ali mesmo.
Future<NfeDevolucaoEscolha?> mostrarDialogoDevolucaoNfe(BuildContext context, Map<String, dynamic> nota) {
  return showDialog<NfeDevolucaoEscolha>(
    context: context,
    builder: (_) => NfeDevolucaoDialog(nota: nota),
  );
}

class NfeDevolucaoDialog extends StatefulWidget {
  final Map<String, dynamic> nota;
  const NfeDevolucaoDialog({super.key, required this.nota});

  @override
  State<NfeDevolucaoDialog> createState() => _NfeDevolucaoDialogState();
}

class _LinhaItem {
  final Map<String, dynamic> item;
  final double qtdNota;
  bool marcado = true;
  final TextEditingController qtd;
  _LinhaItem(this.item, this.qtdNota) : qtd = TextEditingController(text: _fmt(qtdNota));
}

String _fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.'));
}

class _NfeDevolucaoDialogState extends State<NfeDevolucaoDialog> {
  final _motivo = TextEditingController(text: 'Devolução de mercadoria');
  List<_LinhaItem> _linhas = [];
  bool _carregando = true;
  bool _buscandoXml = false;
  bool _semItensAposBuscar = false;
  String? _erro;

  String get _id => widget.nota['id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  @override
  void dispose() {
    _motivo.dispose();
    for (final l in _linhas) {
      l.qtd.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarItens() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final r = await TenantContext.get('${ApiLinks.baseUrl}/api/nfe_item?nfeId=$_id&tamanho=500');
      if (!mounted) return;
      if (r.statusCode != 200) {
        setState(() {
          _erro = 'Não foi possível carregar os itens da nota (HTTP ${r.statusCode}).';
          _carregando = false;
        });
        return;
      }
      final b = jsonDecode(r.body);
      final d = b is Map ? (b['data'] is Map ? b['data']['dados'] : b['data']) : b;
      final itens = (d as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final comId = itens.where((i) => i['id'] != null).toList();
      for (final l in _linhas) {
        l.qtd.dispose();
      }
      setState(() {
        _linhas = [for (final i in comId) _LinhaItem(i, _num(i['q_com'] ?? i['qCom']) ?? 1)];
        if (itens.isNotEmpty && comId.isEmpty) {
          _erro = 'Os itens da nota não têm identificador. Atualize a nota (Buscar XML SEFAZ) e tente de novo.';
        }
        _carregando = false;
      });
    } catch (e, st) {
      AppLogger.i.error('Devolucao NF-e #$_id: erro ao carregar itens: $e', st);
      if (mounted) {
        setState(() {
          _erro = 'Não foi possível carregar os itens da nota: $e';
          _carregando = false;
        });
      }
    }
  }

  Future<void> _buscarXmlSefaz() async {
    setState(() => _buscandoXml = true);
    try {
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe/$_id/buscar-xml-sefaz', {});
      if (!mounted) return;
      if (r.statusCode != 200) {
        setState(() => _erro = 'A SEFAZ ainda não liberou o XML (HTTP ${r.statusCode}). Aguarde alguns instantes e tente de novo.');
      } else {
        _semItensAposBuscar = true;
      }
    } catch (e, st) {
      AppLogger.i.error('Devolucao NF-e #$_id: erro ao buscar XML na SEFAZ: $e', st);
      if (mounted) setState(() => _erro = 'Erro ao buscar o XML na SEFAZ: $e');
    }
    if (!mounted) return;
    setState(() => _buscandoXml = false);
    await _carregarItens();
    if (mounted && _linhas.isEmpty && _semItensAposBuscar && _erro == null) {
      setState(() => _erro = 'A SEFAZ respondeu, mas a nota continua sem itens. Aguarde alguns instantes e tente de novo.');
    }
    _semItensAposBuscar = false;
  }

  String? _validar() {
    final marcados = _linhas.where((l) => l.marcado).toList();
    if (marcados.isEmpty) return 'Marque pelo menos um item para devolver.';
    for (final l in marcados) {
      final q = _num(l.qtd.text);
      if (q == null || q <= 0) return 'Informe a quantidade do item ${l.item['x_prod'] ?? l.item['xProd'] ?? ''}.';
      if (q > l.qtdNota) {
        return 'A quantidade do item ${l.item['x_prod'] ?? l.item['xProd'] ?? ''} não pode passar de ${_fmt(l.qtdNota)}.';
      }
    }
    return null;
  }

  void _confirmar() {
    final erro = _validar();
    if (erro != null) {
      setState(() => _erro = erro);
      return;
    }
    Navigator.pop(
      context,
      NfeDevolucaoEscolha(_motivo.text.trim(), [
        for (final l in _linhas)
          if (l.marcado) {'id': l.item['id'], 'quantidade': _num(l.qtd.text)},
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final marcados = _linhas.where((l) => l.marcado).length;
    return AlertDialog(
      title: const Text('Devolver NF-e de Entrada', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 640,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nota #${widget.nota['numero'] ?? _id} - Chave: ${widget.nota['chave'] ?? ''}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const Key('devolucao_motivo'),
              controller: _motivo,
              decoration: const InputDecoration(labelText: 'Motivo da devolução', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            if (_carregando)
              const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            else if (_linhas.isEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Esta nota não tem itens. Se ela foi importada da SEFAZ, busque o XML completo para trazer os itens.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('devolucao_buscar_xml'),
                    onPressed: _buscandoXml ? null : _buscarXmlSefaz,
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: Text(_buscandoXml ? 'Buscando...' : 'Buscar XML SEFAZ'),
                  ),
                ],
              )
            else ...[
              Text('Itens da nota ($marcados de ${_linhas.length} para devolver)', style: tema.textTheme.titleSmall),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _linhas.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final l = _linhas[i];
                    final cod = l.item['c_prod'] ?? l.item['cProd'] ?? '';
                    final nome = l.item['x_prod'] ?? l.item['xProd'] ?? '';
                    return Row(
                      key: Key('devolucao_item_${l.item['id']}'),
                      children: [
                        Checkbox(value: l.marcado, onChanged: (v) => setState(() => l.marcado = v ?? false)),
                        Expanded(child: Text('$cod - $nome', maxLines: 2, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Text('Nota: ${_fmt(l.qtdNota)}', style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: l.qtd,
                            enabled: l.marcado,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Devolver', isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_erro!, style: TextStyle(color: tema.colorScheme.error)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('devolucao_confirmar'),
          onPressed: _carregando || _linhas.isEmpty ? null : _confirmar,
          child: const Text('Confirmar Devolução'),
        ),
      ],
    );
  }
}
