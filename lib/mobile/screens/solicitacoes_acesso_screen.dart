import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../widgets/solicitacao_acesso_aprovacao_screen.dart';

/// Tela mobile de Solicitações de Acesso — envelopa o componente funcional com AppBar e layout mobile nativo.
class MobileSolicitacoesAcessoScreen extends StatelessWidget {
  const MobileSolicitacoesAcessoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Solicitações de Acesso',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: GridColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: const SafeArea(
        child: const SolicitacaoAcessoAprovacaoScreen(),
      ),
    );
  }
}
