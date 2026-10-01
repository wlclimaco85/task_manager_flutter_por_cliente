import 'dart:convert';

import '../../../models/documento_model.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class DocumentoService {
  final String baseUrl = ApiLinks.fecthAllDocumentos;

  Future<List<Documento>> getDocumentosPorData(DateTime data) async {
    List<Documento>? model = [];
    DocumentoModel models;
    final NetworkResponse response = await NetworkCaller().getRequest(
      '$baseUrl/data/${data.toIso8601String().substring(0, 10)}',
    );

    L.d(
      'Response Status: $baseUrl/data/${data.toIso8601String().substring(0, 10)}',
    );
    if (response.statusCode == 200) {
      models = DocumentoModel.fromJson(response.body!);
      model.addAll(models.data ?? []);
      return model;
    } else {
      throw Exception('Falha ao carregar documentos');
    }
  }

  Future<List<Documento>> getDocumentosPorMesAno(int mes, int ano) async {
    List<Documento>? model = [];
    DocumentoModel models;
    final NetworkResponse response = await NetworkCaller().getRequest(
      '$baseUrl/mes/$mes/ano/$ano',
    );

    if (response.statusCode == 200) {
      models = DocumentoModel.fromJson(response.body!);
      model.addAll(models.data ?? []);
      return model;
    } else {
      throw Exception('Falha ao carregar documentos');
    }
  }

  Future<List<DateTime>> getDatasComDocumentos(int mes, int ano) async {
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        '$baseUrl/datas/mes/$mes/ano/$ano',
      );
      if (response.statusCode == 200 && response.body != null) {
        final models = DocumentoModel.fromJson(response.body!);
        return (models.data ?? [])
            .map<DateTime?>((ts) {
              try { return DateTime.fromMillisecondsSinceEpoch(int.parse(ts.toString())); } catch (_) { return null; }
            })
            .whereType<DateTime>()
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Documento> criarDocumento(Documento documento) async {
    final response = await NetworkCaller().postRequest(
      baseUrl,
      documento.toJson(),
    );

    if (response.statusCode == 200) {
      return Documento.fromJson(json.decode(response.body?['data']['dados']));
    } else {
      throw Exception('Falha ao criar documento');
    }
  }

  //-----

  Future<List<DateTime>> getDatasComDocumentosNovos(
    int mes,
    int ano,
    int usuarioId,
  ) async {
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        '$baseUrl/datas/novos/mes/$mes/ano/$ano/usuario/$usuarioId',
      );

      if (response.statusCode == 200 && response.body != null) {
        final dados = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (dados is! List) return [];
        return (dados)
            .map<DateTime?>((d) {
              try { return DateTime.parse(d.toString()); } catch (_) { return null; }
            })
            .whereType<DateTime>()
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<DateTime>> getDatasComDocumentosLidos(
    int mes,
    int ano,
    int usuarioId,
  ) async {
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        '$baseUrl/datas/lidos/mes/$mes/ano/$ano/usuario/$usuarioId',
      );
      if (response.statusCode == 200 && response.body != null) {
        final dados = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];
        if (dados is! List) return [];
        return (dados)
            .map<DateTime?>((d) {
              try { return DateTime.parse(d.toString()); } catch (_) { return null; }
            })
            .whereType<DateTime>()
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<void> marcarComoLido(int documentoId, int usuarioId) async {
    final NetworkResponse response = await NetworkCaller().postRequest(
      '$baseUrl/$documentoId/ler/usuario/$usuarioId',
      {}, // corpo vazio
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao marcar documento como lido');
    }
  }

  Future<bool> verificarSeLido(int documentoId, int usuarioId) async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      '$baseUrl/$documentoId/lido/usuario/$usuarioId',
    );

    if (response.statusCode == 200) {
      return response.body?['data'] as bool? ?? false;
    } else {
      return false;
    }
  }
}
