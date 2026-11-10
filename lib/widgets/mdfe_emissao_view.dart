import 'package:flutter/material.dart';

import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/file_saver_compat.dart';
import '../utils/tenant_context.dart';
import '../web/screens/transporte_veiculo_grid_screen.dart'
    show kTransporteUfs;
import 'transporte_config_tab.dart'
    show kTransporteTiposEmitente, kTransporteTiposTransportador;

/// Situacoes do MDF-e (espelho de `MdfeStatus` no backend).
const String kMdfeAutorizado = 'AUTORIZADO';
const int kMdfeTamanhoMinimoJustificativa = 15;

/// Maximo de reboques por MDF-e rodoviario (esquema 3.00).
const int kMdfeMaxReboques = 3;

/// Limites do esquema 3.00 para o roteiro do manifesto.
const int kMdfeMaxMunicipiosCarregamento = 50;
const int kMdfeMaxMunicipiosDescarga = 1000;
const int kMdfeMaxUfsPercurso = 25;

/// Municipio de carregamento no formato do corpo do POST.
Map<String, String> montarMunicipioMdfe(String ibge, String nome) =>
    {'codigoIbge': ibge.trim(), 'nome': nome.trim()};

/// Descarga (municipio + chaves de CT-e/NF-e) no formato do corpo do POST.
Map<String, dynamic> montarDescargaMdfe({
  required String ibge,
  required String nome,
  required List<String> chavesCte,
  required List<String> chavesNfe,
}) =>
    {
      'municipio': montarMunicipioMdfe(ibge, nome),
      'chavesCte': chavesCte,
      'chavesNfe': chavesNfe,
    };

/// Tipos de dispositivo do vale-pedagio (valor enviado ao backend -> rotulo).
const Map<String, String> kMdfeTiposValePedagio = {
  '01': 'TAG',
  '04': 'Leitura de placa',
};

/// Categorias de combinacao veicular (esquema 3.00).
const Map<String, String> kMdfeCategoriasCombinacao = {
  '02': '2 eixos',
  '04': '3 eixos',
  '06': '4 eixos',
  '07': '5 eixos',
  '08': '6 eixos',
  '10': '7 eixos',
  '11': '8 eixos',
  '12': '9 eixos',
  '13': '10 eixos',
  '14': 'Acima de 10 eixos',
};

String _soDigitosMdfe(String v) => v.replaceAll(RegExp(r'\D'), '');

/// CIOT da viagem: codigo (12 digitos) e CPF/CNPJ de quem o gerou.
Map<String, dynamic> montarCiotMdfe(String codigo, String documento) => {
      'codigo': _soDigitosMdfe(codigo),
      'cnpjCpfResponsavel': _soDigitosMdfe(documento),
    };

/// Dispositivo do vale-pedagio; pagador, numero da compra e tipo sao opcionais.
Map<String, dynamic> montarDispositivoValePedagioMdfe({
  required String fornecedor,
  String? pagador,
  String? numeroCompra,
  required num valor,
  String? tipo,
}) {
  final pag = _soDigitosMdfe(pagador ?? '');
  final compra = _soDigitosMdfe(numeroCompra ?? '');
  return {
    'cnpjFornecedor': _soDigitosMdfe(fornecedor),
    if (pag.isNotEmpty) 'cnpjCpfPagador': pag,
    if (compra.isNotEmpty) 'numeroCompra': compra,
    'valor': valor,
    if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
  };
}

/// Vale-pedagio da viagem; null quando nao ha dispositivos.
Map<String, dynamic>? montarValePedagioMdfe(
    List<Map<String, dynamic>> dispositivos, String? categoria) {
  if (dispositivos.isEmpty) return null;
  return {
    'dispositivos': dispositivos,
    if (categoria != null && categoria.isNotEmpty)
      'categoriaCombinacaoVeicular': categoria,
  };
}

/// Tipos de componente do pagamento do frete (esquema 3.00).
const Map<String, String> kMdfeTiposComponentePagamento = {
  '04': 'Frete',
  '01': 'Vale-pedágio',
  '02': 'Impostos, taxas e contribuições',
  '03': 'Despesas (bancárias, meios de pagamento, outras)',
  '99': 'Outros',
};

/// Formas de recebimento do frete.
const String kMdfeRecebimentoBanco = 'banco';
const String kMdfeRecebimentoIpef = 'ipef';
const String kMdfeRecebimentoPix = 'pix';

final RegExp _somenteNumericoMdfe = RegExp(r'^[\d.\-/\s]+$');

/// True quando o texto parece CPF/CNPJ (so digitos e pontuacao) e tem 11 ou 14 digitos.
bool documentoNumericoValidoMdfe(String v) {
  final n = _soDigitosMdfe(v).length;
  return n == 11 || n == 14;
}

/// Separa o que o usuario digitou em CPF/CNPJ (digitos) ou identificador de estrangeiro (texto).
/// Texto so com digitos/pontuacao vira CPF/CNPJ; qualquer outro vira idEstrangeiro.
({String? cnpjCpf, String? idEstrangeiro}) separarDocumentoMdfe(String texto) {
  final t = texto.trim();
  if (t.isEmpty) return (cnpjCpf: null, idEstrangeiro: null);
  if (_somenteNumericoMdfe.hasMatch(t)) {
    return (cnpjCpf: _soDigitosMdfe(t), idEstrangeiro: null);
  }
  return (cnpjCpf: null, idEstrangeiro: t);
}

