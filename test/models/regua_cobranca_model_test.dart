import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/models/regua_cobranca_model.dart';

void main() {
  test('converte regra e preserva o contrato da API', () {
    final regra = ReguaCobranca.fromJson({
      'id': 7,
      'nome': 'Primeiro lembrete',
      'diasRelativosVencimento': -3,
      'canal': 'EMAIL',
      'mensagem': 'Pagamento pendente',
      'somenteDiaUtil': true,
      'ativo': true,
      'ordem': 1,
    });

    expect(regra.id, 7);
    expect(regra.canal, CanalCobranca.email);
    expect(regra.toJson(), containsPair('diasAposVencimento', -3));
    expect(regra.toJson(), containsPair('somenteDiaUtil', true));
  });

  test('mantem canais multicanal habilitados para provider configuravel', () {
    expect(CanalCobranca.email.disponivel, isTrue);
    expect(CanalCobranca.notificacaoInterna.disponivel, isTrue);
    expect(CanalCobranca.whatsapp.disponivel, isTrue);
    expect(CanalCobranca.sms.disponivel, isTrue);
  });

  test('converte pendencia e resultado de execucao', () {
    final pendencia = CobrancaRegua.fromJson({
      'id': 10,
      'clienteNome': 'Cliente Teste',
      'valor': 125.5,
      'dataVencimento': '2026-06-10',
      'status': 'VENCIDO',
    });
    final resultado = ExecucaoReguaResultado.fromJson({
      'titulosAvaliados': 8,
      'enviosEnfileirados': 3,
      'duplicadosIgnorados': 2,
    });

    expect(pendencia.clienteNome, 'Cliente Teste');
    expect(pendencia.vencimento, DateTime(2026, 6, 10));
    expect(resultado.enviosEnfileirados, 3);
  });
}
