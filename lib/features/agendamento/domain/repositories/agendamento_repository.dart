import 'package:task_manager_flutter/features/agendamento/domain/entities/agendamento_entity.dart';

/// Repositório abstrato de domínio
abstract class AgendamentoRepository {
  /// Listar agendamentos do usuário/tenant
  Future<List<AgendamentoEntity>> listar();

  /// Criar novo agendamento
  Future<AgendamentoEntity> criar(AgendamentoEntity agendamento);

  /// Atualizar agendamento existente
  Future<AgendamentoEntity> atualizar(AgendamentoEntity agendamento);

  /// Deletar agendamento
  Future<void> deletar(String agendamentoId);

  /// Obter agendamento por ID
  Future<AgendamentoEntity> obterPorId(String agendamentoId);

  /// Sincronizar fila offline
  Future<void> sincronizarOffline();

  /// Verificar conectividade
  Future<bool> isOnline();
}
