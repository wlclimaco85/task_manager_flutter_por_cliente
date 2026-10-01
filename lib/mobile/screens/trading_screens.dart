import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../features/trading/trading_dashboard_screen.dart';
import '../../features/trading/screens/sinais_screen.dart';
import '../../features/trading/screens/oportunidades_screen.dart';
import '../../features/trading/screens/backtest_screen.dart';
import '../../features/trading/screens/trading_config_screen.dart';
import '../../features/trading/services/backtest_repository.dart';
import '../../features/trading/screens/carteira_screen.dart';
import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';

/// Tela mobile de Sinais de Mercado
class MobileTradingSinaisScreen extends StatelessWidget {
  const MobileTradingSinaisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinais de Mercado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(child: SinaisScreen()),
    );
  }
}

/// Tela mobile de Oportunidades
class MobileTradingOportunidadesScreen extends StatelessWidget {
  const MobileTradingOportunidadesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oportunidades',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(child: OportunidadesScreen()),
    );
  }
}

/// Tela mobile de Watchlist
class MobileTradingWatchlistScreen extends StatelessWidget {
  const MobileTradingWatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watchlist',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(child: TradingDashboardScreen(initialTabIndex: 1)),
    );
  }
}

/// Tela mobile de Alertas de Preço
class MobileTradingAlertasScreen extends StatelessWidget {
  const MobileTradingAlertasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Preço',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(child: TradingDashboardScreen(initialTabIndex: 2)),
    );
  }
}

/// Tela mobile de Operações Assistidas
class MobileTradingOperacoesScreen extends StatelessWidget {
  const MobileTradingOperacoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operações Assistidas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(child: TradingDashboardScreen(initialTabIndex: 3)),
    );
  }
}

/// Tela mobile de Configuração da Corretora
class MobileTradingCorretoraScreen extends StatelessWidget {
  const MobileTradingCorretoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração da Corretora',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(child: TradingConfigScreen()),
    );
  }
}

/// Tela mobile de Minha Carteira
class MobileTradingCarteiraScreen extends StatelessWidget {
  const MobileTradingCarteiraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Carteira',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(child: CarteiraScreen()),
    );
  }
}

/// Tela mobile de Backtest
class MobileBacktestScreen extends StatelessWidget {
  const MobileBacktestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backtesting',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GridColors.textPrimary)),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: BacktestScreen(
          repository: BacktestRepository(ApiLinks.baseUrl, headers: TenantContext.jsonHeaders),
        ),
      ),
    );
  }
}
