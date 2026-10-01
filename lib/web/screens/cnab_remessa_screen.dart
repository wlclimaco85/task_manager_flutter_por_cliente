import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/dropdown_helpers.dart';
import '../../widgets/searchable_dropdown.dart';

class CnabRemessaScreen extends StatefulWidget {
  const CnabRemessaScreen({super.key});

  @override
  State<CnabRemessaScreen> createState() => _CnabRemessaScreenState();
}

class _CnabRemessaScreenState extends State<CnabRemessaScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _contasBancarias = [];
  int? _selectedContaId;

  @override
  void initState() {
    super.initState();
    _loadContas();
  }

  Future<void> _loadContas() async {
    setState(() => _loading = true);
    try {
      final contas = await DropdownHelpers.contasBancarias();
      if (mounted) {
        setState(() {
          _contasBancarias = contas;
        });
      }
    } catch (e, stack) {
      AppLogger.i.error('Erro ao carregar contas bancárias', stack);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _gerarRemessa() async {
    if (_selectedContaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma conta bancária')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final url = '${ApiLinks.baseUrl}/api/edi/remessa/gerar/$_selectedContaId';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Não foi possível abrir o link de download');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download da remessa iniciado!')),
        );
      }
    } catch (e, stack) {
      AppLogger.i.error('Erro ao gerar remessa', stack);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao gerar remessa')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Envio EDI (Remessa CNAB)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecione a Conta Bancária para gerar o arquivo de Remessa dos boletos pendentes.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_loading && _contasBancarias.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              SearchableDropdownField(
                label: 'Conta Bancária',
                hintText: 'Clique para selecionar uma conta bancária...',
                value: _selectedContaId?.toString(),
                items: _contasBancarias,
                valueField: 'id',
                displayField: 'nome',
                isRequired: true,
                onChanged: (val) {
                  setState(() {
                    _selectedContaId = val != null ? int.tryParse(val) : null;
                  });
                },
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text('Gerar Arquivo de Remessa (EDI)'),
              onPressed:
                  _loading || _selectedContaId == null ? null : _gerarRemessa,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(250, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
