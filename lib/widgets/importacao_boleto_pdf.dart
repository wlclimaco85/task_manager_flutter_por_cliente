import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:intl/intl.dart';

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/dropdown_helpers.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';

/// Tipos da conta gerada a partir do boleto (o backend usa o valor para escolher a categoria financeira).
const String kBoletoTipoTributo = 'TRIBUTO';
const String kBoletoTipoHonorarios = 'HONORARIOS';
const String kBoletoTipoOutros = 'OUTROS';

/// Dados que o backend leu do PDF (`POST /api/boletos/preview`). Nada foi gravado ainda.
class BoletoPreview {
  final String tipoDocumento;
  final double? valor;
  final DateTime? vencimento;
  final String? documento;
  final int? parceiroId;
  final String? parceiroNome;
  final String tipoSugerido;
  final bool jaImportado;
  final String? aviso;

  const BoletoPreview({
    required this.tipoDocumento,
    this.valor,
    this.vencimento,
    this.documento,
    this.parceiroId,
    this.parceiroNome,
    this.tipoSugerido = kBoletoTipoTributo,
    this.jaImportado = false,
    this.aviso,
  });

  factory BoletoPreview.fromJson(Map<String, dynamic> j) => BoletoPreview(
        tipoDocumento: j['tipoDocumento']?.toString() ?? 'DESCONHECIDO',
        valor: (j['valor'] as num?)?.toDouble(),
        vencimento: DateTime.tryParse(j['dataVencimento']?.toString() ?? ''),
        documento: j['documento']?.toString(),
        parceiroId: (j['parceiroId'] as num?)?.toInt(),
        parceiroNome: j['parceiroNome']?.toString(),
        tipoSugerido: j['tipoSugerido']?.toString() ?? kBoletoTipoTributo,
        jaImportado: j['jaImportado'] == true,
        aviso: j['aviso']?.toString(),
      );
}

/// Corpo (`data`) do `POST /api/boletos/importar-boleto`.
Map<String, dynamic> montarDadosImportacaoBoleto({
  required int empresaId,
  required int parceiroId,
  required String parceiroNome,
  required double valor,
  required DateTime vencimento,
  required String tipo,
}) =>
    {
      'descricao': 'Boleto - $parceiroNome',
      'valor': valor,
      'dataVencimento': DateFormat('yyyy-MM-dd').format(vencimento),
      'empresaId': empresaId,
      'parceiroId': parceiroId,
      'tipo': tipo,
    };

/// Texto "1.234,56" ou "1234.56" para numero; null se invalido ou menor/igual a zero.
double? valorDeTexto(String texto) {
  var t = texto.trim().replaceAll(RegExp(r'[^0-9,.\-]'), '');
  if (t.contains(',')) t = t.replaceAll('.', '').replaceAll(',', '.');
  final v = double.tryParse(t);
  return (v == null || v <= 0) ? null : v;
}

class BoletoPdfCaller {
  static Future<BoletoPreview> preview(Uint8List bytes, String nome) async {
    final empresaId = TenantContext.empresaId;
    if (empresaId == null) throw Exception('Empresa não identificada na sessão.');
    final req = http.MultipartRequest('POST', Uri.parse(ApiLinks.boletoPdfPreview));
    req.headers.addAll(TenantContext.headers);
    req.fields['empresaId'] = empresaId.toString();
    req.files.add(http.MultipartFile.fromBytes('pdf', bytes,
        filename: nome, contentType: http_parser.MediaType('application', 'pdf')));
    final resp = await http.Response.fromStream(await req.send());
    if (resp.statusCode != 200) {
      throw Exception(_mensagemDeErro(resp));
    }
    return BoletoPreview.fromJson(
        jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>);
  }

  static Future<void> importar(
      Uint8List bytes, String nome, Map<String, dynamic> dados) async {
    final req = http.MultipartRequest('POST', Uri.parse(ApiLinks.boletoPdfImportar));
    req.headers.addAll(TenantContext.headers);
    req.files.add(http.MultipartFile.fromBytes('pdf', bytes,
        filename: nome, contentType: http_parser.MediaType('application', 'pdf')));
    req.files.add(http.MultipartFile.fromBytes('data', utf8.encode(jsonEncode(dados)),
        filename: 'data.json', contentType: http_parser.MediaType('application', 'json')));
    final resp = await http.Response.fromStream(await req.send());
    if (resp.statusCode != 200) {
      throw Exception(_mensagemDeErro(resp));
    }
  }

