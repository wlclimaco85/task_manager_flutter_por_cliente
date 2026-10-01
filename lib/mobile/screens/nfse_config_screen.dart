import 'dart:convert';
import '../../widgets/user_banners.dart';
import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';

class NfseConfigScreen extends StatefulWidget {
  const NfseConfigScreen({super.key});

  @override
  State<NfseConfigScreen> createState() => _NfseConfigScreenState();
}

class _NfseConfigScreenState extends State<NfseConfigScreen> {
  final _aliquotaCtrl = TextEditingController();
  final _codigoTribCtrl = TextEditingController();
  final _municipioCtrl = TextEditingController();
  final _cnaeCtrl = TextEditingController();
  String _ambiente = 'HOMOLOGACAO';
  bool _carregando = false;
  bool _salvando = false;
  int? _configId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _aliquotaCtrl.dispose();
    _codigoTribCtrl.dispose();
    _municipioCtrl.dispose();
    _cnaeCtrl.dispose();
    super.dispose();
  }

  int? get _empresaId => AuthUtility.userInfo?.login?.empresa?.id;

  Future<void> _carregar() async {
    final eid = _empresaId;
    if (eid == null) return;
    setState(() => _carregando = true);
    try {
      final r = await TenantContext.get(ApiLinks.nfseConfig(eid));
      if (r.statusCode == 200 && mounted) {
        final body = jsonDecode(r.body);
        final data = body['data'];
        if (data is Map && data.isNotEmpty) {
          _configId = data['id'];
          _aliquotaCtrl.text = data['aliquotaIssPadrao']?.toString() ?? '';
          _codigoTribCtrl.text = data['codigoTributacaoMunicipalPadrao']?.toString() ?? '';
          _municipioCtrl.text = data['municipioPrestacaoPadrao']?.toString() ?? '';
          _cnaeCtrl.text = data['cnaePadrao']?.toString() ?? '';
          _ambiente = data['ambiente']?.toString() ?? 'HOMOLOGACAO';
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _salvar() async {
    final eid = _empresaId;
    if (eid == null) return;
    setState(() => _salvando = true);
    try {
      final body = {
        'empresaId': eid,
        'ambiente': _ambiente,
        'aliquotaIssPadrao': double.tryParse(_aliquotaCtrl.text) ?? 0,
        'codigoTributacaoMunicipalPadrao': _codigoTribCtrl.text,
        'municipioPrestacaoPadrao': _municipioCtrl.text,
        'cnaePadrao': _cnaeCtrl.text,
      };
      final r = await TenantContext.post(ApiLinks.nfseConfigSalvar, body);
      if (mounted) {
        if (r.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuração salva!'), backgroundColor: GridColors.success));
          _carregar();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ${r.statusCode}'), backgroundColor: GridColors.error));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: GridColors.error));
      }
    }
    if (mounted) setState(() => _salvando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: 'Config ISS - NFS-e',
        showBackButton: Navigator.canPop(context),
        onRefresh: _carregar,
        isLoading: _carregando,
        actions: [
          TextButton.icon(
            onPressed: _salvando ? null : _salvar,
            icon: _salvando
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Salvar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Ambiente',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'HOMOLOGACAO', label: Text('Homologação')),
                      ButtonSegment(value: 'PRODUCAO', label: Text('Produção')),
                    ],
                    selected: {_ambiente},
                    onSelectionChanged: (v) => setState(() => _ambiente = v.first),
                  ),
                  const SizedBox(height: 20),
                  _campo('Município de Prestação (padrão)', _municipioCtrl),
                  _campo('Alíquota ISS padrão (%)', _aliquotaCtrl, teclado: TextInputType.number),
                  _campo('Código Tributação Municipal (padrão)', _codigoTribCtrl),
                  _campo('CNAE padrão', _cnaeCtrl),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _salvando ? null : _salvar,
                      icon: _salvando
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(_salvando ? 'Salvando...' : 'Salvar Configuração'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, {TextInputType? teclado}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: teclado,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }
}
