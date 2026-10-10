import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/login_model.dart';
import 'package:task_manager_flutter/models/role_model.dart';
import 'package:task_manager_flutter/mobile/screens/details/login_detail_screen.dart';
import 'package:task_manager_flutter/web/screens/details/login_detail_screen.dart';
import 'package:task_manager_flutter/widgets/generic_detail_form_screen.dart';
import 'package:task_manager_flutter/widgets/login_roles_detail.dart';
import 'package:task_manager_flutter/windows/screens/details/login_detail_screen.dart';

void main() {
  final detalhes = <String, Widget Function(Login)>{
    'web': (login) =>
        WebLoginDetailScreen(item: login, hasPermission: (_) => true),
    'windows': (login) =>
        WindowsLoginDetailScreen(item: login, hasPermission: (_) => true),
    'mobile': (login) =>
        MobileLoginDetailScreen(item: login, hasPermission: (_) => true),
  };

  for (final detalhe in detalhes.entries) {
    testWidgets('detalhe ${detalhe.key}: aba Roles vincula role existente, sem CRUD novo',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: detalhe.value(Login(id: 814, nome: 'Cliente')),
      ));

      final form = tester.widget<GenericDetailFormScreen>(
        find.byType(GenericDetailFormScreen),
      );
      final roles = form.relatedTabs!.singleWhere((t) => t.title == 'Roles');
      expect(roles.telaNome, isNull);
      expect(roles.customWidget, isA<LoginRoleesDetail>());

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));
    });
  }

  testWidgets('aba Roles: sem botao Novo, Vincular salva os ids selecionados',
      (tester) async {
    final todas = [
      Role(id: 25, description: 'Escritorio', key: 'ROLE_ESCRITORIO'),
      Role(id: 30, description: 'Cliente', key: 'CLIENTE'),
    ];
    List<int>? idsSalvos;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LoginRoleesDetail(
          loginId: 814,
          carregarRolees: () async => todas,
          carregarRoleesDoLogin: (_) async => [todas[0]],
          salvarRolees: (_, ids) async {
            idsSalvos = ids;
            return true;
          },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Novo'), findsNothing);
    expect(find.byKey(const Key('btn-vincular-rolees')), findsOneWidget);

    await tester.tap(find.byKey(const Key('btn-vincular-rolees')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('login-role-30')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('btn-salvar-vinculos')));
    await tester.pumpAndSettle();

    expect(idsSalvos, unorderedEquals([25, 30]));
  });
}