  static String _mensagemDeErro(http.Response resp) {
    try {
      final j = jsonDecode(utf8.decode(resp.bodyBytes));
      if (j is Map && (j['message'] ?? j['error'] ?? j['mensagem']) != null) {
        return (j['message'] ?? j['error'] ?? j['mensagem']).toString();
      }
    } catch (_) {}
    return 'Erro ${resp.statusCode} ao processar o boleto.';
  }
}

/// Fluxo "Importar Boleto" (PDF): escolhe o arquivo, mostra os dados lidos para conferencia (cliente, valor,
/// vencimento e tipo tributo/honorarios/outros) e, ao confirmar, gera a conta a pagar com o PDF anexado.
/// Retorna true quando a conta foi criada.
Future<bool> importarBoletoPdf(BuildContext context) async {
  final picked = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    withData: true,
  );
  if (picked == null || picked.files.isEmpty || !context.mounted) return false;

  final file = picked.files.first;
  Uint8List? bytes = file.bytes;
  if (bytes == null && file.path != null) {
    try {
      bytes = await File(file.path!).readAsBytes();
    } catch (e) {
      AppLogger.i.warn('[BOLETO-PDF] não foi possível ler ${file.name}: $e');
    }
  }
  if (bytes == null) {
    _snack(context, 'Não foi possível ler o arquivo.', erro: true);
    return false;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(
      content: Text('Lendo o boleto...'), duration: Duration(seconds: 30)));
  BoletoPreview preview;
  try {
    preview = await BoletoPdfCaller.preview(bytes, file.name);
  } catch (e) {
    AppLogger.i.warn('[BOLETO-PDF] preview falhou para ${file.name}: $e');
    messenger.hideCurrentSnackBar();
    if (context.mounted) {
      _snack(context, '$e'.replaceFirst('Exception: ', ''), erro: true);
    }
    return false;
  }
  messenger.hideCurrentSnackBar();
  if (!context.mounted) return false;

  final dados = await showDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BoletoConfirmacaoDialog(nomeArquivo: file.name, preview: preview),
  );
  if (dados == null || !context.mounted) return false;

  try {
    await BoletoPdfCaller.importar(bytes, file.name, dados);
    if (context.mounted) _snack(context, 'Conta a pagar gerada e boleto anexado.');
    return true;
  } catch (e) {
    AppLogger.i.warn('[BOLETO-PDF] importação falhou para ${file.name}: $e');
    if (context.mounted) {
      _snack(context, '$e'.replaceFirst('Exception: ', ''), erro: true);
    }
    return false;
  }
}

void _snack(BuildContext context, String msg, {bool erro = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor: erro ? GridColors.error : GridColors.success,
    content: Text(msg),
  ));
}

/// Popup de conferencia. Devolve o corpo `data` do importar-boleto, ou null se cancelar.
class BoletoConfirmacaoDialog extends StatefulWidget {
  final String nomeArquivo;
  final BoletoPreview preview;
  const BoletoConfirmacaoDialog(
      {super.key, required this.nomeArquivo, required this.preview});

  @override
  State<BoletoConfirmacaoDialog> createState() => _BoletoConfirmacaoDialogState();
}

class _BoletoConfirmacaoDialogState extends State<BoletoConfirmacaoDialog> {
  late final TextEditingController _valor;
  DateTime? _vencimento;
  int? _parceiroId;
  String? _parceiroNome;
  String _tipo = kBoletoTipoTributo; // vem marcado como Tributo

