import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../models/auth_utility.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/services/auth_interceptor.dart';

class CheckoutCaller {
  static Future<String> carregarTermos() async {
    String jsonString = "";
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequest(ApiLinks.fecthUltimoTermo);

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body?['texto']);
        jsonString = utf8.decode(latin1.encode(jsonString));
        jsonString =
            jsonString.trim().replaceAll(RegExp(r'(\n|\r|\t|\\n|\\r)'), '');
      }
    } catch (e) {
      return "Erro de conexão: ${e.toString()}";
    }
    return jsonString;
  }

  static Future<double> carregarVlrFrete(
      BuildContext context, Map<String, dynamic> parceiroData) async {
    try {
      final NetworkResponse response = await NetworkCaller()
          .postRequest(ApiLinks.fecthCalcFrete, parceiroData);

      if (response.statusCode == 200 && response.body != null) {
        final List<Map<String, dynamic>> data =
            (response.body?['data']['account'] as List)
                .map((item) => item as Map<String, dynamic>)
                .toList();
        return _calcularMediaFrete(data);
      }
      throw Exception('Erro na resposta: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao calcular frete: $e');
    }
  }

  static double _calcularMediaFrete(List<dynamic> data) {
    final filtered = data
        .where((item) =>
            item['tipoCarga'] == 'GRANEL_SOLIDO' &&
            item['lotacao']?['semCargaRetorno'] != null)
        .toList();

    if (filtered.isEmpty) return 0.0;

    final total = filtered.fold<double>(
        0.0,
        (sum, item) =>
            sum + (item['lotacao']['semCargaRetorno'] as num).toDouble());

    return total / filtered.length;
  }

  static Future<void> uploadContract(int vendaID) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        File uploadedFile = File(file.path!);

        // Usa Dio com interceptador de autenticação
        final dio = Dio();
        dio.interceptors.add(AuthInterceptor());
        final url = ApiLinks.upLoadContrato;

        FormData formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(uploadedFile.path,
              filename: file.name),
          'vendaID': vendaID.toString(),
        });

        await dio.post(
          url,
          data: formData,
        );
      }
    } catch (_) {}
  }

  Future<bool> downloadContrato(int contratoId, BuildContext context) async {
    final url = "${ApiLinks.downloadContrato}/$contratoId";
    final token = AuthUtility.userInfo?.token;

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
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
        return true;
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
          return false;
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro ao baixar contrato')),
            );
          }
          return false;
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao baixar contrato')),
        );
      }
      return false;
    }
  }
}
