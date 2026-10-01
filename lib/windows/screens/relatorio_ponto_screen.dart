import 'package:flutter/material.dart';
import '../../services/ponto_service.dart';
import '../../utils/grid_colors.dart';
import '../../models/auth_utility.dart';
import '../../widgets/user_banners.dart';
import 'pdf_preview_dialog.dart';

class RelatorioPontoScreen extends StatefulWidget {
  const RelatorioPontoScreen({super.key});

  @override
  State<RelatorioPontoScreen> createState() => _RelatorioPontoScreenState();
}

class _RelatorioPontoScreenState extends State<RelatorioPontoScreen> {
  bool _loading = false;
  int _mesSelecionado = DateTime.now().month;
  int _anoSelecionado = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: UserBannerAppBar(
        screenTitle: 'Relatório e Espelho',
        showBackButton: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: GridColors.card,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selecione o Período',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: GridColors.textPrimary),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'Mês',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  value: _mesSelecionado,
                                  items: List.generate(
                                      12,
                                      (index) => DropdownMenuItem(
                                            value: index + 1,
                                            child: Text('${index + 1}'),
                                          )),
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(() => _mesSelecionado = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  decoration: InputDecoration(
                                    labelText: 'Ano',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                  ),
                                  value: _anoSelecionado,
                                  items: [2024, 2025, 2026]
                                      .map((a) => DropdownMenuItem(
                                            value: a,
                                            child: Text('${a}'),
                                          ))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null)
                                      setState(() => _anoSelecionado = val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf,
                                color: Colors.white),
                            label: const Text('Gerar Espelho (PDF)',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            onPressed: _loading
                                ? null
                                : () async {
                                    setState(() => _loading = true);
                                    final loginId =
                                        AuthUtility.userInfo?.login?.id;
                                    if (loginId == null) {
                                      setState(() => _loading = false);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Login não encontrado na sessão')));
                                      return;
                                    }

                                    final pdfBytes =
                                        await PontoService.gerarEspelhoPdf(
                                            loginId,
                                            _mesSelecionado,
                                            _anoSelecionado);
                                    if (!mounted) return;
                                    setState(() => _loading = false);

                                    if (pdfBytes != null) {
                                      showDialog(
                                        context: context,
                                        builder: (_) =>
                                            PdfPreviewDialog(bytes: pdfBytes),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Erro ao gerar PDF do Espelho de Ponto.')));
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GridColors.primary,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.table_chart,
                                color: Colors.white),
                            label: const Text('Relatório de Absenteísmo',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            onPressed: _loading
                                ? null
                                : () async {
                                    setState(() => _loading = true);
                                    final dados =
                                        await PontoService.relatorioAbsenteismo(
                                            _mesSelecionado, _anoSelecionado);
                                    if (!mounted) return;
                                    setState(() => _loading = false);
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Absenteísmo'),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: dados.isEmpty
                                              ? const Text(
                                                  'Sem registros de faltas/atrasos neste período.')
                                              : ListView.builder(
                                                  shrinkWrap: true,
                                                  itemCount: dados.length,
                                                  itemBuilder: (c, i) {
                                                    final d = dados[i];
                                                    return ListTile(
                                                      title: Text(
                                                          d['funcionario'] ??
                                                              ''),
                                                      subtitle: Text(
                                                          "Faltas: ${d['faltas']} | Atrasos: ${d['atrasos']}"),
                                                    );
                                                  },
                                                ),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Fechar'))
                                        ],
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GridColors.secondary,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
