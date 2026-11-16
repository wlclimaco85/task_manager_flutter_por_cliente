import 'dart:convert';
import 'dart:typed_data';

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import '../utils/tenant_context.dart';

/// Erro de validacao devolvido pelo backend (HTTP 422/403) com todas as mensagens.
class DpExportacaoErro implements Exception {
  DpExportacaoErro(this.erros);
  final List<String> erros;
  @override
  String toString() => erros.join('\n');
}

class DpExportacaoArquivo {
  DpExportacaoArquivo(this.nome, this.bytes, this.linhas, this.ignorados);
  final String nome;
  final Uint8List bytes;
  final int linhas;
  final int ignorados;
}

/// Uma linha do mapeamento evento do ponto -> codigo de evento da folha.
class DpMapeamentoLinha {
  DpMapeamentoLinha({
    required this.eventoPonto,
    required this.descricao,
    required this.unidade,
    this.codigoEvento = '',
    this.rubricaId,
    this.ativo = true,
  });

  factory DpMapeamentoLinha.fromJson(Map<String, dynamic> j) => DpMapeamentoLinha(
        eventoPonto: (j['eventoPonto'] ?? '').toString(),
        descricao: (j['descricao'] ?? '').toString(),
        unidade: (j['unidade'] ?? 'HORAS').toString(),
        codigoEvento: (j['codigoEvento'] ?? '').toString(),
        rubricaId: j['rubricaId'] is int ? j['rubricaId'] as int : null,
        ativo: j['ativo'] != false,
      );

  final String eventoPonto;
  final String descricao;
  final String unidade;
  String codigoEvento;
  int? rubricaId;
  bool ativo;

  Map<String, dynamic> toJson() => {
        'eventoPonto': eventoPonto,
        'codigoEvento': codigoEvento.trim().isEmpty ? null : codigoEvento.trim(),
        'rubricaId': rubricaId,
        'ativo': ativo,
      };
}

/// Cliente HTTP da exportacao do fechamento de ponto para a folha (Dominio/Alterdata/Questor).
class DpExportacaoFolhaService {
  static const layouts = <String, String>{
    'dominio': 'Domínio (Thomson Reuters)',
    'alterdata': 'Alterdata (Prosoft) - a validar',
    'questor': 'Questor - a validar',
  };

  /// Extrai as mensagens de erro do corpo {"erros": [...]}; cai no HTTP quando nao ha corpo util.
  static List<String> extrairErros(String body, int status) {
    try {
      final j = jsonDecode(body);
      if (j is Map && j['erros'] is List) {
        final l = (j['erros'] as List).map((e) => e.toString()).toList();
        if (l.isNotEmpty) return l;
      }
    } catch (_) {}
    return ['Falha na exportação (HTTP $status)'];
  }

  static String nomeArquivo(String? contentDisposition, String padrao) {
    final m = RegExp(r'filename=([^;]+)').firstMatch(contentDisposition ?? '');
    return m == null ? padrao : m.group(1)!.trim();
  }

  static String _base(int empId) => '${ApiLinks.dpExportacaoFolha}/mapeamento?empId=$empId';

  Future<List<DpMapeamentoLinha>> carregarMapeamento(int empId) async {
    try {
      final r = await TenantContext.get(_base(empId));
      if (r.statusCode != 200) throw DpExportacaoErro(extrairErros(utf8.decode(r.bodyBytes), r.statusCode));
      return (jsonDecode(utf8.decode(r.bodyBytes)) as List)
          .map((e) => DpMapeamentoLinha.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DpExportacaoErro {
      rethrow;
    } catch (e, st) {
      AppLogger.i.error('DP exportacao: falha ao carregar mapeamento: $e', st);
      throw DpExportacaoErro(['Não foi possível carregar o mapeamento.']);
    }
  }

  Future<List<DpMapeamentoLinha>> salvarMapeamento(int empId, List<DpMapeamentoLinha> linhas) async {
    try {
      final r = await TenantContext.put(_base(empId), {'itens': linhas.map((l) => l.toJson()).toList()});
      if (r.statusCode != 200) throw DpExportacaoErro(extrairErros(utf8.decode(r.bodyBytes), r.statusCode));
      return (jsonDecode(utf8.decode(r.bodyBytes)) as List)
          .map((e) => DpMapeamentoLinha.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on DpExportacaoErro {
      rethrow;
    } catch (e, st) {
      AppLogger.i.error('DP exportacao: falha ao salvar mapeamento: $e', st);
      throw DpExportacaoErro(['Não foi possível salvar o mapeamento.']);
    }
  }

  Future<DpExportacaoArquivo> gerar({
    required int empId,
    required String competencia,
    required String layout,
    String? codEmpresa,
  }) async {
    try {
      final cod = (codEmpresa == null || codEmpresa.trim().isEmpty)
          ? ''
          : '&codEmpresa=${Uri.encodeComponent(codEmpresa.trim())}';
      final url = '${ApiLinks.dpExportacaoFolha}/gerar?empId=$empId'
          '&competencia=${Uri.encodeComponent(competencia)}&layout=$layout$cod';
      final r = await TenantContext.get(url);
      if (r.statusCode != 200) {
        final erros = extrairErros(utf8.decode(r.bodyBytes), r.statusCode);
        AppLogger.i.warn('DP exportacao recusada ($layout $competencia): ${erros.join(' | ')}');
        throw DpExportacaoErro(erros);
      }
      return DpExportacaoArquivo(
        nomeArquivo(r.headers['content-disposition'], 'folha_${layout}_$competencia.txt'),
        r.bodyBytes,
        int.tryParse(r.headers['x-dp-linhas'] ?? '') ?? 0,
        int.tryParse(r.headers['x-dp-fechamentos-ignorados'] ?? '') ?? 0,
      );
    } on DpExportacaoErro {
      rethrow;
    } catch (e, st) {
      AppLogger.i.error('DP exportacao: falha ao gerar arquivo: $e', st);
      throw DpExportacaoErro(['Não foi possível gerar o arquivo. Tente novamente.']);
    }
  }
}