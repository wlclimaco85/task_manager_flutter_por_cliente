import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../helpers/download_helper.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import 'package:http/http.dart' as http;

class ExportPowerBiDialog extends StatefulWidget {
  final String tipoInicial; // 'conta_pagar', 'conta_receber', 'lancamentos', etc.

  const ExportPowerBiDialog({super.key, this.tipoInicial = 'conta_pagar'});

  @override
  State<ExportPowerBiDialog> createState() => _ExportPowerBiDialogState();
}

class _ExportPowerBiDialogState extends State<ExportPowerBiDialog> {
  late String _tipoSelecionado;
  String _periodoSelecionado = 'mes_atual';
  DateTime? _dataInicio;
  DateTime? _dataFim;
  bool _exportando = false;

  final Map<String, String> _tipos = {
    'conta_pagar': 'Contas a Pagar',
    'conta_receber': 'Contas a Receber',
    'lancamentos': 'Lançamentos Financeiros',
    'conciliacao': 'Conciliação Bancária',
    'dashboard': 'Dashboard Financeiro',
  };

  final Map<String, String> _periodos = {
    'mes_atual': 'Mês Atual',
    'mes_anterior': 'Mês Anterior',
    'trimestre': 'Último Trimestre',
    'semestre': 'Último Semestre',
    'ano_atual': 'Ano Atual',
    'personalizado': 'Personalizado',
  };

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = widget.tipoInicial;
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final params = <String, String>{
        'formato': 'csv',
        'periodo': _periodoSelecionado,
      };
      if (_periodoSelecionado == 'personalizado') {
        if (_dataInicio != null) {
          params['dataInicio'] = _dataInicio!.toIso8601String().split('T').first;
        }
        if (_dataFim != null) {
          params['dataFim'] = _dataFim!.toIso8601String().split('T').first;
        }
      }

      final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
      final url = '${ApiLinks.exportarCsv(_tipoSelecionado)}?$queryString';

      final resp = await http.get(
        Uri.parse(url),
        headers: TenantContext.headers,
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        // Download CSV
        final bytes = resp.bodyBytes;
        if (kIsWeb) {
          await downloadCsvBytes(bytes, '${_tipoSelecionado}_${DateTime.now().millisecondsSinceEpoch}.csv');
        }

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arquivo CSV exportado com sucesso!'),
            backgroundColor: GridColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na exportação (${resp.statusCode})'),
            backgroundColor: GridColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: GridColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.download, color: GridColors.primary),
          const SizedBox(width: 8),
          const Text('Exportar para Power BI / CSV',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tipo de dados
            const Text('Tipo de Dados:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _tipoSelecionado,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: _tipos.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _tipoSelecionado = v!),
            ),
            const SizedBox(height: 16),

            // Período
            const Text('Período:',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _periodoSelecionado,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              items: _periodos.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _periodoSelecionado = v!),
            ),

            // Período personalizado
            if (_periodoSelecionado == 'personalizado') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dataInicio ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setState(() => _dataInicio = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data Início',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        child: Text(
                          _dataInicio != null
                              ? '${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}'
                              : 'Selecionar',
                          style: TextStyle(
                              color: _dataInicio != null
                                  ? Colors.black
                                  : Colors.grey[500]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _dataFim ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) setState(() => _dataFim = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data Fim',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                        child: Text(
                          _dataFim != null
                              ? '${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}'
                              : 'Selecionar',
                          style: TextStyle(
                              color: _dataFim != null
                                  ? Colors.black
                                  : Colors.grey[500]),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GridColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GridColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: GridColors.info, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O arquivo CSV será baixado e pode ser importado diretamente no Power BI, Excel ou Google Sheets.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _exportando ? null : _exportar,
          icon: _exportando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download, size: 16),
          label: Text(_exportando ? 'Exportando...' : 'Exportar CSV'),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
