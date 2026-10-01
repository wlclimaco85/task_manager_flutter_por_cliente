import 'package:flutter/material.dart';
import '../../../services/nfse_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../customization/generic_grid_card.dart';
import '../../../models/nfse_model.dart';

class NfseConsultaScreen extends StatefulWidget {
  final SecurityCheck hasPermission;
  final VoidCallback? onUserBannerTapped;

  const NfseConsultaScreen({
    super.key,
    required this.hasPermission,
    this.onUserBannerTapped,
  });

  @override
  State<NfseConsultaScreen> createState() => _NfseConsultaScreenState();
}

class _NfseConsultaScreenState extends State<NfseConsultaScreen> {
  final _caller = NfseCaller();
  final _municipioCtrl = TextEditingController();
  final _cnpjCtrl = TextEditingController();
  final _nomeCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _aliquotaCtrl = TextEditingController();
  final _cnaeCtrl = TextEditingController();
  final _codigoTribCtrl = TextEditingController();
  bool _emitindo = false;
  String? _resultadoEmissao;
  int _gridKey = 0;

  @override
  void dispose() {
    _municipioCtrl.dispose();
    _cnpjCtrl.dispose();
    _nomeCtrl.dispose();
    _descricaoCtrl.dispose();
    _valorCtrl.dispose();
    _aliquotaCtrl.dispose();
    _cnaeCtrl.dispose();
    _codigoTribCtrl.dispose();
    super.dispose();
  }

  Future<void> _emitir() async {
    setState(() { _emitindo = true; _resultadoEmissao = null; });
    try {
      final result = await _caller.emitir(
        municipio: _municipioCtrl.text,
        cnpjTomador: _cnpjCtrl.text,
        nomeTomador: _nomeCtrl.text,
        descricaoServico: _descricaoCtrl.text,
        valor: double.parse(_valorCtrl.text),
        aliquotaIss: double.parse(_aliquotaCtrl.text),
        cnae: _cnaeCtrl.text,
        codigoTributacao: _codigoTribCtrl.text,
      );
      if (mounted) {
        setState(() {
          _resultadoEmissao = 'NFSe emitida!\n'
              'Número: ${result['numero'] ?? result['nfseNumber'] ?? '-'}\n'
              'Protocolo: ${result['protocolo'] ?? result['protocol'] ?? '-'}\n'
              'Status: ${result['status'] ?? result['situacao'] ?? '-'}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _resultadoEmissao = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _emitindo = false);
    }
  }

  void _showEmissaoDialog() {
    _municipioCtrl.clear();
    _cnpjCtrl.clear();
    _nomeCtrl.clear();
    _descricaoCtrl.clear();
    _valorCtrl.clear();
    _aliquotaCtrl.clear();
    _cnaeCtrl.clear();
    _codigoTribCtrl.clear();
    _resultadoEmissao = null;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          child: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Emitir NFS-e',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _campo('Município de Prestação', _municipioCtrl),
                  _campo('CNPJ do Tomador', _cnpjCtrl),
                  _campo('Nome do Tomador', _nomeCtrl),
                  _campo('Descrição do Serviço', _descricaoCtrl),
                  Row(children: [
                    Expanded(child: _campo('Valor R\$', _valorCtrl, teclado: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _campo('Alíquota ISS %', _aliquotaCtrl, teclado: TextInputType.number)),
                  ]),
                  Row(children: [
                    Expanded(child: _campo('CNAE', _cnaeCtrl)),
                    const SizedBox(width: 12),
                    Expanded(child: _campo('Cód. Tributação', _codigoTribCtrl)),
                  ]),
                  if (_resultadoEmissao != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _resultadoEmissao!.startsWith('Erro')
                            ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _resultadoEmissao!.startsWith('Erro')
                              ? Colors.red.shade200 : Colors.green.shade200,
                        ),
                      ),
                      child: Text(_resultadoEmissao!, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () { Navigator.pop(ctx); setState(() => _gridKey++); },
                        child: const Text('Fechar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _emitindo ? null : () async {
                          await _emitir();
                          setDlgState(() {});
                        },
                        icon: _emitindo
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, size: 18),
                        label: Text(_emitindo ? 'Emitindo...' : 'Emitir'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: GridColors.primary, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, {TextInputType? teclado}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: teclado,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GenericMobileGridScreen<Nfse>(
      key: ValueKey('nfse_grid_$_gridKey'),
      title: 'Notas de Serviço (NFS-e)',
      fetchEndpoint: ApiLinks.allNfse,
      createEndpoint: ApiLinks.allNfse,
      updateEndpoint: ApiLinks.nfse(':id'),
      deleteEndpoint: ApiLinks.nfse(':id'),
      fromJson: (json) => Nfse.fromJson(json),
      toJson: (obj) => obj.toJson(),
      hasPermission: widget.hasPermission,
      fieldConfigs: Nfse.fieldConfigs,
      idFieldName: 'id',
      dateFieldName: 'dataEmissao',
      useUserBannerAppBar: true,
      onUserBannerTapped: widget.onUserBannerTapped,
      paginationConfig: const PaginationConfig(
        defaultRowsPerPage: 10,
        availableRowsPerPage: [10, 25, 50],
      ),
      enableSearch: true,
      customActions: () => [
        CustomAction<Nfse>(
          icon: Icons.send,
          label: 'Emitir NFS-e',
          onPressed: (ctx, _) => _showEmissaoDialog(),
        ),
      ],
    );
  }
}
