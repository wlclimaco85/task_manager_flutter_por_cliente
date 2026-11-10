import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:intl/intl.dart';

import '../models/auth_utility.dart';
import '../services/consulta_cnpj_service.dart';
import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/dropdown_helpers.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';
import '../windows/dialogs/fornecedor_form_dialog.dart';
import 'automacao_fiscal_screen.dart' show montarPayloadParceiroAutomacaoFiscal;

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

  /// Fornecedor (beneficiario) e observacao/instrucoes impressas no boleto.
  final String? beneficiarioNome;
  final String? beneficiarioDocumento;
  final String? observacao;
  final String? numeroDocumento;
  final String? linhaDigitavel;

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
    this.beneficiarioNome,
    this.beneficiarioDocumento,
    this.observacao,
    this.numeroDocumento,
    this.linhaDigitavel,
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
        beneficiarioNome: j['beneficiarioNome']?.toString(),
        beneficiarioDocumento: j['beneficiarioDocumento']?.toString(),
        observacao: j['observacao']?.toString(),
        numeroDocumento: j['numeroDocumento']?.toString(),
        linhaDigitavel: j['linhaDigitavel']?.toString(),
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
  String? observacao,
}) =>
    {
      if (observacao != null && observacao.trim().isNotEmpty)
        'observacao': observacao.trim(),
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

/// "12345678000195" -> "12.345.678/0001-95"; "12345678909" -> "123.456.789-09"; outro tamanho: devolve so os digitos.
String formatarDocumento(String? documento) {
  final d = (documento ?? '').replaceAll(RegExp(r'\D'), '');
  if (d.length == 14) {
    return '${d.substring(0, 2)}.${d.substring(2, 5)}.${d.substring(5, 8)}/${d.substring(8, 12)}-${d.substring(12)}';
  }
  if (d.length == 11) {
    return '${d.substring(0, 3)}.${d.substring(3, 6)}.${d.substring(6, 9)}-${d.substring(9)}';
  }
  return d;
}

/// Dados iniciais do formulario de cadastro do cliente a partir da ReceitaWS (mesmo contrato do cadastro
/// de pendencias da Automacao Fiscal). [receita] nulo = consulta falhou: o usuario preenche o resto.
Map<String, dynamic> montarDadosCadastroClienteReceitaWs({
  required String documento,
  Map<String, dynamic>? receita,
  int? empresaId,
  String? empresaNome,
  int? parceiroId,
  String? parceiroNome,
}) {
  String t(dynamic v) => (v ?? '').toString().trim();
  final doc = documento.replaceAll(RegExp(r'\D'), '');
  return {
    'empresaId': empresaId,
    'empresaNome': empresaNome,
    'parceiroId': parceiroId,
    'parceiroNome': parceiroNome,
    'nome': t(receita?['nomeFantasia']).isNotEmpty
        ? t(receita?['nomeFantasia'])
        : t(receita?['nome'] ?? receita?['razaoSocial']),
    'razaoSocial': t(receita?['razaoSocial'] ?? receita?['nome']),
    'cpf': doc,
    'cnpj': doc,
    'ie': '',
    'incrMun': '',
    'email': t(receita?['email']),
    'telefone1': t(receita?['telefone']),
    'telefone2': '',
    'cep': t(receita?['cep']),
    'rua': t(receita?['logradouro'] ?? receita?['rua']),
    'numero': t(receita?['numero']),
    'complemento': t(receita?['complemento']),
    'bairro': t(receita?['bairro']),
    'cidade': t(receita?['municipio'] ?? receita?['cidade']),
    'estado': t(receita?['uf'] ?? receita?['estado']),
    'status': 'ATIVO',
    'observacao': 'Cadastrado na importação de boleto (ReceitaWS)',
  };
}

/// Cadastra o cliente do boleto: consulta o CNPJ na ReceitaWS, abre o formulario de cadastro pre-preenchido
/// e, ao salvar, devolve `{id, nome}` do parceiro criado. Devolve null se o usuario cancelar ou falhar.
Future<Map<String, dynamic>?> cadastrarClientePorDocumento(
    BuildContext context, String documento) async {
  final doc = documento.replaceAll(RegExp(r'\D'), '');
  if (doc.length != 11 && doc.length != 14) {
    _snack(context, 'Documento inválido para cadastro.', erro: true);
    return null;
  }

  Map<String, dynamic>? receita;
  if (doc.length == 14) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Consultando o CNPJ na ReceitaWS...'),
        duration: Duration(seconds: 20)));
    try {
      receita = await ConsultaCnpjService.consultar(doc);
    } catch (e) {
      AppLogger.i.warn('[BOLETO-PDF] consulta ReceitaWS falhou para $doc: $e');
    }
    if (context.mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (receita == null && context.mounted) {
      _snack(context,
          'Não foi possível obter os dados na ReceitaWS. Preencha o cadastro manualmente.',
          erro: true);
    }
  }
  if (!context.mounted) return null;

  final empresa = AuthUtility.userInfo?.login?.empresa;
  final inicial = montarDadosCadastroClienteReceitaWs(
    documento: doc,
    receita: receita,
    empresaId: empresa?.id,
    empresaNome: empresa?.nome,
  );

  var salvou = false;
  await showDialog<void>(
    context: context,
    builder: (_) => FornecedorFormDialog(
      item: inicial,
      tituloOverride: 'Cadastrar cliente (ReceitaWS)',
      customSaveHandler: (payload) async {
        final resp = await NetworkCaller().postRequest(
          ApiLinks.insertParceiro,
          montarPayloadParceiroAutomacaoFiscal(payload),
        );
        final texto = resp.body?.toString().toLowerCase() ?? '';
        if (!resp.isSuccess && !texto.contains('existe')) {
          AppLogger.i.warn(
              '[BOLETO-PDF] cadastro do cliente $doc falhou (status ${resp.statusCode})');
        }
        return resp.isSuccess || texto.contains('existe');
      },
      onSaved: () => salvou = true,
    ),
  );
  if (!salvou) return null;

  // O cadastro devolve so bool: busca o parceiro recem criado pelo documento.
  final r = await DropdownHelpers.parceirosBusca(
      busca: doc, pagina: 0, empresaId: TenantContext.empresaId?.toString());
  for (final item in r.items) {
    final cpf = (item['cpf'] ?? item['cnpj'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
    if (cpf == doc) return item;
  }
  return r.items.isNotEmpty ? r.items.first : null;
}

class BoletoPdfCaller {
  static Future<BoletoPreview> preview(Uint8List bytes, String nome,
      {bool receber = false}) async {
    final empresaId = TenantContext.empresaId;
    if (empresaId == null) throw Exception('Empresa não identificada na sessão.');
    final req = http.MultipartRequest(
        'POST',
        Uri.parse(receber
            ? ApiLinks.boletoReceberPdfPreview
            : ApiLinks.boletoPdfPreview));
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
      Uint8List bytes, String nome, Map<String, dynamic> dados,
      {bool receber = false}) async {
    final req = http.MultipartRequest(
        'POST',
        Uri.parse(receber
            ? ApiLinks.boletoReceberPdfImportar
            : ApiLinks.boletoPdfImportar));
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
/// Retorna true quando a conta foi criada. [receber] = conta a receber (cliente = pagador do boleto).
Future<bool> importarBoletoPdf(BuildContext context, {bool receber = false}) async {
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
    preview = await BoletoPdfCaller.preview(bytes, file.name, receber: receber);
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
    builder: (_) => BoletoConfirmacaoDialog(
        nomeArquivo: file.name, preview: preview, receber: receber),
  );
  if (dados == null || !context.mounted) return false;

  try {
    await BoletoPdfCaller.importar(bytes, file.name, dados, receber: receber);
    if (context.mounted) {
      _snack(
          context,
          receber
              ? 'Conta a receber gerada e boleto anexado.'
              : 'Conta a pagar gerada e boleto anexado.');
    }
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

  /// Conta a receber: o cliente e o pagador do boleto.
  final bool receber;
  const BoletoConfirmacaoDialog(
      {super.key,
      required this.nomeArquivo,
      required this.preview,
      this.receber = false});

  @override
  State<BoletoConfirmacaoDialog> createState() => _BoletoConfirmacaoDialogState();
}

class _BoletoConfirmacaoDialogState extends State<BoletoConfirmacaoDialog> {
  late final TextEditingController _valor;
  late final TextEditingController _obs;
  bool _cadastrando = false;
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
    _obs = TextEditingController(text: p.observacao ?? '');
    _vencimento = p.vencimento;
    _parceiroId = p.parceiroId;
    _parceiroNome = p.parceiroNome;
    _tipo = p.tipoSugerido;
  }

  @override
  void dispose() {
    _valor.dispose();
    _obs.dispose();
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
      observacao: _obs.text,
    ));
  }

  /// CPF/CNPJ do documento lido no boleto (so digitos) quando o cliente nao esta no cadastro.
  String get _documentoParaCadastro =>
      (widget.preview.documento ?? '').replaceAll(RegExp(r'\D'), '');

  bool get _podeCadastrar =>
      _parceiroId == null &&
      (_documentoParaCadastro.length == 11 || _documentoParaCadastro.length == 14);

  /// Consulta o CNPJ na ReceitaWS, abre o formulario de cadastro ja preenchido e, ao salvar, seleciona o cliente.
  Future<void> _cadastrarCliente() async {
    if (_cadastrando) return;
    setState(() => _cadastrando = true);
    try {
      final novo = await cadastrarClientePorDocumento(context, _documentoParaCadastro);
      if (novo != null && mounted) {
        setState(() {
          _parceiroId = (novo['id'] as num?)?.toInt();
          _parceiroNome = novo['nome']?.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _cadastrando = false);
    }
  }

  Widget _blocoFornecedor(BoletoPreview p) {
    final nome = (p.beneficiarioNome ?? '').trim();
    final doc = formatarDocumento(p.beneficiarioDocumento);
    final extras = [
      if ((p.numeroDocumento ?? '').trim().isNotEmpty) 'Doc. ${p.numeroDocumento!.trim()}',
      if ((p.linhaDigitavel ?? '').trim().isNotEmpty) p.linhaDigitavel!.trim(),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Fornecedor / Beneficiário',
          style: TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Text(nome.isEmpty ? 'Não identificado no boleto' : nome,
          style: TextStyle(color: nome.isEmpty ? Colors.black45 : null)),
      if (doc.isNotEmpty)
        Text(doc, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      for (final e in extras)
        Text(e, style: const TextStyle(fontSize: 11, color: Colors.black45)),
      const SizedBox(height: 12),
    ]);
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
              _blocoFornecedor(p),
              Text(widget.receber ? 'Cliente (pagador)' : 'Cliente',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
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
              if (_podeCadastrar)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _cadastrando ? null : _cadastrarCliente,
                    icon: _cadastrando
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.person_add_alt_1, size: 18),
                    label: Text(
                        'Cadastrar ${formatarDocumento(_documentoParaCadastro)} (ReceitaWS)'),
                  ),
                ),
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
              const SizedBox(height: 8),
              TextField(
                controller: _obs,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                    labelText: 'Observação (do boleto)',
                    alignLabelWithHint: true),
              ),
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
