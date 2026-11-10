import 'package:task_manager_flutter/utils/file_saver_compat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../services/nfse_faturar_service.dart';
import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/dropdown_helpers.dart';
import '../utils/grid_colors.dart';
import '../utils/nfse_faturar_utils.dart';
import '../utils/tenant_context.dart';
import 'searchable_dropdown.dart';

/// Abre o popUp "Faturar" da tela de NFS-e (Web, Windows e Mobile compartilham este widget).
Future<void> showNfseFaturarDialog(BuildContext context,
    {VoidCallback? onConcluido}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => NfseFaturarDialog(onConcluido: onConcluido),
  );
}

enum _Fase { carregando, formulario, enviando, resultado, erro }

class NfseFaturarDialog extends StatefulWidget {
  final VoidCallback? onConcluido;
  const NfseFaturarDialog({super.key, this.onConcluido});

  @override
  State<NfseFaturarDialog> createState() => _NfseFaturarDialogState();
}

class _NfseFaturarDialogState extends State<NfseFaturarDialog> {
  _Fase _fase = _Fase.carregando;
  String? _erroCarga;
  String _mensagemErro = '';
  NfseFaturarResultado? _resultado;

  List<Map<String, dynamic>> _series = [];
  List<Map<String, dynamic>> _servicos = [];

  String? _tomadorId;
  String? _serieId;
  String? _servicoId;
  late int _mes;
  late int _ano;
  final _valorCtrl = TextEditingController();
  bool _valorEditado = false;

  Map<String, dynamic>? _resumo;
  bool _carregandoResumo = false;
  String? _erroResumo;

