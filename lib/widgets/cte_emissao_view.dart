import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import 'package:file_saver/file_saver.dart';
import '../utils/tenant_context.dart';
import 'mdfe_emissao_view.dart' show extrairChaves, listaMdfeDe;

const String kCteAutorizado = 'AUTORIZADO';
const int kCteTamanhoMinimoJustificativa = 15;
const int kCteMaxCorrecoes = 20;

/// Tipo do CT-e (tpCTe): normal, complemento de valores ou substituicao.
const int kCteTipoNormal = 0;
const int kCteTipoComplemento = 1;
const int kCteTipoSubstituicao = 3;
const int kCteMaxComplementados = 10;

const Map<int, String> kCteTipos = {
  kCteTipoNormal: 'Normal',
  kCteTipoComplemento: 'Complemento de valores',
  kCteTipoSubstituicao: 'Substituição',
};

/// CST do ICMS suportados pelo backend (00, isento/nao tributado/diferido e Simples Nacional).
const Map<String, String> kCteCstIcms = {
  '00': '00 - Tributado',
  '40': '40 - Isento',
  '41': '41 - Não tributado',
  '51': '51 - Diferido',
  'SN': 'Simples Nacional',
};

/// Unidade da quantidade da carga (cUnid do CT-e).
const Map<String, String> kCteUnidades = {
  '01': 'KG',
  '02': 'TON',
  '00': 'M3',
  '03': 'Unidade',
  '04': 'Litros',
  '05': 'MMBTU',
};

/// Papel do tomador do servico (toma do CT-e).
const Map<int, String> kCteTomadores = {
  0: 'Remetente',
  1: 'Expedidor',
  2: 'Recebedor',
  3: 'Destinatário',
  4: 'Outro',
};

const Map<int, String> kCteIndIeTomador = {
  1: 'Contribuinte de ICMS',
  2: 'Contribuinte isento de IE',
  9: 'Não contribuinte',
};

const List<String> kCteUfs = [
  'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MG', 'MS', 'MT',
  'PA', 'PB', 'PE', 'PI', 'PR', 'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP',
  'TO',
];

/// RNTRC: vazio (usa o da configuracao do modulo) ou exatamente 8 digitos.
bool validarRntrcCte(String? v) {
  final d = _soDigitosCte(v ?? '');
  return (v ?? '').trim().isEmpty || d.length == 8;
}

bool _serieValida(String? v) {
  final n = int.tryParse((v ?? '').trim());
  return n != null && n >= 0 && n <= 999;
}

/// Largura de campo/dialogo limitada a tela (celular estreito nao pode estourar).
double larguraCte(BuildContext context, double largura, {double reserva = 140}) =>
    math.min(largura, math.max(120.0, MediaQuery.sizeOf(context).width - reserva));

String _soDigitosCte(String v) => v.replaceAll(RegExp(r'\D'), '');

String? _limpoCte(String? v) {
  final t = v?.trim() ?? '';
  return t.isEmpty ? null : t;
}

/// CPF (11) ou CNPJ (14) com so os digitos informados.
bool documentoValidoCte(String v) {
  final n = _soDigitosCte(v).length;
  return n == 11 || n == 14;
}

/// Titulo do cartao conforme o tipo do CT-e (ausente = normal).
String rotuloTipoCte(dynamic tipo) {
  switch (tipo) {
    case kCteTipoComplemento:
      return 'CT-e complementar';
    case kCteTipoSubstituicao:
      return 'CT-e de substituição';
    default:
      return 'CT-e';
  }
}

/// Confere as chaves de CT-e referenciadas conforme o tipo; devolve a mensagem de
/// erro ou null. Normal nao referencia; complemento 1 a 10; substituicao exatamente 1.
String? validarReferenciasCte(int tipoCte, List<String> chaves) {
  for (final c in chaves) {
    if (c.length == 44 && c.substring(20, 22) != '57') {
      return 'A chave $c nao e de um CT-e (modelo 57).';
    }
  }
  switch (tipoCte) {
    case kCteTipoComplemento:
      if (chaves.isEmpty || chaves.length > kCteMaxComplementados) {
        return 'O CT-e complementar exige de 1 a $kCteMaxComplementados chaves de CT-e.';
      }
      return null;
    case kCteTipoSubstituicao:
      return chaves.length == 1
          ? null
          : 'O CT-e de substituição exige exatamente 1 chave de CT-e.';
    default:
      return chaves.isEmpty ? null : 'O CT-e normal não referencia outro CT-e.';
  }
}

/// Municipio de inicio/fim da prestacao.
Map<String, String> montarLocalCte(String ibge, String nome, String uf) => {
      'codigoIbge': _soDigitosCte(ibge),
      'nome': nome.trim(),
      'uf': uf,
    };

