import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';
import 'data/repositories/agendamento_repository_impl.dart';
import 'presentation/notifiers/agendamento_notifier.dart';
import 'presentation/screens/agendamento_screen.dart';

/// Ponto de entrada real do módulo de Agendamento de NFe Recorrente.
///
/// Faz a fiação de DI (Dio + Connectivity + Hive offline box) que a
/// [AgendamentoScreen] espera via Provider, evitando ProviderNotFoundException
/// ao navegar até a tela pelo menu/sidebar. Sem este wrapper a tela existia
/// no código mas não era navegável nem funcional (card P3-502/P3-503).
class AgendamentoModuleScreen extends StatefulWidget {
  const AgendamentoModuleScreen({Key? key}) : super(key: key);

  @override
  State<AgendamentoModuleScreen> createState() =>
      _AgendamentoModuleScreenState();
}

class _AgendamentoModuleScreenState extends State<AgendamentoModuleScreen> {
  late final AgendamentoRepositoryImpl _repository;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _repository = AgendamentoRepositoryImpl(
      dio: Dio(BaseOptions(
        baseUrl: ApiLinks.baseUrl,
        headers: TenantContext.jsonHeaders,
      )),
      connectivity: Connectivity(),
    );
    _initFuture = _repository.initializeHive();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Agendar NFe Recorrente')),
            body: Center(
              child: Text('Erro ao iniciar agendamento: ${snapshot.error}'),
            ),
          );
        }
        return ChangeNotifierProvider<AgendamentoNotifier>(
          create: (_) => AgendamentoNotifier(repository: _repository),
          child: const AgendamentoScreen(),
        );
      },
    );
  }
}