  @override
  void initState() {
    super.initState();
    final padrao = nfseCompetenciaPadrao(DateTime.now());
    _mes = padrao.mes;
    _ano = padrao.ano;
    _carregarListas();
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarListas() async {
    setState(() {
      _fase = _Fase.carregando;
      _erroCarga = null;
    });
    try {
      final resultados = await Future.wait([
        NfseFaturarService.series(),
        NfseFaturarService.servicos(),
      ]);
      if (!mounted) return;
      setState(() {
        _series = resultados[0];
        _servicos = resultados[1];
        // Conveniencia: unica opcao ja vem selecionada.
        if (_series.length == 1) _serieId = _series.first['id'] as String;
        if (_servicos.length == 1) _servicoId = _servicos.first['id'] as String;
        _fase = _Fase.formulario;
      });
    } on NfseFaturarException catch (e) {
      if (!mounted) return;
      setState(() {
        _erroCarga = e.mensagem;
        _fase = _Fase.formulario;
      });
    }
  }

  Future<void> _carregarResumo() async {
    final tomador = int.tryParse(_tomadorId ?? '');
    if (tomador == null) return;
    setState(() {
      _carregandoResumo = true;
      _erroResumo = null;
    });
    try {
      final resumo = await NfseFaturarService.resumo(
          tomadorId: tomador, mes: _mes, ano: _ano);
      if (!mounted) return;
      setState(() {
        _resumo = resumo;
        if (!_valorEditado) _valorCtrl.text = nfseValorPadrao(resumo);
      });
    } on NfseFaturarException catch (e) {
      if (!mounted) return;
      setState(() {
        _resumo = null;
        _erroResumo = e.mensagem;
        if (!_valorEditado) _valorCtrl.clear();
      });
    } finally {
      if (mounted) setState(() => _carregandoResumo = false);
    }
  }

  double? get _valorMensal => nfseParseNumero(_resumo?['valorMensal']);
  double get _jaFaturado => nfseParseNumero(_resumo?['jaFaturado']) ?? 0;

  String? get _erroValor {
    if (_resumo == null) return null;
    return nfseValidarValorFaturar(
      valor: nfseParseValorDigitado(_valorCtrl.text),
      valorMensal: _valorMensal,
      jaFaturado: _jaFaturado,
    );
  }

  bool get _podeFaturar =>
      _tomadorId != null &&
      _serieId != null &&
      _servicoId != null &&
      _resumo != null &&
      !_carregandoResumo &&
      _erroValor == null;

  Future<void> _faturar() async {
    final valor = nfseParseValorDigitado(_valorCtrl.text);
    final tomador = int.tryParse(_tomadorId ?? '');
    final serie = int.tryParse(_serieId ?? '');
    final servico = int.tryParse(_servicoId ?? '');
    if (valor == null || tomador == null || serie == null || servico == null) {
      return;
    }
    setState(() => _fase = _Fase.enviando);
    try {
      final resultado = await NfseFaturarService.faturar(
        tomadorId: tomador,
        serieId: serie,
        produtoId: servico,
        mes: _mes,
        ano: _ano,
        valor: valor,
        emissorParceiroId: TenantContext.parceiroId,
      );
      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _fase = _Fase.resultado;
      });
      widget.onConcluido?.call();
    } on NfseFaturarException catch (e) {
      if (!mounted) return;
      setState(() {
        _mensagemErro = e.mensagem;
        _fase = _Fase.erro;
      });
    }
  }

  Future<void> _copiarErro() async {
    await Clipboard.setData(ClipboardData(text: _mensagemErro));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Mensagem copiada.'), duration: Duration(seconds: 2)));
  }

  Future<List<int>?> _baixarDanfse() async {
    final id = _resultado?.nfseId;
    if (id == null) return null;
    try {
      final r = await TenantContext.get(ApiLinks.danfseNfse(id.toString()));
      if (r.statusCode == 200) return r.bodyBytes;
      AppLogger.i.warn('Faturar NFS-e: DANFSE #$id retornou HTTP ${r.statusCode}');
      _avisar('Não foi possível obter o PDF (HTTP ${r.statusCode}).');
    } catch (e, st) {
      AppLogger.i.error('Faturar NFS-e: erro ao baixar DANFSE #$id: $e', st);
      _avisar('Erro ao obter o PDF: $e');
    }
    return null;
  }

  Future<void> _baixarPdf() async {
    final bytes = await _baixarDanfse();
    if (bytes == null) return;
    try {
      await FileSaver.instance.saveFile(
        name: 'danfse_${_resultado?.nfseId}',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'pdf',
        mimeType: MimeType.pdf,
      );
    } catch (e, st) {
      AppLogger.i.error('Faturar NFS-e: erro ao salvar PDF: $e', st);
      _avisar('Erro ao salvar o PDF: $e');
    }
  }

  Future<void> _imprimir() async {
    final bytes = await _baixarDanfse();
    if (bytes == null) return;
    try {
      await Printing.layoutPdf(
        name: 'danfse_${_resultado?.nfseId}',
        onLayout: (_) async => Uint8List.fromList(bytes),
      );
    } catch (e, st) {
      AppLogger.i.error('Faturar NFS-e: erro ao imprimir PDF: $e', st);
      _avisar('Erro ao imprimir: $e');
    }
  }

  void _avisar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: GridColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(switch (_fase) {
        _Fase.resultado => 'NFS-e faturada',
        _Fase.erro => 'Não foi possível faturar',
        _ => 'Faturar NFS-e',
      }),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: _conteudo(context)),
        ),
      ),
      actions: _acoes(context),
    );
  }

  Widget _conteudo(BuildContext context) {
    switch (_fase) {
      case _Fase.carregando:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        );
      case _Fase.enviando:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Gerando contas, GED e enviando a NFS-e à prefeitura...',
                textAlign: TextAlign.center),
          ]),
        );
      case _Fase.erro:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nada foi gravado. Você pode tentar novamente ou '
                'emitir a nota manualmente.'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GridColors.error.withOpacity(0.08),
                border: Border.all(color: GridColors.error.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(_mensagemErro,
                  key: const Key('nfse_faturar_erro')),
            ),
          ],
        );
      case _Fase.resultado:
        return _resultadoView(_resultado!);
      case _Fase.formulario:
        return _formulario(context);
    }
  }

  Widget _linha(String rotulo, String valor, {Key? key}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 150,
              child: Text(rotulo,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: SelectableText(valor, key: key)),
        ]),
      );

  Widget _resultadoView(NfseFaturarResultado r) {
    String id(int? v) => v == null ? '-' : '#$v';
    final ged = !r.gedPreenchido
        ? 'Não'
        : r.pdfGerado
            ? 'Sim (arquivo ${id(r.arquivoGedId)})'
            : 'Reservado (arquivo ${id(r.arquivoGedId)}), PDF pendente';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (r.mensagem.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(bottom: 8), child: Text(r.mensagem)),
        _linha('NFS-e nº', r.numeroNfse ?? id(r.nfseId),
            key: const Key('nfse_faturar_numero')),
        _linha('Conta a pagar', id(r.contaPagarId)),
        _linha('Conta a receber', id(r.contaReceberId)),
        _linha('Mensalidade', id(r.mensalidadeId)),
        _linha('GED preenchido', ged),
        if (r.dataVencimento != null)
          _linha('Vencimento', nfseFormatarDataIso(r.dataVencimento!)),
      ],
    );
  }

  Widget _formulario(BuildContext context) {
    final anoAtual = DateTime.now().year;
    final anos = [anoAtual - 2, anoAtual - 1, anoAtual, anoAtual + 1];
    if (!anos.contains(_ano)) anos.add(_ano);
    final erroValor = _erroValor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_erroCarga != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_erroCarga!,
                style: const TextStyle(color: GridColors.error)),
          ),
        SearchableDropdownField(
          label: 'Tomador (parceiro)',
          value: _tomadorId,
          valueField: 'id',
          displayField: 'nome',
          isRequired: true,
          loadPage: ({String? busca, required int pagina}) =>
              DropdownHelpers.parceirosBusca(
            busca: busca,
            pagina: pagina,
            empresaId: TenantContext.empresaId?.toString(),
          ),
          labelResolver: DropdownHelpers.parceiroLabelPorId,
          onChanged: (v) {
            setState(() {
              _tomadorId = v;
              _resumo = null;
              _valorEditado = false;
              _valorCtrl.clear();
            });
            _carregarResumo();
          },
        ),
        const SizedBox(height: 12),
        SearchableDropdownField(
          label: 'Série',
          value: _serieId,
          items: _series,
          valueField: 'id',
          displayField: 'nome',
          isRequired: true,
          onChanged: (v) => setState(() => _serieId = v),
        ),
        const SizedBox(height: 12),
        SearchableDropdownField(
          label: 'Produto/Serviço',
          value: _servicoId,
          items: _servicos,
          valueField: 'id',
          displayField: 'nome',
          isRequired: true,
          onChanged: (v) => setState(() => _servicoId = v),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<int>(
              key: const Key('nfse_faturar_mes'),
              initialValue: _mes,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Mês de referência', border: OutlineInputBorder()),
              items: [
                for (var m = 1; m <= 12; m++)
                  DropdownMenuItem(value: m, child: Text(nfseNomeMes(m))),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _mes = v);
                _carregarResumo();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<int>(
              key: const Key('nfse_faturar_ano'),
              initialValue: _ano,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Ano', border: OutlineInputBorder()),
              items: [
                for (final a in anos..sort())
                  DropdownMenuItem(value: a, child: Text('$a')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _ano = v);
                _carregarResumo();
              },
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          key: const Key('nfse_faturar_valor'),
          controller: _valorCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Valor (R\$)',
            border: const OutlineInputBorder(),
            errorText: erroValor,
            errorMaxLines: 3,
          ),
          onChanged: (_) => setState(() => _valorEditado = true),
        ),
        const SizedBox(height: 8),
        _infoResumo(),
      ],
    );
  }

  Widget _infoResumo() {
    if (_carregandoResumo) {
      return const Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
              height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_erroResumo != null) {
      return Text(_erroResumo!, style: const TextStyle(color: GridColors.error));
    }
    final r = _resumo;
    if (r == null) {
      return const Text('Selecione o tomador para carregar o valor mensal.',
          style: TextStyle(fontSize: 12));
    }
    final venc = r['dataVencimento']?.toString();
    return Text(
      'Valor mensal: R\$ ${nfseFormatarValor(_valorMensal)}  •  '
      'Já faturado no mês: R\$ ${nfseFormatarValor(_jaFaturado)}  •  '
      'Saldo: R\$ ${nfseFormatarValor(nfseParseNumero(r['saldo']))}'
      '${venc != null ? '\nVencimento das contas: ${nfseFormatarDataIso(venc)}' : ''}',
      key: const Key('nfse_faturar_resumo'),
      style: const TextStyle(fontSize: 12),
    );
  }

  List<Widget> _acoes(BuildContext context) {
    const alturaMinima = Size(0, 44);
    switch (_fase) {
      case _Fase.carregando:
      case _Fase.enviando:
        return const [];
      case _Fase.formulario:
        return [
          TextButton(
            style: TextButton.styleFrom(minimumSize: alturaMinima),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            key: const Key('nfse_faturar_confirmar'),
            style: FilledButton.styleFrom(minimumSize: alturaMinima),
            onPressed: _podeFaturar ? _faturar : null,
            icon: const Icon(Icons.request_quote, size: 18),
            label: const Text('Faturar'),
          ),
        ];
      case _Fase.erro:
        return [
          TextButton(
            style: TextButton.styleFrom(minimumSize: alturaMinima),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          OutlinedButton.icon(
            key: const Key('nfse_faturar_copiar'),
            style: OutlinedButton.styleFrom(minimumSize: alturaMinima),
            onPressed: _copiarErro,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copiar'),
          ),
          FilledButton.icon(
            key: const Key('nfse_faturar_tentar_novamente'),
            style: FilledButton.styleFrom(minimumSize: alturaMinima),
            onPressed: _faturar,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Tentar novamente'),
          ),
        ];
      case _Fase.resultado:
        return [
          TextButton(
            style: TextButton.styleFrom(minimumSize: alturaMinima),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          OutlinedButton.icon(
            key: const Key('nfse_faturar_baixar_pdf'),
            style: OutlinedButton.styleFrom(minimumSize: alturaMinima),
            onPressed: _baixarPdf,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Baixar PDF'),
          ),
          FilledButton.icon(
            key: const Key('nfse_faturar_imprimir'),
            style: FilledButton.styleFrom(minimumSize: alturaMinima),
            onPressed: _imprimir,
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Imprimir'),
          ),
        ];
    }
  }
}