/// Remetente, expedidor, recebedor, destinatario ou tomador "outro".
Map<String, dynamic> montarParteCte({
  required String documento,
  String? inscricaoEstadual,
  required String nome,
  String? telefone,
  String? email,
  required String logradouro,
  required String numero,
  String? complemento,
  required String bairro,
  required String codigoMunicipio,
  required String municipio,
  String? cep,
  required String uf,
}) =>
    {
      'cnpjCpf': _soDigitosCte(documento),
      if (_limpoCte(inscricaoEstadual) != null)
        'inscricaoEstadual': _soDigitosCte(inscricaoEstadual!),
      'nome': nome.trim(),
      if (_limpoCte(telefone) != null) 'telefone': _soDigitosCte(telefone!),
      if (_limpoCte(email) != null) 'email': email!.trim(),
      'endereco': {
        'logradouro': logradouro.trim(),
        'numero': numero.trim(),
        if (_limpoCte(complemento) != null) 'complemento': complemento!.trim(),
        'bairro': bairro.trim(),
        'codigoMunicipio': _soDigitosCte(codigoMunicipio),
        'municipio': municipio.trim(),
        if (_limpoCte(cep) != null) 'cep': _soDigitosCte(cep!),
        'uf': uf,
      },
    };

/// ICMS da prestacao: `SN` = Simples Nacional; `00` leva base, aliquota e valor.
Map<String, dynamic> montarIcmsCte({
  required String cst,
  num? baseCalculo,
  num? aliquota,
  num? valor,
}) {
  if (cst == 'SN') {
    return {'cst': '90', 'simplesNacional': true};
  }
  return {
    'cst': cst,
    'simplesNacional': false,
    if (cst == '00' && baseCalculo != null) 'baseCalculo': baseCalculo,
    if (cst == '00' && aliquota != null) 'aliquota': aliquota,
    if (cst == '00' && valor != null) 'valor': valor,
  };
}

Map<String, dynamic> montarComponenteCte(String nome, num valor) =>
    {'nome': nome.trim(), 'valor': valor};

/// Item da carta de correcao (grupo/campo do XML, novo valor e item opcional).
Map<String, dynamic> montarCorrecaoCte({
  required String grupo,
  required String campo,
  required String valor,
  int? item,
}) =>
    {
      'grupoAlterado': grupo.trim(),
      'campoAlterado': campo.trim(),
      'valorAlterado': valor.trim(),
      if (item != null) 'nroItemAlterado': item,
    };

/// Corpo do POST /api/cte. Emitente, numero e data vem do servidor.
Map<String, dynamic> montarCorpoEmissaoCte({
  required int tpAmb,
  required int serie,
  required String cfop,
  required String naturezaOperacao,
  required Map<String, String> origem,
  required Map<String, String> destino,
  required int indIeTomador,
  required int tomadorPapel,
  Map<String, dynamic>? tomadorOutro,
  Map<String, dynamic>? remetente,
  Map<String, dynamic>? expedidor,
  Map<String, dynamic>? recebedor,
  Map<String, dynamic>? destinatario,
  required num valorPrestacao,
  required List<Map<String, dynamic>> componentes,
  required Map<String, dynamic> icms,
  num? valorCarga,
  String? produtoPredominante,
  String unidade = '01',
  String tipoMedida = 'PESO BRUTO',
  num? quantidade,
  List<String> chavesNfe = const [],
  int tipoCte = kCteTipoNormal,
  List<String> chavesReferenciadas = const [],
  bool alteraTomador = false,
  String? rntrc,
  String? infoComplementar,
}) =>
    {
      'tpAmb': tpAmb,
      'serie': serie,
      'cfop': _soDigitosCte(cfop),
      'naturezaOperacao': naturezaOperacao.trim(),
      'origem': origem,
      'destino': destino,
      'indIeTomador': indIeTomador,
      'tomador': {
        'papel': tomadorPapel,
        if (tomadorPapel == 4 && tomadorOutro != null) 'outro': tomadorOutro,
      },
      if (remetente != null) 'remetente': remetente,
      if (expedidor != null) 'expedidor': expedidor,
      if (recebedor != null) 'recebedor': recebedor,
      if (destinatario != null) 'destinatario': destinatario,
      'valorPrestacao': valorPrestacao,
      'componentes': componentes,
      'icms': icms,
      if (tipoCte != kCteTipoComplemento) 'carga': {
        'valor': valorCarga!,
        'produtoPredominante': produtoPredominante!.trim(),
        'quantidades': [
          {'unidade': unidade, 'tipoMedida': tipoMedida.trim(), 'quantidade': quantidade!}
        ],
      },
      if (tipoCte != kCteTipoComplemento) 'chavesNfe': chavesNfe,
      if (tipoCte != kCteTipoNormal) 'tipoCte': tipoCte,
      if (chavesReferenciadas.isNotEmpty) 'chavesReferenciadas': chavesReferenciadas,
      if (alteraTomador && tipoCte == kCteTipoSubstituicao) 'alteraTomador': true,
      if (_limpoCte(rntrc) != null) 'rntrc': _soDigitosCte(rntrc!),
      if (_limpoCte(infoComplementar) != null)
        'infoComplementar': infoComplementar!.trim(),
    };

