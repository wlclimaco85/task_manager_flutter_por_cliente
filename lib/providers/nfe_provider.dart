import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe_state.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';

/// Provider que disponibiliza o NfeNotifier para a árvore de widgets
///
/// Uso:
/// ```dart
/// ChangeNotifierProvider<NfeNotifier>(
///   create: (_) => NfeNotifier(NfeRepository()),
///   child: MyApp(),
/// )
/// ```
///
/// Ou no widget:
/// ```dart
/// final notifier = Provider.of<NfeNotifier>(context);
/// notifier.listarNfe();
/// ```
/// Função factory que cria um NfeNotifier com repositório
NfeNotifier createNfeNotifier() {
  return NfeNotifier(NfeRepository());
}

/// Provider para o notifier de NFes — gerencia estado
///
/// Uso em widget:
/// ```dart
/// ChangeNotifierProvider<NfeNotifier>(
///   create: (_) => createNfeNotifier(),
///   child: MyApp(),
/// )
/// ```
///
/// Ou no Consumer:
/// ```dart
/// Consumer<NfeNotifier>(
///   builder: (context, notifier, child) {
///     return Text(notifier.state.isLoading ? 'Carregando...' : 'Pronto');
///   },
/// )
/// ```
