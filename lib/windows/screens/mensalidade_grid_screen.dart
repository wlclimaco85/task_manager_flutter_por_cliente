import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;
import 'conta_receber_grid_screen.dart';

/// Fix card #453: a tela "Mensalidades" apontava para o dominio errado
/// (mensalidade de aluno/plano de academia, V003 Fitness), sem nenhuma
/// relacao com empresa cliente do escritorio de contabilidade. Substituida
/// por uma view filtrada de Contas a Receber (categoria financeira
/// "Receita de Assinatura", id=293, ja cadastrada), reaproveitando toda a
/// infraestrutura existente (listagem, dar baixa, anexos).
class WindowsMensalidadeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsMensalidadeGridScreen({super.key, required this.hasPermission});

  static const int categoriaFinanceiraMensalidade = 293;

  @override
  Widget build(BuildContext context) {
    return WindowsContaReceberGridScreen(
      hasPermission: hasPermission,
      categoriaFinanceiraIdFixa: categoriaFinanceiraMensalidade,
      // Fix card #470: rótulo "Conta Receber" era exibido mesmo dentro da
      // tela Mensalidades (mesmo widget reaproveitado, filtrado por
      // categoria) -- confuso para o usuário, que via "Conta Receber" no
      // cabeçalho ao entrar pelo menu Mensalidades.
      tituloOverride: 'Mensalidades',
    );
  }
}
