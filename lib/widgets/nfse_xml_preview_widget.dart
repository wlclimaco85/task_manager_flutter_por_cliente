import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';

/// Preview do XML de NFS-e (analogo a NfeXmlPreviewWidget) -- ABRASF tem UM
/// UNICO servico por nota, entao o "item" fica embutido no proprio DTO
/// (NfseImportacaoDTO), sem lista de itens como na NF-e.
///
/// Se o backend sugeriu um produto-servico ja cadastrado (produtoSugeridoId),
/// oferece usar a sugestao ou cadastrar um produto novo -- mesma logica de
/// conciliacao do import de NF-e, so que pra 1 servico em vez de N itens.
class NfseXmlPreviewWidget extends StatefulWidget {
  final Map<String, dynamic> data;
  final void Function({int? produtoId, bool criarNovoProduto}) onConfirm;
  final VoidCallback onCancel;
  final bool confirming;

  const NfseXmlPreviewWidget({
    super.key,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
    this.confirming = false,
  });

  @override
  State<NfseXmlPreviewWidget> createState() => _NfseXmlPreviewWidgetState();
}

class _NfseXmlPreviewWidgetState extends State<NfseXmlPreviewWidget> {
  bool _criarNovoProduto = false;

  String? _get(String key) => widget.data[key]?.toString();

  bool get _duplicata => widget.data['duplicata'] == true;

  int? get _produtoSugeridoId {
    final v = widget.data['produtoSugeridoId'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  @override
  void initState() {
    super.initState();
    _criarNovoProduto = _produtoSugeridoId == null;
  }

  @override
  Widget build(BuildContext context) {
    final numero = _get('numero') ?? '-';
    final codigoVerificacao = _get('codigoVerificacao') ?? '-';
    final tomador = _get('tomadorRazaoSocial') ?? '-';
    final tomadorDocumento = _get('tomadorCnpj') ?? _get('tomadorCpf') ?? '-';
    final dataEmissao = _get('dataEmissao') ?? '-';
    final discriminacao = _get('discriminacao') ?? '-';
    final valorServicos = _get('valorServicos') ?? '-';
    final aliquotaIss = _get('aliquotaIss') ?? '-';
    final valorIss = _get('valorIss') ?? '-';
    final produtoSugeridoNome = _get('produtoSugeridoNome');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, color: GridColors.secondary, size: 22),
                const SizedBox(width: 8),
                const Text('Preview da NFS-e',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _duplicata ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _duplicata ? Colors.red : Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_duplicata ? Icons.cancel : Icons.check_circle,
                          size: 16, color: _duplicata ? Colors.red : Colors.green),
                      const SizedBox(width: 4),
                      Text(
                        _duplicata ? 'NFS-e ja importada' : 'NFS-e nova',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _duplicata ? Colors.red.shade800 : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('Numero / Cod. Verificacao', '$numero / $codigoVerificacao'),
            _buildField('Tomador (Cliente)', '$tomador ($tomadorDocumento)'),
            _buildField('Data de Emissao', dataEmissao),
            _buildField('Discriminacao do Servico', discriminacao),
            _buildField('Valor dos Servicos', valorServicos),
            _buildField('Aliquota ISS / Valor ISS', '$aliquotaIss% / $valorIss'),
            const Divider(height: 24),
            const Text('Conciliacao de Produto-Servico',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            if (produtoSugeridoNome != null)
              RadioListTile<bool>(
                value: false,
                groupValue: _criarNovoProduto,
                onChanged: (v) => setState(() => _criarNovoProduto = v ?? false),
                title: Text('Usar produto ja cadastrado: $produtoSugeridoNome'),
                dense: true,
              ),
            RadioListTile<bool>(
              value: true,
              groupValue: _criarNovoProduto,
              onChanged: (v) => setState(() => _criarNovoProduto = v ?? true),
              title: const Text('Cadastrar como produto-servico novo'),
              dense: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: widget.confirming
                      ? null
                      : () => widget.onConfirm(
                            produtoId: _criarNovoProduto ? null : _produtoSugeridoId,
                            criarNovoProduto: _criarNovoProduto,
                          ),
                  icon: widget.confirming
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(widget.confirming ? 'Importando...' : 'Confirmar Importacao'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: widget.confirming ? null : widget.onCancel,
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
