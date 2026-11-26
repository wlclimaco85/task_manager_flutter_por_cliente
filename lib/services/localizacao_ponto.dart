import 'package:geolocator/geolocator.dart';

import '../utils/app_logger.dart';

/// Coordenada obtida do aparelho para a batida do ponto.
class CoordenadaPonto {
  const CoordenadaPonto(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// A localizacao nao pode ser obtida: a [mensagem] ja e' a orientacao para o usuario.
class LocalizacaoIndisponivelException implements Exception {
  const LocalizacaoIndisponivelException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

/// Localizacao obrigatoria para bater o ponto (Web, Windows e Mobile): sem GPS/localizacao ativa e permitida,
/// o ponto nao e registrado.
class LocalizacaoPonto {
  /// Substituivel em teste.
  static Future<CoordenadaPonto> Function() provedor = _obterDoAparelho;

  /// Limite total: no navegador, um pedido de permissao sem resposta deixaria "Registrando..." girando para sempre.
  static const Duration limite = Duration(seconds: 25);

  static Future<CoordenadaPonto> obter() => provedor().timeout(
        limite,
        onTimeout: () => throw const LocalizacaoIndisponivelException(
            'Não foi possível obter a sua localização a tempo. Permita o acesso à localização do navegador/aparelho e tente de novo.'),
      );

  static Future<CoordenadaPonto> _obterDoAparelho() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocalizacaoIndisponivelException(
            'A localização do aparelho está desligada. Ative o GPS/localização para bater o ponto.');
      }
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied || permissao == LocationPermission.deniedForever) {
        throw const LocalizacaoIndisponivelException(
            'Permissão de localização negada. Permita o acesso à localização nas configurações para bater o ponto.');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)),
      );
      return CoordenadaPonto(p.latitude, p.longitude);
    } on LocalizacaoIndisponivelException {
      rethrow;
    } catch (e) {
      AppLogger.i.warn('[Ponto] não foi possível obter a localização: $e');
      throw const LocalizacaoIndisponivelException(
          'Não foi possível obter a sua localização. Verifique se o GPS está ativo e tente de novo.');
    }
  }
}
