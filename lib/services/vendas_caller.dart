import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/venda_model.dart';
import '../../../models/negotiation_model.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../utils/tenant_context.dart';
import '../../../models/auth_utility.dart';
import '../../mobile/screens/LoginPopup_screens.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:task_manager_flutter/utils/app_logger.dart';

class VendasCaller {
  Future<List<Produto>> fetchCotacoes(BuildContext context) async {
    List<Produto>? model = [];
    ProdutoModel models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.allVendas);

      if (response.statusCode == 200 && response.body != null) {
        models = ProdutoModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  Future<List<Product>> fetchItensAVenda(BuildContext context) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response = await NetworkCaller().getRequests(
          '${ApiLinks.fecthItensAVenda}${AuthUtility.userInfo?.data?.id}',
          context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ProductModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à venda: $e');
    }
    return model;
  }

  Future<List<Product>> fetchItensACompra(BuildContext context) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      if (AuthUtility.userInfo?.data?.id == 1) {
        // AQUI CHAMAR O LOGIN
        await showDialog(
          context: context,
          builder: (BuildContext context) => const LoginPopup(),
        );
      } else {
        final NetworkResponse response = await NetworkCaller().getRequests(
            '${ApiLinks.fecthItensACompra}${AuthUtility.userInfo?.data?.id}',
            context);
        String jsonString;

        if (response.statusCode == 200 && response.body != null) {
          jsonString = json.encode(response.body);
          models = ProductModel.fromJson(response.body!);
          model.addAll(models.produtos ?? []);
        } else if (response.statusCode == 403) {
          // Mova o código que depende do BuildContext para este método.
        } else {
          L.d('Erro: Nenhum dado retornado');
        }
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à compra: $e');
    }
    return model;
  }

  Future<List<Product>> fetchItensANegocias(BuildContext context) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response = await NetworkCaller().getRequests(
          '${ApiLinks.fecthItensANegociar}${AuthUtility.userInfo?.data?.id}',
          context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ProductModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens a negociar: $e');
    }
    return model;
  }

  Future<List<Account>> fetchClassificacao(BuildContext context) async {
    List<Account>? model = [];
    ClassificacaoResponse models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequests(ApiLinks.allClassificacao, context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ClassificacaoResponse.fromJson(response.body!);
        model.addAll(models.data ?? []);
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar classificações: $e');
    }
    return model;
  }

  Future<List<Produto>> fetchProdutoDetails(
      BuildContext context, int id) async {
    List<Produto>? model = [];
    ProdutoModel models;
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        '${ApiLinks.fecthProdutosById}$id',
      );
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = ProdutoModel.fromJson(response.body!);
        model.addAll(models.produtos ?? []);
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  void downloadContrato(int contratoId, BuildContext context) async {
    try {
      final response = await TenantContext.get(
        "${ApiLinks.downloadContrato}/$contratoId",
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/contrato_$contratoId.pdf');
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Download concluído! Abrindo o contrato...')),
          );
        }

        // Abre o arquivo com o app padrão do sistema
        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Erro ao baixar contrato: ${errorData['message'] ?? 'Erro desconhecido'}')),
            );
          }
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao baixar contrato')),
            );
          }
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao baixar contrato')),
        );
      }
    }
  }

  Future<List<Product>> confirmarNegociacao(
      BuildContext context, int negociacaoId) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response = await NetworkCaller().getRequests(
          "${ApiLinks.confirmarNegociacao}/$negociacaoId", context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucesso!!!')),
        );
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à venda: $e');
    }
    return model;
  }

  Future<List<Product>> confirmarRecusar(
      BuildContext context, int negociacaoId) async {
    List<Product>? model = [];
    ProductModel models;
    try {
      final NetworkResponse response = await NetworkCaller()
          .getRequests("${ApiLinks.confirmarRecusar}/$negociacaoId", context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucesso!!!')),
        );
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à venda: $e');
    }
    return model;
  }

  Future<Map<String, dynamic>?> enviarContraProposta(
    BuildContext context,
    int negociacaoId,
    int vendaId,
    int compradorId,
    int vendedorId,
    double qtdSacos,
    double vlrSacos,
  ) async {
    final body = {
      'negociacaoId': negociacaoId,
      'vendaId': vendaId,
      'compradorId': compradorId,
      'vendedorId': vendedorId,
      'qtdSacos': qtdSacos,
      'vlrSacos': vlrSacos,
    };

    try {
      final NetworkResponse response =
          await NetworkCaller().getRequests(ApiLinks.contraProposta, context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sucesso!!!')),
        );
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar itens à venda: $e');
    }
    return null;
  }
}
