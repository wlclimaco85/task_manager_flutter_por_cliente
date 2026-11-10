import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/nfse_logo_service.dart';

/// Logo do DANFSe de uma empresa ou de um parceiro: mostra a atual, troca, salva e remove.
class NfseLogoDialog extends StatefulWidget {
  final String titulo;
  final String urlLogo;
  /// Retorna null quando salvou, ou a mensagem de erro para o usuario.
  final Future<String?> Function(List<int> bytes, String nomeArquivo) enviar;

  const NfseLogoDialog({
    super.key,
    required this.titulo,
    required this.urlLogo,
    required this.enviar,
  });

  @override
  State<NfseLogoDialog> createState() => _NfseLogoDialogState();
}

class _NfseLogoDialogState extends State<NfseLogoDialog> {
  Uint8List? _atual;
  Uint8List? _escolhida;
  String? _nomeEscolhido;
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregarAtual();
  }

  Future<void> _carregarAtual() async {
    final bytes = await NfseLogoService.buscar(widget.urlLogo);
    if (!mounted) return;
    setState(() {
      _atual = bytes == null ? null : Uint8List.fromList(bytes);
      _carregando = false;
    });
  }

  Future<void> _escolher() async {
    final resultado = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (resultado == null || resultado.files.isEmpty) return;
    final arquivo = resultado.files.first;
    final bytes = arquivo.bytes;
    if (bytes == null) return;
    setState(() {
      _escolhida = bytes;
      _nomeEscolhido = arquivo.name;
    });
  }

  Future<void> _salvar() async {
    final bytes = _escolhida;
    if (bytes == null || _salvando) return;
    setState(() => _salvando = true);
    final erro = await widget.enviar(bytes, _nomeEscolhido ?? 'logo.png');
    if (!mounted) return;
    setState(() => _salvando = false);
    final ok = erro == null;
    if (ok) {
      setState(() {
        _atual = bytes;
        _escolhida = null;
        _nomeEscolhido = null;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'Logo do DANFSe salva.'
          : erro),
    ));
  }

  Future<void> _remover() async {
    final ok = await NfseLogoService.remover(widget.urlLogo);
    if (!mounted) return;
    if (ok) {
      setState(() {
        _atual = null;
        _escolhida = null;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Logo removida.' : 'Nao foi possivel remover a logo.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final visivel = _escolhida ?? _atual;
    return AlertDialog(
      title: Text('Logo do DANFSe — ${widget.titulo}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 140,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _carregando
                  ? const CircularProgressIndicator()
                  : visivel == null
                      ? Text('Sem logo cadastrada', style: TextStyle(color: cs.onSurfaceVariant))
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.memory(visivel, fit: BoxFit.contain),
                        ),
            ),
            const SizedBox(height: 8),
            Text(
              _nomeEscolhido != null
                  ? 'Nova imagem: $_nomeEscolhido (ainda nao salva)'
                  : 'PNG ou JPEG, ate 512 KB. Aparece no topo do DANFSe.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _salvando ? null : _escolher,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Escolher imagem'),
            ),
          ],
        ),
      ),
      actions: [
        if (_atual != null)
          TextButton(
            onPressed: _salvando ? null : _remover,
            child: const Text('Remover logo'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
        FilledButton(
          onPressed: (_escolhida == null || _salvando) ? null : _salvar,
          child: Text(_salvando ? 'Salvando…' : 'Salvar logo'),
        ),
      ],
    );
  }
}
