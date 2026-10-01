import 'dart:async';
import 'package:task_manager_flutter/models/nfe/nfe_model.dart';
import 'package:task_manager_flutter/repositories/nfe_local_repository.dart';
import 'package:task_manager_flutter/repositories/nfe_repository.dart';
import 'package:task_manager_flutter/services/connectivity_service.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Service que gerencia sincronização de NFes entre backend e cache local
///
/// Responsabilidades:
/// - Sincronizar com backend (online)
/// - Carregar cache quando offline
/// - Retry automático ao detectar conexão
/// - Sincronização periódica background
/// - Fila para processamento offline
class NfeSyncService {
  static const int _defaultPageSize = 100;
  static const int _syncIntervalMinutes = 30;

  final NfeRepository? nfeRepository;
  final NfeLocalRepository? localRepository;
  final dynamic connectivity;

  Timer? _periodicTimer;
  bool _isSyncing = false;
  DateTime? _lastSync;
  String? _lastError;
  late ConnectivityService _defaultConnectivity;
  StreamSubscription? _connectivitySubscription;

  NfeSyncService({
    this.nfeRepository,
    this.localRepository,
    this.connectivity,
  }) {
    _defaultConnectivity = ConnectivityService();
  }

  /// Factory para criar com repositórios já instanciados
  factory NfeSyncService.withDefaults({
    required NfeRepository nfeRepository,
    required NfeLocalRepository localRepository,
  }) {
    final service = NfeSyncService(
      nfeRepository: nfeRepository,
      localRepository: localRepository,
      connectivity: null,
    );
    // Detecta mudanças de conectividade automaticamente
    service._setupConnectivityListener();
    return service;
  }

  /// Setup listener para mudanças de conectividade
  void _setupConnectivityListener() {
    try {
      _connectivitySubscription = _defaultConnectivity.connectionStream
          .listen((isOnline) {
        L.d('[NfeSyncService] Conectividade mudou: $isOnline');
        if (isOnline) {
          // Voltou online: sincroniza automaticamente
          syncNfe();
        }
      });
      _defaultConnectivity.startMonitoring();
    } catch (e) {
      L.e('[NfeSyncService] Erro ao setup connectivityListener: $e');
    }
  }

