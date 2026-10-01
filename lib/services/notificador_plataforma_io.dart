// Implementacao para mobile/desktop (Android, iOS, macOS, Linux, Windows).
// NUNCA importado num build Web (selecionado via import condicional em
// notificador_plataforma.dart) -- por isso pode depender livremente do
// plugin nativo flutter_local_notifications.
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notificador_plataforma.dart';
import '../utils/app_logger.dart';

NotificadorPlataforma criarNotificadorPlataformaImpl() => _NotificadorLocalNativo();

class _NotificadorLocalNativo implements NotificadorPlataforma {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;
  int _proximoId = 0;

  static const _canalId = 'app_academia_alertas';
  static const _canalNome = 'Alertas AppAcademia';
  static const _canalDescricao =
      'Alertas e avisos do AppAcademia';

  @override
  Future<void> inicializar() async {
    if (_pronto) return;
    try {
      final settings = InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(),
        macOS: const DarwinInitializationSettings(),
        linux: const LinuxInitializationSettings(defaultActionName: 'Abrir'),
        windows: const WindowsInitializationSettings(
          appName: 'Abraço Contabilidade',
          appUserModelId: 'com.appacademia.taskmanagerflutter',
          // GUID fixo do app -- exigido pela API do Windows para
          // identificar o callback de ativacao da notificacao; nao precisa
          // corresponder a nada externo, so ser estavel entre execucoes.
          guid: '2f6e7c2a-9b8a-4a7e-8c5d-6a1b4e7d9f10',
        ),
      );
      await _plugin.initialize(settings);
      _pronto = true;
      await _pedirPermissaoRuntime();
    } catch (e) {
      L.w('[NotificadorLocal] falha ao inicializar plugin nativo: $e');
    }
  }

  Future<void> _pedirPermissaoRuntime() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (e) {
      L.w('[NotificadorLocal] falha ao pedir permissao runtime de notificacao: $e');
    }
  }

  @override
  Future<void> notificar({required String titulo, required String corpo}) async {
    if (!_pronto) {
      await inicializar();
    }
    if (!_pronto) return;
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          _canalId,
          _canalNome,
          channelDescription: _canalDescricao,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
        macOS: const DarwinNotificationDetails(),
        linux: const LinuxNotificationDetails(),
      );
      await _plugin.show(_proximoId++, titulo, corpo, details);
    } catch (e) {
      L.w('[NotificadorLocal] falha ao exibir notificacao nativa: $e');
    }
  }

  @override
  Future<String> statusPermissao() async {
    if (!_pronto) return 'default';
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final habilitado = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled();
        return habilitado == true ? 'granted' : 'denied';
      }
    } catch (e) {
      L.w('[NotificadorLocal] falha ao consultar status de permissao: $e');
    }
    // iOS/macOS/Windows/Linux: plugin nao expoe consulta de status
    // confiavel -- se inicializou sem erro, trata como concedido.
    return 'granted';
  }

  @override
  Future<String> solicitarPermissao() async {
    await inicializar();
    return statusPermissao();
  }
}
