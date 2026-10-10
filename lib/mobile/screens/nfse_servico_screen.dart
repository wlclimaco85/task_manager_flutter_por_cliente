import 'package:flutter/material.dart';
import '../../../services/nfse_caller.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/nfse_ux_helper.dart';

/// Tela de formulário de emissão de NFS-e para mobile.
/// Exibe campos de cabeçalho + dados do serviço + impostos e chama a API via [NfseCaller].
class NfseServicoScreen extends StatefulWidget {
  final Function(String action)? hasPermission;

  const NfseServicoScreen({
    super.key,
    this.hasPermission,
  });

  @override
  State<NfseServicoScreen> createState() => _NfseServicoScreenState();
}

class _NfseServicoScreenState extends State<NfseServicoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _caller = NfseCaller();

  // Cabeçalho
  final _municipioCtrl = TextEditingController();
  final _cnpjTomadorCtrl = TextEditingController();
  final _nomeTomadorCtrl = TextEditingController();
  final _dataEmissaoCtrl = TextEditingController();
  final _serieCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();

  // Dados do serviço
  final _descricaoCtrl = TextEditingController();
  final _cnaeCtrl = TextEditingController();
  final _codigoTribCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _issCtrl = TextEditingController();
  final _deducoesCtrl = TextEditingController();

  // Impostos
  bool _issRetido = false;
  final _aliquotaIssCtrl = TextEditingController();
  final _pisCtrl = TextEditingController();
  final _cofinsCtrl = TextEditingController();
  final _irCtrl = TextEditingController();
  final _csllCtrl = TextEditingController();

  bool _salvando = false;
  String? _resultado;
  bool _sucesso = false;

  @override
  void dispose() {
    _municipioCtrl.dispose();
    _cnpjTomadorCtrl.dispose();
    _nomeTomadorCtrl.dispose();
    _dataEmissaoCtrl.dispose();
    _serieCtrl.dispose();
    _numeroCtrl.dispose();
    _descricaoCtrl.dispose();
    _cnaeCtrl.dispose();
    _codigoTribCtrl.dispose();
    _valorCtrl.dispose();
    _issCtrl.dispose();
    _deducoesCtrl.dispose();
    _aliquotaIssCtrl.dispose();
    _pisCtrl.dispose();
    _cofinsCtrl.dispose();
    _irCtrl.dispose();
    _csllCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final valor = double.tryParse(
          _valorCtrl.text.replaceAll(',', '.'),
        ) ??
        0;
    final aliquota = double.tryParse(
          _aliquotaIssCtrl.text.replaceAll(',', '.'),
        ) ??
        0;
    final errosMunicipais = NfseUxHelper.validarDadosMunicipais(
      municipio: _municipioCtrl.text,
      codigoTributacao: _codigoTribCtrl.text,
      descricaoServico: _descricaoCtrl.text,
      valor: valor,
      aliquotaIss: aliquota,
    );
    if (errosMunicipais.isNotEmpty) {
      setState(() {
        _sucesso = false;
        _resultado = NfseUxHelper.erroValidacaoMunicipal(errosMunicipais);
      });
      return;
    }

    setState(() {
      _salvando = true;
      _resultado = null;
      _sucesso = false;
    });
    try {
      final result = await _caller.emitir(
        municipio: _municipioCtrl.text.trim(),
        cnpjTomador: _cnpjTomadorCtrl.text.trim(),
        nomeTomador: _nomeTomadorCtrl.text.trim(),
        descricaoServico: _descricaoCtrl.text.trim(),
        valor: valor,
        aliquotaIss: aliquota,
        cnae: _cnaeCtrl.text.trim(),
        codigoTributacao: _codigoTribCtrl.text.trim(),
      );

      if (mounted) {
        setState(() {
          _sucesso = true;
          _resultado = NfseUxHelper.retornoPrefeitura(result);
        });
      }
    } catch (e) {
      AppLogger.i.warn('Erro ao emitir NFS-e: $e');
      if (mounted) {
        setState(() {
          _sucesso = false;
          _resultado = e is NfseException ? e.message : 'Erro: $e';
        });
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _limpar() {
    _formKey.currentState?.reset();
    _municipioCtrl.clear();
    _cnpjTomadorCtrl.clear();
    _nomeTomadorCtrl.clear();
    _dataEmissaoCtrl.clear();
    _serieCtrl.clear();
    _numeroCtrl.clear();
    _descricaoCtrl.clear();
    _cnaeCtrl.clear();
    _codigoTribCtrl.clear();
    _valorCtrl.clear();
    _issCtrl.clear();
    _deducoesCtrl.clear();
    _aliquotaIssCtrl.clear();
    _pisCtrl.clear();
    _cofinsCtrl.clear();
    _irCtrl.clear();
    _csllCtrl.clear();
    setState(() {
      _issRetido = false;
      _resultado = null;
      _sucesso = false;
    });
  }

  Widget _secaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        titulo,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: GridColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _campo(
    String label,
    TextEditingController ctrl, {
    TextInputType teclado = TextInputType.text,
    bool obrigatorio = false,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: teclado,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: obrigatorio ? '$label *' : label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        validator: obrigatorio
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Nota de Serviço (NFS-e)'),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: _limpar,
            icon: const Icon(Icons.clear_all, color: Colors.white, size: 20),
            label: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // Cabeçalho
            _secaoTitulo('CABEÇALHO'),
            _campo(
              'Município de Prestação',
              _municipioCtrl,
              obrigatorio: true,
              hint: 'Ex: São Paulo',
            ),
            _campo(
              'CNPJ / CPF do Tomador',
              _cnpjTomadorCtrl,
              teclado: TextInputType.number,
              hint: '00.000.000/0001-00',
            ),
            _campo(
              'Nome / Razão Social do Tomador',
              _nomeTomadorCtrl,
              obrigatorio: true,
            ),
            Row(
              children: [
                Expanded(
                  child: _campo(
                    'Data de Emissão',
                    _dataEmissaoCtrl,
                    hint: 'dd/mm/aaaa',
                    teclado: TextInputType.datetime,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo('Série', _serieCtrl, hint: '1'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    'Número',
                    _numeroCtrl,
                    teclado: TextInputType.number,
                  ),
                ),
              ],
            ),

            // Dados do Serviço
            _secaoTitulo('DADOS DO SERVIÇO'),
            _campo(
              'Descrição do Serviço',
              _descricaoCtrl,
              obrigatorio: true,
              maxLines: 3,
            ),
            Row(
              children: [
                Expanded(
                  child: _campo(
                    'CNAE',
                    _cnaeCtrl,
                    hint: '0000-0/00',
                    teclado: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    'Código de Tributação Municipal (LC116)',
                    _codigoTribCtrl,
                    obrigatorio: true,
                    hint: '01.01',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _campo(
                    'Valor R\$',
                    _valorCtrl,
                    obrigatorio: true,
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    hint: '0,00',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    'ISS R\$',
                    _issCtrl,
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    hint: '0,00',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    'Deduções R\$',
                    _deducoesCtrl,
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    hint: '0,00',
                  ),
                ),
              ],
            ),

            // Impostos
            _secaoTitulo('IMPOSTOS'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('ISS Retido na Fonte'),
              value: _issRetido,
              activeColor: GridColors.primary,
              onChanged: (v) => setState(() => _issRetido = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _campo(
                    'Alíquota ISS %',
                    _aliquotaIssCtrl,
                    obrigatorio: true,
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    hint: '2,00',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    'PIS %',
                    _pisCtrl,
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    hint: '0,65',
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _campo(
                    'COFINS %',
                    _cofinsCtrl,
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    hint: '3,00',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    'IR %',
                    _irCtrl,
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    hint: '1,50',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    'CSLL %',
                    _csllCtrl,
                    teclado:
                        const TextInputType.numberWithOptions(decimal: true),
                    hint: '1,00',
                  ),
                ),
              ],
            ),

            // Resultado
            if (_resultado != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _sucesso ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        _sucesso ? Colors.green.shade200 : Colors.red.shade200,
                  ),
                ),
                child: Text(
                  _resultado!,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        _sucesso ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Botão Salvar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _salvando ? null : _salvar,
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 20),
                label: Text(
                  _salvando ? 'Emitindo...' : 'Emitir NFS-e',
                  style: const TextStyle(fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
