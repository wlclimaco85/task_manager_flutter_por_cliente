import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/dropdown_helpers.dart';
import '../utils/tenant_context.dart';
import 'searchable_dropdown.dart';

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

/// Chave de 44 digitos do XML de NF-e (`Id="NFe<chave>"`), ou null se o texto nao for XML de NF-e.
String? chaveDoXmlNfe(String xml) => RegExp(r'Id="NFe(\d{44})"').firstMatch(xml)?.group(1);

/// Mensagem de erro se o XML nao bate com a nota (chave diferente, sem chave ou sem itens); null se pode importar.
String? erroXmlDiferenteDaNota(String xml, String? chaveNota) {
  final chaveXml = chaveDoXmlNfe(xml);
  if (chaveXml == null) return 'O arquivo não é um XML de NF-e (chave de acesso não encontrada).';
  final chave = (chaveNota ?? '').replaceAll(RegExp(r'\D'), '');
  if (chave.length != 44) return 'A nota não tem chave de acesso válida para conferir com o XML.';
  if (chaveXml != chave) return 'O XML é da chave $chaveXml, mas esta nota é da chave $chave. Importe o XML correto.';
  if (!xml.contains('<det')) return 'O XML não tem itens (<det>). Importe o XML completo (procNFe).';
  return null;
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
  // Nota sem itens: adiciona produto (mesmo seletor da tela de detalhe) para a nota ficar referenciada.
  Map<String, dynamic>? _produtoSel;
  bool _adicionandoProduto = false;
  final _qtdNovoCtrl = TextEditingController(text: '1');
  final _precoNovoCtrl = TextEditingController();

  String get _id => widget.nota['id']?.toString() ?? '';
  String? get _empId => AuthUtility.userInfo?.login?.empresa?.id?.toString();
  String? get _parcId => AuthUtility.userInfo?.login?.parceiro?.id?.toString();

  @override
  void initState() {
    super.initState();
    _carregarItens();
  }

  @override
  void dispose() {
    _motivo.dispose();
    _qtdNovoCtrl.dispose();
    _precoNovoCtrl.dispose();
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

  /// Mensagem que o backend devolve no erro (campo "message"); fallback generico se nao vier.
  String _mensagemErroBusca(int status, String corpo, {String? fallback}) {
    try {
      final b = jsonDecode(corpo);
      if (b is Map && b['message'] is String && (b['message'] as String).isNotEmpty) {
        return b['message'] as String;
      }
    } catch (e) {
      AppLogger.i.warn('Devolucao NF-e: resposta de erro nao e JSON (HTTP $status): $e');
    }
    return fallback ?? 'Não foi possível buscar o XML na SEFAZ (HTTP $status). Tente de novo.';
  }

  /// Cria o item da nota (POST /api/nfe_item) com o produto escolhido; o backend vincula o produto e recalcula os totais.
  Future<void> _adicionarProduto() async {
    final p = _produtoSel;
    final qtd = _num(_qtdNovoCtrl.text);
    final preco = _num(_precoNovoCtrl.text);
    if (p == null) return;
    if (qtd == null || qtd <= 0 || preco == null || preco < 0) {
      setState(() => _erro = 'Informe quantidade e valor unitário do produto.');
      return;
    }
    setState(() {
      _adicionandoProduto = true;
      _erro = null;
    });
    String? erroAdd;
    try {
      final body = {
        'nfe_id': int.tryParse(_id) ?? _id,
        'produto': {'id': p['id']},
        'c_prod': (p['codigo'] ?? p['id']).toString(),
        'x_prod': (p['nome'] ?? '').toString(),
        'ncm': (p['ncm'] ?? '').toString(),
        'cfop': (p['cfop'] ?? '').toString(),
        'u_com': (p['unidadeComercial'] ?? p['unidade_comercial'] ?? p['unidade'] ?? '').toString().toUpperCase(),
        'q_com': qtd,
        'v_un_com': preco,
        'v_prod': qtd * preco,
      };
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe_item', body);
      if (r.statusCode != 200 && r.statusCode != 201) {
        erroAdd = _mensagemErroBusca(r.statusCode, r.body,
            fallback: 'Não foi possível adicionar o produto à nota (HTTP ${r.statusCode}).');
      }
    } catch (e, st) {
      AppLogger.i.error('Devolucao NF-e #$_id: erro ao adicionar produto: $e', st);
      erroAdd = 'Erro ao adicionar o produto à nota: $e';
    }
    if (!mounted) return;
    setState(() => _adicionandoProduto = false);
    if (erroAdd != null) {
      setState(() => _erro = erroAdd);
      return;
    }
    setState(() {
      _produtoSel = null;
      _precoNovoCtrl.clear();
    });
    await _carregarItens();
  }

  Future<void> _buscarXmlSefaz() async {
    setState(() => _buscandoXml = true);
    String? erroBusca;
    try {
      final url = '${ApiLinks.baseUrl}/api/nfe/$_id/buscar-xml-sefaz';
      // Console do navegador (tambem em producao): request e resposta, sem token. O diagnostico da SEFAZ vem no corpo.
      debugPrint('[DEVOLUCAO-BUSCA] REQUEST POST ${TenantContext.applyToUrl(url)} | nfeId=$_id | chave=${widget.nota['chave']} | body={}');
      final r = await TenantContext.post(url, {});
      debugPrint('[DEVOLUCAO-BUSCA] RESPONSE HTTP ${r.statusCode} | ${r.body.length > 4000 ? r.body.substring(0, 4000) : r.body}');
      if (!mounted) return;
      if (r.statusCode != 200) {
        erroBusca = _mensagemErroBusca(r.statusCode, r.body);
      } else {
        _semItensAposBuscar = true;
      }
    } catch (e, st) {
      AppLogger.i.error('Devolucao NF-e #$_id: erro ao buscar XML na SEFAZ: $e', st);
      erroBusca = 'Erro ao buscar o XML na SEFAZ: $e';
    }
    if (!mounted) return;
    setState(() => _buscandoXml = false);
    await _carregarItens();
    if (!mounted) return;
    // _carregarItens zera _erro: aplica a mensagem da busca depois, para ela aparecer.
    setState(() {
      if (erroBusca != null) {
        _erro = erroBusca;
      } else if (_linhas.isEmpty && _semItensAposBuscar && _erro == null) {
        _erro = 'A SEFAZ respondeu, mas a nota continua sem itens. Aguarde alguns instantes e tente de novo.';
      }
    });
    _semItensAposBuscar = false;
  }

  /// Importa o XML da nota por arquivo. So aceita se for da MESMA chave da nota (o que ja temos do resumo da SEFAZ).
  Future<void> _importarXmlArquivo() async {
    final FilePickerResult? picked;
    try {
      picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['xml'], withData: true);
    } catch (e, st) {
      AppLogger.i.error('Devolucao NF-e #$_id: erro ao abrir o seletor de arquivo: $e', st);
      if (mounted) setState(() => _erro = 'Não foi possível abrir o seletor de arquivos: $e');
      return;
    }
    if (picked == null || picked.files.isEmpty || picked.files.first.bytes == null || !mounted) return;
    final file = picked.files.first;
    final erroXml = erroXmlDiferenteDaNota(utf8.decode(file.bytes!, allowMalformed: true), widget.nota['chave']?.toString());
    if (erroXml != null) {
      setState(() => _erro = erroXml);
      return;
    }
    setState(() {
      _buscandoXml = true;
      _erro = null;
    });
    String? erroImport;
    try {
      final url = '${ApiLinks.baseUrl}/api/nfe/entrada/import';
      debugPrint('[DEVOLUCAO-IMPORT] REQUEST POST ${TenantContext.applyToUrl(url)} | nfeId=$_id | arquivo=${file.name}');
      final r = await TenantContext.postMultipart(url, fileBytes: file.bytes!, fileName: file.name, fileField: 'xml');
      debugPrint('[DEVOLUCAO-IMPORT] RESPONSE HTTP ${r.statusCode} | ${r.body.length > 2000 ? r.body.substring(0, 2000) : r.body}');
      if (r.statusCode != 200 && r.statusCode != 201) {
        erroImport = _mensagemErroBusca(r.statusCode, r.body, fallback: 'Não foi possível importar o XML (HTTP ${r.statusCode}).');
      }
    } catch (e, st) {
      AppLogger.i.error('Devolucao NF-e #$_id: erro ao importar XML por arquivo: $e', st);
      erroImport = 'Erro ao importar o XML: $e';
    }
    if (!mounted) return;
    setState(() => _buscandoXml = false);
    await _carregarItens();
    if (!mounted) return;
    if (erroImport != null) {
      setState(() => _erro = erroImport);
    } else if (_linhas.isEmpty) {
      setState(() => _erro = 'O XML foi importado, mas a nota continua sem itens.');
    }
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
      content: SingleChildScrollView(
        child: SizedBox(
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
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('devolucao_importar_xml'),
                    onPressed: _buscandoXml ? null : _importarXmlArquivo,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importar XML (arquivo)'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Ou adicione o produto desta nota para ela ficar referenciada:'),
                  const SizedBox(height: 8),
                  SearchableDropdownField(
                    key: const Key('devolucao_produto'),
                    label: 'Produto',
                    value: _produtoSel?['id']?.toString(),
                    items: const [],
                    valueField: 'id',
                    displayField: 'nome',
                    nullable: true,
                    nullLabel: '— Selecione —',
                    onChanged: (_) {},
                    loadPage: ({String? busca, required int pagina}) => DropdownHelpers.produtosContabeisBusca(
                      busca: busca,
                      pagina: pagina,
                      tamanho: 20,
                      empresaId: _empId,
                      parceiroId: _parcId,
                    ),
                    labelResolver: DropdownHelpers.produtoContabilLabelPorId,
                    onItemSelected: (p) => setState(() {
                      _produtoSel = p;
                      _precoNovoCtrl.text = p == null ? '' : _fmt(_num(p['preco']) ?? 0);
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: TextField(
                          key: const Key('devolucao_produto_qtd'),
                          controller: _qtdNovoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Quantidade', isDense: true, border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 140,
                        child: TextField(
                          key: const Key('devolucao_produto_preco'),
                          controller: _precoNovoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Valor unitário', isDense: true, border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('devolucao_adicionar_produto'),
                    onPressed: _produtoSel == null || _adicionandoProduto ? null : _adicionarProduto,
                    icon: const Icon(Icons.add),
                    label: Text(_adicionandoProduto ? 'Adicionando...' : 'Adicionar produto à nota'),
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
