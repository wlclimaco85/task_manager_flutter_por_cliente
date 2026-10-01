import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:task_manager_flutter/features/agendamento/data/models/agendamento_model.dart';
import 'package:task_manager_flutter/features/agendamento/domain/entities/agendamento_entity.dart';
import 'package:task_manager_flutter/features/agendamento/domain/repositories/agendamento_repository.dart';

/// State Management via ChangeNotifier (Provider)
class AgendamentoNotifier extends ChangeNotifier {
  final AgendamentoRepository _repository;
  final Logger _logger = Logger();

  List<AgendamentoEntity> _agendamentos = [];
  bool _loading = false;
  String? _error;

  // Getters
  List<AgendamentoEntity> get agendamentos => List.unmodifiable(_agendamentos);

  bool get loading => _loading;

  String? get error => _error;

  AgendamentoNotifier({required AgendamentoRepository repository})
      : _repository = repository;

  /// Carrega agendamentos da API ou cache
  Future<void> carregarAgendamentos() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (await _repository.isOnline()) {
        _agendamentos = (await _repository.listar()).toList();
        await _sincronizarOffline();
        _logger.i('Agendamentos carregados: ${_agendamentos.length}');
      } else {
        _logger.w('Offline: usando cache local');
      }
      _error = null;
    } catch (e) {
      _logger.e('Erro ao carregar agendamentos: $e');
      _error = e.toString();
      if (await _repository.isOnline()) {
        rethrow;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Cria novo agendamento (RFC 5545 RRULE)
  Future<void> agendar(String rrule) async {
    _error = null;

    try {
      if (rrule.isEmpty || !rrule.contains('FREQ=')) {
        throw Exception('RRULE inválido: $rrule');
      }

      // Optimistic update
      final model = AgendamentoModel(
        nfeId: 'temp',
        rrule: rrule,
        proximasOcorrencias: _calcularProximasOcorrencias(rrule),
        status: 'PENDING',
      );
      _agendamentos.add(model);
      notifyListeners();

      // Enviar para API
      final created = await _repository.criar(model);

      // Remover optimistic e adicionar resultado real
      _agendamentos.removeWhere((e) => e.nfeId == 'temp');
      _agendamentos.add(created);

      _logger.i('Agendamento criado: ${created.id}');
    } catch (e) {
      _logger.e('Erro ao criar agendamento: $e');
      _error = e.toString();
      // Rollback optimistic
      _agendamentos.removeWhere((e) => e.nfeId == 'temp');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Deleta agendamento
  Future<void> deletar(String agendamentoId) async {
    _error = null;

    try {
      // Optimistic delete
      _agendamentos.removeWhere((e) => e.id == agendamentoId);
      notifyListeners();

      await _repository.deletar(agendamentoId);
      _logger.i('Agendamento deletado: $agendamentoId');
    } catch (e) {
      _logger.e('Erro ao deletar agendamento: $e');
      _error = e.toString();
      // Rollback: recarregar
      await carregarAgendamentos();
      rethrow;
    }
  }

  /// Sincroniza fila offline
  Future<void> _sincronizarOffline() async {
    try {
      await _repository.sincronizarOffline();
      _logger.i('Fila offline sincronizada');
    } catch (e) {
      _logger.w('Erro ao sincronizar fila offline: $e');
    }
  }

  /// Calcula próximas ocorrências (simplificado, sem rrule package)
  List<DateTime> _calcularProximasOcorrencias(String rrule) {
    final List<DateTime> ocorrencias = [];
    DateTime current = DateTime.now();

    // Parseamento básico de RRULE (simplificado)
    // Versão produção usaria pacote rrule
    for (int i = 0; i < 5; i++) {
      if (rrule.contains('DAILY')) {
        ocorrencias.add(current.add(Duration(days: i + 1)));
      } else if (rrule.contains('WEEKLY')) {
        ocorrencias.add(current.add(Duration(days: (i + 1) * 7)));
      } else if (rrule.contains('MONTHLY')) {
        ocorrencias.add(
          DateTime(
            current.year,
            current.month + i + 1,
            current.day,
          ),
        );
      } else if (rrule.contains('YEARLY')) {
        ocorrencias.add(
          DateTime(
            current.year + i + 1,
            current.month,
            current.day,
          ),
        );
      }
    }

    return ocorrencias;
  }
}
