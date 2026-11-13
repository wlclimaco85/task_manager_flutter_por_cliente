import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/auth_screens/solicitacao_acesso_screen.dart';

const _termo = {'titulo': 'Contrato SaaS', 'conteudo': 'Texto do contrato v1'};
const _modulos = [
  {'nome': 'NFS-e', 'descricao': 'Nota de serviço', 'valorMensal': 49.9},
  {'nome': 'Estoque', 'descricao': 'Controle de estoque', 'valorMensal': 30},
];

Future<void> _abrir(
  WidgetTester t, {
  Map<String, dynamic>? termo = _termo,
  Future<String?> Function(Map<String, dynamic>)? enviar,
  Size tamanho = const Size(1300, 1500),
}) async {
  t.view.physicalSize = tamanho;
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    home: SolicitacaoAcessoScreen(
      carregarModulos: () async => _modulos,
      carregarTermo: () async => termo,
      enviar: enviar ?? (_) async => null,
    ),
  ));
  await t.pump();
}

Future<void> _digitar(WidgetTester t, String label, String texto) async {
  await t.enterText(find.widgetWithText(TextFormField, label), texto);
}

Future<void> _continuar(WidgetTester t) async {
  await t.ensureVisible(find.byKey(const Key('avancar')));
  await t.pumpAndSettle();
  await t.tap(find.byKey(const Key('avancar')));
  await t.pumpAndSettle();
}

Future<void> _preencherEmpresa(WidgetTester t) async {
  await _digitar(t, 'CNPJ', '12345678000190');
  await _digitar(t, 'Razão social', 'Empresa Teste LTDA');
  await _digitar(t, 'Cidade', 'Uberaba');
  await _digitar(t, 'UF', 'mg');
  await _digitar(t, 'Inscrição estadual (IE)', '123456');
}

Future<void> _preencherMaster(WidgetTester t, {String senha = 'Senha#1234'}) async {
  await _digitar(t, 'Nome completo', 'Maria Souza');
  await _digitar(t, 'Email', 'maria@empresa.com');
  await _digitar(t, 'Seu CPF', '12345678909');
  await _digitar(t, 'Senha (mín. 8 caracteres)', senha);
  await _digitar(t, 'Confirmar senha', senha);
}

Future<void> _ate_pacote(WidgetTester t) async {
  await _preencherEmpresa(t);
  await _continuar(t);
  await _preencherMaster(t);
  await _continuar(t);
}

void main() {
  testWidgets('missao 1 exige CNPJ e razao social antes de avancar', (t) async {
    await _abrir(t);
    await _continuar(t);
    expect(find.text('Informe um CNPJ válido (14 dígitos)'), findsOneWidget);
    expect(find.text('Razão social é obrigatório'), findsOneWidget);
    expect(find.text('Missão 1 de 3 · Sua empresa'), findsOneWidget);
  });

  testWidgets('missao 2 recusa senha curta e senhas diferentes', (t) async {
    await _abrir(t);
    await _preencherEmpresa(t);
    await _continuar(t);
    await _preencherMaster(t, senha: '1234567');
    await _continuar(t);
    expect(find.text('A senha deve ter pelo menos 8 caracteres'), findsOneWidget);

    await _digitar(t, 'Senha (mín. 8 caracteres)', 'Senha#1234');
    await _digitar(t, 'Confirmar senha', 'outra-senha');
    await _continuar(t);
    expect(find.text('As senhas não coincidem'), findsOneWidget);
  });

  testWidgets('fluxo completo: soma o pacote, exige aceite, envia e mostra parabens', (t) async {
    Map<String, dynamic>? enviado;
    await _abrir(t, enviar: (p) async {
      enviado = p;
      return null;
    });
    await _ate_pacote(t);

    expect(find.text('Missão 3 de 3 · Seu pacote'), findsOneWidget);
    // Sem aceite e sem modulo o botao fica desabilitado.
    expect(t.widget<ElevatedButton>(find.byKey(const Key('avancar'))).onPressed, isNull);

    await t.tap(find.byKey(const Key('modulo-0')));
    await t.tap(find.byKey(const Key('modulo-1')));
    await t.pump();
    expect(find.text('R\$ 79,90'), findsWidgets);
    expect(find.text('Texto do contrato v1'), findsOneWidget);

    await t.tap(find.byKey(const Key('aceite')));
    await t.pump();
    await _continuar(t);

    expect(enviado, isNotNull);
    expect(enviado!['cnpj'], '12345678000190');
    expect(enviado!['cpf'], '12345678909');
    expect(enviado!['papel'], 'MASTER');
    expect(enviado!['modulos'], ['NFS-e', 'Estoque']);
    expect(enviado!['valorTotal'], closeTo(79.9, 0.001));
    expect(enviado!['contratoTextoAceito'], 'Texto do contrato v1');
    expect(enviado!['senha'], 'Senha#1234');
    expect((enviado!['empresa'] as Map)['razaoSocial'], 'Empresa Teste LTDA');
    expect((enviado!['empresa'] as Map)['ie'], '123456');
    expect(enviado!['localizacao'], 'Uberaba/MG');
    expect(find.byKey(const Key('parabens')), findsOneWidget);
    expect(find.text('Parabéns, Maria!'), findsOneWidget);
  });

  testWidgets('erro do servidor aparece e mantem o usuario na missao 3', (t) async {
    await _abrir(t, enviar: (_) async => 'CNPJ já cadastrado');
    await _ate_pacote(t);
    await t.tap(find.byKey(const Key('modulo-0')));
    await t.tap(find.byKey(const Key('aceite')));
    await t.pump();
    await _continuar(t);

    expect(find.text('CNPJ já cadastrado'), findsOneWidget);
    expect(find.byKey(const Key('parabens')), findsNothing);
    expect(find.text('Missão 3 de 3 · Seu pacote'), findsOneWidget);
  });

  testWidgets('sem contrato cadastrado nao deixa finalizar', (t) async {
    await _abrir(t, termo: null);
    await _ate_pacote(t);
    expect(find.byKey(const Key('pacote-falhou')), findsOneWidget);
    expect(t.widget<ElevatedButton>(find.byKey(const Key('avancar'))).onPressed, isNull);
  });

  testWidgets('pontos sobem a cada missao concluida', (t) async {
    await _abrir(t);
    expect(find.text('0 pontos'), findsOneWidget);
    await _preencherEmpresa(t);
    await _continuar(t);
    expect(find.text('100 pontos'), findsOneWidget);
  });

  testWidgets('layout mobile sem overflow', (t) async {
    // Qualquer overflow vira excecao do framework e reprova o teste.
    await _abrir(t, tamanho: const Size(390, 900));
    await _preencherEmpresa(t);
    await _continuar(t);
    await _preencherMaster(t);
    await _continuar(t);
    expect(find.text('Missão 3 de 3 · Seu pacote'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
