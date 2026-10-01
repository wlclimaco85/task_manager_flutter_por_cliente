// test/services/dashboard_service_test.dart
// Dashboard: apenas GET → todos devem retornar 200
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;

  setUpAll(() async {
    token = await loginAndGetToken();
  });

  group('Dashboard API', () {
    test('Finance series → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.getFinance), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Finance Series');
    });

    test('KPIs → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.kpis), headers: authHeaders(token));
      expectListOk(res.statusCode, 'KPIs');
    });

    test('Quarterly comparison → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.quarterlyComparison), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Quarterly Comparison');
    });

    test('Finance trend → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.trend), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Finance Trend');
    });

    test('Tickets trend → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.ticketsTrend), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Tickets Trend');
    });

    test('Fluxo diário → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.financeFluxoDiario), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Fluxo Diário');
    });

    test('Client distribution → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.clientDistribution), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Client Distribution');
    });

    test('Contas saldos → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.financeFluxoDiarioSaldo), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Contas Saldos');
    });

    test('Alerts overdue → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.overdue), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Alerts Overdue');
    });

    test('Alerts due soon → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.dueSoon), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Alerts Due Soon');
    });

    test('Chat daily → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.chatDaily), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Chat Daily');
    });
  });
}
