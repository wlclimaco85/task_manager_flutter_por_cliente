import 'package:flutter/material.dart';
import '../auth_screens/login_screen.dart';
import '../models/auth_utility.dart';
import '../utils/app_logger.dart';

/// Trata expiração/invalidação real de sessão (401) fazendo logout global.
///
/// 403 (Forbidden) NÃO desloga: significa "sem permissão para este recurso
/// especifico", nao "sessao invalida". Endpoints ainda nao implementados no
/// backend tambem retornam 403 (nao 404, por design de seguranca), entao
/// qualquer tela incompleta acabava derrubando a sessao inteira do usuario
/// -- bug encontrado ao testar a tela de NFSe.
class SessionExpiredHandler {
  SessionExpiredHandler._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> handle() async {
    await AuthUtility.clearUserInfo();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  static void resetForbiddenCount() {
    // Mantido por compatibilidade com chamadores existentes.
  }

  static void handleForbidden() {
    L.w('[SessionExpiredHandler] 403 recebido — acesso negado ao recurso, sessao mantida');
  }
}
