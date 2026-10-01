import 'package:flutter_test/flutter_test.dart';

/// Serviço de Calendário Simples
class CalendarService {
  /// Formata data em padrão brasileiro (dd/MM/yyyy)
  static String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year;
    return '$dia/$mes/$ano';
  }

  /// Verifica se é fim de semana
  static bool ehFimDeSemana(DateTime data) {
    return data.weekday == 6 || data.weekday == 7;
  }

  /// Retorna nome do dia
  static String nomeDia(DateTime data) {
    const nomes = [
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    return nomes[data.weekday - 1];
  }

  /// Calcula próximo dia útil
  static DateTime proximoDiaUtil(DateTime data) {
    DateTime proximo = data.add(const Duration(days: 1));
    while (ehFimDeSemana(proximo)) {
      proximo = proximo.add(const Duration(days: 1));
    }
    return proximo;
  }
}

void main() {
  group('Calendar Service — Testes Unit', () {
    test(
      'deve formatar data em padrão brasileiro',
      () {
        final data = DateTime(2024, 7, 15);
        final formatado = CalendarService.formatarData(data);
        expect(formatado, '15/07/2024');
      },
    );

    test(
      'deve adicionar zeros à esquerda',
      () {
        final data = DateTime(2024, 1, 5);
        final formatado = CalendarService.formatarData(data);
        expect(formatado, '05/01/2024');
      },
    );

    test(
      'deve detectar sábado como fim de semana',
      () {
        final sabado = DateTime(2024, 7, 20);
        expect(CalendarService.ehFimDeSemana(sabado), true);
      },
    );

    test(
      'deve detectar domingo como fim de semana',
      () {
        final domingo = DateTime(2024, 7, 21);
        expect(CalendarService.ehFimDeSemana(domingo), true);
      },
    );

    test(
      'deve detectar segunda como dia útil',
      () {
        final segunda = DateTime(2024, 7, 15);
        expect(CalendarService.ehFimDeSemana(segunda), false);
      },
    );

    test(
      'deve retornar nome correto do dia',
      () {
        final segunda = DateTime(2024, 7, 15);
        expect(CalendarService.nomeDia(segunda), 'Segunda');
      },
    );

    test(
      'deve calcular próximo dia útil partindo de dia útil',
      () {
        final segunda = DateTime(2024, 7, 15);
        final proximo = CalendarService.proximoDiaUtil(segunda);
        expect(proximo.weekday, 2); // Terça
      },
    );

    test(
      'deve calcular próximo dia útil pulando fim de semana',
      () {
        final sexta = DateTime(2024, 7, 19);
        final proximo = CalendarService.proximoDiaUtil(sexta);
        expect(proximo.weekday, 1); // Segunda
        expect(proximo.day, 22);
      },
    );

    test(
      'deve formatar com ano diferente',
      () {
        final data = DateTime(2025, 12, 25);
        final formatado = CalendarService.formatarData(data);
        expect(formatado, '25/12/2025');
      },
    );

    test(
      'deve manter ordem sequencial de dias',
      () {
        final data1 = DateTime(2024, 7, 10);
        final data2 = DateTime(2024, 7, 11);
        final formato1 = CalendarService.formatarData(data1);
        final formato2 = CalendarService.formatarData(data2);
        expect(formato1, '10/07/2024');
        expect(formato2, '11/07/2024');
      },
    );
  });
}
