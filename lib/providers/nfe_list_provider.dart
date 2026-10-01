import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/providers/nfe_notifier.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Provider wrapper com FutureBuilder para carregar NFes inicialmente
///
/// Responsável por:
/// - Carregar lista de NFes ao montar
/// - Aplicar paginação e filtros
/// - Gerenciar estado de carregamento com FutureBuilder
///
/// Uso:
/// ```dart
/// NfeListProvider(
///   child: NfeListScreen(),
/// )
/// ```
class NfeListProvider extends StatefulWidget {
  final Widget child;
  final int pageSize;

  const NfeListProvider({
    super.key,
    required this.child,
    this.pageSize = 10,
  });

  @override
  State<NfeListProvider> createState() => _NfeListProviderState();
}

class _NfeListProviderState extends State<NfeListProvider> {
  late Future<List<NfeModel>> _nfesFuture;

  @override
  void initState() {
    super.initState();
    _nfesFuture = _loadNfes();
  }

  Future<List<NfeModel>> _loadNfes() async {
    try {
      L.d('[NfeListProvider] Carregando NFes inicialmente');
      final notifier = context.read<NfeNotifier>();
      await notifier.listarNfe(page: 1, pageSize: widget.pageSize);
      return notifier.state.nfes;
    } catch (e) {
      L.e('[NfeListProvider] Erro ao carregar NFes: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NfeModel>>(
      future: _nfesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Erro ao carregar NFes'),
                  const SizedBox(height: 8),
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _nfesFuture = _loadNfes()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        return widget.child;
      },
    );
  }
}

/// Widget para envolver NfeListScreen com provider de dados
/// Facilita inicialização de dados com padrão FutureBuilder
class NfeListProviderWrapper extends StatelessWidget {
  final int pageSize;

  const NfeListProviderWrapper({
    super.key,
    this.pageSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return NfeListProvider(
      pageSize: pageSize,
      child: Container(),
    );
  }
}

/// Extension para facilitar acesso ao NfeNotifier a partir de NFe
extension NfeListProviderExt on BuildContext {
  NfeNotifier get nfeNotifier => read<NfeNotifier>();

  Future<void> loadNfes({
    int page = 1,
    int pageSize = 10,
    String? status,
    DateTime? dataInicio,
    DateTime? dataFim,
    String? clienteCnpj,
  }) async {
    await nfeNotifier.listarNfe(
      page: page,
      pageSize: pageSize,
      status: status,
      dataInicio: dataInicio,
      dataFim: dataFim,
      clienteCnpj: clienteCnpj,
    );
  }
}
