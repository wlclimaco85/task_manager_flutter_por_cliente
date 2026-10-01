/// Fixtures fake para testes de SessaoTreino e FichaTreino
class SessaoTreinoFixtures {
  static Map<String, dynamic> sessaoUnica() => {
        'id': 1,
        'treinoId': 10,
        'alunoId': 5,
        'alunoNome': 'João Silva',
        'dataInicio': '2026-06-25T09:00:00',
        'dataFim': '2026-06-25T10:00:00',
        'duracaoSegundos': 3600,
        'feedbackNota': 5,
        'feedbackTexto': 'Excelente treino',
      };

  static Map<String, dynamic> sessaoSemSeries() => {
        'id': 2,
        'treinoId': 11,
        'alunoId': 6,
        'alunoNome': 'Maria Santos',
        'dataInicio': '2026-06-24T14:30:00',
        'dataFim': '2026-06-24T15:30:00',
        'duracaoSegundos': 3600,
        'feedbackNota': 4,
        'feedbackTexto': 'Bom treino',
      };

  static List<Map<String, dynamic>> series() => [
        {
          'ordem': 1,
          'exercicioNome': 'Agachamento',
          'exercicioNivel': 'intermediário',
          'carga': 100.5,
          'repeticoes': 10,
          'duracaoSegundos': 300,
        },
        {
          'ordem': 2,
          'exercicioNome': 'Rosca Direta',
          'exercicioNivel': 'iniciante',
          'carga': 20.0,
          'repeticoes': 15,
          'duracaoSegundos': 250,
        },
        {
          'ordem': 3,
          'exercicioNome': 'Supino Reto',
          'exercicioNivel': 'intermediário',
          'carga': 80.0,
          'repeticoes': 12,
          'duracaoSegundos': 280,
        },
      ];

  static List<Map<String, dynamic>> seriesVazias() => [];
}
