import 'package:flutter/material.dart';

import '../../models/auth_utility.dart';
import '../../services/ponto_rep_p_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/file_saver_compat.dart';

/// Arquivos fiscais do Ponto (Portaria MTP 671/2021): AFD, AEJ, espelho (Art. 84) e
/// situacao de conformidade. Layout vertical unico: serve Web, Windows e Mobile.
class PontoRepPScreen extends StatefulWidget {
  const PontoRepPScreen({super.key, this.service});

  final PontoRepPService? service;

  @override
  State<PontoRepPScreen> createState() => _PontoRepPScreenState();
}

class _PontoRepPScreenState extends State<PontoRepPScreen> {
  late final PontoRepPService _service = widget.service ?? PontoRepPService();
  final _funcionarioCtrl = TextEditingController();
  late DateTime _inicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  late DateTime _fim = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  bool _carregando = false;
  Map<String, dynamic>? _conformidade;

  int? get _empresaId => AuthUtility.userInfo?.login?.empresa?.id;

  @override
  void initState() {
    super.initState();
    _carregarConformidade();
  }

  @override
  void dispose() {
    _funcionarioCtrl.dispose();
    super.dispose();
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _carregarConformidade() async {
    final r = await _service.conformidade();
    if (!mounted) return;
    setState(() => _conformidade = r.dado);
    if (!r.ok) _aviso(r.erro!);
  }

  Future<void> _escolherData(bool inicio) async {
    final d = await showDatePicker(
      context: context,
      initialDate: inicio ? _inicio : _fim,
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => inicio ? _inicio = d : _fim = d);
  }

  Future<void> _executar(Future<RepPResultado<RepPArquivo>> Function(int empresaId) acao) async {
    final empresaId = _empresaId;
    if (empresaId == null) {
      _aviso('Empresa nao identificada na sessao.');
      return;
    }
    if (_fim.isBefore(_inicio)) {
      _aviso('A data final deve ser igual ou posterior a inicial.');
      return;
    }
    setState(() => _carregando = true);
    try {
      final r = await acao(empresaId);
      if (!r.ok) {
        _aviso(r.erro!);
        return;
      }
      final a = r.dado!;
      final destino = await FileSaver.instance.saveFile(
        name: a.nome,
        bytes: a.bytes,
        fileExtension: a.extensao,
        mimeType: a.extensao == 'pdf' ? MimeType.pdf : MimeType.other,
      );
      _aviso('Arquivo gerado: $destino');
    } catch (e, st) {
      AppLogger.i.error('[REP-P] erro ao salvar arquivo: $e', st);
      _aviso('Nao foi possivel salvar o arquivo.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final pend = (_conformidade?['pendencias'] as List?)?.cast<String>() ?? const <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Arquivos Fiscais de Ponto (Portaria 671)')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Periodo', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 8, children: [
              OutlinedButton.icon(
                key: const Key('repp_inicio'),
                icon: const Icon(Icons.event),
                label: Text('Inicio: ${_fmt(_inicio)}'),
                onPressed: () => _escolherData(true),
              ),
              OutlinedButton.icon(
                key: const Key('repp_fim'),
                icon: const Icon(Icons.event),
                label: Text('Fim: ${_fmt(_fim)}'),
                onPressed: () => _escolherData(false),
              ),
            ]),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 8, children: [
              FilledButton.icon(
                key: const Key('repp_afd'),
                icon: const Icon(Icons.download),
                label: const Text('Baixar AFD'),
                onPressed: _carregando ? null : () => _executar((e) => _service.baixarAfd(e, _inicio, _fim)),
              ),
              FilledButton.icon(
                key: const Key('repp_aej'),
                icon: const Icon(Icons.download),
                label: const Text('Baixar AEJ'),
                onPressed: _carregando ? null : () => _executar((e) => _service.baixarAej(e, _inicio, _fim)),
              ),
              OutlinedButton(
                key: const Key('repp_afd_p7s'),
                onPressed: _carregando ? null : () => _executar((e) => _service.baixarAfdAssinatura(e, _inicio, _fim)),
                child: const Text('Assinatura AFD (.p7s)'),
              ),
              OutlinedButton(
                key: const Key('repp_aej_p7s'),
                onPressed: _carregando ? null : () => _executar((e) => _service.baixarAejAssinatura(e, _inicio, _fim)),
                child: const Text('Assinatura AEJ (.p7s)'),
              ),
            ]),
            const SizedBox(height: 24),
            Text('Espelho de ponto (Art. 84)', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              key: const Key('repp_funcionario'),
              controller: _funcionarioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'ID do funcionario'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('repp_espelho'),
              icon: const Icon(Icons.picture_as_pdf),
              label: Text('Espelho de ${_inicio.month.toString().padLeft(2, '0')}/${_inicio.year}'),
              onPressed: _carregando
                  ? null
                  : () {
                      final f = int.tryParse(_funcionarioCtrl.text.trim());
                      if (f == null) {
                        _aviso('Informe o ID do funcionario.');
                        return;
                      }
                      _executar((e) => _service.baixarEspelho(e, f, _inicio.month, _inicio.year));
                    },
            ),
            if (_carregando) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
            const SizedBox(height: 24),
            Text('Conformidade', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_conformidade == null)
              const Text('Situacao indisponivel no momento.')
            else if (pend.isEmpty)
              const Text('Sem pendencias.')
            else
              ...pend.map((p) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.info_outline),
                    title: Text(p),
                  )),
          ],
        ),
      ),
    );
  }
}
