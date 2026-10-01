import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/features/agendamento/presentation/notifiers/agendamento_notifier.dart';
import 'package:task_manager_flutter/features/agendamento/presentation/widgets/rrule_picker_segmentado.dart';
import 'package:task_manager_flutter/features/agendamento/presentation/widgets/preview_ocorrencias.dart';

/// Tela principal de agendamento de NFe recorrente
class AgendamentoScreen extends StatefulWidget {
  const AgendamentoScreen({Key? key}) : super(key: key);

  @override
  State<AgendamentoScreen> createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  late String _selectedRrule = 'FREQ=DAILY';

  @override
  void initState() {
    super.initState();
    // Carregar agendamentos ao abrir
    Future.microtask(() {
      context.read<AgendamentoNotifier>().carregarAgendamentos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final isTablet = MediaQuery.of(context).size.width >= 600 &&
        MediaQuery.of(context).size.width < 1024;
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar NFe Recorrente'),
        elevation: 2,
      ),
      body: Consumer<AgendamentoNotifier>(
        builder: (context, notifier, _) {
          if (notifier.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notifier.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro: ${notifier.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: notifier.carregarAgendamentos,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (isMobile) {
            return _buildMobileLayout(context, notifier);
          } else if (isTablet) {
            return _buildTabletLayout(context, notifier);
          } else {
            return _buildDesktopLayout(context, notifier);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AgendamentoNotifier notifier) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNfeInfoCard(context),
            const SizedBox(height: 24),
            _buildRrulePickerSection(context),
            const SizedBox(height: 24),
            PreviewOcorrencias(rrule: _selectedRrule),
            const SizedBox(height: 24),
            _buildActionButtons(context, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, AgendamentoNotifier notifier) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildNfeInfoCard(context),
                  const SizedBox(height: 24),
                  _buildRrulePickerSection(context),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  PreviewOcorrencias(rrule: _selectedRrule),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, notifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AgendamentoNotifier notifier) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _buildNfeInfoCard(context),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 1,
              child: _buildRrulePickerSection(context),
            ),
            const SizedBox(width: 32),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  PreviewOcorrencias(rrule: _selectedRrule),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, notifier),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNfeInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações da NFe',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Número:', '1234567'),
            _buildInfoRow('Fornecedor:', 'Empresa LTDA'),
            _buildInfoRow('Valor:', 'R\$ 1.500,00'),
            _buildInfoRow('Status:', 'Pendente'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildRrulePickerSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequência de Recorrência',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            RrulePickerSegmentado(
              onRruleChanged: (rrule) {
                setState(() => _selectedRrule = rrule);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AgendamentoNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle),
          label: const Text('Agendar'),
          onPressed: () => _handleAgendar(context, notifier),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel),
          label: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Future<void> _handleAgendar(BuildContext context, AgendamentoNotifier notifier) async {
    try {
      await notifier.agendar(_selectedRrule);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento criado com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erro'),
            content: Text('Falha ao criar agendamento: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
