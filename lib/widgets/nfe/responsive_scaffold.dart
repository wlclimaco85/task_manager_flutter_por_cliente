import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/widgets/nfe/nfe_filter_chip.dart';

/// Scaffold adaptativo reutilizável para todas as screens NFe
///
/// Gerencia AppBar, body, filters, FAB de forma responsiva
/// Aplica padding adaptativo por breakpoint
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Breakpoint breakpoint;
  final List<NfeFilterChip>? filters;
  final Widget? fab;
  final PreferredSizeWidget? bottomBar;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.breakpoint,
    this.filters,
    this.fab,
    this.bottomBar,
  });

  /// Retorna padding responsivo para body
  EdgeInsets _getBodyPadding() {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return const EdgeInsets.symmetric(horizontal: DesignTokens.spacingSm, vertical: DesignTokens.spacingSm);
      case Breakpoint.tablet:
        return const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd, vertical: DesignTokens.spacingMd);
      case Breakpoint.desktop:
        return const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg, vertical: DesignTokens.spacingMd);
    }
  }

  /// Constrói AppBar customizado
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: DesignTokens.h1FontSizeDesktop,
          fontWeight: DesignTokens.h1FontWeight,
          color: DesignTokens.textPrimary,
        ),
      ),
      backgroundColor: DesignTokens.primary,
      elevation: 2,
      centerTitle: false,
      actions: breakpoint == Breakpoint.desktop
          ? [
              Padding(
                padding: const EdgeInsets.all(12),
                child: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                  tooltip: 'Buscar',
                ),
              ),
            ]
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filtros (se houver)
          if (filters != null && filters!.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.spacingMd,
                vertical: DesignTokens.spacingSm,
              ),
              child: Row(
                children: List.generate(
                  filters!.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: filters![index],
                  ),
                ),
              ),
            ),
          // Body principal
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: _getBodyPadding(),
                child: body,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: fab,
      bottomNavigationBar: bottomBar,
    );
  }
}