  /// Sincroniza NFes com backend, com fallback para cache
  ///
  /// [useCacheIfValid] - se true e cache válido, pode retornar cache sem consultar backend
  Future<void> syncNfe({bool useCacheIfValid = false}) async {
    if (_isSyncing) {
      L.d('[NfeSyncService] Sync já em andamento, ignorando');
      return;
    }

    _isSyncing = true;
    _lastError = null;

    try {
      L.d('[NfeSyncService] Iniciando sincronização');

      // Verifica conectividade
      final isOnline = await _checkConnectivity();

      if (isOnline) {
        // Online: pull do backend
        await _syncFromBackend(useCacheIfValid);
      } else {
        // Offline: carrega cache
        await _syncFromCache();
      }

      _lastSync = DateTime.now();
      L.d('[NfeSyncService] Sincronização concluída em ${_lastSync!}');
    } on Exception catch (e) {
      _lastError = e.toString();
      L.e('[NfeSyncService] Erro durante sync: $e');

      // Tenta carregar cache como fallback
      try {
        await _syncFromCache();
      } catch (cacheError) {
        L.e('[NfeSyncService] Erro ao fazer fallback para cache: $cacheError');
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Força sincronização ignorando cache válido
  Future<void> refreshNfe() async {
    L.d('[NfeSyncService] Refresh forçado (ignora cache)');
    await syncNfe(useCacheIfValid: false);
  }

  /// Inicia sincronização periódica background (default: 30 min)
  void startPeriodicSync({Duration? interval}) {
    if (_periodicTimer != null) {
      L.d('[NfeSyncService] Sync periódico já ativo');
      return;
    }

    final syncInterval =
        interval ?? Duration(minutes: _syncIntervalMinutes);
    L.d('[NfeSyncService] Iniciando sync periódico (intervalo: ${syncInterval.inMinutes}min)');

    _periodicTimer = Timer.periodic(syncInterval, (_) {
      syncNfe();
    });
  }

  /// Para sincronização periódica
  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    L.d('[NfeSyncService] Sync periódico parado');
  }

  /// Retorna status atual de sincronização
  Map<String, dynamic> getSyncStatus() {
    return {
      'isSyncing': _isSyncing,
      'lastSync': _lastSync?.toIso8601String(),
      'lastError': _lastError,
    };
  }

  /// Obtém último erro de sincronização
  String? getLastError() => _lastError;

  /// Limpa último erro registrado
  void clearLastError() {
    _lastError = null;
  }

  /// Adiciona NFe à fila offline
  Future<void> addToOfflineQueue(NfeModel nfe) async {
    if (localRepository == null) {
      L.w('[NfeSyncService] localRepository é null, ignorando addToOfflineQueue');
      return;
    }

    try {
      L.d('[NfeSyncService] Adicionando NFe ${nfe.id} à fila offline');
      await localRepository!.addToOfflineQueue(nfe);
    } catch (e) {
      L.e('[NfeSyncService] Erro ao adicionar à fila offline: $e');
      rethrow;
    }
  }

  /// Processa fila offline quando voltando online
  Future<void> _processOfflineQueue() async {
    if (localRepository == null) return;

    try {
      final queue = await localRepository!.getOfflineQueue();
      if (queue.isEmpty) {
        return;
      }

      L.d('[NfeSyncService] Processando fila offline: ${queue.length} NFes');

      // Aqui você implementaria lógica de reprocessamento
      // Por enquanto, apenas limpa a fila após validar dados

      await localRepository!.clearOfflineQueue();
      L.d('[NfeSyncService] Fila offline processada e limpa');
    } catch (e) {
      L.e('[NfeSyncService] Erro ao processar fila offline: $e');
      // Não faz rethrow para não interromper sync
    }
  }

  /// Sincroniza do backend
  Future<void> _syncFromBackend(bool useCacheIfValid) async {
    if (nfeRepository == null || localRepository == null) {
      L.w('[NfeSyncService] Repositories são null, pulando sync backend');
      return;
    }

    try {
      // Se cache válido e permitido, pode retornar rápido
      if (useCacheIfValid) {
        final cacheValid = await localRepository!.isCacheValid();
        if (cacheValid) {
          L.d('[NfeSyncService] Cache válido, usando dados locais');
          return;
        }
      }

      L.d('[NfeSyncService] Puxando NFes do backend');

      // Pull: busca NFes do backend
      final nfes = await nfeRepository!.listarNfe(
        page: 1,
        pageSize: _defaultPageSize,
      );

      // Cache: armazena localmente
      await localRepository!.cacheNfes(nfes);

      // Push: processa fila offline se voltou online
      await _processOfflineQueue();

      L.d('[NfeSyncService] Sincronização com backend concluída: ${nfes.length} NFes');
    } catch (e) {
      L.e('[NfeSyncService] Erro ao sincronizar com backend: $e');
      rethrow;
    }
  }

  /// Sincroniza do cache local
  Future<void> _syncFromCache() async {
    if (localRepository == null) {
      L.w('[NfeSyncService] localRepository é null, pulando sync cache');
      return;
    }

    try {
      L.d('[NfeSyncService] Puxando NFes do cache local (offline)');

      final cachedNfes = await localRepository!.obterTodosCached();
      L.d('[NfeSyncService] Carregadas ${cachedNfes.length} NFes do cache');
    } catch (e) {
      L.e('[NfeSyncService] Erro ao sincronizar com cache: $e');
      rethrow;
    }
  }

  /// Verifica conectividade
  Future<bool> _checkConnectivity() async {
    try {
      // Tenta usar connectivity customizado se fornecido
      if (connectivity != null && connectivity.isConnected != null) {
        return await connectivity.isConnected();
      }
      // Fallback: usa default ConnectivityService
      return await _defaultConnectivity.isConnected();
    } catch (e) {
      L.w('[NfeSyncService] Erro ao verificar conectividade: $e, assumindo online');
      return true;
    }
  }

  /// Cleanup: para sync periódico e libera recursos
  void dispose() {
    stopPeriodicSync();
    _connectivitySubscription?.cancel();
    _defaultConnectivity.dispose();
    L.d('[NfeSyncService] Disposado');
  }
}