  @override
  void initState() {
    super.initState();
    final p = widget.preview;
    _valor = TextEditingController(
        text: p.valor == null
            ? ''
            : p.valor!.toStringAsFixed(2).replaceAll('.', ','));
    _vencimento = p.vencimento;
    _parceiroId = p.parceiroId;
    _parceiroNome = p.parceiroNome;
    _tipo = p.tipoSugerido;
  }

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final hoje = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _vencimento ?? hoje,
      firstDate: DateTime(hoje.year - 2),
      lastDate: DateTime(hoje.year + 5),
    );
    if (d != null) setState(() => _vencimento = d);
  }

  Future<void> _escolherCliente() async {
    final escolhido = await showDialog<Map<String, dynamic>>(
        context: context, builder: (_) => const _BuscarClienteDialog());
    if (escolhido != null) {
      setState(() {
        _parceiroId = (escolhido['id'] as num?)?.toInt();
        _parceiroNome = escolhido['nome']?.toString();
      });
    }
  }

  bool get _valido =>
      _parceiroId != null &&
      valorDeTexto(_valor.text) != null &&
      _vencimento != null;

  void _confirmar() {
    final empresaId = TenantContext.empresaId;
    if (!_valido || empresaId == null) return;
    Navigator.of(context).pop(montarDadosImportacaoBoleto(
      empresaId: empresaId,
      parceiroId: _parceiroId!,
      parceiroNome: _parceiroNome ?? 'Cliente',
      valor: valorDeTexto(_valor.text)!,
      vencimento: _vencimento!,
      tipo: _tipo,
    ));
  }

  Widget _tipoOpcao(String valor, String rotulo) => CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(rotulo),
        value: _tipo == valor,
        // exclusivo: marcar um desmarca os outros; nunca fica sem tipo
        onChanged: (_) => setState(() => _tipo = valor),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.preview;
    final data = _vencimento == null
        ? 'Selecionar'
        : DateFormat('dd/MM/yyyy').format(_vencimento!);
    return AlertDialog(
      title: const Text('Confirmar importação do boleto'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Arquivo: ${widget.nomeArquivo}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              if (p.aviso != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      border: Border.all(color: Colors.amber.shade300),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(p.aviso!, style: const TextStyle(fontSize: 12)),
                ),
              ],
              const SizedBox(height: 12),
              const Text('Cliente', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                    child: Text(_parceiroNome ?? 'Não identificado',
                        style: TextStyle(
                            color: _parceiroId == null ? Colors.red.shade700 : null))),
                TextButton(
                    onPressed: _escolherCliente,
                    child: Text(_parceiroId == null ? 'Selecionar' : 'Trocar')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _valor,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Valor (R\$)'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Vencimento'),
                    child: InkWell(onTap: _escolherData, child: Text(data)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w600)),
              _tipoOpcao(kBoletoTipoTributo, 'Tributo'),
              _tipoOpcao(kBoletoTipoHonorarios, 'Honorários'),
              _tipoOpcao(kBoletoTipoOutros, 'Outros'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _valido && !p.jaImportado ? _confirmar : null,
          child: const Text('Confirmar e gerar conta'),
        ),
      ],
    );
  }
}

/// Busca de cliente (parceiro) por nome ou CNPJ/CPF, escopada pelo tenant no backend.
class _BuscarClienteDialog extends StatefulWidget {
  const _BuscarClienteDialog();

  @override
  State<_BuscarClienteDialog> createState() => _BuscarClienteDialogState();
}

class _BuscarClienteDialogState extends State<_BuscarClienteDialog> {
  final _busca = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _itens = [];
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busca.dispose();
    super.dispose();
  }

  void _agendar(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _buscar);
  }

  Future<void> _buscar() async {
    setState(() => _carregando = true);
    final r = await DropdownHelpers.parceirosBusca(
        busca: _busca.text,
        pagina: 0,
        empresaId: TenantContext.empresaId?.toString());
    if (!mounted) return;
    setState(() {
      _itens = r.items;
      _erro = r.erro;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Selecionar cliente'),
      content: SizedBox(
        width: 420,
        height: 360,
        child: Column(children: [
          TextField(
            controller: _busca,
            autofocus: true,
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search), hintText: 'Nome ou CNPJ/CPF'),
            onChanged: _agendar,
          ),
          if (_carregando) const LinearProgressIndicator(),
          if (_erro != null)
            Padding(padding: const EdgeInsets.all(8), child: Text(_erro!)),
          Expanded(
            child: ListView.builder(
              itemCount: _itens.length,
              itemBuilder: (_, i) => ListTile(
                dense: true,
                title: Text(_itens[i]['nome']?.toString() ?? ''),
                subtitle: Text(_itens[i]['cpf']?.toString() ?? ''),
                onTap: () => Navigator.of(context).pop(_itens[i]),
              ),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar')),
      ],
    );
  }
}
