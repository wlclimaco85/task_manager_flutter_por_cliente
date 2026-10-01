import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';

/// Widget de loading moderno e de alto impacto visual ("Sping Massa / UX Pro")
/// Projetado para transições de login, carregamento de módulos e inicialização do sistema.
class AppLoadingOverlay extends StatefulWidget {
  final String title;
  final String message;
  final bool isFullScreen;

  const AppLoadingOverlay({
    super.key,
    this.title = 'Iniciando Sessão',
    this.message = 'Carregando ambiente...',
    this.isFullScreen = false,
  });

  @override
  State<AppLoadingOverlay> createState() => _AppLoadingOverlayState();
}

class _AppLoadingOverlayState extends State<AppLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 36,
              spreadRadius: 4,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: GridColors.primary.withValues(alpha: 0.25),
              blurRadius: 40,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinner duplo customizado em Canvas com logo/ícone central
            SizedBox(
              width: 90,
              height: 90,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _DualRingSpinnerPainter(
                      progress: _controller.value,
                      primaryColor: GridColors.primary,
                      secondaryColor: GridColors.secondary,
                      accentColor: const Color(0xFFE53935),
                    ),
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_open_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Título
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 8),
            // Mensagem dinâmica de status
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                widget.message,
                key: ValueKey(widget.message),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Barra de progresso linear fina e elegante
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: SizedBox(
                height: 4,
                width: 200,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    GridColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (widget.isFullScreen) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.2,
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF0A0F1D),
                    ],
                  ),
                ),
              ),
            ),
            content,
          ],
        ),
      );
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: content,
    );
  }
}

/// Custom painter de alta performance para desenhar anéis concêntricos de gradiente
class _DualRingSpinnerPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;

  _DualRingSpinnerPainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 4;
    final innerRadius = size.width / 2 - 14;

    // Anel externo (gira no sentido horário)
    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          primaryColor.withValues(alpha: 0.0),
          primaryColor,
          accentColor,
          primaryColor,
        ],
        stops: const [0.0, 0.4, 0.8, 1.0],
        transform: GradientRotation(progress * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: outerRadius),
      progress * 2 * math.pi,
      1.5 * math.pi,
      false,
      outerPaint,
    );

    // Anel interno (gira no sentido anti-horário com velocidade diferente)
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          secondaryColor.withValues(alpha: 0.0),
          secondaryColor,
          Colors.white.withValues(alpha: 0.8),
          secondaryColor,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
        transform: GradientRotation(-progress * 2.5 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: innerRadius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: innerRadius),
      -progress * 2.5 * math.pi,
      1.2 * math.pi,
      false,
      innerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DualRingSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
