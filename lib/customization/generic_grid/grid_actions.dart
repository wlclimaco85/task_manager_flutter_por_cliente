// lib/data/customization/generic_grid/grid_actions.dart
// -----------------------------------------------------------------------------
// 🚀 Controle de ações de servidor, permissões e exclusão
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import 'grid_models.dart';
import 'grid_helpers.dart';
import 'grid_theme.dart';
import '../../utils/grid_texts.dart';

// -----------------------------------------------------------------------------
// 🔐 Controle de Permissões
// -----------------------------------------------------------------------------
class PermissionManager {
  final Future<bool> Function(String permission)? asyncHasPermission;
  final bool Function(String permission)? hasPermission;
  final Map<String, bool> _cache = {};

  PermissionManager({this.hasPermission, this.asyncHasPermission});

  Future<void> resolve(List<String> permissions) async {
    if (asyncHasPermission == null) {
      for (final p in permissions) {
        _cache[p] = true;
      }
      return;
    }

    for (final p in permissions) {
      try {
        _cache[p] = await asyncHasPermission!(p);
      } catch (_) {
        _cache[p] = true;
      }
    }
  }

  bool can(String perm) => _cache[perm] ?? true;
}

// -----------------------------------------------------------------------------
// 🧱 Execução de ações do servidor
// -----------------------------------------------------------------------------
class ServerActionExecutor {
  final BuildContext context;

  const ServerActionExecutor(this.context);

  Future<void> run(ServerAction action, {Map<String, dynamic>? item}) async {
    final ok = await _confirm(
      context,
      title: action.label,
      message: action.confirmMessage ??
          'Deseja realmente executar "${action.label}"?',
      confirmText: 'Executar',
    );
    if (ok != true) return;

    try {
      final endpoint = item == null
          ? action.endpoint
          : action.endpoint
              .replaceFirst(':id', getNestedValue(item, 'id').toString());

      NetworkResponse resp;
      switch (action.method.toUpperCase()) {
        case 'GET':
          resp = await NetworkCaller().getRequest(endpoint);
          break;
        case 'POST':
          resp = await NetworkCaller().postRequest(endpoint, const {});
          break;
        case 'PUT':
          resp = await NetworkCaller().putRequest(endpoint, const {});
          break;
        case 'DELETE':
          resp = await NetworkCaller().deleteRequest(endpoint);
          break;
        default:
          _showSnack(context, 'Método não suportado: ${action.method}', true);
          return;
      }

      if (resp.isSuccess) {
        _showSnack(context, 'Ação "${action.label}" executada com sucesso!');
      } else {
        _showSnack(
          context,
          'Falha em "${action.label}": ${resp.statusCode}',
          true,
        );
      }
    } catch (e) {
      _showSnack(context, 'Erro ao executar ação: $e', true);
    }
  }
}

// -----------------------------------------------------------------------------
// ❌ Exclusão de item
// -----------------------------------------------------------------------------
class DeletionHandler {
  final BuildContext context;
  const DeletionHandler(this.context);

  Future<void> delete(String endpoint, String id) async {
    final ok = await _confirm(
      context,
      title: 'Excluir',
      message: 'Deseja excluir o item #$id? Esta ação não pode ser desfeita.',
      confirmText: 'Excluir',
    );
    if (ok != true) return;

    try {
      final resp = await NetworkCaller().deleteRequest(
        endpoint.replaceFirst(':id', id),
      );

      if (resp.isSuccess) {
        _showSnack(context, 'Item excluído com sucesso!');
      } else {
        _showSnack(context, 'Erro ao excluir: ${resp.statusCode}', true);
      }
    } catch (e) {
      _showSnack(context, 'Erro ao excluir: $e', true);
    }
  }
}

// -----------------------------------------------------------------------------
// 🧩 Helpers locais (confirm, snack)
// -----------------------------------------------------------------------------
Future<bool?> _confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Confirmar',
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

void _showSnack(BuildContext context, String msg, [bool error = false]) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: error ? GridColors.error : GridColors.success,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
