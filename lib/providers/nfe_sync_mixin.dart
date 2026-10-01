import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:task_manager_flutter/repositories/nfe_local_repository.dart';
import 'package:task_manager_flutter/services/connectivity_service.dart';
import 'package:task_manager_flutter/services/nfe/nfe_sync_service.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Mixin que adiciona capacidades de sincronização a notifiers de NFe
///
/// Fornece:
/// - Sincronização automática com backend
/// - Fallback para cache local
/// - Detecção de conectividade
/// - Offline badge status
mixin NfeSyncMixin on ChangeNotifier {
  late NfeSyncService _syncService;
  late ConnectivityService _connectivityService;
  bool _isOnline = true;
  bool _isSyncing = false;
  DateTime? _lastSync;

  /// Initializa serviços de sync
  void initSync({
    required NfeSyncService syncService,
    required ConnectivityService connectivityService,
  }) {
    _syncService = syncService;
    _connectivityService = connectivityService;

    // Monitora mudanças de conectividade
    _connectivityService.connectionStream.listen((isOnline) {
      _isOnline = isOnline;
      L.d('[NfeSyncMixin] Conectividade mudou: $_isOnline');
      notifyListeners();

      // Se voltou online, sincroniza
      if (isOnline) {
        sincronizar();
      }
    });

    _connectivityService.startMonitoring();
  }

  /// Sincroniza com backend e atualiza estado
  Future<void> sincronizar() async {
    if (_isSyncing) {
      L.d('[NfeSyncMixin] Sync já em andamento');
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      L.d('[NfeSyncMixin] Iniciando sincronização');
      await _syncService.syncNfe();
      _lastSync = DateTime.now();
      L.d('[NfeSyncMixin] Sync concluído em $_lastSync');
    } catch (e) {
      L.e('[NfeSyncMixin] Erro durante sync: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Força refresh ignorando cache
  Future<void> forcarRefresh() async {
    await _syncService.refreshNfe();
    notifyListeners();
  }

  /// Getter: está online?
  bool get isOnline => _isOnline;

  /// Getter: está sincronizando?
  bool get isSyncing => _isSyncing;

  /// Getter: última sincronização
  DateTime? get lastSync => _lastSync;

  /// Retorna mensagem offline amigável se aplicável
  String? get offlineMessage {
    if (!_isOnline) {
      return 'Modo offline - mostrando cache local';
    }
    return null;
  }

  /// Cleanup
  @override
  void dispose() {
    _syncService.dispose();
    _connectivityService.dispose();
    super.dispose();
  }
}
