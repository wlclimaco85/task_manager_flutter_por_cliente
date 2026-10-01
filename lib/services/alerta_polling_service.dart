import 'dart:async';
import 'dart:convert';

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/tenant_context.dart';
import 'alerta_novo_detector.dart';
import 'notificador_plataforma.dart';

/// Poll periodico de `/api/notificacoes` que dispara uma notificacao NATIVA
/// da plataforma (toast do Windows/desktop/mobile, ou popup da Notification
/// API no navegador) para cada alerta GENUINAMENTE NOVO desde o inicio do
/// polling -- mesmo com o app em segundo plano/aba sem foco.
///
/// Pedido explicito do usuario: avisar a empresa que esta sendo solicitado
/// o acesso via "browser notificações windows app windows tmb e no app no
/// push de mensagens do aparelho". O push mobile real ja existia via FCM
/// (PushNotificationService) e o Alert in-app ja existia via
/// NotificacoesDrawer -- este servico cobre o que faltava: toast nativo
/// desktop/mobile e popup nativo do navegador.
class AlertaPollingService {
  AlertaPollingService._({
    AlertaNovoDetector detector = const AlertaNovoDetector(),
    NotificadorPlataforma? notificador,
    Future<List<Map<String, dynamic>>?> Function()? buscarNotificacoes,
    Duration intervalo = const Duration(seconds: 20),
  })  : _detector = detector,
        _notificador = notificador,
        _buscarNotificacoesParaTeste = buscarNotificacoes,
        _intervalo = intervalo;

  AlertaPollingService.paraTeste({
    AlertaNovoDetector detector = const AlertaNovoDetector(),
    required NotificadorPlataforma notificador,
    required Future<List<Map<String, dynamic>>?> Function() buscarNotificacoes,
  }) : this._(
          detector: detector,
          notificador: notificador,
          buscarNotificacoes: buscarNotificacoes,
          intervalo: const Duration(days: 1),
        );

  static final AlertaPollingService instance = AlertaPollingService._();

  final Duration _intervalo;
  final AlertaNovoDetector _detector;
  final Future<List<Map<String, dynamic>>?> Function()?
      _buscarNotificacoesParaTeste;
  NotificadorPlataforma? _notificador;

  Timer? _timer;
  // null = ainda nao fez a leitura de baseline (evita notificar alertas que
  // ja existiam antes do polling comecar).
  Set<int>? _idsConhecidos;
  bool _executando = false;

  Future<void> iniciar() async {
    if (_timer != null) return; // ja iniciado (ex.: hot restart de sessao)
    _notificador ??= criarNotificadorPlataforma();
    await _notificador!.inicializar();
    _timer = Timer.periodic(_intervalo, (_) => _executarCiclo());
    await _executarCiclo();
  }

  /// Dispara imediatamente uma notificacao nativa avulsa (ex: recebimento de chat em tempo real)
  Future<void> notificarInstantaneo({
    required String titulo,
    required String corpo,
  }) async {
    _notificador ??= criarNotificadorPlataforma();
    await _notificador!.notificar(titulo: titulo, corpo: corpo);
  }

  /// Status atual da permissao ('granted'/'denied'/'default'/'unsupported').
  /// Usado pela UI pra decidir se mostra o botao de reativar notificacoes.
  Future<String> statusPermissaoNotificacao() async {
    _notificador ??= criarNotificadorPlataforma();
    return _notificador!.statusPermissao();
  }

  /// Pede a permissao de novo -- so deve ser chamado a partir de um clique
  /// direto do usuario (ex.: botao "Ativar notificações"), nunca do boot ou
  /// login automatico. Ver `NotificadorPlataforma.solicitarPermissao`.
  Future<String> solicitarPermissaoNotificacao() async {
    _notificador ??= criarNotificadorPlataforma();
    return _notificador!.solicitarPermissao();
  }

  /// Chamado no logout -- sem isso, o timer continuaria rodando e
  /// notificando com o TenantContext de uma sessao ja encerrada.
  void parar() {
    _timer?.cancel();
    _timer = null;
    _idsConhecidos = null;
  }

  Future<void> executarCicloParaTeste() => _executarCiclo();

  Future<void> _executarCiclo() async {
    if (_executando) return; // evita sobreposicao se um ciclo demorar
    _executando = true;
    try {
      final atuais = await _buscarNotificacoes();
      if (atuais == null) return; // falha de rede: mantem baseline anterior

      if (_idsConhecidos == null) {
        await _notificarPendenciasIniciais(atuais);
        _idsConhecidos = _detector.extrairIds(atuais);
        return;
      }

      final novos = _detector.detectarNovos(
        idsConhecidos: _idsConhecidos!,
        alertasAtuais: atuais,
      );
      await _notificarAlertas(novos);
      _idsConhecidos = _detector.extrairIds(atuais);
    } catch (e) {
      L.w('[AlertaPolling] falha no ciclo de polling: $e');
    } finally {
      _executando = false;
    }
  }

  Future<void> _notificarPendenciasIniciais(
      List<Map<String, dynamic>> alertas) async {
    if (alertas.isEmpty) return;
    if (alertas.length == 1) {
      await _notificarAlertas(alertas);
      return;
    }
    await _notificador?.notificar(
      titulo: 'Abraço Contabilidade',
      corpo: 'Você tem ${alertas.length} notificações pendentes.',
    );
  }

  Future<void> _notificarAlertas(List<Map<String, dynamic>> alertas) async {
    for (final alerta in alertas) {
      final tipo = alerta['tipo']?.toString();
      final texto = alerta['mensagem']?.toString() ??
          alerta['texto']?.toString() ??
          alerta['conteudo']?.toString() ??
          'Nova notificação recebida';
      String titulo = 'Abraço Contabilidade';
      if (tipo != null && tipo.isNotEmpty) {
        if (tipo == 'CHAMADO') {
          titulo = '🎫 Chamado';
        } else if (tipo == 'GED') {
          titulo = '📎 Documentos (GED)';
        } else if (tipo == 'COMUNICADO') {
          titulo = '📢 Comunicado';
        } else if (tipo == 'ALVARA') {
          titulo = '⚠️ Vencimento de Alvará';
        } else if (tipo == 'CP' || tipo == 'CR') {
          titulo = '💰 Financeiro';
        } else if (tipo == 'CHAT') {
          titulo = '💬 Chat / Atendimento';
        }
      }
      await _notificador?.notificar(
        titulo: titulo,
        corpo: texto,
      );
    }
  }

  Future<List<Map<String, dynamic>>?> _buscarNotificacoes() async {
    final buscarParaTeste = _buscarNotificacoesParaTeste;
    if (buscarParaTeste != null) return buscarParaTeste();

    try {
      final empresaId = TenantContext.empresaId;
      final param = empresaId != null ? '?empresaId=$empresaId' : '';
      final resp =
          await TenantContext.get('${ApiLinks.baseUrl}/api/notificacoes$param');
      if (resp.statusCode != 200) return null;

      final body = jsonDecode(resp.body);
      List raw = [];
      if (body is List) {
        raw = body;
      } else if (body is Map) {
        raw = body['data'] is List
            ? body['data']
            : body['dados'] ?? body['content'] ?? body['items'] ?? [];
      }
      return raw
          .whereType<Map>()
          .map((n) => Map<String, dynamic>.from(n))
          .toList();
    } catch (e) {
      L.w('[AlertaPolling] falha ao buscar /api/notificacoes: $e');
      return null;
    }
  }
}