/// Tela de emissao e acompanhamento do CT-e (Web, Windows e Mobile).
/// Lista `/api/cte`, emite, e permite consultar, imprimir o DACTE, ver eventos,
/// enviar carta de correcao, cancelar e excluir (so homologacao).
class CteEmissaoView extends StatefulWidget {
  const CteEmissaoView({super.key});

  @override
  State<CteEmissaoView> createState() => _CteEmissaoViewState();
}

class _CteEmissaoViewState extends State<CteEmissaoView> {
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
      final r = await _net.getRequest('${ApiLinks.allCte}?pagina=0&tamanho=50');
      if (!mounted) return;
      if (r.isSuccess) {
        _itens = listaMdfeDe(r.body);
      } else {
        _erro = r.statusCode == 403
            ? 'Sem acesso ao módulo Transporte (CT-e).'
            : 'Não foi possível carregar os CT-e (HTTP ${r.statusCode}).';
      }
    } catch (e, st) {
      AppLogger.i.error('CteEmissaoView: erro ao carregar: $e', st);
      _erro = 'Não foi possível carregar os CT-e.';
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
      AppLogger.i.error('CteEmissaoView: erro em $descricao: $e', st);
      _aviso('Não foi possível $descricao.');
    }
  }

  Future<void> _novo() async {
    final criado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CteFormDialog(),
    );
    if (criado == true && mounted) _carregar();
  }

  Future<void> _consultar(Map<String, dynamic> c) =>
      _acao('consultar o CT-e', () async {
        final r = await _net.postRequest(ApiLinks.cteConsultar('${c['id']}'), {});
        if (r.isSuccess) {
          _aviso('Consulta concluída: ${r.body?['status'] ?? ''}');
          _carregar();
        } else {
          _aviso(r.statusCode == 502
              ? 'SEFAZ indisponível para consulta. Tente novamente.'
              : 'Falha na consulta (HTTP ${r.statusCode}).');
        }
      });

  Future<void> _cancelar(Map<String, dynamic> c) async {
    final texto = await _pedirTexto(
      titulo: 'Cancelar CT-e ${c['numero']}',
      rotulo: 'Justificativa (mín. $kCteTamanhoMinimoJustificativa caracteres)',
      minimo: kCteTamanhoMinimoJustificativa,
    );
    if (texto == null) return;
    await _acao('cancelar o CT-e', () async {
      final r = await _net.postRequest(
          ApiLinks.cteCancelar('${c['id']}'), {'justificativa': texto});
      _aviso(r.isSuccess
          ? 'Cancelamento: ${r.body?['status'] ?? ''} ${r.body?['motivo'] ?? ''}'
          : 'Falha ao cancelar (HTTP ${r.statusCode}).');
      if (r.isSuccess) _carregar();
    });
  }

  Future<void> _cartaCorrecao(Map<String, dynamic> c) async {
    final correcoes = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CartaCorrecaoDialog(numero: '${c['numero'] ?? ''}'),
    );
    if (correcoes == null) return;
    await _acao('enviar a carta de correção', () async {
      final r = await _net.postRequest(
          ApiLinks.cteCartaCorrecao('${c['id']}'), {'correcoes': correcoes});
      _aviso(r.isSuccess
          ? 'Carta de correção: ${r.body?['status'] ?? ''} ${r.body?['motivo'] ?? ''}'
          : 'Falha ao enviar a carta de correção (HTTP ${r.statusCode}).');
      if (r.isSuccess) _carregar();
    });
  }

  Future<void> _dacte(Map<String, dynamic> c) => _acao('gerar o DACTE', () async {
        final r = await TenantContext.get(ApiLinks.cteDacte('${c['id']}'));
        if (r.statusCode != 200) {
          AppLogger.i.warn('CteEmissaoView: DACTE #${c['id']} falhou: HTTP ${r.statusCode}');
          _aviso('Não foi possível gerar o DACTE (HTTP ${r.statusCode}).');
          return;
        }
        await FileSaver.instance.saveFile(
          name: 'dacte_${c['numero'] ?? c['id']}',
          bytes: r.bodyBytes,
          fileExtension: 'pdf',
          mimeType: MimeType.pdf,
        );
        _aviso('DACTE gerado.');
      });

  Future<void> _eventos(Map<String, dynamic> c) =>
      _acao('listar os eventos', () async {
        final r = await _net.getRequest(ApiLinks.cteEventos('${c['id']}'));
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
            title: Text('Eventos do CT-e ${c['numero']}'),
            content: SizedBox(
              width: larguraCte(context, 420, reserva: 90),
              child: lista.isEmpty
                  ? const Text('Nenhum evento registrado.')
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final e in lista)
                          ListTile(
                            dense: true,
                            title: Text('${_nomeEvento('${e['tipoEvento']}')} — ${e['status']}'),
                            subtitle: Text('${e['dhEvento'] ?? ''}\n${e['motivo'] ?? ''}'),
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

  Future<void> _excluir(Map<String, dynamic> c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir CT-e de teste'),
        content: Text(
            'Excluir o CT-e ${c['numero']} (homologação)? Esta ação não pode ser desfeita.'),
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
    await _acao('excluir o CT-e', () async {
      final r = await _net.deleteRequest(ApiLinks.cte('${c['id']}'));
      _aviso(r.isSuccess
          ? 'CT-e excluído.'
          : 'Não foi possível excluir (HTTP ${r.statusCode}). Só é permitido em homologação e CT-e autorizado precisa ser cancelado antes.');
      if (r.isSuccess) _carregar();
    });
  }

  Future<String?> _pedirTexto(
      {required String titulo, required String rotulo, required int minimo}) async {
    final ctrl = TextEditingController();
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) {
        String? erro;
        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            title: Text(titulo),
            content: TextField(
              controller: ctrl,
              maxLines: 3,
              maxLength: 255,
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
    ctrl.dispose();
    return resultado;
  }

  static String _nomeEvento(String tipo) {
    switch (tipo) {
      case '110111':
        return 'Cancelamento';
      case '110110':
        return 'Carta de correção';
      default:
        return tipo;
    }
  }

  Color _corStatus(String? s) {
    switch (s) {
      case 'AUTORIZADO':
      case 'REGISTRADO':
        return Colors.green.shade700;
      case 'REJEITADO':
      case 'CANCELADO':
      case 'DENEGADO':
        return Colors.red.shade700;
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
                child: Text('CT-e', style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                  tooltip: 'Atualizar',
                  onPressed: _carregar,
                  icon: const Icon(Icons.refresh)),
              FilledButton.icon(
                onPressed: _novo,
                icon: const Icon(Icons.add),
                label: const Text('Novo CT-e'),
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
                    ? const Center(child: Text('Nenhum CT-e emitido.'))
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

  Widget _cartao(Map<String, dynamic> c) {
    final status = c['status']?.toString();
    final autorizado = status == kCteAutorizado;
    final homolog = c['tpAmb'] == 2;
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
                    '${rotuloTipoCte(c['tipoCte'])} nº ${c['numero'] ?? '-'} • série ${c['serie'] ?? '-'}'
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
            if (c['valorPrestacao'] != null)
              Text('Valor da prestação: R\$ ${c['valorPrestacao']}',
                  style: const TextStyle(fontSize: 12)),
            if (c['chaveAcesso'] != null)
              SelectableText('Chave: ${c['chaveAcesso']}',
                  style: const TextStyle(fontSize: 12)),
            if (c['protocolo'] != null)
              Text('Protocolo: ${c['protocolo']}',
                  style: const TextStyle(fontSize: 12)),
            if ((c['motivo'] ?? '').toString().isNotEmpty)
              Text('${c['codigoRetorno'] ?? ''} ${c['motivo']}',
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                OutlinedButton.icon(
                    onPressed: () => _consultar(c),
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Consultar')),
                OutlinedButton.icon(
                    onPressed: () => _dacte(c),
                    icon: const Icon(Icons.picture_as_pdf, size: 18),
                    label: const Text('DACTE')),
                OutlinedButton.icon(
                    onPressed: () => _eventos(c),
                    icon: const Icon(Icons.history, size: 18),
                    label: const Text('Eventos')),
                if (autorizado)
                  OutlinedButton.icon(
                      onPressed: () => _cartaCorrecao(c),
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: const Text('Carta de correção')),
                if (autorizado)
                  OutlinedButton.icon(
                      onPressed: () => _cancelar(c),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancelar')),
                if (homolog)
                  TextButton.icon(
                      onPressed: () => _excluir(c),
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

class _CorrecaoCtl {
  final grupo = TextEditingController();
  final campo = TextEditingController();
  final valor = TextEditingController();
  final item = TextEditingController();

  void dispose() {
    grupo.dispose();
    campo.dispose();
    valor.dispose();
    item.dispose();
  }
}

/// Carta de correcao: uma ou mais correcoes (grupo, campo, novo valor, item).
class _CartaCorrecaoDialog extends StatefulWidget {
  final String numero;
  const _CartaCorrecaoDialog({required this.numero});

  @override
  State<_CartaCorrecaoDialog> createState() => _CartaCorrecaoDialogState();
}

class _CartaCorrecaoDialogState extends State<_CartaCorrecaoDialog> {
  final _form = GlobalKey<FormState>();
  final List<_CorrecaoCtl> _linhas = [_CorrecaoCtl()];

  @override
  void dispose() {
    for (final l in _linhas) {
      l.dispose();
    }
    super.dispose();
  }

  String? _obrigatorio(String? v, int max) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Obrigatório';
    if (t.length > max) return 'Máx. $max caracteres';
    return null;
  }

  void _enviar() {
    if (!_form.currentState!.validate()) return;
    Navigator.pop(context, [
      for (final l in _linhas)
        montarCorrecaoCte(
          grupo: l.grupo.text,
          campo: l.campo.text,
          valor: l.valor.text,
          item: int.tryParse(l.item.text.trim()),
        )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Carta de correção — CT-e ${widget.numero}'),
      content: SizedBox(
        width: larguraCte(context, 520, reserva: 90),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'Não pode corrigir valores do imposto, dados do emitente, tomador, '
                    'remetente ou destinatário, nem a data de emissão.',
                    style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                for (var i = 0; i < _linhas.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                            width: larguraCte(context, 150),
                            child: TextFormField(
                                controller: _linhas[i].grupo,
                                decoration: const InputDecoration(
                                    labelText: 'Grupo (ex.: infCarga)'),
                                validator: (v) => _obrigatorio(v, 20))),
                        SizedBox(
                            width: larguraCte(context, 150),
                            child: TextFormField(
                                controller: _linhas[i].campo,
                                decoration: const InputDecoration(
                                    labelText: 'Campo (ex.: proPred)'),
                                validator: (v) => _obrigatorio(v, 20))),
                        SizedBox(
                            width: larguraCte(context, 240),
                            child: TextFormField(
                                controller: _linhas[i].valor,
                                decoration:
                                    const InputDecoration(labelText: 'Novo valor'),
                                validator: (v) => _obrigatorio(v, 500))),
                        SizedBox(
                            width: larguraCte(context, 80),
                            child: TextFormField(
                                controller: _linhas[i].item,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Item'),
                                validator: (v) {
                                  final t = v?.trim() ?? '';
                                  if (t.isEmpty) return null;
                                  final n = int.tryParse(t);
                                  return (n == null || n < 1 || n > 99) ? '1 a 99' : null;
                                })),
                        if (_linhas.length > 1)
                          IconButton(
                              tooltip: 'Remover',
                              onPressed: () => setState(() {
                                    _linhas.removeAt(i).dispose();
                                  }),
                              icon: const Icon(Icons.remove_circle_outline)),
                      ],
                    ),
                  ),
                if (_linhas.length < kCteMaxCorrecoes)
                  TextButton.icon(
                      onPressed: () => setState(() => _linhas.add(_CorrecaoCtl())),
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar correção')),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Voltar')),
        FilledButton(onPressed: _enviar, child: const Text('Enviar')),
      ],
    );
  }
}

class _ParteCtl {
  final documento = TextEditingController();
  final ie = TextEditingController();
  final nome = TextEditingController();
  final telefone = TextEditingController();
  final logradouro = TextEditingController();
  final numero = TextEditingController();
  final bairro = TextEditingController();
  final ibge = TextEditingController();
  final municipio = TextEditingController();
  final cep = TextEditingController();
  String? uf;

  Map<String, dynamic> montar() => montarParteCte(
        documento: documento.text,
        inscricaoEstadual: ie.text,
        nome: nome.text,
        telefone: telefone.text,
        logradouro: logradouro.text,
        numero: numero.text,
        bairro: bairro.text,
        codigoMunicipio: ibge.text,
        municipio: municipio.text,
        cep: cep.text,
        uf: uf ?? '',
      );

  void dispose() {
    for (final c in [documento, ie, nome, telefone, logradouro, numero, bairro,
        ibge, municipio, cep]) {
      c.dispose();
    }
  }
}

class _CompCtl {
  final nome = TextEditingController(text: 'FRETE VALOR');
  final valor = TextEditingController();

  void dispose() {
    nome.dispose();
    valor.dispose();
  }
}

class _CteFormDialog extends StatefulWidget {
  const _CteFormDialog();

  @override
  State<_CteFormDialog> createState() => _CteFormDialogState();
}

class _CteFormDialogState extends State<_CteFormDialog> {
  final _net = NetworkCaller();
  final _form = GlobalKey<FormState>();
  final _serie = TextEditingController(text: '1');
  final _cfop = TextEditingController(text: '6353');
  final _natureza =
      TextEditingController(text: 'Prestação de serviço de transporte');
  final _origIbge = TextEditingController();
  final _origNome = TextEditingController();
  final _destIbge = TextEditingController();
  final _destNome = TextEditingController();
  final _valor = TextEditingController();
  final _icmsBase = TextEditingController();
  final _icmsAliq = TextEditingController();
  final _icmsValor = TextEditingController();
  final _cargaValor = TextEditingController();
  final _produto = TextEditingController();
  final _tipoMedida = TextEditingController(text: 'PESO BRUTO');
  final _quantidade = TextEditingController();
  final _chaves = TextEditingController();
  final _refs = TextEditingController();
  final _rntrc = TextEditingController();
  final _info = TextEditingController();
  final _rem = _ParteCtl();
  final _dest = _ParteCtl();
  final _exped = _ParteCtl();
  final _receb = _ParteCtl();
  final _outro = _ParteCtl();
  final List<_CompCtl> _componentes = [_CompCtl()];

  int _tpAmb = 2;
  int _tipoCte = kCteTipoNormal;
  bool _alteraTomador = false;
  int _indIeTomador = 1;
  int _tomador = 0;
  String? _origUf;
  String? _destUf;
  String _cst = '40';
  String _unidade = '01';
  bool _usaExped = false;
  bool _usaReceb = false;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    for (final c in [_serie, _cfop, _natureza, _origIbge, _origNome, _destIbge,
        _destNome, _valor, _icmsBase, _icmsAliq, _icmsValor, _cargaValor,
        _produto, _tipoMedida, _quantidade, _chaves, _refs, _rntrc, _info]) {
      c.dispose();
    }
    for (final p in [_rem, _dest, _exped, _receb, _outro]) {
      p.dispose();
    }
    for (final c in _componentes) {
      c.dispose();
    }
    super.dispose();
  }

  /// Complemento de valores nao exige remetente/destinatario (so o do tomador, se for um deles).
  bool get _exigeRemetente => _tipoCte != kCteTipoComplemento || _tomador == 0;
  bool get _exigeDestinatario => _tipoCte != kCteTipoComplemento || _tomador == 3;

  num? _numero(String t) => num.tryParse(t.trim().replaceAll(',', '.'));

  String? _obrigatorio(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

  String? _numeroObrigatorio(String? v) {
    final n = _numero(v ?? '');
    return (n == null || n < 0) ? 'Valor inválido' : null;
  }

  Widget _campo(String rotulo, TextEditingController c,
          {double largura = 200,
          String? Function(String?)? validator,
          TextInputType? teclado}) =>
      SizedBox(
        width: larguraCte(context, largura),
        child: TextFormField(
          controller: c,
          keyboardType: teclado,
          decoration: InputDecoration(labelText: rotulo),
          validator: validator ?? _obrigatorio,
        ),
      );

  Widget _ufDrop(String rotulo, String? valor, ValueChanged<String?> onChanged) =>
      SizedBox(
        width: 100,
        child: DropdownButtonFormField<String>(
          value: valor,
          decoration: InputDecoration(labelText: rotulo),
          items: [
            for (final uf in kCteUfs) DropdownMenuItem(value: uf, child: Text(uf))
          ],
          onChanged: onChanged,
          validator: (v) => v == null ? 'Obrigatório' : null,
        ),
      );

  Widget _secao(String titulo) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
      );

  Widget _parteCampos(String titulo, _ParteCtl p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secao(titulo),
          Wrap(spacing: 8, runSpacing: 4, children: [
            _campo('CPF/CNPJ', p.documento,
                validator: (v) =>
                    documentoValidoCte(v ?? '') ? null : 'CPF (11) ou CNPJ (14)'),
            _campo('Nome / razão social', p.nome, largura: 260),
            _campo('IE (opcional)', p.ie, validator: (_) => null),
            _campo('Telefone (opcional)', p.telefone, validator: (_) => null),
            _campo('Logradouro', p.logradouro, largura: 240),
            _campo('Número', p.numero, largura: 90),
            _campo('Bairro', p.bairro),
            _campo('Cód. IBGE do município', p.ibge,
                validator: (v) =>
                    _soDigitosCte(v ?? '').length == 7 ? null : '7 dígitos',
                teclado: TextInputType.number),
            _campo('Município', p.municipio),
            _campo('CEP (opcional)', p.cep, largura: 120, validator: (_) => null),
            _ufDrop('UF', p.uf, (v) => setState(() => p.uf = v)),
          ]),
        ],
      );

  Future<void> _emitir() async {
    if (!_form.currentState!.validate()) return;
    final invalidas = <String>[];
    final chaves = _tipoCte == kCteTipoComplemento
        ? <String>[]
        : extrairChaves(_chaves.text, invalidas: invalidas);
    final referencias = _tipoCte == kCteTipoNormal
        ? <String>[]
        : extrairChaves(_refs.text, invalidas: invalidas);
    if (invalidas.isNotEmpty) {
      setState(() => _erro = 'Chave(s) com tamanho inválido (esperado 44 dígitos): '
          '${invalidas.join(', ')}');
      return;
    }
    final erroReferencias = validarReferenciasCte(_tipoCte, referencias);
    if (erroReferencias != null) {
      setState(() => _erro = erroReferencias);
      return;
    }
    if (_tipoCte != kCteTipoComplemento && chaves.isEmpty) {
      setState(() => _erro = 'Informe ao menos uma chave de NF-e.');
      return;
    }
    final valorTotal = _numero(_valor.text)!;
    final componentes = [
      for (final c in _componentes)
        montarComponenteCte(c.nome.text, _numero(c.valor.text) ?? 0)
    ];
    final soma = componentes.fold<num>(0, (a, c) => a + (c['valor'] as num));
    if ((soma - valorTotal).abs() > 0.004) {
      setState(() => _erro =
          'A soma dos componentes (R\$ ${soma.toStringAsFixed(2)}) deve ser igual ao valor da prestação.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      final corpo = montarCorpoEmissaoCte(
        tpAmb: _tpAmb,
        serie: int.parse(_serie.text.trim()),
        cfop: _cfop.text,
        naturezaOperacao: _natureza.text,
        origem: montarLocalCte(_origIbge.text, _origNome.text, _origUf!),
        destino: montarLocalCte(_destIbge.text, _destNome.text, _destUf!),
        indIeTomador: _indIeTomador,
        tomadorPapel: _tomador,
        tomadorOutro: _tomador == 4 ? _outro.montar() : null,
        remetente: _exigeRemetente ? _rem.montar() : null,
        expedidor: (_usaExped || _tomador == 1) ? _exped.montar() : null,
        recebedor: (_usaReceb || _tomador == 2) ? _receb.montar() : null,
        destinatario: _exigeDestinatario ? _dest.montar() : null,
        valorPrestacao: valorTotal,
        componentes: componentes,
        icms: montarIcmsCte(
          cst: _cst,
          baseCalculo: _numero(_icmsBase.text),
          aliquota: _numero(_icmsAliq.text),
          valor: _numero(_icmsValor.text),
        ),
        valorCarga:
            _tipoCte == kCteTipoComplemento ? null : _numero(_cargaValor.text),
        produtoPredominante:
            _tipoCte == kCteTipoComplemento ? null : _produto.text,
        unidade: _unidade,
        tipoMedida: _tipoMedida.text,
        quantidade:
            _tipoCte == kCteTipoComplemento ? null : _numero(_quantidade.text),
        chavesNfe: chaves,
        tipoCte: _tipoCte,
        chavesReferenciadas: referencias,
        alteraTomador: _alteraTomador,
        rntrc: _rntrc.text,
        infoComplementar: _info.text,
      );
      final r = await _net.postRequest(ApiLinks.allCte, corpo);
      if (!mounted) return;
      if (r.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'CT-e ${r.body?['numero'] ?? ''}: ${r.body?['status']} ${r.body?['motivo'] ?? ''}')));
        Navigator.pop(context, true);
        return;
      }
      _erro = 'Não foi possível emitir (HTTP ${r.statusCode}). '
          'Confira os dados do emitente (cadastro da empresa), RNTRC, partes e valores.';
    } catch (e, st) {
      AppLogger.i.error('CteFormDialog: erro ao emitir: $e', st);
      _erro = 'Não foi possível emitir o CT-e.';
    }
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo CT-e'),
      content: SizedBox(
        width: larguraCte(context, 760, reserva: 90),
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_erro != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.red.shade50,
                    child: Text(_erro!, style: TextStyle(color: Colors.red.shade800)),
                  ),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  SizedBox(
                    width: larguraCte(context, 160),
                    child: DropdownButtonFormField<int>(
                      value: _tpAmb,
                      decoration: const InputDecoration(labelText: 'Ambiente'),
                      items: const [
                        DropdownMenuItem(value: 2, child: Text('Homologação')),
                        DropdownMenuItem(value: 1, child: Text('Produção')),
                      ],
                      onChanged: (v) => setState(() => _tpAmb = v ?? 2),
                    ),
                  ),
                  _campo('Série', _serie,
                      largura: 90,
                      teclado: TextInputType.number,
                      validator: (v) =>
                          _serieValida(v) ? null : '0 a 999'),
                  _campo('CFOP', _cfop,
                      largura: 100,
                      teclado: TextInputType.number,
                      validator: (v) =>
                          _soDigitosCte(v ?? '').length == 4 ? null : '4 dígitos'),
                  _campo('Natureza da prestação', _natureza, largura: 300),
                  _campo('RNTRC (opcional, 8 dígitos)', _rntrc,
                      validator: (v) => validarRntrcCte(v) ? null : '8 dígitos'),
                  SizedBox(
                    width: larguraCte(context, 240),
                    child: DropdownButtonFormField<int>(
                      value: _tipoCte,
                      decoration: const InputDecoration(labelText: 'Tipo do CT-e'),
                      items: [
                        for (final e in kCteTipos.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value))
                      ],
                      onChanged: (v) => setState(() {
                        _tipoCte = v ?? kCteTipoNormal;
                        if (_tipoCte != kCteTipoSubstituicao) _alteraTomador = false;
                      }),
                    ),
                  ),
                ]),
                if (_tipoCte != kCteTipoNormal) ...[
                  _secao(_tipoCte == kCteTipoComplemento
                      ? 'CT-e complementados'
                      : 'CT-e substituído'),
                  TextFormField(
                    controller: _refs,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                        labelText: _tipoCte == kCteTipoComplemento
                            ? 'Chaves dos CT-e (44 dígitos, 1 a $kCteMaxComplementados, uma por linha)'
                            : 'Chave do CT-e substituído (44 dígitos)'),
                    validator: _obrigatorio,
                  ),
                  if (_tipoCte == kCteTipoSubstituicao)
                    CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('O tomador do serviço foi alterado'),
                      value: _alteraTomador,
                      onChanged: (v) => setState(() => _alteraTomador = v ?? false),
                    ),
                ],
                _secao('Percurso da prestação'),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  _campo('Origem - IBGE', _origIbge,
                      validator: (v) =>
                          _soDigitosCte(v ?? '').length == 7 ? null : '7 dígitos',
                      teclado: TextInputType.number),
                  _campo('Origem - município', _origNome),
                  _ufDrop('UF', _origUf, (v) => setState(() => _origUf = v)),
                  _campo('Destino - IBGE', _destIbge,
                      validator: (v) =>
                          _soDigitosCte(v ?? '').length == 7 ? null : '7 dígitos',
                      teclado: TextInputType.number),
                  _campo('Destino - município', _destNome),
                  _ufDrop('UF', _destUf, (v) => setState(() => _destUf = v)),
                ]),
                _secao('Tomador do serviço'),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  SizedBox(
                    width: larguraCte(context, 200),
                    child: DropdownButtonFormField<int>(
                      value: _tomador,
                      decoration: const InputDecoration(labelText: 'Tomador'),
                      items: [
                        for (final e in kCteTomadores.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value))
                      ],
                      onChanged: (v) => setState(() => _tomador = v ?? 0),
                    ),
                  ),
                  SizedBox(
                    width: larguraCte(context, 240),
                    child: DropdownButtonFormField<int>(
                      value: _indIeTomador,
                      decoration: const InputDecoration(labelText: 'IE do tomador'),
                      items: [
                        for (final e in kCteIndIeTomador.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value))
                      ],
                      onChanged: (v) => setState(() => _indIeTomador = v ?? 1),
                    ),
                  ),
                ]),
                if (_exigeRemetente) _parteCampos('Remetente', _rem),
                if (_exigeDestinatario) _parteCampos('Destinatário', _dest),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Informar expedidor'),
                  value: _usaExped || _tomador == 1,
                  onChanged: _tomador == 1
                      ? null
                      : (v) => setState(() => _usaExped = v ?? false),
                ),
                if (_usaExped || _tomador == 1) _parteCampos('Expedidor', _exped),
                CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Informar recebedor'),
                  value: _usaReceb || _tomador == 2,
                  onChanged: _tomador == 2
                      ? null
                      : (v) => setState(() => _usaReceb = v ?? false),
                ),
                if (_usaReceb || _tomador == 2) _parteCampos('Recebedor', _receb),
                if (_tomador == 4) _parteCampos('Tomador (outro)', _outro),
                _secao('Valores da prestação'),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  _campo('Valor total (R\$)', _valor,
                      teclado: TextInputType.number,
                      validator: _numeroObrigatorio),
                ]),
                for (var i = 0; i < _componentes.length; i++)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _campo('Componente', _componentes[i].nome, largura: 260),
                      _campo('Valor (R\$)', _componentes[i].valor,
                          teclado: TextInputType.number,
                          validator: _numeroObrigatorio),
                      if (_componentes.length > 1)
                        IconButton(
                            tooltip: 'Remover',
                            onPressed: () => setState(() {
                                  _componentes.removeAt(i).dispose();
                                }),
                            icon: const Icon(Icons.remove_circle_outline)),
                    ],
                  ),
                TextButton.icon(
                    onPressed: () => setState(() => _componentes.add(_CompCtl())),
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar componente')),
                _secao('ICMS'),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  SizedBox(
                    width: larguraCte(context, 220),
                    child: DropdownButtonFormField<String>(
                      value: _cst,
                      decoration: const InputDecoration(labelText: 'Situação tributária'),
                      items: [
                        for (final e in kCteCstIcms.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value))
                      ],
                      onChanged: (v) => setState(() => _cst = v ?? '40'),
                    ),
                  ),
                  if (_cst == '00') ...[
                    _campo('Base de cálculo', _icmsBase,
                        teclado: TextInputType.number, validator: _numeroObrigatorio),
                    _campo('Alíquota (%)', _icmsAliq,
                        largura: 120,
                        teclado: TextInputType.number,
                        validator: _numeroObrigatorio),
                    _campo('Valor do ICMS', _icmsValor,
                        teclado: TextInputType.number, validator: _numeroObrigatorio),
                  ],
                ]),
                if (_tipoCte != kCteTipoComplemento) ...[
                _secao('Carga'),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  _campo('Valor da carga (R\$)', _cargaValor,
                      teclado: TextInputType.number, validator: _numeroObrigatorio),
                  _campo('Produto predominante', _produto, largura: 260),
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<String>(
                      value: _unidade,
                      decoration: const InputDecoration(labelText: 'Unidade'),
                      items: [
                        for (final e in kCteUnidades.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value))
                      ],
                      onChanged: (v) => setState(() => _unidade = v ?? '01'),
                    ),
                  ),
                  _campo('Tipo da medida', _tipoMedida,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        return (t.isEmpty || t.length > 20) ? '1 a 20 caracteres' : null;
                      }),
                  _campo('Quantidade', _quantidade,
                      teclado: TextInputType.number,
                      validator: (v) {
                        final n = _numero(v ?? '');
                        return (n == null || n <= 0) ? 'Valor inválido' : null;
                      }),
                ]),
                _secao('Documentos originários'),
                TextFormField(
                  controller: _chaves,
                  minLines: 2,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      labelText: 'Chaves das NF-e (44 dígitos, uma por linha)'),
                  validator: _obrigatorio,
                ),
                ],
                const SizedBox(height: 8),
                TextFormField(
                  controller: _info,
                  maxLines: 2,
                  decoration:
                      const InputDecoration(labelText: 'Observações (opcional)'),
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
        FilledButton(
          onPressed: _enviando ? null : _emitir,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Emitir'),
        ),
      ],
    );
  }
}
