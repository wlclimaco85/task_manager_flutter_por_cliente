import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager_flutter/features/agendamento/data/models/agendamento_model.dart';
import 'package:task_manager_flutter/features/agendamento/domain/entities/agendamento_entity.dart';
import 'package:task_manager_flutter/features/agendamento/domain/repositories/agendamento_repository.dart';

/// Implementação concreta do repositório com offline-first + optimistic update
class AgendamentoRepositoryImpl implements AgendamentoRepository {
  final Dio dio;
  final Connectivity connectivity;
  late final Box<AgendamentoModel> offlineBox;

  static const String _offlineBoxName = 'agendamentos_offline';
  static const String _apiBaseUrl = '/api/v3/nfe';

  AgendamentoRepositoryImpl({
    required this.dio,
    required this.connectivity,
  });

  Future<void> initializeHive() async {
    if (!Hive.isBoxOpen(_offlineBoxName)) {
      Hive.registerAdapter(AgendamentoModelAdapter());
      offlineBox = await Hive.openBox<AgendamentoModel>(_offlineBoxName);
    } else {
      offlineBox = Hive.box<AgendamentoModel>(_offlineBoxName);
    }
  }

  @override
  Future<List<AgendamentoEntity>> listar() async {
    try {
      if (await isOnline()) {
        final response = await dio.get('$_apiBaseUrl/agendamentos');
        final List<dynamic> data = response.data ?? [];

        return data
            .map((json) => AgendamentoModel.fromJson(json as Map<String, dynamic>))
            .cast<AgendamentoEntity>()
            .toList();
      } else {
        // Offline: retornar cache local
        return offlineBox.values
            .cast<AgendamentoEntity>()
            .toList();
      }
    } catch (e) {
      // Se erro e offline, usar cache
      if (!await isOnline()) {
        return offlineBox.values
            .cast<AgendamentoEntity>()
            .toList();
      }
      rethrow;
    }
  }

  @override
  Future<AgendamentoEntity> criar(AgendamentoEntity agendamento) async {
    final model = AgendamentoModel.fromEntity(agendamento);

    try {
      if (await isOnline()) {
        final response = await dio.post(
          '$_apiBaseUrl/${agendamento.nfeId}/agendar',
          data: model.toJson(),
        );

        final createdModel = AgendamentoModel.fromJson(
          response.data as Map<String, dynamic>,
        );

        // Remove da fila offline se existia
        await offlineBox.delete(model.id);

        return createdModel;
      } else {
        // Offline: adicionar à fila e retornar modelo local
        await offlineBox.put(model.id ?? DateTime.now().toString(), model);
        return model;
      }
    } catch (e) {
      if (!await isOnline()) {
        // Offline: adicionar à fila
        await offlineBox.put(model.id ?? DateTime.now().toString(), model);
        return model;
      }
      rethrow;
    }
  }

  @override
  Future<AgendamentoEntity> atualizar(AgendamentoEntity agendamento) async {
    final model = AgendamentoModel.fromEntity(agendamento);

    try {
      if (await isOnline()) {
        final response = await dio.put(
          '$_apiBaseUrl/${agendamento.id}',
          data: model.toJson(),
        );

        return AgendamentoModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        // Offline: atualizar local
        if (model.id != null) {
          await offlineBox.put(model.id!, model);
        }
        return model;
      }
    } catch (e) {
      if (!await isOnline()) {
        if (model.id != null) {
          await offlineBox.put(model.id!, model);
        }
        return model;
      }
      rethrow;
    }
  }

  @override
  Future<void> deletar(String agendamentoId) async {
    try {
      if (await isOnline()) {
        await dio.delete('$_apiBaseUrl/$agendamentoId');
      }
      // Sempre remove do local
      await offlineBox.delete(agendamentoId);
    } catch (e) {
      if (await isOnline()) {
        rethrow;
      }
      // Offline: apenas remove do local
    }
  }

  @override
  Future<AgendamentoEntity> obterPorId(String agendamentoId) async {
    try {
      if (await isOnline()) {
        final response = await dio.get('$_apiBaseUrl/$agendamentoId');

        return AgendamentoModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        final model = offlineBox.get(agendamentoId);
        if (model != null) {
          return model;
        }
        throw Exception('Agendamento não encontrado offline');
      }
    } catch (e) {
      final model = offlineBox.get(agendamentoId);
      if (model != null) {
        return model;
      }
      rethrow;
    }
  }

  @override
  Future<void> sincronizarOffline() async {
    if (!await isOnline()) return;

    final queue = offlineBox.values.toList();

    for (final modelo in queue) {
      try {
        await dio.post(
          '$_apiBaseUrl/${modelo.nfeId}/agendar',
          data: modelo.toJson(),
        );
        await offlineBox.delete(modelo.id);
      } catch (e) {
        // Retry próximo ciclo online
      }
    }
  }

  @override
  Future<bool> isOnline() async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}

/// Adapter Hive para persistência offline de [AgendamentoModel].
/// Serializa via toJson/fromJson já existentes no model.
class AgendamentoModelAdapter extends TypeAdapter<AgendamentoModel> {
  @override
  final int typeId = 40;

  @override
  AgendamentoModel read(BinaryReader reader) {
    final json = Map<String, dynamic>.from(reader.readMap());
    return AgendamentoModel.fromJson(json);
  }

  @override
  void write(BinaryWriter writer, AgendamentoModel obj) {
    writer.writeMap(obj.toJson());
  }
}
