import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/app_logger.dart';

/// Tela de execução de treino em tempo real.
///
/// Recebe [treinoId] e [alunoId] no construtor, inicia uma sessão via
/// POST /api/sessoes-treino e exibe cronômetro progressivo.
/// O aluno pode registrar séries e ao concluir avalia com 1–5 estrelas.
class SessaoTreinoScreen extends StatefulWidget {
  final int treinoId;
  final int alunoId;

  const SessaoTreinoScreen({
    super.key,
    required this.treinoId,
    required this.alunoId,
  });

  @override
  State<SessaoTreinoScreen> createState() => _SessaoTreinoScreenState();
}

class _SessaoTreinoScreenState extends State<SessaoTreinoScreen> {
  // ── Estado da sessão ────────────────────────────────────────────────────────
  int? _sessaoId;
  bool _iniciando = true;
  String? _erroInicio;

  // ── Cronômetro ──────────────────────────────────────────────────────────────
  int _segundos = 0;
  Timer? _cronometro;

  // ── Formulário de série ─────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _ctrlExercicioNome = TextEditingController();
  final _ctrlCarga = TextEditingController();
  final _ctrlRepeticoes = TextEditingController();
  bool _adicionandoSerie = false;

  // ── Lista de séries registradas (exibição local) ────────────────────────────
  final List<Map<String, dynamic>> _seriesRegistradas = [];

  // ── Feedback ────────────────────────────────────────────────────────────────
  int _notaFeedback = 0;
  final _ctrlFeedbackTexto = TextEditingController();
  bool _finalizando = false;

  @override
  void initState() {
    super.initState();
    _iniciarSessao();
  }

  @override
  void dispose() {
    _cronometro?.cancel();
    _ctrlExercicioNome.dispose();
    _ctrlCarga.dispose();
    _ctrlRepeticoes.dispose();
    _ctrlFeedbackTexto.dispose();
    super.dispose();
  }

  // ── Inicia sessão no backend ─────────────────────────────────────────────────
  Future<void> _iniciarSessao() async {
    try {
      final empresaId = TenantContext.empresaId ?? 0;
      final body = {
        'treinoId': widget.treinoId,
        'alunoId': widget.alunoId,
        'empresaId': empresaId,
      };
      final resposta = await TenantContext.post(
        '${ApiLinks.baseUrl}/api/sessoes-treino',
        body,
      );

      if (!mounted) return;

      if (resposta.statusCode == 200 || resposta.statusCode == 201) {
        final dados = jsonDecode(resposta.body);
        final id = dados['id'] as int?;
        if (id == null) {
          setState(() {
            _erroInicio = 'Backend não retornou o id da sessão.';
            _iniciando = false;
          });
          return;
        }
        setState(() {
          _sessaoId = id;
          _iniciando = false;
        });
        _iniciarCronometro();
      } else {
        setState(() {
          _erroInicio =
              'Erro ao iniciar sessão (HTTP ${resposta.statusCode}).';
          _iniciando = false;
        });
      }
    } catch (e) {
      L.d('Erro ao iniciar sessão de treino: $e');
      if (!mounted) return;
      setState(() {
        _erroInicio = 'Falha de conexão: $e';
        _iniciando = false;
      });
    }
  }