String? _opcMdfe(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

/// Contratante do servico (infContratante).
Map<String, dynamic> montarContratanteMdfe({
  String? nome,
  required String documento,
  String? numeroContrato,
  num? valorContratoGlobal,
}) {
  final doc = separarDocumentoMdfe(documento);
  final contrato = _opcMdfe(numeroContrato);
  return {
    if (_opcMdfe(nome) != null) 'nome': _opcMdfe(nome),
    if (doc.cnpjCpf != null) 'cnpjCpf': doc.cnpjCpf,
    if (doc.idEstrangeiro != null) 'idEstrangeiro': doc.idEstrangeiro,
    if (contrato != null) 'numeroContrato': contrato,
    if (contrato != null && valorContratoGlobal != null)
      'valorContratoGlobal': valorContratoGlobal,
  };
}

Map<String, dynamic> montarComponentePagamentoMdfe(
        String tipo, num valor, String? descricao) =>
    {
      'tipo': tipo,
      'valor': valor,
      if (_opcMdfe(descricao) != null) 'descricao': _opcMdfe(descricao),
    };

Map<String, dynamic> montarParcelaMdfe(String vencimento, num valor) =>
    {'vencimento': vencimento.trim(), 'valor': valor};

/// Dados bancarios conforme a [forma] escolhida; so o grupo da forma vai no corpo.
Map<String, dynamic> montarBancoMdfe({
  required String forma,
  String? codBanco,
  String? codAgencia,
  String? cnpjIpef,
  String? pix,
}) {
  switch (forma) {
    case kMdfeRecebimentoBanco:
      return {'codBanco': _opcMdfe(codBanco), 'codAgencia': _opcMdfe(codAgencia)};
    case kMdfeRecebimentoIpef:
      return {'cnpjIpef': _soDigitosMdfe(cnpjIpef ?? '')};
    default:
      return {'pix': _opcMdfe(pix)};
  }
}

/// Pagamento do frete (infPag). Adiantamento e parcelas so vao em pagamento a prazo ([indPag] = 1).
Map<String, dynamic> montarPagamentoMdfe({
  String? nome,
  required String documento,
  required List<Map<String, dynamic>> componentes,
  required num valorContrato,
  bool altoDesempenho = false,
  required int indPag,
  num? adiantamento,
  bool anteciparAdiantamento = false,
  List<Map<String, dynamic>> parcelas = const [],
  int? tipoAntecipacao,
  required Map<String, dynamic> banco,
}) {
  final doc = separarDocumentoMdfe(documento);
  final aPrazo = indPag == 1;
  return {
    if (_opcMdfe(nome) != null) 'nome': _opcMdfe(nome),
    if (doc.cnpjCpf != null) 'cnpjCpf': doc.cnpjCpf,
    if (doc.idEstrangeiro != null) 'idEstrangeiro': doc.idEstrangeiro,
    'componentes': componentes,
    'valorContrato': valorContrato,
    'altoDesempenho': altoDesempenho,
    'indPag': indPag,
    if (aPrazo && adiantamento != null) 'adiantamento': adiantamento,
    'anteciparAdiantamento': aPrazo && anteciparAdiantamento,
    'parcelas': aPrazo ? parcelas : const <Map<String, dynamic>>[],
    if (tipoAntecipacao != null) 'tipoAntecipacao': tipoAntecipacao,
    'banco': banco,
  };
}

class _ContratanteCtl {
  final nome = TextEditingController();
  final documento = TextEditingController();
  final contrato = TextEditingController();
  final valorGlobal = TextEditingController();
  void dispose() {
    nome.dispose();
    documento.dispose();
    contrato.dispose();
    valorGlobal.dispose();
  }
}

class _ComponenteCtl {
  String tipo = '04';
  final valor = TextEditingController();
  final descricao = TextEditingController();
  void dispose() {
    valor.dispose();
    descricao.dispose();
  }
}

class _ParcelaCtl {
  final vencimento = TextEditingController();
  final valor = TextEditingController();
  void dispose() {
    vencimento.dispose();
    valor.dispose();
  }
}

class _PagamentoCtl {
  final nome = TextEditingController();
  final documento = TextEditingController();
  final valorContrato = TextEditingController();
  final adiantamento = TextEditingController();
  final codBanco = TextEditingController();
  final codAgencia = TextEditingController();
  final cnpjIpef = TextEditingController();
  final pix = TextEditingController();
  final List<_ComponenteCtl> componentes = [_ComponenteCtl()];
  final List<_ParcelaCtl> parcelas = [];
  bool altoDesempenho = false;
  bool anteciparAdiantamento = false;
  int indPag = 0;
  int? tipoAntecipacao;
  String recebimento = kMdfeRecebimentoPix;
  void dispose() {
    for (final c in [
      nome, documento, valorContrato, adiantamento, codBanco, codAgencia,
      cnpjIpef, pix
    ]) {
      c.dispose();
    }
    for (final c in componentes) {
      c.dispose();
    }
    for (final p in parcelas) {
      p.dispose();
    }
  }
}

class _CiotCtl {
  final codigo = TextEditingController();
  final documento = TextEditingController();
  void dispose() {
    codigo.dispose();
    documento.dispose();
  }
}

class _ValeDispCtl {
  final fornecedor = TextEditingController();
  final pagador = TextEditingController();
  final compra = TextEditingController();
  final valor = TextEditingController();
  String? tipo;
  void dispose() {
    fornecedor.dispose();
    pagador.dispose();
    compra.dispose();
    valor.dispose();
  }
}

class _MunicipioCtl {
  final ibge = TextEditingController();
  final nome = TextEditingController();
  void dispose() {
    ibge.dispose();
    nome.dispose();
  }
}

class _DescargaCtl extends _MunicipioCtl {
  final chavesCte = TextEditingController();
  final chavesNfe = TextEditingController();
  @override
  void dispose() {
    super.dispose();
    chavesCte.dispose();
    chavesNfe.dispose();
  }
}

/// Monta o corpo do POST /api/mdfe a partir dos campos do formulario.
/// Dados rodoviarios vem do cadastro (veiculoId + motoristaIds); numero e
/// emissao sao definidos pelo backend.
Map<String, dynamic> montarCorpoEmissaoMdfe({
  required int tpAmb,
  required int tpEmit,
  int? tpTransp,
  required int serie,
  required String ufIni,
  required String ufFim,
  required List<Map<String, String>> municipiosCarregamento,
  required List<Map<String, dynamic>> descargas,
  List<String> ufsPercurso = const [],
  required num valorCarga,
  required String unidadeCarga,
  required num quantidadeCarga,
  String? infoComplementar,
  required int veiculoId,
  required List<int> motoristaIds,
  Map<String, dynamic>? seguro,
  List<int> reboqueIds = const [],
  List<Map<String, dynamic>> ciots = const [],
  Map<String, dynamic>? valePedagio,
  List<Map<String, dynamic>> contratantes = const [],
  Map<String, dynamic>? pagamento,
}) {
  return {
    'tpAmb': tpAmb,
    'tpEmit': tpEmit,
    'tpTransp': tpTransp,
    'serie': serie,
    'ufIni': ufIni,
    'ufFim': ufFim,
    'municipiosCarregamento': municipiosCarregamento,
    if (ufsPercurso.isNotEmpty) 'ufsPercurso': ufsPercurso,
    'descargas': descargas,
    'valorCarga': valorCarga,
    'unidadeCarga': unidadeCarga,
    'quantidadeCarga': quantidadeCarga,
    if (infoComplementar != null && infoComplementar.trim().isNotEmpty)
      'infoComplementar': infoComplementar.trim(),
    'veiculoId': veiculoId,
    'motoristaIds': motoristaIds,
    if (seguro != null) 'seguros': [seguro],
    if (reboqueIds.isNotEmpty) 'reboqueIds': reboqueIds,
    if (ciots.isNotEmpty) 'ciots': ciots,
    if (valePedagio != null) 'valePedagio': valePedagio,
    if (contratantes.isNotEmpty) 'contratantes': contratantes,
    if (pagamento != null) 'pagamentos': [pagamento],
  };
}

/// Monta o grupo de seguro da carga. [respSeg]: 1 = emitente, 2 = contratante
/// (exige CPF/CNPJ). Devolve null quando nada foi informado ([respSeg] null).
/// Averbacoes: uma por linha.
Map<String, dynamic>? montarSeguroMdfe({
  required int? respSeg,
  String? documentoContratante,
  String? seguradoraNome,
  String? seguradoraCnpj,
  String? apolice,
  String? averbacoes,
}) {
  if (respSeg == null) return null;
  String? limpo(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
  final lista = (averbacoes ?? '')
      .split(RegExp(r'[\r\n]+'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return {
    'respSeg': respSeg,
    if (respSeg == 2) 'cnpjCpfResponsavel': limpo(documentoContratante),
    if (limpo(seguradoraNome) != null) 'seguradoraNome': limpo(seguradoraNome),
    if (limpo(seguradoraNome) != null) 'seguradoraCnpj': limpo(seguradoraCnpj),
    if (limpo(apolice) != null) 'numeroApolice': limpo(apolice),
    if (lista.isNotEmpty) 'averbacoes': lista,
  };
}

/// Separa um texto com uma chave por linha; devolve so as de 44 digitos e
/// registra as invalidas em [invalidas].
List<String> extrairChaves(String texto, {List<String>? invalidas}) {
  final chaves = <String>[];
  for (final linha in texto.split(RegExp(r'[\n;,\s]+'))) {
    final limpa = linha.replaceAll(RegExp(r'\D'), '');
    if (limpa.isEmpty) continue;
    if (limpa.length == 44) {
      chaves.add(limpa);
    } else {
      invalidas?.add(linha);
    }
  }
  return chaves;
}

/// Le a lista do envelope `data.dados` devolvido pela API.
List<Map<String, dynamic>> listaMdfeDe(Map<String, dynamic>? body) {
  final dados = (body?['data'] is Map) ? body!['data']['dados'] : null;
  if (dados is! List) return [];
  return dados
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// Tela de emissao e acompanhamento do MDF-e (Web, Windows e Mobile).
/// Lista `/api/mdfe`, emite pelo cadastro de veiculos/motoristas e permite
/// consultar, cancelar, encerrar, ver eventos e excluir (so homologacao).
class MdfeEmissaoView extends StatefulWidget {
  const MdfeEmissaoView({super.key});

  @override
  State<MdfeEmissaoView> createState() => _MdfeEmissaoViewState();
}

class _MdfeEmissaoViewState extends State<MdfeEmissaoView> {
  final _net = NetworkCaller();
  List<Map<String, dynamic>> _itens = [];
  bool _loading = true;
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
    try {
      final r = await _net.getRequest('${ApiLinks.allMdfe}?pagina=0&tamanho=50');
      if (!mounted) return;
      if (r.isSuccess) {
        _itens = listaMdfeDe(r.body);
      } else {
        _erro = r.statusCode == 403
            ? 'Sem acesso ao módulo Transporte (MDF-e).'
            : 'Não foi possível carregar os MDF-e (HTTP ${r.statusCode}).';
      }
    } catch (e, st) {
      AppLogger.i.error('MdfeEmissaoView: erro ao carregar: $e', st);
      _erro = 'Não foi possível carregar os MDF-e.';
    }
    if (mounted) setState(() => _loading = false);
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _acao(String descricao, Future<void> Function() corpo) async {
    try {
      await corpo();
    } catch (e, st) {
      AppLogger.i.error('MdfeEmissaoView: erro em $descricao: $e', st);
      _aviso('Não foi possível $descricao.');
    }
  }

  Future<void> _novo() async {
    final criado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _MdfeFormDialog(),
    );
    if (criado == true) _carregar();
  }

  Future<void> _consultar(Map<String, dynamic> m) => _acao('consultar o MDF-e', () async {
        final r = await _net.postRequest(ApiLinks.mdfeConsultar('${m['id']}'), {});
        if (r.isSuccess) {
          _aviso('Consulta concluída: ${r.body?['status'] ?? ''}');
          _carregar();
        } else {
          _aviso(r.statusCode == 502
              ? 'SEFAZ indisponível para consulta. Tente novamente.'
              : 'Falha na consulta (HTTP ${r.statusCode}).');
        }
      });

  Future<void> _cancelar(Map<String, dynamic> m) async {
    final texto = await _pedirTexto(
      titulo: 'Cancelar MDF-e ${m['numero']}',
      rotulo: 'Justificativa (mín. $kMdfeTamanhoMinimoJustificativa caracteres)',
      minimo: kMdfeTamanhoMinimoJustificativa,
    );
    if (texto == null) return;
    await _acao('cancelar o MDF-e', () async {
      final r = await _net.postRequest(
          ApiLinks.mdfeCancelar('${m['id']}'), {'justificativa': texto});
      _aviso(r.isSuccess
          ? 'Cancelamento: ${r.body?['status'] ?? ''} ${r.body?['motivo'] ?? ''}'
          : 'Falha ao cancelar (HTTP ${r.statusCode}).');
      if (r.isSuccess) _carregar();
    });
  }

  Future<void> _encerrar(Map<String, dynamic> m) async {
    final dados = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EncerrarDialog(ufInicial: '${m['uf'] ?? ''}'),
    );
    if (dados == null) return;
    await _acao('encerrar o MDF-e', () async {
      final r = await _net.postRequest(ApiLinks.mdfeEncerrar('${m['id']}'), dados);
      _aviso(r.isSuccess
          ? 'Encerramento: ${r.body?['status'] ?? ''} ${r.body?['motivo'] ?? ''}'
          : 'Falha ao encerrar (HTTP ${r.statusCode}).');
      if (r.isSuccess) _carregar();
    });
  }

  Future<void> _damdfe(Map<String, dynamic> m) => _acao('gerar o DAMDFE', () async {
        final r = await TenantContext.get(ApiLinks.mdfeDamdfe('${m['id']}'));
        if (r.statusCode != 200) {
          AppLogger.i.warn('MdfeEmissaoView: DAMDFE #${m['id']} falhou: HTTP ${r.statusCode}');
          _aviso('Não foi possível gerar o DAMDFE (HTTP ${r.statusCode}).');
          return;
        }
        await FileSaver.instance.saveFile(
          name: 'damdfe_${m['numero'] ?? m['id']}',
          bytes: r.bodyBytes,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
        _aviso('DAMDFE gerado.');
      });

  Future<void> _eventos(Map<String, dynamic> m) => _acao('listar os eventos', () async {
        final r = await _net.getRequest(ApiLinks.mdfeEventos('${m['id']}'));
        if (!r.isSuccess) {
          _aviso('Falha ao buscar eventos (HTTP ${r.statusCode}).');
          return;
        }
        final lista = (r.body?['data'] is List)
            ? (r.body!['data'] as List).whereType<Map>().toList()
            : <Map>[];
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Eventos do MDF-e ${m['numero']}'),
            content: SizedBox(
              width: 420,
              child: lista.isEmpty
                  ? const Text('Nenhum evento registrado.')
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final e in lista)
                          ListTile(
                            dense: true,
                            title: Text('${e['tipoEvento']} — ${e['status']}'),
                            subtitle: Text(
                                '${e['dhEvento'] ?? ''}\n${e['motivo'] ?? ''}'),
                          ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar')),
            ],
          ),
        );
      });

  Future<void> _excluir(Map<String, dynamic> m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir MDF-e de teste'),
        content: Text(
            'Excluir o MDF-e ${m['numero']} (homologação)? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    await _acao('excluir o MDF-e', () async {
      final r = await _net.deleteRequest(ApiLinks.mdfe('${m['id']}'));
      _aviso(r.isSuccess
          ? 'MDF-e excluído.'
          : 'Não foi possível excluir (HTTP ${r.statusCode}). Só é permitido em homologação sem desfecho fiscal.');
      if (r.isSuccess) _carregar();
    });
  }

  Future<String?> _pedirTexto(
      {required String titulo, required String rotulo, required int minimo}) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String? erro;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: Text(titulo),
            content: TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: rotulo, errorText: erro),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Voltar')),
              FilledButton(
                onPressed: () {
                  final t = ctrl.text.trim();
                  if (t.length < minimo) {
                    setS(() => erro = 'Mínimo de $minimo caracteres.');
                    return;
                  }
                  Navigator.pop(ctx, t);
                },
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _corStatus(String? s) {
    switch (s) {
      case 'AUTORIZADO':
      case 'REGISTRADO':
        return Colors.green.shade700;
      case 'REJEITADO':
      case 'CANCELADO':
        return Colors.red.shade700;
      case 'ENCERRADO':
        return Colors.blueGrey;
      default:
        return Colors.orange.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping),
              const SizedBox(width: 10),
              Expanded(
                child: Text('MDF-e',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _carregar,
                  icon: const Icon(Icons.refresh)),
              FilledButton.icon(
                onPressed: _novo,
                icon: const Icon(Icons.add),
                label: const Text('Novo MDF-e'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_erro != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_erro!, style: TextStyle(color: Colors.red.shade800)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _itens.isEmpty
                    ? const Center(child: Text('Nenhum MDF-e emitido.'))
                    : ListView.separated(
                        itemCount: _itens.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _cartao(_itens[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _cartao(Map<String, dynamic> m) {
    final status = m['status']?.toString();
    final autorizado = status == kMdfeAutorizado;
    final homolog = m['tpAmb'] == 2;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'MDF-e nº ${m['numero'] ?? '-'} • série ${m['serie'] ?? '-'}'
                    '${homolog ? ' • HOMOLOGAÇÃO' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text(status ?? '-',
                      style: const TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: _corStatus(status),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (m['chaveAcesso'] != null)
              SelectableText('Chave: ${m['chaveAcesso']}',
                  style: const TextStyle(fontSize: 12)),
            if (m['protocolo'] != null)
              Text('Protocolo: ${m['protocolo']}',
                  style: const TextStyle(fontSize: 12)),
            if ((m['motivo'] ?? '').toString().isNotEmpty)
              Text('${m['codigoRetorno'] ?? ''} ${m['motivo']}',
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                    onPressed: () => _consultar(m),
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Consultar')),
                OutlinedButton.icon(
                    onPressed: () => _damdfe(m),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('DAMDFE')),
                OutlinedButton.icon(
                    onPressed: () => _eventos(m),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Eventos')),
                if (autorizado)
                  OutlinedButton.icon(
                      onPressed: () => _encerrar(m),
                      icon: const Icon(Icons.flag, size: 18),
                      label: const Text('Encerrar')),
                if (autorizado)
                  OutlinedButton.icon(
                      onPressed: () => _cancelar(m),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancelar')),
                if (homolog)
                  TextButton.icon(
                      onPressed: () => _excluir(m),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EncerrarDialog extends StatefulWidget {
  final String ufInicial;
  const _EncerrarDialog({required this.ufInicial});

  @override
  State<_EncerrarDialog> createState() => _EncerrarDialogState();
}

class _EncerrarDialogState extends State<_EncerrarDialog> {
  late String? _uf =
      kTransporteUfs.contains(widget.ufInicial) ? widget.ufInicial : null;
  final _municipio = TextEditingController();
  DateTime _data = DateTime.now();
  String? _erro;

  @override
  void dispose() {
    _municipio.dispose();
    super.dispose();
  }

  String get _dataIso =>
      '${_data.year.toString().padLeft(4, '0')}-${_data.month.toString().padLeft(2, '0')}-${_data.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Encerrar MDF-e'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Data do encerramento'),
              subtitle: Text(_dataIso),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _data,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now(),
                );
                if (d != null) setState(() => _data = d);
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _uf,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'UF de encerramento'),
              items: [
                for (final uf in kTransporteUfs)
                  DropdownMenuItem(value: uf, child: Text(uf)),
              ],
              onChanged: (v) => setState(() => _uf = v),
            ),
            TextField(
              controller: _municipio,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Código IBGE do município (7 dígitos)'),
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_erro!, style: TextStyle(color: Colors.red.shade800)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Voltar')),
        FilledButton(
          onPressed: () {
            final cod = _municipio.text.trim();
            if (_uf == null || !RegExp(r'^\d{7}$').hasMatch(cod)) {
              setState(() => _erro = 'Informe a UF e o código IBGE de 7 dígitos.');
              return;
            }
            Navigator.pop(context,
                {'data': _dataIso, 'uf': _uf, 'codigoMunicipio': cod});
          },
          child: const Text('Encerrar'),
        ),
      ],
    );
  }
}

class _MdfeFormDialog extends StatefulWidget {
  const _MdfeFormDialog();

  @override
  State<_MdfeFormDialog> createState() => _MdfeFormDialogState();
}

class _MdfeFormDialogState extends State<_MdfeFormDialog> {
  final _net = NetworkCaller();
  final _form = GlobalKey<FormState>();
  final _serie = TextEditingController(text: '1');
  final List<_MunicipioCtl> _carregs = [_MunicipioCtl()];
  final List<_DescargaCtl> _descargas = [_DescargaCtl()];
  final List<String> _percurso = [];
  final List<_CiotCtl> _ciots = [];
  final List<_ValeDispCtl> _valeDisps = [];
  String? _valeCategoria;
  final List<_ContratanteCtl> _contratantes = [];
  _PagamentoCtl? _pag;
  final _valor = TextEditingController();
  final _quantidade = TextEditingController();
  final _info = TextEditingController();
  final _segDocumento = TextEditingController();
  final _segNome = TextEditingController();
  final _segCnpj = TextEditingController();
  final _segApolice = TextEditingController();
  final _segAverbacoes = TextEditingController();
  int? _respSeg;

  int _tpAmb = 2;
  int _tpEmit = 1;
  int? _tpTransp;
  String? _ufIni;
  String? _ufFim;
  String _unidade = '01';
  int? _veiculoId;
  final Set<int> _motoristas = {};
  final Set<int> _reboques = {};
  List<Map<String, dynamic>> _veiculos = [];
  List<Map<String, dynamic>> _motoristasDisp = [];
  bool _loading = true;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarCadastros();
  }

  @override
  void dispose() {
    for (final c in [
      _serie, _valor, _quantidade, _info, _segDocumento, _segNome,
      _segCnpj, _segApolice, _segAverbacoes
    ]) {
      c.dispose();
    }
    for (final m in [..._carregs, ..._descargas]) {
      m.dispose();
    }
    for (final c in _ciots) {
      c.dispose();
    }
    for (final d in _valeDisps) {
      d.dispose();
    }
    for (final c in _contratantes) {
      c.dispose();
    }
    _pag?.dispose();
    super.dispose();
  }

  Future<void> _carregarCadastros() async {
    try {
      final v = await _net
          .getRequest('${ApiLinks.allTransporteVeiculos}?pagina=0&tamanho=100');
      final m = await _net.getRequest(
          '${ApiLinks.allTransporteMotoristas}?pagina=0&tamanho=100');
      final c = await _net.getRequest(ApiLinks.transporteConfig);
      if (!mounted) return;
      if (v.isSuccess) {
        _veiculos = listaMdfeDe(v.body)
            .where((e) => e['ativo'] != false)
            .toList();
      }
      if (m.isSuccess) {
        _motoristasDisp = listaMdfeDe(m.body)
            .where((e) => e['ativo'] != false)
            .toList();
      }
      if (c.isSuccess && c.body != null) {
        _serie.text = c.body!['serieMdfe']?.toString() ?? '1';
        _tpEmit = (c.body!['tpEmit'] as num?)?.toInt() ?? 1;
        _tpTransp = (c.body!['tpTransp'] as num?)?.toInt();
      }
      if (!v.isSuccess || !m.isSuccess) {
        _erro = 'Não foi possível carregar veículos/motoristas.';
      }
    } catch (e, st) {
      AppLogger.i.error('MdfeFormDialog: erro ao carregar cadastros: $e', st);
      _erro = 'Não foi possível carregar veículos/motoristas.';
    }
    if (mounted) setState(() => _loading = false);
  }

  num? _numero(String t) => num.tryParse(t.trim().replaceAll(',', '.'));

  Future<void> _emitir() async {
    if (!_form.currentState!.validate()) return;
    final invalidas = <String>[];
    final descargas = <Map<String, dynamic>>[];
    for (final d in _descargas) {
      final cte = extrairChaves(d.chavesCte.text, invalidas: invalidas);
      final nfe = extrairChaves(d.chavesNfe.text, invalidas: invalidas);
      if (cte.isEmpty && nfe.isEmpty && invalidas.isEmpty) {
        setState(() => _erro = 'Informe ao menos uma chave de CT-e ou NF-e em '
            'cada município de descarga (${d.nome.text.trim()}).');
        return;
      }
      descargas.add(montarDescargaMdfe(
          ibge: d.ibge.text, nome: d.nome.text, chavesCte: cte, chavesNfe: nfe));
    }
    if (invalidas.isNotEmpty) {
      setState(() => _erro = 'Chave(s) com tamanho inválido (esperado 44 dígitos): '
          '${invalidas.join(', ')}');
      return;
    }
    if (_veiculoId == null || _motoristas.isEmpty) {
      setState(() => _erro = 'Selecione o veículo e ao menos um motorista.');
      return;
    }
    if (_respSeg == 2 && _segDocumento.text.replaceAll(RegExp(r'\D'), '').length
        != 11 && _segDocumento.text.replaceAll(RegExp(r'\D'), '').length != 14) {
      setState(() => _erro = 'Seguro: informe CPF ou CNPJ do contratante.');
      return;
    }
    if (_segNome.text.trim().isNotEmpty &&
        _segCnpj.text.replaceAll(RegExp(r'\D'), '').length != 14) {
      setState(() => _erro = 'Seguro: informe o CNPJ da seguradora (14 dígitos).');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final corpo = montarCorpoEmissaoMdfe(
        tpAmb: _tpAmb,
        tpEmit: _tpEmit,
        tpTransp: _tpTransp,
        serie: int.parse(_serie.text.trim()),
        ufIni: _ufIni!,
        ufFim: _ufFim!,
        municipiosCarregamento: [
          for (final c in _carregs) montarMunicipioMdfe(c.ibge.text, c.nome.text)
        ],
        ufsPercurso: _percurso.toList(),
        descargas: descargas,
        valorCarga: _numero(_valor.text)!,
        unidadeCarga: _unidade,
        quantidadeCarga: _numero(_quantidade.text)!,
        infoComplementar: _info.text,
        veiculoId: _veiculoId!,
        motoristaIds: _motoristas.toList(),
        reboqueIds: _reboques.toList(),
        ciots: [for (final c in _ciots) montarCiotMdfe(c.codigo.text, c.documento.text)],
        valePedagio: montarValePedagioMdfe([
          for (final d in _valeDisps)
            montarDispositivoValePedagioMdfe(
              fornecedor: d.fornecedor.text,
              pagador: d.pagador.text,
              numeroCompra: d.compra.text,
              valor: _numero(d.valor.text)!,
              tipo: d.tipo,
            )
        ], _valeCategoria),
        contratantes: [
          for (final c in _contratantes)
            montarContratanteMdfe(
              nome: c.nome.text,
              documento: c.documento.text,
              numeroContrato: c.contrato.text,
              valorContratoGlobal: _numero(c.valorGlobal.text),
            )
        ],
        pagamento: _pag == null ? null : _montarPagamento(_pag!),
        seguro: montarSeguroMdfe(
          respSeg: _respSeg,
          documentoContratante: _segDocumento.text,
          seguradoraNome: _segNome.text,
          seguradoraCnpj: _segCnpj.text,
          apolice: _segApolice.text,
          averbacoes: _segAverbacoes.text,
        ),
      );
      final r = await _net.postRequest(ApiLinks.allMdfe, corpo);
      if (!mounted) return;
      if (r.isSuccess) {
        final status = r.body?['status'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'MDF-e ${r.body?['numero'] ?? ''}: $status ${r.body?['motivo'] ?? ''}')));
        Navigator.pop(context, true);
        return;
      }
      _erro = 'Não foi possível emitir (HTTP ${r.statusCode}). '
          'Confira RNTRC, veículo, motoristas, municípios e chaves.';
    } catch (e, st) {
      AppLogger.i.error('MdfeFormDialog: erro ao emitir: $e', st);
      _erro = 'Não foi possível emitir o MDF-e.';
    }
    if (mounted) setState(() => _enviando = false);
  }

  String? _obrig(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

  String? _ibge(String? v) =>
      RegExp(r'^\d{7}$').hasMatch((v ?? '').trim()) ? null : '7 dígitos';

  Map<String, dynamic> _montarPagamento(_PagamentoCtl p) => montarPagamentoMdfe(
        nome: p.nome.text,
        documento: p.documento.text,
        componentes: [
          for (final c in p.componentes)
            montarComponentePagamentoMdfe(c.tipo, _numero(c.valor.text)!, c.descricao.text)
        ],
        valorContrato: _numero(p.valorContrato.text)!,
        altoDesempenho: p.altoDesempenho,
        indPag: p.indPag,
        adiantamento: _numero(p.adiantamento.text),
        anteciparAdiantamento: p.anteciparAdiantamento,
        parcelas: [
          for (final r in p.parcelas)
            montarParcelaMdfe(r.vencimento.text, _numero(r.valor.text)!)
        ],
        tipoAntecipacao: p.tipoAntecipacao,
        banco: montarBancoMdfe(
          forma: p.recebimento,
          codBanco: p.codBanco.text,
          codAgencia: p.codAgencia.text,
          cnpjIpef: p.cnpjIpef.text,
          pix: p.pix.text,
        ),
      );

  /// Documento de contratante/pagador: CPF/CNPJ (so digitos e pontuacao) ou ID de estrangeiro.
  String? _docOuEstrangeiro(String? v, {int minEstrangeiro = 2}) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Obrigatório';
    if (_somenteNumericoMdfe.hasMatch(t)) {
      return documentoNumericoValidoMdfe(t) ? null : 'CPF (11) ou CNPJ (14)';
    }
    return (t.length >= minEstrangeiro && t.length <= 20)
        ? null
        : '$minEstrangeiro a 20 caracteres';
  }

  String? _valorNaoNegativo(String? v) {
    final n = _numero(v ?? '');
    return (n == null || n < 0) ? 'Valor inválido' : null;
  }

  String? _cpfOuCnpj(String? v) {
    final n = _soDigitosMdfe(v ?? '').length;
    return (n == 11 || n == 14) ? null : 'CPF (11) ou CNPJ (14)';
  }

  String? _positivo(String? v) {
    final n = _numero(v ?? '');
    return (n == null || n <= 0) ? 'Valor inválido' : null;
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      );

  Widget _linha(List<Widget> filhos) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Wrap(spacing: 12, runSpacing: 12, children: filhos),
      );

  Widget _caixa(Widget child, {double largura = 220}) =>
      SizedBox(width: largura, child: child);

  List<Widget> _secaoContratantes() => [
        _tituloLista('Contratantes do serviço (opcional)', true,
            () => setState(() => _contratantes.add(_ContratanteCtl()))),
        for (var i = 0; i < _contratantes.length; i++)
          _linha([
            _caixa(TextFormField(
              controller: _contratantes[i].documento,
              decoration: _dec('CPF/CNPJ (ou ID de estrangeiro)'),
              validator: _docOuEstrangeiro,
            ), largura: 240),
            _caixa(TextFormField(
              controller: _contratantes[i].nome,
              maxLength: 60,
              decoration: _dec('Nome (opcional)'),
              validator: (v) => (v ?? '').trim().isEmpty || v!.trim().length >= 2
                  ? null
                  : 'Mínimo 2 caracteres',
            ), largura: 260),
            _caixa(TextFormField(
              controller: _contratantes[i].contrato,
              maxLength: 20,
              decoration: _dec('Nº do contrato (opcional)'),
              validator: (v) => (v ?? '').trim().isEmpty || v!.trim().length >= 2
                  ? null
                  : 'Mínimo 2 caracteres',
            ), largura: 200),
            _caixa(TextFormField(
              controller: _contratantes[i].valorGlobal,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('Valor global do contrato (R\$)'),
              validator: (v) {
                if (_contratantes[i].contrato.text.trim().isEmpty) return null;
                return _valorNaoNegativo(v);
              },
            ), largura: 220),
            IconButton(
              tooltip: 'Remover contratante',
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  setState(() => _contratantes.removeAt(i).dispose()),
            ),
          ]),
      ];

  List<Widget> _secaoPagamento() {
    final p = _pag;
    return [
      CheckboxListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: const Text('Informar pagamento do frete (opcional)'),
        value: p != null,
        onChanged: (v) => setState(() {
          if (v == true) {
            _pag = _PagamentoCtl();
          } else {
            _pag?.dispose();
            _pag = null;
          }
        }),
      ),
      if (p != null) ...[
        _linha([
          _caixa(TextFormField(
            controller: p.documento,
            decoration: _dec('Responsável: CPF/CNPJ (ou ID de estrangeiro)'),
            validator: (v) => _docOuEstrangeiro(v, minEstrangeiro: 5),
          ), largura: 300),
          _caixa(TextFormField(
            controller: p.nome,
            maxLength: 60,
            decoration: _dec('Responsável: nome (opcional)'),
            validator: (v) => (v ?? '').trim().isEmpty || v!.trim().length >= 2
                ? null
                : 'Mínimo 2 caracteres',
          ), largura: 300),
        ]),
        _tituloLista('Componentes do pagamento', true,
            () => setState(() => p.componentes.add(_ComponenteCtl()))),
        for (var i = 0; i < p.componentes.length; i++)
          _linha([
            _caixa(DropdownButtonFormField<String>(
              initialValue: p.componentes[i].tipo,
              isExpanded: true,
              decoration: _dec('Tipo'),
              items: [
                for (final e in kMdfeTiposComponentePagamento.entries)
                  DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => setState(() => p.componentes[i].tipo = v ?? '04'),
            ), largura: 260),
            _caixa(TextFormField(
              controller: p.componentes[i].valor,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('Valor (R\$)'),
              validator: _valorNaoNegativo,
            ), largura: 160),
            if (p.componentes[i].tipo == '99')
              _caixa(TextFormField(
                controller: p.componentes[i].descricao,
                maxLength: 60,
                decoration: _dec('Descrição do componente'),
                validator: (v) => (v ?? '').trim().length >= 2 ? null : 'Mínimo 2 caracteres',
              ), largura: 260),
            if (p.componentes.length > 1)
              IconButton(
                tooltip: 'Remover componente',
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    setState(() => p.componentes.removeAt(i).dispose()),
              ),
          ]),
        _linha([
          _caixa(TextFormField(
            controller: p.valorContrato,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _dec('Valor total do contrato (R\$)'),
            validator: _valorNaoNegativo,
          ), largura: 240),
          _caixa(DropdownButtonFormField<int>(
            initialValue: p.indPag,
            isExpanded: true,
            decoration: _dec('Forma de pagamento'),
            items: const [
              DropdownMenuItem(value: 0, child: Text('À vista')),
              DropdownMenuItem(value: 1, child: Text('A prazo')),
            ],
            onChanged: (v) => setState(() => p.indPag = v ?? 0),
          ), largura: 200),
        ]),
        CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Operação de transporte de alto desempenho'),
          value: p.altoDesempenho,
          onChanged: (v) => setState(() => p.altoDesempenho = v == true),
        ),
        if (p.indPag == 1) ...[
          _linha([
            _caixa(TextFormField(
              controller: p.adiantamento,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dec('Adiantamento (R\$, opcional)'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? null : _valorNaoNegativo(v),
            ), largura: 240),
            _caixa(DropdownButtonFormField<int?>(
              initialValue: p.tipoAntecipacao,
              isExpanded: true,
              decoration: _dec('Antecipação das parcelas'),
              items: const [
                DropdownMenuItem<int?>(value: null, child: Text('Não informada')),
                DropdownMenuItem<int?>(value: 0, child: Text('Não permite antecipar')),
                DropdownMenuItem<int?>(value: 1, child: Text('Permite antecipar')),
                DropdownMenuItem<int?>(
                    value: 2, child: Text('Permite, mediante confirmação')),
              ],
              onChanged: (v) => setState(() => p.tipoAntecipacao = v),
            ), largura: 300),
          ]),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Concordo em antecipar o adiantamento'),
            value: p.anteciparAdiantamento,
            onChanged: (v) => setState(() => p.anteciparAdiantamento = v == true),
          ),
          _tituloLista('Parcelas', true,
              () => setState(() => p.parcelas.add(_ParcelaCtl()))),
          for (var i = 0; i < p.parcelas.length; i++)
            _linha([
              _caixa(TextFormField(
                controller: p.parcelas[i].vencimento,
                keyboardType: TextInputType.datetime,
                decoration: _dec('Vencimento (AAAA-MM-DD)'),
                validator: (v) => RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch((v ?? '').trim()) &&
                        DateTime.tryParse(v!.trim()) != null
                    ? null
                    : 'AAAA-MM-DD',
              ), largura: 220),
              _caixa(TextFormField(
                controller: p.parcelas[i].valor,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _dec('Valor da parcela (R\$)'),
                validator: _valorNaoNegativo,
              ), largura: 200),
              IconButton(
                tooltip: 'Remover parcela',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => p.parcelas.removeAt(i).dispose()),
              ),
            ]),
        ],
        _linha([
          _caixa(DropdownButtonFormField<String>(
            initialValue: p.recebimento,
            isExpanded: true,
            decoration: _dec('Recebimento do frete'),
            items: const [
              DropdownMenuItem(value: kMdfeRecebimentoPix, child: Text('Chave PIX')),
              DropdownMenuItem(value: kMdfeRecebimentoBanco, child: Text('Banco e agência')),
              DropdownMenuItem(
                  value: kMdfeRecebimentoIpef,
                  child: Text('Instituição de pagamento eletrônico (IPEF)')),
            ],
            onChanged: (v) =>
                setState(() => p.recebimento = v ?? kMdfeRecebimentoPix),
          ), largura: 340),
          if (p.recebimento == kMdfeRecebimentoPix)
            _caixa(TextFormField(
              controller: p.pix,
              decoration: _dec('Chave PIX'),
              validator: (v) {
                final n = (v ?? '').trim().length;
                return (n >= 2 && n <= 60) ? null : '2 a 60 caracteres';
              },
            ), largura: 300),
          if (p.recebimento == kMdfeRecebimentoBanco) ...[
            _caixa(TextFormField(
              controller: p.codBanco,
              decoration: _dec('Banco (3 a 5)'),
              validator: (v) {
                final n = (v ?? '').trim().length;
                return (n >= 3 && n <= 5) ? null : '3 a 5 caracteres';
              },
            ), largura: 140),
            _caixa(TextFormField(
              controller: p.codAgencia,
              decoration: _dec('Agência (1 a 10)'),
              validator: (v) {
                final n = (v ?? '').trim().length;
                return (n >= 1 && n <= 10) ? null : '1 a 10 caracteres';
              },
            ), largura: 160),
          ],
          if (p.recebimento == kMdfeRecebimentoIpef)
            _caixa(TextFormField(
              controller: p.cnpjIpef,
              keyboardType: TextInputType.number,
              decoration: _dec('CNPJ da IPEF'),
              validator: (v) =>
                  _soDigitosMdfe(v ?? '').length == 14 ? null : '14 dígitos',
            ), largura: 240),
        ]),
      ],
    ];
  }

  Widget _tituloLista(String titulo, bool podeAdicionar, VoidCallback onAdd) =>
      Row(children: [
        Expanded(child: Text(titulo)),
        TextButton.icon(
          onPressed: podeAdicionar ? onAdd : null,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar'),
        ),
      ]);

  /// UFs de percurso, na ordem em que o veiculo passa: toque para incluir ao fim
  /// da rota; toque numa UF ja escolhida para remove-la.
  Widget _secaoPercurso() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UFs de percurso (opcional, em ordem) — '
              '${_percurso.isEmpty ? 'nenhuma' : _percurso.join(' → ')}'),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (final uf in kTransporteUfs)
              FilterChip(
                label: Text(uf),
                selected: _percurso.contains(uf),
                onSelected: (marcado) => setState(() {
                  if (!marcado) {
                    _percurso.remove(uf);
                  } else if (_percurso.length < kMdfeMaxUfsPercurso) {
                    _percurso.add(uf);
                  }
                }),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _ufDrop(String label, String? valor, ValueChanged<String?> onChanged) =>
      _caixa(DropdownButtonFormField<String>(
        initialValue: valor,
        isExpanded: true,
        decoration: _dec(label),
        validator: (v) => v == null ? 'Obrigatório' : null,
        items: [
          for (final uf in kTransporteUfs)
            DropdownMenuItem(value: uf, child: Text(uf)),
        ],
        onChanged: onChanged,
      ), largura: 120);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo MDF-e'),
      content: SizedBox(
        width: 720,
        child: _loading
            ? const SizedBox(
                height: 120, child: Center(child: CircularProgressIndicator()))
            : SingleChildScrollView(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_erro != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_erro!,
                              style: TextStyle(color: Colors.red.shade800)),
                        ),
                      _linha([
                        _caixa(DropdownButtonFormField<int>(
                          initialValue: _tpAmb,
                          isExpanded: true,
                          decoration: _dec('Ambiente'),
                          items: const [
                            DropdownMenuItem(value: 2, child: Text('2 - Homologação')),
                            DropdownMenuItem(value: 1, child: Text('1 - Produção')),
                          ],
                          onChanged: (v) => setState(() => _tpAmb = v ?? 2),
                        )),
                        _caixa(TextFormField(
                          controller: _serie,
                          keyboardType: TextInputType.number,
                          decoration: _dec('Série'),
                          validator: (v) {
                            final s = int.tryParse((v ?? '').trim());
                            return (s == null || s < 1 || s > 999) ? '1 a 999' : null;
                          },
                        ), largura: 100),
                        _caixa(DropdownButtonFormField<int>(
                          initialValue: _tpEmit,
                          isExpanded: true,
                          decoration: _dec('Tipo de emitente'),
                          items: [
                            for (final o in kTransporteTiposEmitente)
                              DropdownMenuItem<int>(
                                  value: o['value'] as int,
                                  child: Text(o['label'] as String,
                                      overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) => setState(() => _tpEmit = v ?? 1),
                        ), largura: 300),
                        _caixa(DropdownButtonFormField<int?>(
                          initialValue: _tpTransp,
                          isExpanded: true,
                          decoration: _dec('Tipo de transportador'),
                          items: [
                            const DropdownMenuItem<int?>(
                                value: null, child: Text('Não informado')),
                            for (final o in kTransporteTiposTransportador)
                              DropdownMenuItem<int?>(
                                  value: o['value'] as int,
                                  child: Text(o['label'] as String)),
                          ],
                          onChanged: (v) => setState(() => _tpTransp = v),
                        ), largura: 200),
                      ]),
                      _linha([
                        _ufDrop('UF início', _ufIni, (v) => setState(() => _ufIni = v)),
                        _ufDrop('UF fim', _ufFim, (v) => setState(() => _ufFim = v)),
                      ]),
                      _secaoPercurso(),
                      _tituloLista('Municípios de carregamento',
                          _carregs.length < kMdfeMaxMunicipiosCarregamento,
                          () => setState(() => _carregs.add(_MunicipioCtl()))),
                      for (var i = 0; i < _carregs.length; i++)
                        _linha([
                          _caixa(TextFormField(
                            controller: _carregs[i].ibge,
                            keyboardType: TextInputType.number,
                            decoration: _dec('Carregamento: IBGE'),
                            validator: _ibge,
                          ), largura: 180),
                          _caixa(TextFormField(
                            controller: _carregs[i].nome,
                            decoration: _dec('Carregamento: município'),
                            validator: _obrig,
                          ), largura: 260),
                          if (_carregs.length > 1)
                            IconButton(
                              tooltip: 'Remover município de carregamento',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => setState(
                                  () => _carregs.removeAt(i).dispose()),
                            ),
                        ]),
                      _tituloLista('Municípios de descarga e documentos',
                          _descargas.length < kMdfeMaxMunicipiosDescarga,
                          () => setState(() => _descargas.add(_DescargaCtl()))),
                      for (var i = 0; i < _descargas.length; i++) ...[
                        _linha([
                          _caixa(TextFormField(
                            controller: _descargas[i].ibge,
                            keyboardType: TextInputType.number,
                            decoration: _dec('Descarga: IBGE'),
                            validator: _ibge,
                          ), largura: 180),
                          _caixa(TextFormField(
                            controller: _descargas[i].nome,
                            decoration: _dec('Descarga: município'),
                            validator: _obrig,
                          ), largura: 260),
                          if (_descargas.length > 1)
                            IconButton(
                              tooltip: 'Remover município de descarga',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => setState(
                                  () => _descargas.removeAt(i).dispose()),
                            ),
                        ]),
                        _linha([
                          _caixa(TextFormField(
                            controller: _descargas[i].chavesCte,
                            maxLines: 3,
                            decoration: _dec('Chaves CT-e (uma por linha)'),
                          ), largura: 340),
                          _caixa(TextFormField(
                            controller: _descargas[i].chavesNfe,
                            maxLines: 3,
                            decoration: _dec('Chaves NF-e (uma por linha)'),
                          ), largura: 340),
                        ]),
                      ],
                      _linha([
                        _caixa(TextFormField(
                          controller: _valor,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: _dec('Valor da carga (R\$)'),
                          validator: _positivo,
                        )),
                        _caixa(DropdownButtonFormField<String>(
                          initialValue: _unidade,
                          isExpanded: true,
                          decoration: _dec('Unidade'),
                          items: const [
                            DropdownMenuItem(value: '01', child: Text('01 - KG')),
                            DropdownMenuItem(value: '02', child: Text('02 - TON')),
                          ],
                          onChanged: (v) => setState(() => _unidade = v ?? '01'),
                        ), largura: 140),
                        _caixa(TextFormField(
                          controller: _quantidade,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: _dec('Peso total'),
                          validator: _positivo,
                        ), largura: 160),
                      ]),
                      _linha([
                        _caixa(DropdownButtonFormField<int>(
                          initialValue: _veiculoId,
                          isExpanded: true,
                          decoration: _dec('Veículo'),
                          validator: (v) => v == null ? 'Obrigatório' : null,
                          items: [
                            for (final v in _veiculos)
                              DropdownMenuItem<int>(
                                  value: (v['id'] as num).toInt(),
                                  child: Text('${v['placa']}')),
                          ],
                          onChanged: (v) => setState(() {
                            _veiculoId = v;
                            _reboques.remove(v);
                          }),
                        ), largura: 240),
                      ]),
                      if (_veiculos.length > 1) ...[
                        const Text('Reboques (opcional, até 3)'),
                        for (final v in _veiculos.where(
                            (v) => (v['id'] as num).toInt() != _veiculoId))
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text('${v['placa']}'),
                            value: _reboques.contains((v['id'] as num).toInt()),
                            onChanged: (marcado) => setState(() {
                              final id = (v['id'] as num).toInt();
                              if (marcado != true) {
                                _reboques.remove(id);
                              } else if (_reboques.length < kMdfeMaxReboques) {
                                _reboques.add(id);
                              }
                            }),
                          ),
                      ],
                      const Text('Motoristas'),
                      if (_motoristasDisp.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Text('Nenhum motorista ativo cadastrado.'),
                        ),
                      for (final m in _motoristasDisp)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${m['nome']}'),
                          value: _motoristas.contains((m['id'] as num).toInt()),
                          onChanged: (v) => setState(() {
                            final id = (m['id'] as num).toInt();
                            v == true ? _motoristas.add(id) : _motoristas.remove(id);
                          }),
                        ),
                      _tituloLista('CIOT (opcional)', true,
                          () => setState(() => _ciots.add(_CiotCtl()))),
                      for (var i = 0; i < _ciots.length; i++)
                        _linha([
                          _caixa(TextFormField(
                            controller: _ciots[i].codigo,
                            keyboardType: TextInputType.number,
                            decoration: _dec('CIOT (12 dígitos)'),
                            validator: (v) => _soDigitosMdfe(v ?? '').length == 12
                                ? null
                                : '12 dígitos',
                          ), largura: 220),
                          _caixa(TextFormField(
                            controller: _ciots[i].documento,
                            keyboardType: TextInputType.number,
                            decoration: _dec('CPF/CNPJ de quem gerou'),
                            validator: _cpfOuCnpj,
                          ), largura: 240),
                          IconButton(
                            tooltip: 'Remover CIOT',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setState(() => _ciots.removeAt(i).dispose()),
                          ),
                        ]),
                      _tituloLista('Vale-pedágio (opcional)', true,
                          () => setState(() => _valeDisps.add(_ValeDispCtl()))),
                      for (var i = 0; i < _valeDisps.length; i++) ...[
                        _linha([
                          _caixa(TextFormField(
                            controller: _valeDisps[i].fornecedor,
                            keyboardType: TextInputType.number,
                            decoration: _dec('CNPJ do fornecedor'),
                            validator: (v) => _soDigitosMdfe(v ?? '').length == 14
                                ? null
                                : '14 dígitos',
                          ), largura: 220),
                          _caixa(TextFormField(
                            controller: _valeDisps[i].pagador,
                            keyboardType: TextInputType.number,
                            decoration: _dec('CPF/CNPJ do pagador (opcional)'),
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? null
                                : _cpfOuCnpj(v),
                          ), largura: 240),
                          IconButton(
                            tooltip: 'Remover dispositivo do vale-pedágio',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                setState(() => _valeDisps.removeAt(i).dispose()),
                          ),
                        ]),
                        _linha([
                          _caixa(TextFormField(
                            controller: _valeDisps[i].compra,
                            keyboardType: TextInputType.number,
                            maxLength: 20,
                            decoration: _dec('Nº da compra (opcional)'),
                          ), largura: 220),
                          _caixa(TextFormField(
                            controller: _valeDisps[i].valor,
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            decoration: _dec('Valor (R\$)'),
                            validator: (v) {
                              final n = _numero(v ?? '');
                              return (n == null || n < 0) ? 'Valor inválido' : null;
                            },
                          ), largura: 160),
                          _caixa(DropdownButtonFormField<String?>(
                            initialValue: _valeDisps[i].tipo,
                            isExpanded: true,
                            decoration: _dec('Tipo (opcional)'),
                            items: [
                              const DropdownMenuItem<String?>(
                                  value: null, child: Text('Não informado')),
                              for (final e in kMdfeTiposValePedagio.entries)
                                DropdownMenuItem<String?>(
                                    value: e.key, child: Text(e.value)),
                            ],
                            onChanged: (v) => setState(() => _valeDisps[i].tipo = v),
                          ), largura: 200),
                        ]),
                      ],
                      if (_valeDisps.isNotEmpty)
                        _linha([
                          _caixa(DropdownButtonFormField<String?>(
                            initialValue: _valeCategoria,
                            isExpanded: true,
                            decoration: _dec('Categoria de combinação veicular'),
                            items: [
                              const DropdownMenuItem<String?>(
                                  value: null, child: Text('Não informada')),
                              for (final e in kMdfeCategoriasCombinacao.entries)
                                DropdownMenuItem<String?>(
                                    value: e.key, child: Text(e.value)),
                            ],
                            onChanged: (v) => setState(() => _valeCategoria = v),
                          ), largura: 300),
                        ]),
                      ..._secaoContratantes(),
                      ..._secaoPagamento(),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        initialValue: _respSeg,
                        decoration: _dec('Seguro da carga — responsável'),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Não informar seguro')),
                          DropdownMenuItem(value: 1, child: Text('Emitente do MDF-e')),
                          DropdownMenuItem(value: 2, child: Text('Contratante do transporte')),
                        ],
                        onChanged: (v) => setState(() => _respSeg = v),
                      ),
                      if (_respSeg != null) ...[
                        if (_respSeg == 2) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _segDocumento,
                            decoration: _dec('CPF/CNPJ do contratante'),
                          ),
                        ],
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _segNome,
                          maxLength: 30,
                          decoration: _dec('Seguradora (opcional)'),
                        ),
                        TextFormField(
                          controller: _segCnpj,
                          decoration: _dec('CNPJ da seguradora'),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _segApolice,
                          maxLength: 20,
                          decoration: _dec('Nº da apólice (opcional)'),
                        ),
                        TextFormField(
                          controller: _segAverbacoes,
                          maxLines: 2,
                          decoration: _dec('Averbações (uma por linha, opcional)'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _info,
                        maxLines: 2,
                        decoration: _dec('Informações complementares (opcional)'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      actions: [
        TextButton(
            onPressed: _enviando ? null : () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: (_loading || _enviando) ? null : _emitir,
          icon: _enviando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: const Text('Emitir'),
        ),
      ],
    );
  }
}
