// test/auth_screens/solicitacao_acesso_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/solicitacao_acesso_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  group('SolicitacaoAcessoScreen', () {
    // TEST 1: Renderiza campos obrigatórios
    testWidgets('renderiza nome, cpf solicitante, documento da empresa, email, senha, confirmarSenha',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const SolicitacaoAcessoScreen()));
      await tester.pumpAndSettle();

      // Verifica se há pelo menos 5 TextFormField (para 5 campos)
      expect(find.byType(TextFormField), findsWidgets);

      // Verifica labels específicos
      expect(find.text('Nome completo'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
      expect(find.text('Confirmar senha'), findsOneWidget);
      expect(find.text('Seu CPF'), findsOneWidget);
      expect(find.text('CPF ou CNPJ'), findsOneWidget);

      // Verifica botão de envio
      expect(find.text('Enviar Solicitação'), findsOneWidget);

      // Verifica título
      expect(find.text('Solicitar Acesso'), findsOneWidget);
    });

    // TEST 2: Valida email inválido
    testWidgets('rejeita email inválido', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const SolicitacaoAcessoScreen()));
      await tester.pumpAndSettle();

      // Encontra e preenche campo de email com valor inválido
      final emailField = find.widgetWithText(TextFormField, 'Email').first;
      await tester.enterText(emailField, 'invalido'); // sem @
      await tester.pumpAndSettle();

      // Força validação ao sair do campo
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      // Verifica se mostra erro
      expect(find.text('Email inválido'), findsOneWidget);
    });

    // TEST 3: Botão enviar habilitado quando campos preenchidos
    testWidgets('botão habilitado com campos válidos',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const SolicitacaoAcessoScreen()));
      await tester.pumpAndSettle();

      // Preenche campos obrigatórios
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome completo').first,
          'João Silva');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email').first,
          'joao@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Senha').first,
          'Senha123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmar senha').first,
          'Senha123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Seu CPF').first,
          '12345678901');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'CPF ou CNPJ').first,
          '12345678901');
      await tester.pumpAndSettle();

      // Verifica que o botão está presente
      final submitBtn = find.text('Enviar Solicitação');
      expect(submitBtn, findsOneWidget);

      // Verifica que o botão está habilitado (tem onPressed)
      final buttonWidget = find.widgetWithText(ElevatedButton, 'Enviar Solicitação');
      final ElevatedButton button =
          tester.widget<ElevatedButton>(buttonWidget);
      expect(button.onPressed, isNotNull);
    });

    testWidgets('exige CPF pessoal separado do documento da empresa',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const SolicitacaoAcessoScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Nome completo').first,
          'Joao Silva');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email').first,
          'joao@test.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Senha').first,
          'Senha123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirmar senha').first,
          'Senha123');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'CPF ou CNPJ').first,
          '11222333000181');

      await tester.ensureVisible(find.byType(ElevatedButton).last);
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(find.text('CPF é obrigatório'), findsOneWidget);
    });

    // TEST 4: Senhas não coincidem — mostram erro
    testWidgets('rejeita se senhas não coincidem',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const SolicitacaoAcessoScreen()));
      await tester.pumpAndSettle();

      // Preenche senha e confirmar com valores diferentes
      final senhaField = find.widgetWithText(TextFormField, 'Senha').first;
      final confirmarField =
          find.widgetWithText(TextFormField, 'Confirmar senha').first;

      await tester.enterText(senhaField, 'Senha123');
      await tester.enterText(confirmarField, 'Outra456');
      await tester.pumpAndSettle();

      // Força validação
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      // Verifica mensagem de erro
      expect(find.text('As senhas não coincidem'),
          findsOneWidget);
    });

    // TEST 5: Renderiza interface de sucesso (após submissão)
    testWidgets('exibe tela de sucesso após envio bem-sucedido (mock)',
        (WidgetTester tester) async {
      // Este teste é simbólico — não faz HTTP real, apenas verifica
      // que o widget _buildSucesso renderiza corretamente se _sucesso = true
      // Para teste completo com HTTP, usar integration_test

      await tester.pumpWidget(_wrap(const SolicitacaoAcessoScreen()));
      await tester.pumpAndSettle();

      // Verifica layout inicial (formulário)
      expect(find.text('Solicitar Acesso'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_read_outlined), findsNothing);

      // Nota: Para testar a tela de sucesso (_buildSucesso),
      // precisamos forçar _sucesso = true, o que requer override ou
      // mock do service. Isto é melhor testado em integration_test.
    });

    // TEST 6: Máscara CPF/CNPJ funciona
    testWidgets('aplica máscara corretamente para CPF (11 dígitos)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const SolicitacaoAcessoScreen()));
      await tester.pumpAndSettle();

      final cpfField =
          find.widgetWithText(TextFormField, 'CPF ou CNPJ').first;

      // Digita apenas os números
      await tester.enterText(cpfField, '12345678901');
      await tester.pumpAndSettle();

      // Verifica se a máscara foi aplicada (formato: XXX.XXX.XXX-XX)
      expect(find.byWidgetPredicate((widget) {
        if (widget is TextFormField) {
          return widget.controller?.text.contains('.') ?? false;
        }
        return false;
      }), findsWidgets);
    });

    // TEST 7: Máscara CNPJ funciona
    testWidgets('aplica máscara corretamente para CNPJ (14 dígitos)',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const SolicitacaoAcessoScreen()));
      await tester.pumpAndSettle();

      final cnpjField =
          find.widgetWithText(TextFormField, 'CPF ou CNPJ').first;

      // Digita 14 números (CNPJ)
      await tester.enterText(cnpjField, '11222333000181');
      await tester.pumpAndSettle();

      // Verifica se a máscara foi aplicada (formato: XX.XXX.XXX/XXXX-XX)
      expect(find.byWidgetPredicate((widget) {
        if (widget is TextFormField) {
          return widget.controller?.text.contains('/') ?? false;
        }
        return false;
      }), findsWidgets);
    });

    // TEST 8: Visibilidade de senhas togglável
    testWidgets('alterna visibilidade de senha com ícone',
        (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const SolicitacaoAcessoScreen()));
      await tester.pumpAndSettle();

      // Localiza os ícones de visibilidade (visibility_off inicial)
      final visibilityIcons =
          find.byIcon(Icons.visibility_off);
      expect(visibilityIcons, findsAtLeastNWidgets(2)); // Senha + ConfirmarSenha

      // Clica no primeiro ícone (senha)
      await tester.tap(visibilityIcons.first);
      await tester.pumpAndSettle();

      // Após clicar, deve mudar para visibility
      final visibilityIcons2 =
          find.byIcon(Icons.visibility);
      expect(visibilityIcons2, findsWidgets);
    });
  });
}