  // ── Cronômetro progressivo ───────────────────────────────────────────────────
  void _iniciarCronometro() {
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _segundos++);
    });
  }

  void _pararCronometro() {
    _cronometro?.cancel();
    _cronometro = null;
  }

  // ── Formata MM:SS ou HH:MM:SS ───────────────────────────────────────────────
  String _formatarTempo(int totalSegundos) {
    final horas = totalSegundos ~/ 3600;
    final minutos = (totalSegundos % 3600) ~/ 60;
    final segs = totalSegundos % 60;
    final mm = minutos.toString().padLeft(2, '0');
    final ss = segs.toString().padLeft(2, '0');
    if (horas > 0) {
      final hh = horas.toString().padLeft(2, '0');
      return '$hh:$mm:$ss';
    }
    return '$mm:$ss';
  }

  // ── Adiciona série no backend ────────────────────────────────────────────────
  Future<void> _adicionarSerie() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_sessaoId == null) return;

    setState(() => _adicionandoSerie = true);
    try {
      final body = {
        'exercicioNome': _ctrlExercicioNome.text.trim(),
        'carga': double.tryParse(_ctrlCarga.text) ?? 0.0,
        'repeticoes': int.tryParse(_ctrlRepeticoes.text) ?? 0,
      };
      final resposta = await TenantContext.post(
        '${ApiLinks.baseUrl}/api/sessoes-treino/$_sessaoId/series',
        body,
      );

      if (!mounted) return;

      if (resposta.statusCode == 200 || resposta.statusCode == 201) {
        setState(() {
          _seriesRegistradas.add({
            'exercicioNome': _ctrlExercicioNome.text.trim(),
            'carga': _ctrlCarga.text,
            'repeticoes': _ctrlRepeticoes.text,
          });
          _ctrlExercicioNome.clear();
          _ctrlCarga.clear();
          _ctrlRepeticoes.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Série adicionada!'),
              backgroundColor: GridColors.success,
            ),
          );
        }
      } else {
        _mostrarErro('Erro ao salvar série (HTTP ${resposta.statusCode}).');
      }
    } catch (e) {
      L.d('Erro ao adicionar série: $e');
      if (mounted) _mostrarErro('Falha de conexão: $e');
    } finally {
      if (mounted) setState(() => _adicionandoSerie = false);
    }
  }

  // ── Abre dialog de feedback e finaliza sessão ────────────────────────────────
  Future<void> _concluirTreino() async {
    _pararCronometro();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _buildDialogFeedback(),
    );
  }

  // ── Finaliza sessão no backend ───────────────────────────────────────────────
  Future<void> _finalizarSessao() async {
    if (_sessaoId == null) return;
    setState(() => _finalizando = true);
    try {
      final body = {
        'duracaoSegundos': _segundos,
        'feedbackNota': _notaFeedback,
        'feedbackTexto': _ctrlFeedbackTexto.text.trim(),
      };
      final resposta = await TenantContext.put(
        '${ApiLinks.baseUrl}/api/sessoes-treino/$_sessaoId/finalizar',
        body,
      );

      if (!mounted) return;

      Navigator.of(context).pop(); // fecha o dialog
      if (resposta.statusCode == 200 || resposta.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Treino concluído com sucesso!'),
            backgroundColor: GridColors.success,
          ),
        );
        Navigator.of(context).pop(); // volta para a tela anterior
      } else {
        _mostrarErro(
            'Erro ao finalizar sessão (HTTP ${resposta.statusCode}).');
      }
    } catch (e) {
      L.d('Erro ao finalizar sessão: $e');
      if (mounted) {
        Navigator.of(context).pop();
        _mostrarErro('Falha de conexão: $e');
      }
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: GridColors.error,
      ),
    );
  }

  // ── Dialog de feedback ───────────────────────────────────────────────────────
  Widget _buildDialogFeedback() {
    return StatefulBuilder(
      builder: (ctx, setStateDialog) {
        return AlertDialog(
          backgroundColor: GridColors.dialogBackground,
          title: const Text(
            'Como foi o treino?',
            style: TextStyle(
              color: GridColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Avaliação',
                style: TextStyle(color: GridColors.textSecondary),
              ),
              const SizedBox(height: 8),
              // Estrelas 1–5
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final estrelaIndex = i + 1;
                  return IconButton(
                    icon: Icon(
                      estrelaIndex <= _notaFeedback
                          ? Icons.star
                          : Icons.star_border,
                      color: GridColors.warning,
                      size: 32,
                    ),
                    onPressed: () {
                      setStateDialog(
                          () => _notaFeedback = estrelaIndex);
                      setState(() {});
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrlFeedbackTexto,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Comentário (opcional)',
                  labelStyle:
                      const TextStyle(color: GridColors.textMuted),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: GridColors.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: GridColors.primary, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _finalizando ? null : () => Navigator.of(ctx).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: GridColors.textMuted),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.secondary,
                foregroundColor: GridColors.textPrimary,
              ),
              onPressed: _finalizando ? null : _finalizarSessao,
              child: _finalizando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GridColors.textPrimary),
                    )
                  : const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  // ── Build principal ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_iniciando) {
      return Scaffold(
        backgroundColor: GridColors.background,
        appBar: AppBar(
          title: const Text('Execução de Treino'),
          backgroundColor: GridColors.primary,
          foregroundColor: GridColors.textPrimary,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_erroInicio != null) {
      return Scaffold(
        backgroundColor: GridColors.background,
        appBar: AppBar(
          title: const Text('Execução de Treino'),
          backgroundColor: GridColors.primary,
          foregroundColor: GridColors.textPrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: GridColors.error, size: 48),
              const SizedBox(height: 12),
              Text(
                _erroInicio!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: GridColors.error),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text('Execução de Treino'),
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: 'Concluir treino',
            onPressed: _concluirTreino,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCronometro(),
            const SizedBox(height: 20),
            _buildFormularioSerie(),
            const SizedBox(height: 20),
            if (_seriesRegistradas.isNotEmpty) _buildListaSeries(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GridColors.secondary,
                foregroundColor: GridColors.textPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.flag_outlined),
              label: const Text(
                'Concluir Treino',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              onPressed: _concluirTreino,
            ),
          ],
        ),
      ),
    );
  }

  // ── Widget do cronômetro ─────────────────────────────────────────────────────
  Widget _buildCronometro() {
    return Card(
      color: GridColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'Tempo de Treino',
              style: TextStyle(
                color: GridColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatarTempo(_segundos),
              style: const TextStyle(
                color: GridColors.secondary,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Formulário para registrar série ─────────────────────────────────────────
  Widget _buildFormularioSerie() {
    return Card(
      color: GridColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Registrar Série',
                style: TextStyle(
                  color: GridColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ctrlExercicioNome,
                decoration: _inputDecoration('Exercício'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o exercício' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ctrlCarga,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration: _inputDecoration('Carga (kg)'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe a carga' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _ctrlRepeticoes,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration('Repetições'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe as reps' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: GridColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: _adicionandoSerie
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: GridColors.textPrimary),
                      )
                    : const Icon(Icons.add),
                label: const Text('Adicionar Série'),
                onPressed: _adicionandoSerie ? null : _adicionarSerie,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Lista de séries já registradas ──────────────────────────────────────────
  Widget _buildListaSeries() {
    return Card(
      color: GridColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Séries Registradas (${_seriesRegistradas.length})',
              style: const TextStyle(
                color: GridColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ..._seriesRegistradas.asMap().entries.map((entry) {
              final i = entry.key;
              final serie = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: GridColors.secondarySoft,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: GridColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        serie['exercicioNome'] as String,
                        style: const TextStyle(
                            color: GridColors.textSecondary,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${serie['carga']} kg  ×  ${serie['repeticoes']} reps',
                      style: const TextStyle(color: GridColors.textMuted),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── Helper de InputDecoration ────────────────────────────────────────────────
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: GridColors.textMuted),
      filled: true,
      fillColor: GridColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GridColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GridColors.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GridColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: GridColors.error),
      ),
    );
  }
}
