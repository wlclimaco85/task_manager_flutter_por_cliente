import 'dart:async';

import 'package:flutter/material.dart';
import '../../../utils/grid_colors.dart';

import '../../../models/nfce/nfce_resultado_model.dart';
import '../../../models/nfce/nfce_status_model.dart';
import '../../../services/nfce_provider.dart';
import '../../../services/nfce_service.dart';
import 'nfce_autorizada_screen.dart';
import 'nfce_contingencia_screen.dart';
import 'nfce_rejeicao_screen.dart';

/// Tela de aguardo enquanto a SEFAZ processa a NFC-e.
/// Faz polling a cada 2s no endpoint de status, com timeout de 60s.
class NfceFinalizacaoScreen extends StatefulWidget {
  final NfceProvider provider;

  const NfceFinalizacaoScreen({super.key, required this.provider});

  @override
  State<NfceFinalizacaoScreen> createState() => _NfceFinalizacaoScreenState();
}

class _NfceFinalizacaoScreenState extends State<NfceFinalizacaoScreen> {
  final NfceService _service = NfceService();
  Timer? _pollingTimer;
  Timer? _timeoutTimer;
  String _mensagem = 'Enviando NFC-e para a SEFAZ...';
  int _nfceId = -1;
  bool _iniciou = false;
  String? _ultimaMensagemStatus;

  static const _pollingInterval = Duration(seconds: 2);
  static const _timeout = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    _iniciarEmissao();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _iniciarEmissao() async {
    if (_iniciou) return;
    _iniciou = true;

    final resultado = await widget.provider.emitirNfce();

    if (!mounted) return;

    if (resultado == null) {
      // Erro ao emitir
      _navegarParaContingencia(motivo: widget.provider.erro ?? 'Erro ao emitir.');
      return;
    }

    _nfceId = resultado.id;

    if (resultado.isAutorizada) {
      _navegarParaAutorizada(resultado);
      return;
    }

    if (resultado.isRejeitada) {
      _navegarParaRejeicao(resultado);
      return;
    }

    if (resultado.isContingencia) {
      _navegarParaContingencia(
        motivo: resultado.motivoRejeicao ??
            'SEFAZ indisponível. NFC-e em contingência para regularização posterior.',
        persistirVendaAtual: false,
      );
      return;
    }

    // Pendente — iniciar polling
    setState(() => _mensagem = 'Aguardando autorização da SEFAZ...');
    _iniciarPolling();
    _iniciarTimeout();
  }

  void _iniciarPolling() {
    _pollingTimer =
        Timer.periodic(_pollingInterval, (_) => _consultarStatus());
  }

  void _iniciarTimeout() {
    _timeoutTimer = Timer(_timeout, () {
      if (!mounted) return;
      _pollingTimer?.cancel();
      _navegarParaContingencia(
        motivo: 'Timeout: SEFAZ não respondeu em 60s.',
      );
    });
  }

  Future<void> _consultarStatus() async {
    if (_nfceId < 0) return;
    try {
      final status = await _service.consultarStatus(_nfceId);
      if (!mounted) return;
      final mensagemStatus = status.xMotivo ??
          status.mensagem ??
          (status.codigoRetorno != null && status.codigoRetorno!.isNotEmpty
              ? 'SEFAZ retornou código ${status.codigoRetorno}.'
              : null);
      if (mensagemStatus != null && mensagemStatus != _ultimaMensagemStatus) {
        setState(() {
          _ultimaMensagemStatus = mensagemStatus;
          _mensagem = mensagemStatus;
        });
      }
      if (status.isAutorizada) {
        _pollingTimer?.cancel();
        _timeoutTimer?.cancel();
        // Buscar resultado completo
        final resultado = widget.provider.ultimaNfce;
        if (resultado != null) {
          _navegarParaAutorizada(resultado);
        }
      } else if (status.isRejeitada) {
        _pollingTimer?.cancel();
        _timeoutTimer?.cancel();
        _navegarParaRejeicaoStatus(status);
      } else if (status.isContingencia) {
        _pollingTimer?.cancel();
        _timeoutTimer?.cancel();
        _navegarParaContingencia(
          motivo: status.mensagem ?? status.motivoRejeicao ?? 'SEFAZ indisponível.',
          persistirVendaAtual: false,
        );
      }
    } catch (_) {
      // Continua tentando enquanto nao atingir timeout
    }
  }

  void _navegarParaAutorizada(NfceResultadoModel resultado) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NfceAutorizadaScreen(
          resultado: resultado,
          onNovaVenda: _voltarParaPdv,
        ),
      ),
    );
  }

  void _navegarParaRejeicao(NfceResultadoModel resultado) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NfceRejeicaoScreen(
          motivo: resultado.motivoRejeicao ?? resultado.xMotivo ?? 'Rejeição sem mensagem.',
          codigoRetorno: resultado.codigoRetorno,
          chaveAcesso: resultado.chaveAcessoFormatada,
          xMotivo: resultado.xMotivo,
          onTentarNovamente: _voltarParaPdv,
          onCancelar: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
    );
  }

  void _navegarParaRejeicaoStatus(NfceStatusModel status) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NfceRejeicaoScreen(
          motivo: status.motivoRejeicao ?? status.mensagem ?? status.xMotivo ?? 'Rejeição sem mensagem.',
          codigoRetorno: status.codigoRetorno,
          xMotivo: status.xMotivo,
          onTentarNovamente: _voltarParaPdv,
          onCancelar: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
    );
  }

  void _navegarParaContingencia({
    required String motivo,
    bool persistirVendaAtual = true,
  }) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => NfceContingenciaScreen(
          motivo: motivo,
          provider: widget.provider,
          onNovaVenda: _voltarParaPdv,
          persistirVendaAtual: persistirVendaAtual,
        ),
      ),
    );
  }

  void _voltarParaPdv() {
    widget.provider.limparCarrinho();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: GridColors.secondary,
                strokeWidth: 4,
              ),
              const SizedBox(height: 32),
              Text(
                _mensagem,
                style: const TextStyle(fontSize: 18, color: GridColors.secondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Não feche esta tela.\nAguardando resposta da SEFAZ...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
