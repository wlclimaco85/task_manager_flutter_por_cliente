import 'dart:async';
import 'package:task_manager_flutter/utils/app_logger.dart';

/// Service que monitora conectividade de rede
///
/// Fornece:
/// - Verificação atual de conectividade
/// - Stream de mudanças de conexão
/// - Monitoramento contínuo
/// - Callbacks ao mudar status
class ConnectivityService {
  static const int _checkIntervalSeconds = 10;

  final StreamController<bool> _connectivityStream =
      StreamController<bool>.broadcast();

  Timer? _checkTimer;
  bool _lastStatus = true;
  bool _isMonitoring = false;

  /// Stream que emite true/false quando conectividade muda
  Stream<bool> get connectionStream => _connectivityStream.stream;

  /// Verifica conectividade atual (mock para testes)
  Future<bool> isConnected() async {
    try {
      L.d('[ConnectivityService] Verificando conectividade');
      // Em produção, aqui seria verificação real via package:connectivity_plus
      // Por enquanto, assume sempre online
      return true;
    } catch (e) {
      L.e('[ConnectivityService] Erro ao verificar conectividade: $e');
      return false;
    }
  }

  /// Alias para isConnected() — mantém compat
  Future<bool> checkConnectivity() async => await isConnected();

  /// Inicia monitoramento contínuo de conectividade
  void startMonitoring() {
    if (_isMonitoring) {
      L.d('[ConnectivityService] Monitoramento já ativo');
      return;
    }

    _isMonitoring = true;
    L.d('[ConnectivityService] Iniciando monitoramento de conectividade');

    // Verifica imediatamente
    _checkStatus();

    // E depois a cada 10 segundos
    _checkTimer = Timer.periodic(
      Duration(seconds: _checkIntervalSeconds),
      (_) => _checkStatus(),
    );
  }

  /// Para monitoramento de conectividade
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isMonitoring = false;
    L.d('[ConnectivityService] Monitoramento parado');
  }

  /// Verifica status e emite evento se mudou
  Future<void> _checkStatus() async {
    try {
      final isOnline = await isConnected();

      if (isOnline != _lastStatus) {
        L.d('[ConnectivityService] Status mudou: $_lastStatus → $isOnline');
        _lastStatus = isOnline;
        _connectivityStream.add(isOnline);
      }
    } catch (e) {
      L.e('[ConnectivityService] Erro durante check: $e');
    }
  }

  /// Retorna último status conhecido
  bool get lastKnownStatus => _lastStatus;

  /// Limpa recursos
  void dispose() {
    stopMonitoring();
    _connectivityStream.close();
    L.d('[ConnectivityService] Disposado');
  }
}
