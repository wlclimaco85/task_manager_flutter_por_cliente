import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/models/nfe/nfe_filter_model.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';
import 'package:task_manager_flutter/widgets/nfe_filter_bar.dart';
import 'details/nfe_detail_dialog.dart';

/// Tela principal para visualizar e gerenciar NFes emitidas.
/// Suporta grid responsivo (4 colunas desktop, 2 tablet, 1 mobile).
/// Inclui filtros, ordenação, paginação e busca.
class NfeListScreen extends StatefulWidget {
  const NfeListScreen({super.key});

  @override
  State<NfeListScreen> createState() => _NfeListScreenState();
}

class _NfeListScreenState extends State<NfeListScreen> {
  late NfeFilterModel _currentFilter;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _currentFilter = NfeFilterModel();
    L.d('[NfeListScreen] Iniciado com filtro padrão');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas Fiscais Emitidas'),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Consumer<NfeNotifier>(
        builder: (context, notifier, _) {
          if (notifier.state.isLoading && notifier.state.nfes.isEmpty) {
            return _buildLoadingShimmer();
          }

          if (notifier.state.hasError) {
            return _buildErrorState(notifier);
          }

          if (notifier.state.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              NfeFilterBar(
                onFilterChanged: (filter) {
                  setState(() => _currentFilter = filter);
                  // TODO: Implementar applyFilter em NfeNotifier
                },
              ),
              Expanded(
                child: _buildNfeGrid(notifier, context),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  /// Constrói grid responsivo de NFes
  Widget _buildNfeGrid(NfeNotifier notifier, BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final breakpoint = ResponsiveHelper.getBreakpoint(width);
    final colCount = _getColumnCount(breakpoint);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: colCount,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: notifier.state.nfes.length,
      itemBuilder: (context, index) {
        final nfe = notifier.state.nfes[index];
        return _buildNfeCard(nfe, context);
      },
    );
  }

  /// Retorna número de colunas baseado em breakpoint
  int _getColumnCount(Breakpoint breakpoint) {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return 1;
      case Breakpoint.tablet:
        return 2;
      case Breakpoint.desktop:
        return 4;
    }
  }

  /// Constrói card individual de NFe
  Widget _buildNfeCard(NfeModel nfe, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _showDetailDialog(nfe, context),
      child: Card(
        elevation: 2,
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cabeçalho: Número + Série + Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NFe #${nfe.numero}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Série ${nfe.serie}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: nfe.statusNfe.code == 'AUTORIZADA'
                      ? GridColors.success.withOpacity(0.2)
                      : nfe.statusNfe.code == 'CANCELADA'
                          ? GridColors.error.withOpacity(0.2)
                          : const Color(0xFFF9A825).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  nfe.statusNfe.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: nfe.statusNfe.code == 'AUTORIZADA'
                        ? GridColors.success
                        : nfe.statusNfe.code == 'CANCELADA'
                            ? GridColors.error
                            : const Color(0xFFF9A825),
                  ),
                ),
              ),

              // Data + Valor
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatDate(nfe.dataHora),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${nfe.valores.total.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Destinatário (truncado)
              Text(
                nfe.tomador.razaoSocial.length > 25
                    ? '${nfe.tomador.razaoSocial.substring(0, 25)}...'
                    : nfe.tomador.razaoSocial,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formata DateTime para DD/MM/YYYY
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  /// Abre dialog de detalhes
  void _showDetailDialog(NfeModel nfe, BuildContext context) {
    L.d('[NfeListScreen] Abrindo detalhes da NFe #${nfe.numero}');
    showDialog(
      context: context,
      builder: (context) => NfeDetailDialog(nfe: nfe),
    );
  }

  /// Construtor do FAB (Novo)
  Widget? _buildFab(BuildContext context) {
    const hasPermission = true; // TODO: Verificar permissão real

    if (!hasPermission) {
      return Tooltip(
        message: 'Você não tem permissão para criar NFes',
        child: FloatingActionButton(
          onPressed: null,
          backgroundColor: Colors.grey[400],
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }

    return FloatingActionButton(
      onPressed: () => _createNewNfe(context),
      tooltip: 'Criar nova NFe',
      child: const Icon(Icons.add),
    );
  }

  /// Ação de criar nova NFe
  void _createNewNfe(BuildContext context) {
    L.d('[NfeListScreen] Iniciando criação de nova NFe');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Funcionalidade em desenvolvimento')),
    );
  }

  /// Builder para estado vazio
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma NFe encontrada',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajuste os filtros ou crie uma nova',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Builder para estado de erro
  Widget _buildErrorState(NfeNotifier notifier) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar NFes',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              notifier.state.errorMessage ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              notifier.limparErro();
              notifier.listarNfe();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  /// Builder para skeleton loading shimmer
  Widget _buildLoadingShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 16,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  /// Card shimmer individual
  Widget _buildShimmerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 12,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
