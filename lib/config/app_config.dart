/// Configuração de ambiente do app.
class AppConfig {
  AppConfig._();

  static const String brokerLogin = String.fromEnvironment(
    'BROKER_LOGIN',
    defaultValue: '',
  );

  static const String brokerPassword = String.fromEnvironment(
    'BROKER_PASSWORD',
    defaultValue: '',
  );

  static bool get hasBrokerLogin => brokerLogin.trim().isNotEmpty;
  static bool get hasBrokerPassword => brokerPassword.trim().isNotEmpty;
}
