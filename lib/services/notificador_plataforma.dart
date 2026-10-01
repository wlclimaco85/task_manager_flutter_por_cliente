import 'notificador_plataforma_io.dart'
    if (dart.library.html) 'notificador_plataforma_web.dart' as impl;

/// Contrato para disparar uma notificacao nativa da PLATAFORMA (toast do
/// SO no Windows/desktop/mobile, ou a Notification API do navegador na
/// Web) -- diferente do Alert in-app (NotificacoesDrawer) e do push mobile
/// via FCM (PushNotificationService), que ja existiam e continuam intactos.
///
/// A implementacao concreta e escolhida em TEMPO DE COMPILACAO via import
/// condicional (`if (dart.library.html)`): um build Web nunca inclui o
/// plugin nativo flutter_local_notifications, e um build mobile/desktop
/// nunca inclui dart:html.
abstract class NotificadorPlataforma {
  /// Prepara a plataforma (inicializa o plugin nativo ou pede permissao de
  /// notificacao do navegador). Deve ser chamado uma vez, apos login.
  /// Falhas sao engolidas e logadas -- nunca podem derrubar o boot do app.
  Future<void> inicializar();

  /// Exibe uma notificacao. Se [inicializar] falhou ou ainda nao rodou,
  /// e um no-op silencioso.
  Future<void> notificar({required String titulo, required String corpo});

  /// Estado atual da permissao: 'granted', 'denied', 'default' (ainda nao
  /// perguntado) ou 'unsupported' (plataforma sem suporte). Usado pela UI
  /// pra mostrar um botao de reativar quando a notificacao nunca aparece --
  /// sem isso o usuario nao tem como saber que o navegador bloqueou o
  /// pedido silenciosamente (ex.: prompt automatico no boot/login sem gesto
  /// direto do usuario e ignorado por politica do Chrome).
  Future<String> statusPermissao();

  /// Pede a permissao de novo, chamado DIRETAMENTE de um clique do usuario
  /// (nunca do boot/login automatico) -- e o unico jeito confiavel do
  /// navegador mostrar o popup nativo. Se ja estiver 'denied', o navegador
  /// nao reexibe o popup (limitacao da propria Notification API); a UI deve
  /// orientar o usuario a liberar manualmente nas configuracoes do site.
  Future<String> solicitarPermissao();
}

NotificadorPlataforma criarNotificadorPlataforma() =>
    impl.criarNotificadorPlataformaImpl();
