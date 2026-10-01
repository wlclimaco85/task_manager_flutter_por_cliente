// Implementacao para Web -- usa a Notification API nativa do navegador.
// NUNCA importado num build mobile/desktop (selecionado via import
// condicional em notificador_plataforma.dart) -- por isso pode depender
// livremente de dart:html, indisponivel fora do Web. O lint
// avoid_web_libraries_in_flutter existe para evitar dart:html vazando pra
// um build nao-web; aqui isso e garantido pelo import condicional, entao a
// suprimir e intencional.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'notificador_plataforma.dart';
import '../utils/app_logger.dart';

NotificadorPlataforma criarNotificadorPlataformaImpl() => _NotificadorWeb();

class _NotificadorWeb implements NotificadorPlataforma {
  bool _permitido = false;

  @override
  Future<void> inicializar() async {
    try {
      if (!html.Notification.supported) {
        L.w('[NotificadorLocal] navegador nao suporta Notification API.');
        return;
      }
      // 'granted' pode ja vir concedido de uma sessao anterior; so pede de
      // novo (mostra o popup do navegador) quando ainda nao foi decidido.
      String? permissao = html.Notification.permission;
      if (permissao == null || permissao == 'default') {
        permissao = await html.Notification.requestPermission();
      }
      _permitido = permissao == 'granted';
    } catch (e) {
      L.w('[NotificadorLocal] falha ao pedir permissao de notificacao do navegador: $e');
    }
  }

  @override
  Future<void> notificar({required String titulo, required String corpo}) async {
    if (!_permitido) return;
    try {
      html.Notification(titulo, body: corpo);
    } catch (e) {
      L.w('[NotificadorLocal] falha ao exibir notificacao do navegador: $e');
    }
  }

  @override
  Future<String> statusPermissao() async {
    if (!html.Notification.supported) return 'unsupported';
    return html.Notification.permission ?? 'default';
  }

  @override
  Future<String> solicitarPermissao() async {
    if (!html.Notification.supported) return 'unsupported';
    try {
      final permissao = await html.Notification.requestPermission();
      _permitido = permissao == 'granted';
      return permissao;
    } catch (e) {
      L.w('[NotificadorLocal] falha ao solicitar permissao de notificacao: $e');
      return html.Notification.permission ?? 'default';
    }
  }
}
