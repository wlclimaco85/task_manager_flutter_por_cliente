import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../helpers/file_upload_helper.dart';
import '../../utils/grid_colors.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../models/auth_utility.dart';
import '../../../services/tela_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/automacao_fiscal_screen.dart';
import '../../../widgets/importacao_sintegra_card.dart';
import '../../../widgets/importacao_sped_card.dart';
import '../../../widgets/searchable_dropdown.dart';
import 'defaults_importacao_screen.dart';

const _primary = GridColors.primary;
const _green = GridColors.secondary;
const _bg = Color(0xFFF5F5F5);
const _white = Colors.white;
const _border = Color(0xFFDDDDDD);

class ConfiguracoesSistemaScreen extends StatefulWidget {
  const ConfiguracoesSistemaScreen({super.key});
  @override
  State<ConfiguracoesSistemaScreen> createState() =>
      _ConfiguracoesSistemaScreenState();
}

class _ConfiguracoesSistemaScreenState
    extends State<ConfiguracoesSistemaScreen> {
  final Map<String, dynamic> _resultados = {};
  final Map<String, bool> _loading = {};
  int? _seedEmpresaId;
  int _seedQuantidade = 20;
  int _seedMeses = 6;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: _white,
        elevation: 2,
        title: const Row(children: [
          Icon(Icons.settings_applications, size: 20),
          SizedBox(width: 8),
          Text('Configuracoes do Sistema',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _section('Geracao de Telas', Icons.table_chart_outlined, [
            _actionCard(
                id: 'gerar_telas_full',
                title: 'Gerar Telas (Full Reset)',
                subtitle:
                    'Limpa e recria todas as telas. POST /api/telas/generate?forceUpdate=true&fullReset=true',
                icon: Icons.refresh,
                color: _primary,
                onTap: _gerarTelasFullReset),
            _actionCard(
                id: 'gerar_telas_update',
                title: 'Atualizar Telas (Force Update)',
                subtitle:
                    'Atualiza telas existentes. POST /api/telas/generate?forceUpdate=true',
                icon: Icons.update,
                color: Colors.orange.shade700,
                onTap: _gerarTelasUpdate),
            _actionCard(
                id: 'regenerar_telas',
                title: 'Regenerar Telas (Admin)',
                subtitle:
                    'Limpa controle de versao e regenera. POST /api/admin/regenerar-telas',
                icon: Icons.auto_fix_high,
                color: Colors.blue.shade700,
                onTap: _regenerarTelas),
            _actionCard(
                id: 'limpar_cache_telas',
                title: 'Limpar Cache de Telas (Local)',
                subtitle:
                    'Remove o cache local do Flutter. As telas serao recarregadas da API no proximo acesso.',
                icon: Icons.cleaning_services,
                color: Colors.teal.shade700,
                onTap: _limparCacheTelas),
          ]),
          const SizedBox(height: 20),
          _section('Dados de Teste (Mock)', Icons.data_array, [_seedCard()]),
          const SizedBox(height: 20),
          _section('Noticias', Icons.newspaper, [
            _actionCard(
                id: 'limpar_baixar_noticias',
                title: 'Limpar e Baixar Noticias',
                subtitle:
                    'Apaga todas as noticias e baixa novamente de todas as fontes',
                icon: Icons.refresh,
                color: Colors.blue.shade700,
                onTap: _limparEBaixarNoticias),
            _actionCard(
                id: 'apagar_noticias',
                title: 'Apagar Todas as Noticias',
                subtitle:
                    'Remove todas as noticias e imagens do banco (sem baixar novamente)',
                icon: Icons.delete_forever,
                color: Colors.red.shade700,
                onTap: _apagarNoticias),
          ]),
          const SizedBox(height: 20),
          _JobsSection(baseUrl: ApiLinks.baseUrl),
          const SizedBox(height: 20),
          _section('Banco de Dados', Icons.storage_outlined, [
            _actionCard(
                id: 'db_status',
                title: 'Status do Banco',
                subtitle:
                    'Verifica estado das colunas e sequencias. GET /api/admin/db-status',
                icon: Icons.health_and_safety_outlined,
                color: _green,
                onTap: _dbStatus),
            _actionCard(
                id: 'fix_db',
                title: 'Corrigir Banco (Fix DB)',
                subtitle:
                    'Aplica correcoes de colunas, FKs e sequencias. POST /api/admin/fix-db',
                icon: Icons.build_outlined,
                color: Colors.purple.shade700,
                onTap: _fixDb),
            _actionCard(
                id: 'reset_database',
                title: 'Resetar Banco de Dados (Zerar Tudo)',
                subtitle:
                    'TRUNCA TODAS as tabelas da aplicacao. Todos os dados serao PERMANENTEMENTE EXCLUIDOS. POST /api/admin/reset-database',
                icon: Icons.delete_sweep,
                color: Colors.red.shade900,
                onTap: _confirmResetDatabase),
            _actionCard(
                id: 'limpar_base_preservar',
                title: 'Limpar Base (Preservar 1 e 20001)',
                subtitle:
                    'Apaga todos os parceiros e dados de todas as empresas exceto 1 e 20001. POST /api/admin/limpar-base-preservar-empresas',
                icon: Icons.cleaning_services_outlined,
                color: Colors.deepOrange.shade800,
                onTap: _confirmLimparBasePreservar),
            _deleteEmpresaCard(),
          ]),
          const SizedBox(height: 20),
          _ImportacaoSection(baseUrl: ApiLinks.baseUrl),
          const SizedBox(height: 20),
          _section('Importacao Fiscal', Icons.receipt_long_outlined, [
            ImportacaoSintegraCard(baseUrl: ApiLinks.baseUrl),
            const SizedBox(height: 12),
            ImportacaoSpedCard(baseUrl: ApiLinks.baseUrl),
          ]),
          const SizedBox(height: 20),
          _section('Automação Fiscal', Icons.folder_special_outlined, [
            _actionCard(
                id: 'automacao_fiscal',
                title: 'Automação Fiscal (Pastas)',
                subtitle:
                    'Configura uma pasta monitorada (boletos/speds/sintegra) para '
                    'importação automática periódica.',
                icon: Icons.folder_special_outlined,
                color: _green,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AutomacaoFiscalScreen()))),
          ]),
          const SizedBox(height: 20),
          _ImportacaoCadastrosSection(baseUrl: ApiLinks.baseUrl),
          const SizedBox(height: 20),
          _section('Defaults Financeiros de Importação',
              Icons.settings_suggest_outlined, [
            _actionCard(
                id: 'defaults_importacao',
                title: 'Defaults de Importação (SINTEGRA/SPED)',
                subtitle:
                    'Conta bancária, conta/caixa, centro de custo e baixa '
                    'automática no vencimento usados para completar dados '
                    'ausentes nas importações, por empresa.',
                icon: Icons.tune,
                color: _primary,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const DefaultsImportacaoScreen()))),
          ]),
          const SizedBox(height: 20),
          if (_resultados.isNotEmpty) _buildResultados(),
        ]),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: _primary, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
      ]),
      const SizedBox(height: 8),
      ...children,
    ]);
  }

  Widget _actionCard(
      {required String id,
      required String title,
      required String subtitle,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    final isLoading = _loading[id] == true;
    final resultado = _resultados[id];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _border)),
      child: ListTile(
        leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (resultado != null) ...[
            const SizedBox(height: 4),
            _resultadoCard(id, resultado)
          ],
        ]),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: _primary))
            : ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: _white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12)),
                child: const Text('Executar')),
      ),
    );
  }

  Widget _seedCard() {
    final isLoading = _loading['seed'] == true;
    final resultado = _resultados['seed'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _border)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.science_outlined,
                      color: Colors.teal, size: 20)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Gerar Dados Mock',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                        'Histórico integrado: Comercial, Contábil, Financeiro, '
                        'Produtos, DP, Chat, OS, GED, NFC-e e NFS-e',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextFormField(
                      initialValue: '',
                      decoration: const InputDecoration(
                          labelText: 'Empresa ID (vazio = criar nova)',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8)),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _seedEmpresaId =
                          v.trim().isEmpty ? null : int.tryParse(v))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextFormField(
                      initialValue: '$_seedQuantidade',
                      decoration: const InputDecoration(
                          labelText: 'Quantidade base',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8)),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          _seedQuantidade = int.tryParse(v) ?? 20)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextFormField(
                      initialValue: '$_seedMeses',
                      decoration: const InputDecoration(
                          labelText: 'Meses de historico',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8)),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _seedMeses = int.tryParse(v) ?? 6)),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                  onPressed: isLoading ? null : _gerarSeed,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _white))
                      : const Icon(Icons.play_arrow),
                  label: Text(isLoading ? 'Gerando...' : 'Gerar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: _white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14))),
            ]),
            if (resultado != null) ...[
              const SizedBox(height: 8),
              _resultadoCard('seed', resultado)
            ],
          ])),
    );
  }

  Widget _buildResultados() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Divider(),
      const Text('Ultimos Resultados',
          style: TextStyle(fontWeight: FontWeight.bold, color: _primary)),
      const SizedBox(height: 8),
      ..._resultados.entries.map((e) => _resultadoCard(e.key, e.value)),
    ]);
  }

  Widget _resultadoCard(String id, dynamic resultado) {
    final texto = _resultadoTexto(resultado);
    final cor = _resultadoColor(resultado);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cor.withValues(alpha: 0.4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8))),
          child: Row(children: [
            Icon(
                resultado is Map && resultado['error'] != null
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: cor,
                size: 16),
            const SizedBox(width: 8),
            Expanded(
                child: Text(id,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: cor))),
            IconButton(
                icon: const Icon(Icons.copy, size: 16),
                tooltip: 'Copiar',
                color: cor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: texto));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Copiado'),
                      duration: Duration(seconds: 2)));
                }),
          ]),
        ),
        Container(
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(12),
            child: Scrollbar(
                child: SingleChildScrollView(
                    child: SelectableText(texto,
                        style: TextStyle(
                            fontSize: 12,
                            color: cor,
                            fontFamily: 'monospace',
                            height: 1.5))))),
      ]),
    );
  }

  Color _resultadoColor(dynamic r) {
    if (r is Map && (r['status'] == 'ok' || r['status'] == 'success'))
      return _green;
    if (r is Map && r['error'] != null) return _primary;
    if (r is String && r.toLowerCase().contains('erro')) return _primary;
    return Colors.blue.shade700;
  }

  String _resultadoTexto(dynamic r) {
    if (r is Map) {
      try {
        return const JsonEncoder.withIndent('  ').convert(r);
      } catch (_) {
        return r.toString();
      }
    }
    return r.toString();
  }

  Future<void> _gerarTelasFullReset() async =>
      _executar('gerar_telas_full', () async {
        final resp = await TenantContext.post(
            '${ApiLinks.baseUrl}/api/telas/generate',
            {'forceUpdate': true, 'forceRebuild': true, 'fullReset': true});
        // Limpa cache local de telas para forÃ§ar reload do banco
        await TelaService.clearAllTelaCache();
        return resp;
      });

  Future<void> _gerarTelasUpdate() async =>
      _executar('gerar_telas_update', () async {
        final resp = await TenantContext.post(
            '${ApiLinks.baseUrl}/api/telas/generate', {'forceUpdate': true});
        await TelaService.clearAllTelaCache();
        return resp;
      });

  Future<void> _regenerarTelas() async =>
      _executar('regenerar_telas', () async {
        final resp = await TenantContext.post(
            '${ApiLinks.baseUrl}/api/admin/regenerar-telas', {});
        await TelaService.clearAllTelaCache();
        return resp;
      });

  Future<void> _limparCacheTelas() async {
    setState(() => _loading['limpar_cache_telas'] = true);
    try {
      await TelaService.clearAllTelaCache();
      setState(() => _resultados['limpar_cache_telas'] = {
            'status': 'ok',
            'message':
                'Cache de telas limpo com sucesso. Recarregue a pagina (F5).'
          });
    } catch (e) {
      setState(
          () => _resultados['limpar_cache_telas'] = {'error': e.toString()});
    } finally {
      setState(() => _loading['limpar_cache_telas'] = false);
    }
  }

  Future<void> _dbStatus() async {
    setState(() => _loading['db_status'] = true);
    try {
      final resp =
          await TenantContext.get('${ApiLinks.baseUrl}/api/admin/db-status');
      setState(() => _resultados['db_status'] = resp.statusCode == 200
          ? jsonDecode(resp.body)
          : {'error': 'HTTP ${resp.statusCode}', 'body': resp.body});
    } catch (e) {
      setState(() => _resultados['db_status'] = {'error': e.toString()});
    } finally {
      setState(() => _loading['db_status'] = false);
    }
  }

  Future<void> _fixDb() async => _executar('fix_db',
      () => TenantContext.post('${ApiLinks.baseUrl}/api/admin/fix-db', {}));

  Future<void> _limparEBaixarNoticias() async => _executar(
      'limpar_baixar_noticias',
      () => TenantContext.post(
          '${ApiLinks.baseUrl}/api/admin/jobs/noticias-limpar-e-baixar', {}));

  Future<void> _apagarNoticias() async {
    setState(() => _loading['apagar_noticias'] = true);
    try {
      final resp = await TenantContext.delete(
          '${ApiLinks.baseUrl}/api/admin/jobs/noticias-apagar');
      setState(() => _resultados['apagar_noticias'] = resp.statusCode == 200
          ? jsonDecode(resp.body)
          : {'error': 'HTTP ${resp.statusCode}', 'body': resp.body});
    } catch (e) {
      setState(() => _resultados['apagar_noticias'] = {'error': e.toString()});
    } finally {
      setState(() => _loading['apagar_noticias'] = false);
    }
  }

  // â”€â”€ Apagar Empresa Mock â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  int? _deleteEmpresaId;

  Widget _deleteEmpresaCard() {
    final isLoading = _loading['delete_empresa'] == true;
    final resultado = _resultados['delete_empresa'];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: _border)),
      child: Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_forever,
                      color: _primary, size: 20)),
              const SizedBox(width: 12),
              const Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Apagar Empresa Mock',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                        'Remove TODOS os dados de uma empresa (parceiros, logins, NF-e, chamados, contas, etc)',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'ID da Empresa para apagar',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8)),
                      keyboardType: TextInputType.number,
                      onChanged: (v) =>
                          setState(() => _deleteEmpresaId = int.tryParse(v)))),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                  onPressed: isLoading || _deleteEmpresaId == null
                      ? null
                      : _deletarEmpresa,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _white))
                      : const Icon(Icons.delete),
                  label: Text(isLoading ? 'Apagando...' : 'Apagar'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: _white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14))),
            ]),
            if (resultado != null) ...[
              const SizedBox(height: 8),
              _resultadoCard('delete_empresa', resultado)
            ],
          ])),
    );
  }

  Future<void> _deletarEmpresa() async {
    if (_deleteEmpresaId == null) return;
    setState(() => _loading['delete_empresa'] = true);
    try {
      // Usa http.delete direto (sem TenantContext) para nao sobrescrever o empresaId
      final token = AuthUtility.userInfo?.token;
      final resp = await http.delete(
        Uri.parse(
            '${ApiLinks.baseUrl}/api/admin/seed?empresaId=$_deleteEmpresaId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      setState(() => _resultados['delete_empresa'] = resp.statusCode == 200
          ? jsonDecode(resp.body)
          : {'error': 'HTTP ${resp.statusCode}', 'body': resp.body});
    } catch (e) {
      setState(() => _resultados['delete_empresa'] = {'error': e.toString()});
    } finally {
      setState(() => _loading['delete_empresa'] = false);
    }
  }

  Future<void> _confirmResetDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
          SizedBox(width: 8),
          Text('Resetar Banco de Dados',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ATENCAO: Esta operacao e IRREVERSIVEL!',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              SizedBox(height: 12),
              Text('Todos os dados serao PERMANENTEMENTE EXCLUIDOS:'),
              SizedBox(height: 8),
              Text('- Empresas, Parceiros, Logins'),
              Text('- Contas a Pagar e a Receber'),
              Text('- NF-e, Chamados, Comunicados'),
              Text('- Lancamentos Contabeis, Ponto, Chat'),
              Text('- E todos os demais registros'),
              SizedBox(height: 12),
              Text('As tabelas de controle (Flyway, Telas) serao preservadas.'),
              SizedBox(height: 12),
              Text('Digite "RESET" no campo abaixo para confirmar:'),
            ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar Reset'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _executar(
        'reset_database',
        () => TenantContext.post(
            '${ApiLinks.baseUrl}/api/admin/reset-database', {}));
  }

  Future<void> _confirmLimparBasePreservar() async {
    final controller = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final matches = controller.text.trim() == 'LIMPAR';
          return AlertDialog(
            title: const Row(children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.deepOrange, size: 24),
              SizedBox(width: 8),
              Text('Limpar Base de Produção',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ATENCAO: Esta operacao e IRREVERSIVEL!',
                      style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 12),
                  const Text(
                      'Todos os parceiros, movimentações, contas, notas fiscais e logins de outras empresas serão PERMANENTEMENTE EXCLUÍDOS.'),
                  const SizedBox(height: 8),
                  const Text(
                      'Serão PRESERVADOS APENAS os dados das empresas 1 e 20001.'),
                  const SizedBox(height: 12),
                  const Text('Digite "LIMPAR" no campo abaixo para confirmar:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'LIMPAR',
                      isDense: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange.shade800,
                    foregroundColor: Colors.white),
                onPressed: matches ? () => Navigator.pop(ctx, true) : null,
                child: const Text('Confirmar Limpeza'),
              ),
            ],
          );
        },
      ),
    );
    if (confirm != true) return;
    await _executar(
        'limpar_base_preservar',
        () => TenantContext.post(
            '${ApiLinks.baseUrl}/api/admin/limpar-base-preservar-empresas',
            {}));
  }

  Future<void> _gerarSeed() async {
    setState(() => _loading['seed'] = true);
    try {
      final params =
          StringBuffer('quantidade=$_seedQuantidade&meses=$_seedMeses');
      if (_seedEmpresaId != null) params.write('&empresaId=$_seedEmpresaId');
      final resp = await TenantContext.post(
          '${ApiLinks.baseUrl}/api/admin/seed?$params', {});
      setState(() => _resultados['seed'] = resp.statusCode == 200
          ? jsonDecode(resp.body)
          : {'error': 'HTTP ${resp.statusCode}', 'body': resp.body});
    } catch (e) {
      setState(() => _resultados['seed'] = {'error': e.toString()});
    } finally {
      setState(() => _loading['seed'] = false);
    }
  }

  Future<void> _executar(String id, Future<dynamic> Function() fn) async {
    setState(() => _loading[id] = true);
    try {
      final resp = await fn();
      dynamic body;
      try {
        body = jsonDecode(resp.body);
      } catch (_) {
        body = resp.body;
      }
      setState(() => _resultados[id] = resp.statusCode < 300
          ? body
          : {'error': 'HTTP ${resp.statusCode}', 'body': resp.body});
    } catch (e) {
      setState(() => _resultados[id] = {'error': e.toString()});
    } finally {
      setState(() => _loading[id] = false);
    }
  }
}

// â”€â”€ Controle de Jobs â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _JobsSection extends StatefulWidget {
  final String baseUrl;
  const _JobsSection({required this.baseUrl});
  @override
  State<_JobsSection> createState() => _JobsSectionState();
}

class _JobsSectionState extends State<_JobsSection> {
  final Map<String, Map<String, dynamic>> _ultimaExec = {};
  bool _carregando = true;
  final Map<String, bool> _executando = {};
  final Map<String, List<Map<String, dynamic>>> _historicos = {};
  final Set<String> _historicoAberto = {};
  final Set<String> _erroAberto = {};

  static const _jobsMeta = [
    {
      'nome': 'ContabeisScraperJob',
      'label': 'Scraping Contabeis.com.br',
      'cron': 'Diario 08:00'
    },
    {
      'nome': 'ContabeisReprocessarImagens',
      'label': 'Reprocessar Imagens Contabeis',
      'cron': 'Manual'
    },
    {
      'nome': 'PontoVerificacaoJob',
      'label': 'Verificacao de Pontos',
      'cron': 'Diario 00:00'
    },
    {
      'nome': 'ObrigacaoFiscalJob',
      'label': 'Obrigacoes Fiscais (diario)',
      'cron': 'Diario 06:00'
    },
    {
      'nome': 'ObrigacaoFiscalJobMensal',
      'label': 'Obrigacoes Fiscais (mensal)',
      'cron': '1o dia do mes 08:00'
    },
    {
      'nome': 'ScrapeNewsInvesting',
      'label': 'Scraping Investing.com',
      'cron': 'A cada hora'
    },
    {
      'nome': 'ScrapeNewsAgroLink',
      'label': 'Scraping AgroLink',
      'cron': 'A cada hora'
    },
    {
      'nome': 'ScrapeNewsCNN',
      'label': 'Scraping CNN Brasil',
      'cron': 'A cada hora'
    },
    {
      'nome': 'ScrapeCotacaoESALQ',
      'label': 'Cotacao ESALQ',
      'cron': 'A cada hora'
    },
    {
      'nome': 'AtualizarCotacao',
      'label': 'Atualizar Cotacoes',
      'cron': 'Seg-Sex a cada hora'
    },
    {
      'nome': 'ScrapeCotacaoDollar',
      'label': 'Cotacao Dolar',
      'cron': 'Seg-Sex a cada hora'
    },
    {
      'nome': 'InstagramDataCollector',
      'label': 'Instagram Monitor',
      'cron': 'A cada hora'
    },
    {
      'nome': 'InstagramInteracaoJob',
      'label': 'Instagram Interacoes (following)',
      'cron': 'Diario 23:59'
    },
    {
      'nome': 'MensalidadeEscritorioJob',
      'label': 'Mensalidade do Escritorio (gera parcela)',
      'cron': '1o dia do mes 06:00'
    },
    {
      'nome': 'ReguaCobrancaJob',
      'label': 'Regua de Cobranca Automatica',
      'cron': 'Diario 08:00'
    },
    {
      'nome': 'AlertasVencimentoJob',
      'label': 'Alertas de Vencimento (Contas a Pagar)',
      'cron': 'Diario 07:00'
    },
    {
      'nome': 'CertificadoExpiracaoJob',
      'label': 'Verificacao de Certificados NFC-e',
      'cron': 'Diario 08:00'
    },
    {
      'nome': 'ContingenciaJob',
      'label': 'Reenvio de NFC-e em Contingencia',
      'cron': 'A cada 5 minutos'
    },
  ];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final resp = await TenantContext.get('${widget.baseUrl}/api/admin/jobs');
      if (resp.statusCode == 200) {
        final map = <String, Map<String, dynamic>>{};
        for (final j
            in (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>()) {
          map[j['jobNome'] as String] = j;
        }
        if (mounted) setState(() => _ultimaExec.addAll(map));
      }
    } catch (_) {}
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _executar(String nome, {bool forcar = false}) async {
    final chave = forcar ? '${nome}_forcado' : nome;
    setState(() => _executando[chave] = true);
    try {
      final url = forcar
          ? '${widget.baseUrl}/api/admin/jobs/$nome/executar?forcar=true'
          : '${widget.baseUrl}/api/admin/jobs/$nome/executar';
      final resp = await TenantContext.post(url, {});
      if (resp.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(forcar
                  ? 'Job $nome iniciado (FORÇADO)'
                  : 'Job $nome iniciado'),
              backgroundColor: forcar ? Colors.orange : _green));
        }
        await Future.delayed(const Duration(seconds: 3));
        await _carregar();
        if (_historicoAberto.contains(nome)) await _carregarHistorico(nome);
      } else {
        if (mounted)
          _mostrarErroDialog(context, 'Erro ao executar $nome', resp.body);
      }
    } catch (e) {
      if (mounted)
        _mostrarErroDialog(context, 'Erro ao executar $nome', e.toString());
    } finally {
      if (mounted) setState(() => _executando[chave] = false);
    }
  }

  void _mostrarErroDialog(BuildContext context, String titulo, String erro) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          const Icon(Icons.error_outline, color: _primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(titulo,
                  style: const TextStyle(fontSize: 14, color: _primary))),
        ]),
        content: SizedBox(
          width: 600,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botao copiar
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                      onPressed: () => _copiar(context, erro),
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copiar tudo',
                          style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: _primary)),
                ),
                // Textarea scrollavel
                Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: _primary.withValues(alpha: 0.25))),
                    child: Scrollbar(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.all(10),
                            child: SelectableText(erro,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _primary,
                                    fontFamily: 'monospace',
                                    height: 1.5))))),
              ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Fechar')),
        ],
      ),
    );
  }

  Future<void> _carregarHistorico(String nome) async {
    try {
      final resp = await TenantContext.get(
          '${widget.baseUrl}/api/admin/jobs/$nome/historico');
      if (resp.statusCode == 200 && mounted) {
        setState(() => _historicos[nome] =
            (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>());
      }
    } catch (_) {}
  }

  void _toggleHistorico(String nome) async {
    if (_historicoAberto.contains(nome)) {
      setState(() => _historicoAberto.remove(nome));
      return;
    }
    await _carregarHistorico(nome);
    if (mounted) setState(() => _historicoAberto.add(nome));
  }

  void _toggleErro(String nome) => setState(() {
        if (_erroAberto.contains(nome)) {
          _erroAberto.remove(nome);
        } else {
          _erroAberto.add(nome);
        }
      });

  void _copiar(BuildContext ctx, String texto) {
    Clipboard.setData(ClipboardData(text: texto));
    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
        content: Text('Copiado'), duration: Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.schedule, color: _primary, size: 18),
        const SizedBox(width: 8),
        const Text('Controle de Jobs',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
        const Spacer(),
        if (_carregando)
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _primary))
        else
          IconButton(
              icon: const Icon(Icons.refresh, size: 18),
              tooltip: 'Atualizar',
              onPressed: _carregar,
              color: _primary),
      ]),
      const SizedBox(height: 8),
      ..._jobsMeta.map((meta) => _jobCard(context, meta)),
    ]);
  }

  Widget _jobCard(BuildContext context, Map<String, dynamic> meta) {
    final nome = meta['nome'] as String;
    final label = meta['label'] as String;
    final cron = meta['cron'] as String;
    final ultima = _ultimaExec[nome];
    final status = ultima?['status'] as String?;
    final inicio = ultima?['inicio'] as String?;
    final duracaoMs = ultima?['duracaoMs'];
    final mensagem = ultima?['mensagem'] as String?;
    final erro = ultima?['erro'] as String?;
    final executando = _executando[nome] == true;
    final histAberto = _historicoAberto.contains(nome);
    final erroAberto = _erroAberto.contains(nome);

    Color cor = Colors.grey.shade400;
    IconData icone = Icons.radio_button_unchecked;
    if (status == 'SUCESSO') {
      cor = _green;
      icone = Icons.check_circle;
    } else if (status == 'ERRO') {
      cor = _primary;
      icone = Icons.error;
    } else if (status == 'EXECUTANDO') {
      cor = Colors.orange;
      icone = Icons.sync;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cor.withValues(alpha: 0.35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // linha principal
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
          child: Row(children: [
            Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icone, color: cor, size: 18)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Row(children: [
                    const Icon(Icons.timer_outlined,
                        size: 11, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(cron,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(width: 8),
                    if (status != null)
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                              color: cor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(status,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: cor,
                                  fontWeight: FontWeight.bold)))
                    else
                      const Text('Nunca executado',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ]),
                  if (inicio != null)
                    Text(
                        'Ultima: ${_fmt(inicio)}${duracaoMs != null ? '  -  ${duracaoMs}ms' : ''}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  if (status == 'SUCESSO' &&
                      mensagem != null &&
                      mensagem.isNotEmpty)
                    Text(mensagem,
                        style: const TextStyle(fontSize: 11, color: _green),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ])),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                  icon: Icon(histAberto ? Icons.expand_less : Icons.history,
                      size: 18),
                  tooltip: 'Historico',
                  color: Colors.blue.shade600,
                  onPressed: () => _toggleHistorico(nome)),
              executando
                  ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _primary)))
                  : IconButton(
                      icon: const Icon(Icons.play_circle_outline, size: 22),
                      tooltip: 'Executar agora',
                      color: _green,
                      onPressed: () => _executar(nome)),
              if (nome == 'InstagramDataCollector')
                (_executando['${nome}_forcado'] ?? false)
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.orange)))
                    : IconButton(
                        icon: const Icon(Icons.bolt, size: 22),
                        tooltip:
                            'Forçar coleta completa (ignora cache de contagem)',
                        color: Colors.orange,
                        onPressed: () => _executar(nome, forcar: true)),
            ]),
          ]),
        ),

        // â”€â”€ Erro com textarea copiavel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (status == 'ERRO' && erro != null && erro.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: InkWell(
              onTap: () => _toggleErro(nome),
              child: Row(children: [
                Icon(erroAberto ? Icons.expand_less : Icons.expand_more,
                    size: 14, color: _primary),
                const SizedBox(width: 4),
                Text(erroAberto ? 'Ocultar erro' : 'Ver erro completo',
                    style: const TextStyle(
                        fontSize: 11,
                        color: _primary,
                        decoration: TextDecoration.underline)),
              ]),
            ),
          ),
          if (erroAberto)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Container(
                decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: _primary.withValues(alpha: 0.25))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header com botao copiar
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 6, 0),
                        child: Row(children: [
                          const Text('Erro',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _primary)),
                          const Spacer(),
                          TextButton.icon(
                              onPressed: () => _copiar(context, erro),
                              icon: const Icon(Icons.copy, size: 13),
                              label: const Text('Copiar',
                                  style: TextStyle(fontSize: 11)),
                              style: TextButton.styleFrom(
                                  foregroundColor: _primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero)),
                        ]),
                      ),
                      // textarea scrollavel e selecionavel
                      Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                          child: Scrollbar(
                              child: SingleChildScrollView(
                                  child: SelectableText(erro,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: _primary,
                                          fontFamily: 'monospace',
                                          height: 1.5))))),
                    ]),
              ),
            ),
        ],

        // â”€â”€ Historico expandido â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (histAberto) ...[
          const Divider(height: 1, indent: 12, endIndent: 12),
          Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
              child: Text('Ultimas execucoes',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600))),
          if (_historicos[nome] == null || _historicos[nome]!.isEmpty)
            const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Text('Nenhum historico disponivel.',
                    style: TextStyle(fontSize: 11, color: Colors.grey)))
          else
            ..._historicos[nome]!.map((h) => _historicoRow(context, h)),
          const SizedBox(height: 6),
        ],
      ]),
    );
  }

  Widget _historicoRow(BuildContext context, Map<String, dynamic> h) {
    final status = h['status'] as String? ?? '';
    final cor = status == 'SUCESSO'
        ? _green
        : status == 'ERRO'
            ? _primary
            : Colors.orange;
    final inicio = h['inicio'] as String?;
    final duracao = h['duracaoMs'];
    final msg = (h['mensagem'] ?? h['erro'] ?? '').toString();
    final erroCompleto = h['erro'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
              status == 'SUCESSO'
                  ? Icons.check_circle
                  : status == 'ERRO'
                      ? Icons.cancel
                      : Icons.sync,
              size: 12,
              color: cor),
          const SizedBox(width: 6),
          Text(inicio != null ? _fmt(inicio) : '-',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(width: 8),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3)),
              child: Text(status,
                  style: TextStyle(
                      fontSize: 10, color: cor, fontWeight: FontWeight.bold))),
          if (duracao != null) ...[
            const SizedBox(width: 6),
            Text('${duracao}ms',
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
          if (msg.isNotEmpty) ...[
            const SizedBox(width: 6),
            Expanded(
                child: Text(msg,
                    style: TextStyle(fontSize: 10, color: cor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ],
          if (status == 'ERRO' && erroCompleto != null)
            IconButton(
                icon: const Icon(Icons.copy, size: 12),
                tooltip: 'Copiar erro',
                color: _primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => _copiar(context, erroCompleto)),
        ]),
        // textarea do erro no historico
        if (status == 'ERRO' && erroCompleto != null)
          Padding(
              padding: const EdgeInsets.only(left: 18, top: 2, bottom: 4),
              child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 80),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(4),
                      border:
                          Border.all(color: _primary.withValues(alpha: 0.2))),
                  child: Scrollbar(
                      child: SingleChildScrollView(
                          child: SelectableText(erroCompleto,
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: _primary,
                                  fontFamily: 'monospace',
                                  height: 1.4)))))),
      ]),
    );
  }

  String _fmt(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

// â”€â”€ Importacao CSV â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ImportacaoSection extends StatefulWidget {
  final String baseUrl;
  const _ImportacaoSection({required this.baseUrl});
  @override
  State<_ImportacaoSection> createState() => _ImportacaoSectionState();
}

class _ImportacaoSectionState extends State<_ImportacaoSection> {
  // â”€â”€ Empresa / Parceiro selecionados â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Listas carregadas da API
  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _parceiros = [];
  bool _loadingEmpresas = false;
  bool _loadingParceiros = false;

  // Valores selecionados nos dropdowns (null = usar o do TenantContext)
  String? _empresaIdSelecionada;
  String? _parceiroIdSelecionado;

  // â”€â”€ Estado Contas a Pagar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  PlatformFile? _arquivoCP;
  bool _importandoCP = false;
  bool _upsertCP = false;
  Map<String, dynamic>? _resultadoCP;
  bool _mapeamentoExpandidoCP = false;
  final Map<String, TextEditingController> _ctrlCP = {
    'colDescricao': TextEditingController(text: 'historico'),
    'colValor': TextEditingController(text: 'vlr_do_desdobramento'),
    'colVencimento': TextEditingController(text: 'dt_vencimento'),
    'colParceiro': TextEditingController(text: 'parceiro'),
    'colFormaPagamento': TextEditingController(text: 'forma_pagamento'),
    'colStatus': TextEditingController(text: 'status'),
    'colNumeroNota': TextEditingController(text: 'nro_nota'),
    'colObservacao': TextEditingController(text: 'observacao'),
    'colDataBaixa': TextEditingController(text: ''),
    'colValorBaixa': TextEditingController(text: ''),
    'colValorMulta': TextEditingController(text: ''),
    'colValorJuros': TextEditingController(text: ''),
    'colValorDesconto': TextEditingController(text: ''),
    'colParceiroDev': TextEditingController(text: ''),
    'colContaBancaria': TextEditingController(text: ''),
  };

  // â”€â”€ Estado Contas a Receber â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  PlatformFile? _arquivoCR;
  bool _importandoCR = false;
  bool _upsertCR = false;
  Map<String, dynamic>? _resultadoCR;
  bool _mapeamentoExpandidoCR = false;
  final Map<String, TextEditingController> _ctrlCR = {
    'colDescricao': TextEditingController(text: 'historico'),
    'colValor': TextEditingController(text: 'vlr_do_desdobramento'),
    'colVencimento': TextEditingController(text: 'dt_vencimento'),
    'colParceiro': TextEditingController(text: 'parceiro'),
    'colFormaPagamento': TextEditingController(text: 'forma_pagamento'),
    'colStatus': TextEditingController(text: 'status'),
    'colNumeroNota': TextEditingController(text: 'nro_nota'),
    'colObservacao': TextEditingController(text: 'observacao'),
    'colDataBaixa': TextEditingController(text: ''),
    'colValorBaixa': TextEditingController(text: ''),
    'colValorMulta': TextEditingController(text: ''),
    'colValorJuros': TextEditingController(text: ''),
    'colValorDesconto': TextEditingController(text: ''),
    'colParceiroDev': TextEditingController(text: ''),
    'colContaBancaria': TextEditingController(text: ''),
  };

  static const _camposMapeamento = [
    {'key': 'colDescricao', 'label': 'Coluna Descricao *'},
    {'key': 'colValor', 'label': 'Coluna Valor *'},
    {'key': 'colVencimento', 'label': 'Coluna Vencimento *'},
    {'key': 'colParceiro', 'label': 'Coluna Parceiro'},
    {'key': 'colFormaPagamento', 'label': 'Coluna Forma Pagamento'},
    {'key': 'colStatus', 'label': 'Coluna Status'},
    {'key': 'colNumeroNota', 'label': 'Coluna Numero Nota'},
    {'key': 'colObservacao', 'label': 'Coluna Observacao'},
    {'key': 'colDataBaixa', 'label': 'Coluna Data Baixa'},
    {'key': 'colValorBaixa', 'label': 'Coluna Valor Baixa'},
    {'key': 'colValorMulta', 'label': 'Coluna Valor Multa'},
    {'key': 'colValorJuros', 'label': 'Coluna Valor Juros'},
    {'key': 'colValorDesconto', 'label': 'Coluna Valor Desconto'},
    {'key': 'colParceiroDev', 'label': 'Coluna Parceiro Dev'},
    {'key': 'colContaBancaria', 'label': 'Coluna Conta Bancaria'},
  ];

  @override
  void initState() {
    super.initState();
    // Sempre carrega empresas â€” mesmo quando fixada pelo login,
    // precisamos da lista para resolver o nome a exibir no campo bloqueado.
    _carregarEmpresas();
    // Sempre carrega parceiros filtrados pela empresa (do contexto ou aguarda seleÃ§Ã£o)
    if (TenantContext.hasEmpresa) {
      _carregarParceiros(TenantContext.empresaId.toString());
    }
  }

  Future<void> _carregarEmpresas() async {
    setState(() => _loadingEmpresas = true);
    try {
      final resp = await TenantContext.get('${widget.baseUrl}/api/empresa');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body['data'] is Map && body['data']['dados'] is List) {
          lista = body['data']['dados'] as List;
        } else if (body['data'] is List) {
          lista = body['data'] as List;
        }
        if (mounted) {
          setState(() => _empresas = lista
              .map<Map<String, dynamic>>((e) => {
                    'id': e['id'].toString(),
                    'nome': e['nome']?.toString() ?? ''
                  })
              .toList());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingEmpresas = false);
  }

  Future<void> _carregarParceiros([String? empresaId]) async {
    setState(() {
      _loadingParceiros = true;
      _parceiros = [];
      _parceiroIdSelecionado = null;
    });
    try {
      // Usa empresa do contexto, ou a passada como parÃ¢metro, ou carrega todos
      final empId = empresaId ??
          (TenantContext.hasEmpresa
              ? TenantContext.empresaId.toString()
              : null);

      final url = empId != null
          ? '${widget.baseUrl}/api/parceiro/empresa/$empId'
          : '${widget.baseUrl}/api/parceiro';

      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        // /empresa/{id} retorna body['data']['dados'] ou body['data'] direto
        if (body['data'] is Map && body['data']['dados'] is List) {
          lista = body['data']['dados'] as List;
        } else if (body['data'] is List) {
          lista = body['data'] as List;
        } else if (body is List) {
          lista = body;
        }
        if (mounted) {
          setState(() => _parceiros = lista
              .map<Map<String, dynamic>>((e) => {
                    'id': e['id'].toString(),
                    'nome': e['nome']?.toString() ?? ''
                  })
              .toList());
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingParceiros = false);
  }

  @override
  void dispose() {
    for (final c in _ctrlCP.values) {
      c.dispose();
    }
    for (final c in _ctrlCR.values) {
      c.dispose();
    }
    super.dispose();
  }

  // Colunas detectadas no CSV apÃ³s seleÃ§Ã£o
  List<String> _colunasCP = [];
  List<String> _colunasCR = [];

  Future<void> _selecionarArquivo(bool isCP) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;

      // Detecta colunas localmente (fallback rÃ¡pido)
      final colunasLocal = _detectarColunas(file.bytes);
      setState(() {
        if (isCP) {
          _arquivoCP = file;
          _resultadoCP = null;
          _colunasCP = colunasLocal;
          _autoMapear(_ctrlCP, colunasLocal);
        } else {
          _arquivoCR = file;
          _resultadoCR = null;
          _colunasCR = colunasLocal;
          _autoMapear(_ctrlCR, colunasLocal);
        }
      });

      // Chama o preview da API para detecÃ§Ã£o precisa (suporta tab, BOM, etc.)
      try {
        final resp = await TenantContext.postMultipart(
          '${widget.baseUrl}/api/importacao/preview',
          fileBytes: file.bytes!,
          fileName: file.name,
          fileField: 'arquivo',
        );
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body);
          final colunas =
              (body['colunas'] as List?)?.cast<String>() ?? colunasLocal;
          if (mounted) {
            setState(() {
              if (isCP) {
                _colunasCP = colunas;
                _autoMapear(_ctrlCP, colunas);
              } else {
                _colunasCR = colunas;
                _autoMapear(_ctrlCR, colunas);
              }
            });
          }
        }
      } catch (_) {
        // MantÃ©m detecÃ§Ã£o local se API falhar
      }
    }
  }

  /// LÃª o cabeÃ§alho do CSV e retorna os nomes das colunas
  List<String> _detectarColunas(List<int>? bytes) {
    if (bytes == null) return [];
    try {
      final texto = String.fromCharCodes(bytes).replaceAll('\uFEFF', '');
      final primeiraLinha = texto.split(RegExp(r'\r?\n')).first;
      final sep = primeiraLinha.contains(';') ? ';' : ',';
      return primeiraLinha
          .split(sep)
          .map((c) => c.trim().replaceAll('"', ''))
          .where((c) => c.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Normaliza string igual ao backend: minÃºsculo, sem acentos, underscore
  String _normalizar(String s) {
    const acentos =
        'Ã Ã¡Ã¢Ã£Ã¤Ã¥Ã¨Ã©ÃªÃ«Ã¬Ã­Ã®Ã¯Ã²Ã³Ã´ÃµÃ¶Ã¹ÃºÃ»Ã¼Ã½Ã¿Ã±Ã§Ã€ÃÃ‚ÃƒÃ„Ã…ÃˆÃ‰ÃŠÃ‹ÃŒÃÃŽÃÃ’Ã“Ã”Ã•Ã–Ã™ÃšÃ›ÃœÃÃ‘Ã‡';
    const semAcento = 'aaaaaaeeeeiiiioooooouuuuyyÃ±cAAAAAAEEEEIIIIOOOOOUUUUYNC';
    var r = s.toLowerCase();
    for (var i = 0; i < acentos.length; i++) {
      r = r.replaceAll(acentos[i], semAcento[i]);
    }
    return r
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  /// Tenta mapear automaticamente as colunas detectadas para os campos conhecidos
  void _autoMapear(
      Map<String, TextEditingController> ctrl, List<String> colunas) {
    // Mapa de sinÃ´nimos: campo â†’ lista de possÃ­veis nomes normalizados
    final sinonimos = <String, List<String>>{
      'colDescricao': [
        'descricao',
        'description',
        'historico',
        'lancamento',
        'titulo',
        'nome',
        'descricao_tipo_de_titulo',
        'descricao_natureza'
      ],
      'colValor': [
        'valor',
        'value',
        'montante',
        'total',
        'vlr',
        'vl',
        'valor_liquido',
        'vlr_do_desdobramento'
      ],
      'colVencimento': [
        'vencimento',
        'data_vencimento',
        'dt_vencimento',
        'datavencimento',
        'due_date',
        'venc',
        'dt_prevista_p_baixa'
      ],
      'colParceiro': [
        'parceiro',
        'fornecedor',
        'cliente',
        'partner',
        'vendor',
        'supplier',
        'nome_parceiro_parceiro',
        'nome_fantasia_empresa'
      ],
      'colFormaPagamento': [
        'forma_pagamento',
        'formapagamento',
        'payment_method',
        'pagamento',
        'forma',
        'tipo_operacao',
        'descricao_tipo_de_operacao'
      ],
      'colStatus': ['status', 'situacao', 'state', 'tipo_de_movimento'],
      'colNumeroNota': [
        'numero_nota',
        'numeronota',
        'nota',
        'nf',
        'nfe',
        'invoice',
        'documento',
        'nro_nota',
        'nro_duplicata'
      ],
      'colObservacao': [
        'observacao',
        'obs',
        'observation',
        'nota',
        'comentario',
        'observacao_padrao'
      ],
      'colDataBaixa': [
        'data_baixa',
        'dt_baixa',
        'databaixa',
        'dtbaixa',
        'data_pagamento',
        'dt_pagamento',
        'data_recebimento',
        'dt_recebimento',
        'data_quitacao'
      ],
      'colValorBaixa': [
        'valor_baixa',
        'vlr_baixa',
        'valor_pago',
        'vlr_pago',
        'valor_recebido',
        'vlr_recebido',
        'valor_liquido',
        'vlr_liquido'
      ],
      'colValorMulta': ['valor_multa', 'vlr_multa', 'multa', 'vl_multa'],
      'colValorJuros': [
        'valor_juros',
        'vlr_juros',
        'juros',
        'vl_juros',
        'juro'
      ],
      'colValorDesconto': [
        'valor_desconto',
        'vlr_desconto',
        'desconto',
        'vl_desconto'
      ],
      'colParceiroDev': [
        'parceiro_dev',
        'parceiro_devedor',
        'devedor',
        'parceiro_rec',
        'recebedor',
        'nome_parceiro_dev'
      ],
      'colContaBancaria': [
        'conta_bancaria',
        'conta',
        'banco',
        'bank_account',
        'conta_id',
        'nome_conta'
      ],
    };

    final colunasNorm = colunas.map((c) => _normalizar(c)).toList();

    for (final entry in sinonimos.entries) {
      final campo = entry.key;
      final candidatos = entry.value;
      for (final candidato in candidatos) {
        final idx = colunasNorm.indexWhere((cn) =>
            cn == candidato ||
            cn.contains(candidato) ||
            candidato.contains(cn));
        if (idx >= 0) {
          ctrl[campo]?.text = colunas[idx]; // usa o nome original da coluna
          break;
        }
      }
    }
  }

  Future<void> _importar(bool isCP) async {
    final arquivo = isCP ? _arquivoCP : _arquivoCR;
    if (arquivo == null || arquivo.bytes == null) return;

    // empId vem do TenantContext (injetado automaticamente por applyToUrl),
    // ou do dropdown quando o usuÃ¡rio nÃ£o tem empresa no contexto.
    final empIdCtx = TenantContext.hasEmpresa
        ? TenantContext.empresaId?.toString()
        : _empresaIdSelecionada;
    final parIdCtx = TenantContext.hasParceiro
        ? TenantContext.parceiroId?.toString()
        : _parceiroIdSelecionado;

    if (empIdCtx == null) {
      _mostrarErro('Selecione uma empresa antes de importar.');
      return;
    }

    setState(() {
      if (isCP) {
        _importandoCP = true;
      } else {
        _importandoCR = true;
      }
    });

    try {
      final ctrl = isCP ? _ctrlCP : _ctrlCR;
      final endpoint = isCP ? 'conta-pagar' : 'conta-receber';

      // Monta URL com todos os parÃ¢metros necessÃ¡rios.
      // empId: se nÃ£o estÃ¡ no TenantContext (applyToUrl nÃ£o injeta), passa manualmente.
      // parId: SEMPRE passa quando disponÃ­vel â€” applyToUrl passa parceiroId/parcId mas
      //         o endpoint de importaÃ§Ã£o usa parId para vincular empresa/parceiro ao registro.
      var url = '${widget.baseUrl}/api/importacao/$endpoint';
      final upsert = isCP ? _upsertCP : _upsertCR;
      {
        final uri = Uri.parse(url);
        final params = Map<String, String>.from(uri.queryParameters);
        if (!TenantContext.hasEmpresa) params['empId'] = empIdCtx;
        // parId: vincula parceiro ao registro importado (independente do TenantContext)
        if (parIdCtx != null) params['parId'] = parIdCtx;
        if (upsert) params['upsert'] = 'true';
        url = uri.replace(queryParameters: params).toString();
      }

      // Apenas campos de mapeamento de colunas vÃ£o no form-data
      final fields = <String, String>{};
      for (final entry in ctrl.entries) {
        if (entry.value.text.trim().isNotEmpty) {
          fields[entry.key] = entry.value.text.trim();
        }
      }

      final resp = await TenantContext.postMultipart(
        url,
        fileBytes: arquivo.bytes!,
        fileName: arquivo.name,
        fileField: 'arquivo',
        fields: fields,
      );

      dynamic body;
      try {
        body = jsonDecode(resp.body);
      } catch (_) {
        body = {'error': resp.body};
      }

      setState(() {
        if (isCP) {
          _resultadoCP = resp.statusCode < 300
              ? body
              : {'error': 'HTTP ${resp.statusCode}: ${resp.body}'};
        } else {
          _resultadoCR = resp.statusCode < 300
              ? body
              : {'error': 'HTTP ${resp.statusCode}: ${resp.body}'};
        }

        // Se 100% ignorado, abre o mapeamento automaticamente para o usuÃ¡rio corrigir
        if (resp.statusCode < 300 && body is Map) {
          final s = body['sucesso'] as int? ?? 0;
          final e = body['erros'] as int? ?? 0;
          final ig = body['ignorados'] as int? ?? 0;
          if (s == 0 && e == 0 && ig > 0) {
            if (isCP) {
              _mapeamentoExpandidoCP = true;
            } else {
              _mapeamentoExpandidoCR = true;
            }
          }
        }
      });
    } catch (e) {
      setState(() {
        if (isCP) {
          _resultadoCP = {'error': e.toString()};
        } else {
          _resultadoCR = {'error': e.toString()};
        }
      });
    } finally {
      setState(() {
        if (isCP) {
          _importandoCP = false;
        } else {
          _importandoCR = false;
        }
      });
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: _primary));
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.upload_file, color: _primary, size: 18),
        SizedBox(width: 8),
        Text('Importacao CSV',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
      ]),
      const SizedBox(height: 10),

      // â”€â”€ SeleÃ§Ã£o de Empresa e Parceiro â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: _border)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Destino da Importacao',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            const Text(
                'Selecione a empresa e/ou parceiro para os lancamentos importados. '
                'Se ja estiver definido pelo login, o campo fica bloqueado.',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 12),
            Row(children: [
              // â”€â”€ Empresa â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(child: _buildDropdownEmpresa()),
              const SizedBox(width: 12),
              // â”€â”€ Parceiro â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(child: _buildDropdownParceiro()),
            ]),
          ]),
        ),
      ),
      const SizedBox(height: 12),

      _importCard(
        isCP: true,
        titulo: 'Importar Contas a Pagar',
        subtitulo:
            'Importa lancamentos de CP a partir de CSV. Cria Parceiros e Formas de Pagamento automaticamente.',
        arquivo: _arquivoCP,
        importando: _importandoCP,
        upsert: _upsertCP,
        resultado: _resultadoCP,
        mapeamentoExpandido: _mapeamentoExpandidoCP,
        onToggleMapeamento: () =>
            setState(() => _mapeamentoExpandidoCP = !_mapeamentoExpandidoCP),
        onToggleUpsert: () => setState(() => _upsertCP = !_upsertCP),
        ctrl: _ctrlCP,
      ),
      const SizedBox(height: 12),
      _importCard(
        isCP: false,
        titulo: 'Importar Contas a Receber',
        subtitulo:
            'Importa lancamentos de CR a partir de CSV. Cria Parceiros e Formas de Pagamento automaticamente.',
        arquivo: _arquivoCR,
        importando: _importandoCR,
        upsert: _upsertCR,
        resultado: _resultadoCR,
        mapeamentoExpandido: _mapeamentoExpandidoCR,
        onToggleMapeamento: () =>
            setState(() => _mapeamentoExpandidoCR = !_mapeamentoExpandidoCR),
        onToggleUpsert: () => setState(() => _upsertCR = !_upsertCR),
        ctrl: _ctrlCR,
      ),
    ]);
  }

  // â”€â”€ Dropdown Empresa â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDropdownEmpresa() {
    final fixo = TenantContext.hasEmpresa;
    final empresaIdCtx = TenantContext.empresaId?.toString();

    // Label do valor fixo (do contexto)
    String? labelFixo;
    if (fixo && empresaIdCtx != null) {
      // Tenta achar o nome na lista carregada; se nÃ£o tiver, mostra o ID
      final found = _empresas.where((e) => e['id'] == empresaIdCtx).firstOrNull;
      labelFixo = found?['nome'] as String? ?? 'Empresa #$empresaIdCtx';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.business, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        const Text('Empresa',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        if (fixo) ...[
          const SizedBox(width: 6),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('do login',
                  style: TextStyle(
                      fontSize: 9,
                      color: _green,
                      fontWeight: FontWeight.bold))),
        ],
      ]),
      const SizedBox(height: 4),
      if (fixo)
        // Campo desabilitado mostrando a empresa do login
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
                child: Text(labelFixo ?? 'Empresa do login',
                    style: const TextStyle(fontSize: 13, color: Colors.grey))),
          ]),
        )
      else
        // Dropdown editÃ¡vel
        _loadingEmpresas
            ? const SizedBox(
                height: 44,
                child: Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _primary))))
            : SearchableDropdownField(
                label: 'Empresa',
                value: _empresaIdSelecionada,
                items: _empresas,
                valueField: 'id',
                displayField: 'nome',
                hintText: 'Selecione a empresa',
                onChanged: (v) {
                  setState(() => _empresaIdSelecionada = v);
                  // Recarrega parceiros filtrados pela empresa selecionada
                  if (!TenantContext.hasParceiro && v != null) {
                    _carregarParceiros(v);
                  }
                },
              ),
    ]);
  }

  // â”€â”€ Dropdown Parceiro â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDropdownParceiro() {
    final fixo = TenantContext.hasParceiro;
    final parceiroIdCtx = TenantContext.parceiroId?.toString();

    String? labelFixo;
    if (fixo && parceiroIdCtx != null) {
      final found =
          _parceiros.where((e) => e['id'] == parceiroIdCtx).firstOrNull;
      labelFixo = found?['nome'] as String? ?? 'Parceiro #$parceiroIdCtx';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.person_outline, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        const Text('Parceiro (opcional)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        if (fixo) ...[
          const SizedBox(width: 6),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
              child: const Text('do login',
                  style: TextStyle(
                      fontSize: 9,
                      color: _green,
                      fontWeight: FontWeight.bold))),
        ],
      ]),
      const SizedBox(height: 4),
      if (fixo)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(6)),
          child: Row(children: [
            const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
                child: Text(labelFixo ?? 'Parceiro do login',
                    style: const TextStyle(fontSize: 13, color: Colors.grey))),
          ]),
        )
      else
        _loadingParceiros
            ? const SizedBox(
                height: 44,
                child: Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _primary))))
            : SearchableDropdownField(
                label: 'Parceiro',
                value: _parceiroIdSelecionado,
                items: _parceiros,
                valueField: 'id',
                displayField: 'nome',
                hintText: 'Nenhum (opcional)',
                nullable: true,
                nullLabel: 'Limpar seleÃ§Ã£o',
                onChanged: (v) => setState(() => _parceiroIdSelecionado = v),
              ),
    ]);
  }

  Widget _importCard({
    required bool isCP,
    required String titulo,
    required String subtitulo,
    required PlatformFile? arquivo,
    required bool importando,
    required bool upsert,
    required Map<String, dynamic>? resultado,
    required bool mapeamentoExpandido,
    required VoidCallback onToggleMapeamento,
    required VoidCallback onToggleUpsert,
    required Map<String, TextEditingController> ctrl,
  }) {
    final cor = isCP ? Colors.indigo.shade700 : Colors.teal.shade700;
    final icone = isCP ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: cor.withValues(alpha: 0.35))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // â”€â”€ CabeÃ§alho â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(children: [
            Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icone, color: cor, size: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitulo,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ])),
          ]),
          const SizedBox(height: 14),

          // â”€â”€ SeleÃ§Ã£o de arquivo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          Row(children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey.shade50),
                child: Row(children: [
                  Icon(Icons.attach_file,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(
                          arquivo != null
                              ? arquivo.name
                              : 'Nenhum arquivo selecionado',
                          style: TextStyle(
                              fontSize: 13,
                              color: arquivo != null
                                  ? Colors.black87
                                  : Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis)),
                  if (arquivo != null) ...[
                    const SizedBox(width: 8),
                    Text('${(arquivo.size / 1024).toStringAsFixed(1)} KB',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ]),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
                onPressed: importando ? null : () => _selecionarArquivo(isCP),
                icon: const Icon(Icons.folder_open, size: 16),
                label: const Text('Selecionar CSV'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: cor,
                    side: BorderSide(color: cor),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12))),
          ]),

          // â”€â”€ Colunas detectadas no CSV â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if ((isCP ? _colunasCP : _colunasCR).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: cor.withValues(alpha: 0.2))),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.table_chart_outlined, size: 13, color: cor),
                      const SizedBox(width: 5),
                      Expanded(
                          child: Text(
                              'Colunas detectadas â€” clique para usar como Descricao:',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cor,
                                  fontWeight: FontWeight.w500))),
                    ]),
                    const SizedBox(height: 6),
                    Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: (isCP ? _colunasCP : _colunasCR)
                            .map((col) => Tooltip(
                                  message:
                                      'Usar "$col" como coluna de Descricao',
                                  child: InkWell(
                                    onTap: () {
                                      // Preenche o campo de descriÃ§Ã£o com o nome desta coluna
                                      ctrl['colDescricao']?.text = col;
                                      // Abre o mapeamento para o usuÃ¡rio ver o que foi preenchido
                                      if (!mapeamentoExpandido)
                                        onToggleMapeamento();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  '"$col" definido como coluna de Descricao'),
                                              duration:
                                                  const Duration(seconds: 2),
                                              backgroundColor: cor));
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                            color: cor.withValues(alpha: 0.08),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: cor.withValues(
                                                    alpha: 0.25))),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(col,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: cor)),
                                              const SizedBox(width: 4),
                                              Icon(Icons.arrow_downward,
                                                  size: 10,
                                                  color: cor.withValues(
                                                      alpha: 0.6)),
                                            ])),
                                  ),
                                ))
                            .toList()),
                  ]),
            ),
          ],
          const SizedBox(height: 10),

          // â”€â”€ Mapeamento de colunas (expansÃ­vel) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          InkWell(
            onTap: onToggleMapeamento,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: cor.withValues(alpha: 0.2))),
              child: Row(children: [
                Icon(Icons.tune, size: 15, color: cor),
                const SizedBox(width: 6),
                Text('Mapeamento de colunas do CSV',
                    style: TextStyle(
                        fontSize: 12, color: cor, fontWeight: FontWeight.w500)),
                const Spacer(),
                Icon(
                    mapeamentoExpandido ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: cor),
              ]),
            ),
          ),
          if (mapeamentoExpandido) ...[
            const SizedBox(height: 10),
            // InstruÃ§Ã£o contextual
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200)),
              child: Row(children: [
                Icon(Icons.info_outline, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(
                        'Informe o nome exato da coluna no seu CSV para cada campo. '
                        'Use os chips acima para preencher rapidamente.',
                        style: TextStyle(
                            fontSize: 11, color: Colors.blue.shade700))),
              ]),
            ),
            const SizedBox(height: 10),
            // Se temos colunas detectadas, mostra dropdown; senÃ£o, campo de texto
            Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _camposMapeamento.map((campo) {
                  final colunas = isCP ? _colunasCP : _colunasCR;
                  return SizedBox(
                    width: 220,
                    child: colunas.isNotEmpty
                        // Dropdown pesquisÃ¡vel com as colunas do CSV
                        ? SearchableDropdownField(
                            label: campo['label'] as String,
                            value: colunas.contains(ctrl[campo['key']]?.text)
                                ? ctrl[campo['key']]?.text
                                : null,
                            items: colunas
                                .map((c) =>
                                    <String, dynamic>{'id': c, 'nome': c})
                                .toList(),
                            valueField: 'id',
                            displayField: 'nome',
                            hintText: 'â€” nÃ£o importar â€”',
                            nullable: true,
                            nullLabel: 'â€” nÃ£o importar â€”',
                            onChanged: (v) => setState(
                                () => ctrl[campo['key']]?.text = v ?? ''),
                          )
                        // Fallback: campo de texto livre
                        : TextFormField(
                            controller: ctrl[campo['key']],
                            decoration: InputDecoration(
                                labelText: campo['label'],
                                labelStyle: const TextStyle(fontSize: 11),
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8)),
                            style: const TextStyle(fontSize: 12)),
                  );
                }).toList()),
          ],
          const SizedBox(height: 12),

          // â”€â”€ OpÃ§Ã£o Upsert â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          InkWell(
            onTap: onToggleUpsert,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                  color: upsert ? Colors.orange.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: upsert ? Colors.orange.shade300 : _border)),
              child: Row(children: [
                Icon(upsert ? Icons.sync_alt : Icons.add_circle_outline,
                    size: 16,
                    color: upsert ? Colors.orange.shade700 : Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          upsert
                              ? 'Modo: Inserir + Atualizar (Upsert)'
                              : 'Modo: Apenas Inserir',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: upsert
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade700)),
                      Text(
                          upsert
                              ? 'Se o Numero de Nota ja existe na empresa, atualiza o registro. Novos sao inseridos.'
                              : 'Sempre insere novos registros. Reimportar pode duplicar.',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey.shade600)),
                    ])),
                Switch(
                    value: upsert,
                    onChanged: (_) => onToggleUpsert(),
                    activeThumbColor: Colors.orange.shade700,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ]),
            ),
          ),
          const SizedBox(height: 10),

          // â”€â”€ BotÃ£o importar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
                onPressed: (arquivo == null || importando)
                    ? null
                    : () => _importar(isCP),
                icon: importando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _white))
                    : const Icon(Icons.upload),
                label: Text(importando ? 'Importando...' : 'Importar'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: cor,
                    foregroundColor: _white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600))),
          ),

          // â”€â”€ Resultado â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
          if (resultado != null) ...[
            const SizedBox(height: 14),
            _buildResultadoImportacao(resultado, cor),
          ],
        ]),
      ),
    );
  }

  Widget _buildResultadoImportacao(Map<String, dynamic> resultado, Color cor) {
    final erro = resultado['error'];
    if (erro != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _primary.withValues(alpha: 0.3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline, color: _primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: SelectableText(erro.toString(),
                  style: const TextStyle(
                      fontSize: 12, color: _primary, fontFamily: 'monospace'))),
        ]),
      );
    }

    final sucesso = resultado['sucesso'] as int? ?? 0;
    final erros = resultado['erros'] as int? ?? 0;
    final ignorados = resultado['ignorados'] as int? ?? 0;
    final total = resultado['total'] as int? ?? (sucesso + erros + ignorados);
    final novosParceiros = resultado['novosParceiros'] as int? ?? 0;
    final novasFormas = resultado['novasFormasPagamento'] as int? ?? 0;
    final detalhes =
        (resultado['detalhes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final colunasCSV = (resultado['colunasCSV'] as List?)?.cast<String>() ?? [];
    final avisoMapeamento = resultado['avisoMapeamento'] as String?;

    // 100% ignorado = mapeamento errado
    final tudo100Ignorado =
        total > 0 && sucesso == 0 && erros == 0 && ignorados == total;
    final temErros = erros > 0 || tudo100Ignorado;
    final corStatus = tudo100Ignorado
        ? _primary
        : (temErros ? Colors.orange.shade700 : _green);

    return Container(
      decoration: BoxDecoration(
          color: corStatus.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: corStatus.withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // â”€â”€ CabeÃ§alho â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: corStatus.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8))),
          child: Row(children: [
            Icon(
                tudo100Ignorado
                    ? Icons.error_outline
                    : (temErros
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle),
                color: corStatus,
                size: 18),
            const SizedBox(width: 8),
            Text(
                tudo100Ignorado
                    ? 'Nenhum registro importado â€” verifique o mapeamento'
                    : 'Importacao concluida',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: corStatus)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.copy, size: 15),
                tooltip: 'Copiar resultado',
                color: corStatus,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  final txt =
                      'Total: $total | Sucesso: $sucesso | Erros: $erros | Ignorados: $ignorados${novosParceiros > 0 ? ' | Parceiros novos: $novosParceiros' : ''}${novasFormas > 0 ? ' | Formas novas: $novasFormas' : ''}';
                  Clipboard.setData(ClipboardData(text: txt));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Copiado'),
                      duration: Duration(seconds: 2)));
                }),
          ]),
        ),

        // â”€â”€ Aviso de mapeamento incorreto â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (avisoMapeamento != null) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _primary.withValues(alpha: 0.3))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded,
                  color: _primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: SelectableText(avisoMapeamento,
                      style: const TextStyle(
                          fontSize: 11, color: _primary, height: 1.5))),
            ]),
          ),
        ],

        // â”€â”€ Chips de contagem â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Wrap(spacing: 10, runSpacing: 8, children: [
            _chip('Total', total, Colors.grey.shade600),
            _chip('Importados', sucesso, _green),
            if (erros > 0) _chip('Erros', erros, _primary),
            if (ignorados > 0)
              _chip('Ignorados', ignorados, Colors.orange.shade700),
            if (novosParceiros > 0)
              _chip('Parceiros novos', novosParceiros, Colors.blue.shade700),
            if (novasFormas > 0)
              _chip('Formas novas', novasFormas, Colors.purple.shade700),
          ]),
        ),

        // â”€â”€ Avisos de criaÃ§Ã£o automÃ¡tica â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (novosParceiros > 0) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade300)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.amber.shade800, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      '$novosParceiros parceiro(s) criado(s) automaticamente â€” verifique e complete o cadastro',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade900,
                          height: 1.5))),
            ]),
          ),
        ],
        if (novasFormas > 0) ...[
          Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.shade300)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, color: Colors.orange.shade800, size: 16),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                      '$novasFormas forma(s) de pagamento criada(s) automaticamente â€” verifique e complete o cadastro',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade900,
                          height: 1.5))),
            ]),
          ),
        ],

        // â”€â”€ Colunas detectadas no CSV (do backend) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (colunasCSV.isNotEmpty) ...[
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: Row(children: [
              Icon(Icons.table_chart_outlined,
                  size: 13, color: Colors.grey.shade600),
              const SizedBox(width: 5),
              Text('Colunas lidas do CSV: ${colunasCSV.join(', ')}',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic)),
            ]),
          ),
        ],

        // â”€â”€ Detalhes (erros e ignorados) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (detalhes.any((d) => d['status'] != 'sucesso')) ...[
          const Divider(height: 1),
          Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Row(children: [
                Text('Detalhes de erros e ignorados',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700)),
                const SizedBox(width: 8),
                // Mostra sÃ³ as primeiras 20 linhas para nÃ£o travar
                if (detalhes.where((d) => d['status'] != 'sucesso').length > 20)
                  Text(
                      '(mostrando primeiras 20 de ${detalhes.where((d) => d['status'] != 'sucesso').length})',
                      style:
                          TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                const Spacer(),
                // â”€â”€ BotÃ£o copiar todos os erros â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                TextButton.icon(
                    onPressed: () {
                      final todos = detalhes
                          .where((d) => d['status'] != 'sucesso')
                          .toList();
                      final texto = todos
                          .map((d) =>
                              'Linha ${d['linha']} [${d['status']}]: ${d['mensagem']}')
                          .join('\n');
                      Clipboard.setData(ClipboardData(text: texto));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${todos.length} erros copiados'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: Colors.grey.shade700));
                    },
                    icon: const Icon(Icons.copy_all, size: 14),
                    label: Text(
                        'Copiar todos (${detalhes.where((d) => d['status'] != 'sucesso').length})',
                        style: const TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
              ])),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            child: Scrollbar(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                itemCount: detalhes
                    .where((d) => d['status'] != 'sucesso')
                    .take(20)
                    .length,
                itemBuilder: (_, i) {
                  final d = detalhes
                      .where((d) => d['status'] != 'sucesso')
                      .take(20)
                      .toList()[i];
                  final st = d['status'] as String? ?? '';
                  final corD = st == 'erro' ? _primary : Colors.orange.shade700;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(st == 'erro' ? Icons.cancel : Icons.info_outline,
                              size: 13, color: corD),
                          const SizedBox(width: 6),
                          Text('Linha ${d['linha']}: ',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: corD)),
                          Expanded(
                              child: SelectableText(
                                  d['mensagem']?.toString() ?? '',
                                  style: TextStyle(fontSize: 11, color: corD))),
                        ]),
                  );
                },
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _chip(String label, int valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cor.withValues(alpha: 0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$valor',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: cor)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: cor)),
      ]),
    );
  }
}

enum _ImportacaoCadastroTipo {
  empresa,
  parceiros,
  funcionarios,
  loginsClientes,
  planos
}

class _CadastroImportField {
  final String key;
  final String label;
  final List<String> sinonimos;

  const _CadastroImportField(this.key, this.label, this.sinonimos);
}

class _CadastroImportConfig {
  final _ImportacaoCadastroTipo tipo;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_CadastroImportField> campos;

  const _CadastroImportConfig({
    required this.tipo,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.campos,
  });
}

class _ImportacaoCadastrosSection extends StatefulWidget {
  final String baseUrl;
  const _ImportacaoCadastrosSection({required this.baseUrl});

  @override
  State<_ImportacaoCadastrosSection> createState() =>
      _ImportacaoCadastrosSectionState();
}

class _ImportacaoCadastrosSectionState
    extends State<_ImportacaoCadastrosSection> {
  final Map<_ImportacaoCadastroTipo, PlatformFile?> _arquivos = {};
  final Map<_ImportacaoCadastroTipo, Map<String, TextEditingController>> _ctrl =
      {};
  final Map<_ImportacaoCadastroTipo, List<String>> _colunas = {};
  final Map<_ImportacaoCadastroTipo, bool> _loading = {};
  final Map<_ImportacaoCadastroTipo, bool> _atualizar = {};
  final Map<_ImportacaoCadastroTipo, Map<String, dynamic>?> _resultados = {};
  final Map<_ImportacaoCadastroTipo, String?> _avisosArquivo = {};
  final Map<_ImportacaoCadastroTipo, List<Map<String, String>>> _previews = {};

  List<Map<String, dynamic>> _empresas = [];
  List<Map<String, dynamic>> _parceiros = [];
  String? _empresaIdSelecionada;
  String? _parceiroIdSelecionado;
  bool _loadingEmpresas = false;
  bool _loadingParceiros = false;

  late final List<_CadastroImportConfig> _configs = [
    _CadastroImportConfig(
      tipo: _ImportacaoCadastroTipo.empresa,
      title: 'Importar Empresas',
      subtitle: 'Cria ou atualiza empresas a partir do CSV.',
      icon: Icons.business_outlined,
      color: _primary,
      campos: const [
        _CadastroImportField('external_id', 'External ID',
            ['external_id', 'codigo', 'cod_empresa']),
        _CadastroImportField('nome', 'Nome Fantasia *',
            ['nome', 'nome_fantasia', 'fantasia', 'empresa']),
        _CadastroImportField('razaoSocial', 'Razao Social',
            ['razao_social', 'razaosocial', 'razo_social']),
        _CadastroImportField('cnpj', 'CNPJ', ['cnpj', 'cpf_cnpj', 'documento']),
        _CadastroImportField('email', 'Email', ['email', 'e_mail']),
        _CadastroImportField(
            'telefone', 'Telefone', ['telefone', 'fone', 'celular']),
        _CadastroImportField('rua', 'Rua', ['rua', 'logradouro', 'endereco']),
        _CadastroImportField('numero', 'Numero', ['numero', 'nro', 'num']),
        _CadastroImportField('bairro', 'Bairro', ['bairro']),
        _CadastroImportField('cidade', 'Cidade', ['cidade', 'municipio']),
        _CadastroImportField('estado', 'Estado', ['estado', 'uf']),
        _CadastroImportField('cep', 'CEP', ['cep']),
        _CadastroImportField('regime_codigo', 'Regime',
            ['regime_codigo', 'regime', 'regime_tributario', 'tributacao']),
        _CadastroImportField(
            'ambiente', 'Ambiente', ['ambiente', 'sefaz_ambiente']),
        _CadastroImportField(
            'app_id', 'App ID', ['app_id', 'aplicativo_id', 'aplicativo']),
      ],
    ),
    _CadastroImportConfig(
      tipo: _ImportacaoCadastroTipo.parceiros,
      title: 'Importar Parceiros',
      subtitle:
          'Importa clientes, fornecedores ou parceiros vinculados a empresa selecionada.',
      icon: Icons.groups_2_outlined,
      color: Colors.teal.shade700,
      campos: const [
        _CadastroImportField('external_id', 'External ID',
            ['external_id', 'codigo', 'cod_parceiro']),
        _CadastroImportField('empresa_id', 'Empresa ID',
            ['empresa_id', 'empresa_external_id', 'cod_empresa', 'id_empresa']),
        _CadastroImportField(
            'nome', 'Nome *', ['nome', 'cliente', 'parceiro', 'nome_fantasia']),
        _CadastroImportField('razaoSocial', 'Razao Social',
            ['razao_social', 'razaosocial', 'razo_social']),
        _CadastroImportField(
            'cpf', 'CPF/CNPJ', ['cpf', 'cnpj', 'cpf_cnpj', 'documento']),
        _CadastroImportField('codProdutor', 'Codigo Produtor',
            ['cod_produtor', 'codprodutor', 'codigo_produtor']),
        _CadastroImportField('email', 'Email', ['email', 'e_mail']),
        _CadastroImportField('telefone1', 'Telefone',
            ['telefone', 'telefone1', 'fone', 'celular']),
        _CadastroImportField('rua', 'Rua', ['rua', 'logradouro', 'endereco']),
        _CadastroImportField('bairro', 'Bairro', ['bairro']),
        _CadastroImportField('cidade', 'Cidade', ['cidade', 'municipio']),
        _CadastroImportField('estado', 'Estado', ['estado', 'uf']),
        _CadastroImportField('cep', 'CEP', ['cep']),
        _CadastroImportField('numero', 'Numero', ['numero', 'nro', 'num']),
        _CadastroImportField('ie', 'IE', ['ie', 'inscricao_estadual']),
        _CadastroImportField('incrMun', 'Insc. Municipal',
            ['incr_mun', 'inscricao_municipal', 'im']),
        _CadastroImportField('regime_codigo', 'Regime',
            ['regime_codigo', 'regime', 'regime_tributario', 'tributacao']),
        _CadastroImportField('status', 'Status', ['status', 'situacao']),
        _CadastroImportField('tipoCliente', 'Tipo Cliente',
            ['tipo_cliente', 'tipo', 'classificacao']),
        _CadastroImportField('tipo_parceiro_id', 'Tipo Parceiro ID',
            ['tipo_parceiro_id', 'tipo_parceiro', 'tipoParceiro', 'perfil']),
        _CadastroImportField('valorMensal', 'Valor Mensal',
            ['valor_mensal', 'mensalidade', 'valor']),
      ],
    ),
    _CadastroImportConfig(
      tipo: _ImportacaoCadastroTipo.funcionarios,
      title: 'Importar Funcionarios e Logins',
      subtitle:
          'Cria login, funcionario e vincula o funcionario ao login criado.',
      icon: Icons.badge_outlined,
      color: Colors.blue.shade700,
      campos: const [
        _CadastroImportField('empresa_id', 'Empresa ID',
            ['empresa_id', 'empresa_external_id', 'cod_empresa', 'id_empresa']),
        _CadastroImportField(
            'nome', 'Nome *', ['nome', 'funcionario', 'colaborador']),
        _CadastroImportField('cpf', 'CPF *', ['cpf', 'cpf_cnpj', 'documento']),
        _CadastroImportField(
            'email', 'Email/Login *', ['email', 'login', 'usuario', 'e_mail']),
        _CadastroImportField(
            'setor', 'Setor', ['setor', 'departamento', 'area']),
        _CadastroImportField(
            'tipoLogin', 'Tipo Login', ['tipo_login', 'tipologin', 'perfil']),
        _CadastroImportField(
            'senha', 'Senha Padrao', ['senha', 'senha_padrao', 'password']),
        _CadastroImportField('ativo', 'Ativo', ['ativo', 'status', 'situacao']),
      ],
    ),
    _CadastroImportConfig(
      tipo: _ImportacaoCadastroTipo.loginsClientes,
      title: 'Importar Logins de Clientes',
      subtitle:
          'Cria ou atualiza logins de clientes vinculando pelo CNPJ do parceiro.',
      icon: Icons.manage_accounts_outlined,
      color: Colors.indigo.shade700,
      campos: const [
        _CadastroImportField('external_id', 'External ID',
            ['external_id', 'codigo', 'cod_parceiro']),
        _CadastroImportField('empresa_id', 'Empresa ID',
            ['empresa_id', 'empresa_external_id', 'cod_empresa', 'id_empresa']),
        _CadastroImportField('parceiro_cnpj', 'CNPJ Cliente *',
            ['parceiro_cnpj', 'codigo_cliente', 'cnpj', 'cpf', 'documento']),
        _CadastroImportField('codigo_faturamento', 'Codigo Faturamento',
            ['codigo_faturamento', 'cod_faturamento']),
        _CadastroImportField(
            'nome', 'Nome *', ['nome', 'cliente', 'parceiro', 'razao_social']),
        _CadastroImportField(
            'email', 'Email/Login *', ['email', 'login', 'usuario', 'e_mail']),
        _CadastroImportField(
            'senha', 'Senha Padrao', ['senha', 'senha_padrao', 'password']),
        _CadastroImportField(
            'tipoLogin', 'Tipo Login', ['tipo_login', 'tipologin', 'perfil']),
        _CadastroImportField(
            'app_id', 'App ID', ['app_id', 'aplicativo_id', 'aplicativo']),
      ],
    ),
    _CadastroImportConfig(
      tipo: _ImportacaoCadastroTipo.planos,
      title: 'Importar Planos',
      subtitle:
          'Importa planos comuns ou planos da academia conforme a coluna tipo_plano.',
      icon: Icons.workspace_premium_outlined,
      color: Colors.deepPurple.shade600,
      campos: const [
        _CadastroImportField('empresa_id', 'Empresa ID',
            ['empresa_id', 'empresa_external_id', 'cod_empresa', 'id_empresa']),
        _CadastroImportField(
            'parceiro_id', 'Parceiro ID', ['parceiro_id', 'cliente_id']),
        _CadastroImportField('cnpj', 'CNPJ Cliente',
            ['cnpj', 'cpf_cnpj', 'documento', 'cpf', 'cod_produtor']),
        _CadastroImportField('codigo_faturamento', 'Codigo Faturamento',
            ['codigo_faturamento', 'cod_faturamento', 'codigo']),
        _CadastroImportField('nome_cliente', 'Cliente',
            ['nome_faturamento', 'cliente', 'parceiro', 'razao_social']),
        _CadastroImportField('nome', 'Nome *',
            ['nome', 'plano', 'nome_plano', 'servico', 'nome_faturamento']),
        _CadastroImportField(
            'descricao', 'Descricao', ['descricao', 'description']),
        _CadastroImportField('valor', 'Valor',
            ['valor', 'valor_mensal', 'preco', 'mensalidade']),
        _CadastroImportField(
            'dt_inicio', 'Data Inicio', ['dt_inicio', 'data_inicio', 'inicio']),
        _CadastroImportField(
            'dt_final', 'Data Final', ['dt_final', 'data_final', 'fim']),
        _CadastroImportField(
            'qtd_aula', 'Qtd. Aula', ['qtd_aula', 'qtd_aulas', 'aulas']),
        _CadastroImportField(
            'cod_personal', 'Cod. Personal', ['cod_personal', 'personal_id']),
        _CadastroImportField(
            'cod_academia', 'Cod. Academia', ['cod_academia', 'academia_id']),
        _CadastroImportField(
            'tipo_plano', 'Tipo Plano', ['tipo_plano', 'tipo', 'origem']),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final config in _configs) {
      _ctrl[config.tipo] = {
        for (final campo in config.campos) campo.key: TextEditingController()
      };
      _atualizar[config.tipo] = false;
      _loading[config.tipo] = false;
    }
    _carregarEmpresas();
  }

  @override
  void dispose() {
    for (final mapa in _ctrl.values) {
      for (final controller in mapa.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _carregarEmpresas() async {
    setState(() => _loadingEmpresas = true);
    try {
      final appId = TenantContext.aplicativoId;
      final url =
          '${widget.baseUrl}/api/empresa${appId != null ? '?codApp=$appId' : ''}';
      final resp =
          await http.get(Uri.parse(url), headers: TenantContext.headers);
      if (resp.statusCode == 200) {
        final lista = _extractList(jsonDecode(resp.body));
        if (mounted) {
          setState(() {
            _empresas = lista
                .map<Map<String, dynamic>>((e) => {
                      'id': e['id']?.toString() ?? '',
                      'nome': e['nome']?.toString() ??
                          e['razaoSocial']?.toString() ??
                          '',
                    })
                .where((e) => e['id']!.isNotEmpty)
                .toList();
            final contexto = TenantContext.empresaId?.toString();
            if (_empresaIdSelecionada == null &&
                contexto != null &&
                _empresas.any((e) => e['id'] == contexto)) {
              _empresaIdSelecionada = contexto;
            }
          });
          if (_empresaIdSelecionada != null) {
            _carregarParceiros(_empresaIdSelecionada);
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingEmpresas = false);
  }

  Future<void> _carregarParceiros(String? empresaId) async {
    if (empresaId == null || empresaId.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _parceiros = [];
          _parceiroIdSelecionado = null;
        });
      }
      return;
    }
    setState(() {
      _loadingParceiros = true;
      _parceiros = [];
      _parceiroIdSelecionado = null;
    });
    try {
      final resp = await http.get(
        Uri.parse('${widget.baseUrl}/api/parceiro/empresa/$empresaId'),
        headers: TenantContext.headers,
      );
      if (resp.statusCode == 200) {
        final lista = _extractList(jsonDecode(resp.body));
        if (mounted) {
          setState(() {
            _parceiros = lista
                .map<Map<String, dynamic>>((e) => {
                      'id': e['id']?.toString() ?? '',
                      'nome': e['nome']?.toString() ??
                          e['razaoSocial']?.toString() ??
                          '',
                      'razaoSocial': e['razaoSocial']?.toString() ?? '',
                      'cpf': e['cpf']?.toString() ?? '',
                      'codProdutor': e['codProdutor']?.toString() ?? '',
                      'valorMensal': e['valorMensal']?.toString() ?? '',
                    })
                .where((e) => e['id']!.isNotEmpty)
                .toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingParceiros = false);
  }

  Future<void> _selecionarArquivo(_ImportacaoCadastroTipo tipo) async {
    try {
      if (!kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('Importacao de arquivo so disponivel no navegador.')),
        );
        return;
      }
      final result =
          await pickAndReadFile(accept: '.csv,.txt,text/csv,text/plain');
      if (result == null || result.bytes.isEmpty) return;

      final arquivo = PlatformFile(
          name: result.name,
          size: result.size,
          bytes: Uint8List.fromList(result.bytes));
      _aplicarArquivoSelecionado(tipo, arquivo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Falha ao selecionar arquivo: $e'),
          backgroundColor: Colors.red.shade700,
        ));
      }
      return;
    }
  }

  void _aplicarArquivoSelecionado(
      _ImportacaoCadastroTipo tipo, PlatformFile arquivo) {
    final colunas = _detectarColunas(arquivo.bytes);
    final preview = _previewCsv(arquivo, 3);
    final aviso = arquivo.bytes == null
        ? 'Arquivo selecionado, mas o conteÃºdo nÃ£o veio para leitura. Selecione novamente ou use um CSV menor.'
        : colunas.isEmpty
            ? 'Arquivo selecionado, mas nÃ£o consegui detectar o cabeÃ§alho. Confira se Ã© CSV texto com a primeira linha contendo os nomes das colunas.'
            : null;
    setState(() {
      _arquivos[tipo] = arquivo;
      _colunas[tipo] = colunas;
      _resultados[tipo] = null;
      _avisosArquivo[tipo] = aviso;
      _previews[tipo] = preview;
      _autoMapear(tipo, colunas);
    });
    if (aviso != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(aviso),
        backgroundColor: Colors.orange.shade800,
      ));
    }
  }

  List<String> _detectarColunas(List<int>? bytes) {
    if (bytes == null) return [];
    try {
      final texto =
          utf8.decode(bytes, allowMalformed: true).replaceAll('\uFEFF', '');
      final primeiraLinha = texto
          .split(RegExp(r'\r?\n'))
          .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
      if (primeiraLinha.isEmpty) return [];
      final sep = _separatorFor(primeiraLinha);
      return _splitCsvLine(primeiraLinha, sep)
          .map((c) => c.trim())
          .where((c) => c.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, String>> _parseCsv(PlatformFile arquivo) {
    final bytes = arquivo.bytes;
    if (bytes == null) {
      throw Exception(
          'O arquivo selecionado nÃ£o foi carregado para memÃ³ria. Selecione o CSV novamente.');
    }
    final texto =
        utf8.decode(bytes, allowMalformed: true).replaceAll('\uFEFF', '');
    final linhas = texto
        .split(RegExp(r'\r?\n'))
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (linhas.isEmpty) return [];

    final sep = _separatorFor(linhas.first);
    final headers =
        _splitCsvLine(linhas.first, sep).map((h) => h.trim()).toList();
    final rows = <Map<String, String>>[];

    for (var i = 1; i < linhas.length; i++) {
      final valores = _splitCsvLine(linhas[i], sep);
      final row = <String, String>{};
      for (var c = 0; c < headers.length; c++) {
        row[headers[c]] = c < valores.length ? valores[c].trim() : '';
      }
      if (row.values.any((v) => v.trim().isNotEmpty)) rows.add(row);
    }
    return rows;
  }

  List<Map<String, String>> _previewCsv(PlatformFile arquivo, int maxRows) {
    try {
      return _parseCsv(arquivo).take(maxRows).toList();
    } catch (_) {
      return [];
    }
  }

  String _separatorFor(String line) {
    final semicolon = ';'.allMatches(line).length;
    final comma = ','.allMatches(line).length;
    return semicolon >= comma ? ';' : ',';
  }

  List<String> _splitCsvLine(String line, String sep) {
    final out = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (quoted && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (char == sep && !quoted) {
        out.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    out.add(buffer.toString());
    return out;
  }

  String _normalizar(String value) {
    var r = value.toLowerCase().trim();
    const mapa = {
      'Ã¡': 'a',
      'Ã ': 'a',
      'Ã¢': 'a',
      'Ã£': 'a',
      'Ã¤': 'a',
      'Ã©': 'e',
      'Ã¨': 'e',
      'Ãª': 'e',
      'Ã«': 'e',
      'Ã­': 'i',
      'Ã¬': 'i',
      'Ã®': 'i',
      'Ã¯': 'i',
      'Ã³': 'o',
      'Ã²': 'o',
      'Ã´': 'o',
      'Ãµ': 'o',
      'Ã¶': 'o',
      'Ãº': 'u',
      'Ã¹': 'u',
      'Ã»': 'u',
      'Ã¼': 'u',
      'Ã§': 'c',
      'Ã±': 'n',
    };
    mapa.forEach((a, b) => r = r.replaceAll(a, b));
    return r
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  void _autoMapear(_ImportacaoCadastroTipo tipo, List<String> colunas) {
    final config = _config(tipo);
    final normalizadas = {
      for (final coluna in colunas) _normalizar(coluna): coluna,
    };
    final controllers = _ctrl[tipo]!;

    for (final campo in config.campos) {
      final candidatos = <String>{
        _normalizar(campo.key),
        ...campo.sinonimos.map(_normalizar)
      };
      for (final candidato in candidatos) {
        final coluna = normalizadas[candidato];
        if (coluna != null) {
          controllers[campo.key]?.text = coluna;
          break;
        }
      }
    }
  }

  Future<void> _importar(_ImportacaoCadastroTipo tipo) async {
    final arquivo = _arquivos[tipo];
    if (arquivo == null) return;

    setState(() => _loading[tipo] = true);
    final detalhes = <Map<String, dynamic>>[];
    var sucesso = 0;
    var erros = 0;
    var ignorados = 0;
    var total = 0;
    int? ultimoIdSalvo;

    try {
      final rows = _parseCsv(arquivo);
      total = rows.length;
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        final linha = i + 2;
        try {
          if (_linhaVazia(row)) {
            ignorados++;
            detalhes.add({
              'linha': linha,
              'status': 'ignorado',
              'mensagem': 'Linha vazia'
            });
            continue;
          }

          final id = await _importarLinha(tipo, row);
          if (id != null) ultimoIdSalvo = id;
          sucesso++;
          detalhes.add({
            'linha': linha,
            'status': 'sucesso',
            'mensagem':
                id != null ? 'Registro salvo com ID $id' : 'Registro salvo',
          });
        } catch (e) {
          erros++;
          detalhes.add(
              {'linha': linha, 'status': 'erro', 'mensagem': e.toString()});
        }
      }
    } catch (e) {
      erros++;
      detalhes.add({'linha': 0, 'status': 'erro', 'mensagem': e.toString()});
    }

    if (mounted) {
      setState(() {
        _loading[tipo] = false;
        if (tipo == _ImportacaoCadastroTipo.empresa && ultimoIdSalvo != null) {
          _empresaIdSelecionada = ultimoIdSalvo.toString();
        }
        _resultados[tipo] = {
          'total': total,
          'sucesso': sucesso,
          'erros': erros,
          'ignorados': ignorados,
          'detalhes': detalhes,
          'arquivo': arquivo.name,
        };
      });
      if (tipo == _ImportacaoCadastroTipo.empresa && ultimoIdSalvo != null) {
        _carregarEmpresas();
      }
    }
  }

  Future<int?> _importarLinha(
      _ImportacaoCadastroTipo tipo, Map<String, String> row) {
    switch (tipo) {
      case _ImportacaoCadastroTipo.empresa:
        return _importarEmpresa(row);
      case _ImportacaoCadastroTipo.parceiros:
        return _importarParceiro(row);
      case _ImportacaoCadastroTipo.funcionarios:
        return _importarFuncionarioLogin(row);
      case _ImportacaoCadastroTipo.loginsClientes:
        return _importarLoginCliente(row);
      case _ImportacaoCadastroTipo.planos:
        return _importarPlano(row);
    }
  }

  Future<int?> _importarEmpresa(Map<String, String> row) async {
    final nome = _valor(row, _ImportacaoCadastroTipo.empresa, 'nome');
    if (nome.isEmpty) throw Exception('Nome fantasia obrigatorio');

    final cnpj = _digits(_valor(row, _ImportacaoCadastroTipo.empresa, 'cnpj'));
    final regimeId = _regimeId(
        _valor(row, _ImportacaoCadastroTipo.empresa, 'regime_codigo'));
    final appId =
        _toInt(_valor(row, _ImportacaoCadastroTipo.empresa, 'app_id')) ??
            TenantContext.aplicativoId ??
            1;

    final createPayload = _compact({
      'nome': nome,
      'razaoSocial':
          _valor(row, _ImportacaoCadastroTipo.empresa, 'razaoSocial'),
      'email': _valor(row, _ImportacaoCadastroTipo.empresa, 'email'),
      'telefone': _valor(row, _ImportacaoCadastroTipo.empresa, 'telefone'),
      'rua': _valor(row, _ImportacaoCadastroTipo.empresa, 'rua'),
      'numero': _valor(row, _ImportacaoCadastroTipo.empresa, 'numero'),
      'cep': _digits(_valor(row, _ImportacaoCadastroTipo.empresa, 'cep')),
      'centroCustoObrigatorio': false,
    });

    final updatePayload = _compact({
      'nome': nome,
      'razaoSocial':
          _valor(row, _ImportacaoCadastroTipo.empresa, 'razaoSocial'),
      'cnpj': cnpj,
      'email': _valor(row, _ImportacaoCadastroTipo.empresa, 'email'),
      'telefone': _valor(row, _ImportacaoCadastroTipo.empresa, 'telefone'),
      'rua': _valor(row, _ImportacaoCadastroTipo.empresa, 'rua'),
      'numero': _valor(row, _ImportacaoCadastroTipo.empresa, 'numero'),
      'bairro': _valor(row, _ImportacaoCadastroTipo.empresa, 'bairro'),
      'cep': _digits(_valor(row, _ImportacaoCadastroTipo.empresa, 'cep')),
      'ambiente':
          _ambiente(_valor(row, _ImportacaoCadastroTipo.empresa, 'ambiente')),
      'regime': regimeId != null ? {'id': regimeId} : null,
      'aplicativo': {'id': appId},
      'centroCustoObrigatorio': false,
    });

    final atualizar = _atualizar[_ImportacaoCadastroTipo.empresa] == true;
    final existentePorCnpj = cnpj.isNotEmpty
        ? await _buscarExistente('${widget.baseUrl}/api/empresa', 'cnpj', cnpj)
        : null;
    if (existentePorCnpj != null && !atualizar) {
      throw Exception(
          'CNPJ $cnpj ja existe no cadastro de empresas. Ative "Atualizar se existir" para atualizar.');
    }
    final existente = existentePorCnpj ??
        (atualizar
            ? await _buscarExistente(
                '${widget.baseUrl}/api/empresa', 'nome', nome)
            : null);

    if (existente != null) {
      await _put('${widget.baseUrl}/api/empresa/update/$existente',
          {'id': existente, ...updatePayload});
      return existente;
    }

    final body = await _post('${widget.baseUrl}/api/empresa', createPayload);
    final id = _extractId(body);
    if (id == null)
      throw Exception(
          'Empresa salva, mas a API nao retornou o ID para atualizar e selecionar o destino.');
    await _put('${widget.baseUrl}/api/empresa/update/$id',
        {'id': id, ...updatePayload});
    return id;
  }

  Future<int?> _importarParceiro(Map<String, String> row) async {
    final nome = _valor(row, _ImportacaoCadastroTipo.parceiros, 'nome');
    if (nome.isEmpty) throw Exception('Nome do parceiro obrigatorio');

    final empresaId = _empresaId(row, _ImportacaoCadastroTipo.parceiros);
    if (empresaId == null)
      throw Exception(
          'Selecione a empresa destino ou informe empresa_id no CSV');

    final documento =
        _digits(_valor(row, _ImportacaoCadastroTipo.parceiros, 'cpf'));
    final codProdutor =
        _valor(row, _ImportacaoCadastroTipo.parceiros, 'codProdutor');
    final documentoDuplicidade =
        documento.isNotEmpty ? documento : _digits(codProdutor);
    final tipoParceiroId = _toInt(_valor(
            row, _ImportacaoCadastroTipo.parceiros, 'tipo_parceiro_id')) ??
        1;
    final regimeId = _regimeId(
        _valor(row, _ImportacaoCadastroTipo.parceiros, 'regime_codigo'));
    final status =
        _status(_valor(row, _ImportacaoCadastroTipo.parceiros, 'status'));

    final payload = _compact({
      'nome': nome,
      'cpf': documento,
      'codProdutor': codProdutor,
      'email': _valor(row, _ImportacaoCadastroTipo.parceiros, 'email'),
      'telefone1': _valor(row, _ImportacaoCadastroTipo.parceiros, 'telefone1'),
      'razao_social':
          _valor(row, _ImportacaoCadastroTipo.parceiros, 'razaoSocial'),
      'incr_mun': _valor(row, _ImportacaoCadastroTipo.parceiros, 'incrMun'),
      'ie': _valor(row, _ImportacaoCadastroTipo.parceiros, 'ie'),
      'rua': _valor(row, _ImportacaoCadastroTipo.parceiros, 'rua'),
      'bairro': _valor(row, _ImportacaoCadastroTipo.parceiros, 'bairro'),
      'cidade': _valor(row, _ImportacaoCadastroTipo.parceiros, 'cidade'),
      'estado': _valor(row, _ImportacaoCadastroTipo.parceiros, 'estado'),
      'cep': _digits(_valor(row, _ImportacaoCadastroTipo.parceiros, 'cep')),
      'numero': _valor(row, _ImportacaoCadastroTipo.parceiros, 'numero'),
      'status': status,
      'tipo_cliente':
          _valor(row, _ImportacaoCadastroTipo.parceiros, 'tipoCliente')
                  .isNotEmpty
              ? _valor(row, _ImportacaoCadastroTipo.parceiros, 'tipoCliente')
              : 'CLIENTE',
      'empresa': {'id': empresaId},
      'regime': regimeId != null ? {'id': regimeId} : null,
      'tipos_parceiro': [
        {'id': tipoParceiroId}
      ],
      'valor_mensal':
          _money(_valor(row, _ImportacaoCadastroTipo.parceiros, 'valorMensal')),
    });

    final atualizar = _atualizar[_ImportacaoCadastroTipo.parceiros] == true;
    final existentePorDocumento = documentoDuplicidade.isNotEmpty
        ? await _buscarExistente(
            '${widget.baseUrl}/api/parceiro/empresa/$empresaId',
            documento.isNotEmpty ? 'cpf' : 'codProdutor',
            documentoDuplicidade)
        : null;
    if (existentePorDocumento != null && !atualizar) {
      throw Exception(
          'CPF/CNPJ $documentoDuplicidade ja existe para a empresa destino. Ative "Atualizar se existir" para atualizar.');
    }
    final existente = existentePorDocumento ??
        (atualizar
            ? await _buscarExistente(
                '${widget.baseUrl}/api/parceiro/empresa/$empresaId',
                'nome',
                nome)
            : null);

    if (existente != null) {
      await _put('${widget.baseUrl}/api/parceiro/update/$existente',
          {'id': existente, ...payload});
      return existente;
    }

    final body = await _post('${widget.baseUrl}/api/parceiro/insert', payload);
    return _extractId(body);
  }

  Future<int?> _importarFuncionarioLogin(Map<String, String> row) async {
    final nome = _valor(row, _ImportacaoCadastroTipo.funcionarios, 'nome');
    final email = _valor(row, _ImportacaoCadastroTipo.funcionarios, 'email');
    final cpf =
        _digits(_valor(row, _ImportacaoCadastroTipo.funcionarios, 'cpf'));
    if (nome.isEmpty) throw Exception('Nome do funcionario obrigatorio');
    if (email.isEmpty) throw Exception('Email/login obrigatorio');
    if (cpf.isEmpty) throw Exception('CPF obrigatorio');

    final empresaId = _empresaId(row, _ImportacaoCadastroTipo.funcionarios);
    if (empresaId == null)
      throw Exception(
          'Selecione a empresa destino ou informe empresa_id no CSV');

    final tipoLogin =
        _valor(row, _ImportacaoCadastroTipo.funcionarios, 'tipoLogin')
                .isNotEmpty
            ? _valor(row, _ImportacaoCadastroTipo.funcionarios, 'tipoLogin')
            : 'APP_ABRACO';
    final senha =
        _valor(row, _ImportacaoCadastroTipo.funcionarios, 'senha').isNotEmpty
            ? _valor(row, _ImportacaoCadastroTipo.funcionarios, 'senha')
            : '123456';
    final ativo = _boolOrNull(
            _valor(row, _ImportacaoCadastroTipo.funcionarios, 'ativo')) ??
        true;

    final loginPayload = _compact({
      'email': email,
      'senha': senha,
      'nome': nome,
      'cpfCnpj': cpf,
      'tipoLogin': tipoLogin,
      'empresa': {'id': empresaId},
      'aplicativo': {'id': TenantContext.aplicativoId ?? 1},
    });

    final atualizar = _atualizar[_ImportacaoCadastroTipo.funcionarios] == true;
    var loginId = atualizar
        ? await _buscarExistente(
            '${widget.baseUrl}/api/logins?empId=$empresaId', 'email', email)
        : null;
    if (loginId != null) {
      await _put('${widget.baseUrl}/api/logins/$loginId', loginPayload);
    } else {
      loginId =
          _extractId(await _post('${widget.baseUrl}/api/logins', loginPayload));
    }

    final funcionarioPayload = _compact({
      'nome': nome,
      'cpf': cpf,
      'email': email,
      'status': 'A',
      'tipoCliente': 'FUNCIONARIO',
      'ativo': ativo,
      'observacao': _valor(row, _ImportacaoCadastroTipo.funcionarios, 'setor'),
      'empresa': {'id': empresaId},
      'login': loginId != null ? {'id': loginId} : null,
    });

    var funcionarioId = atualizar
        ? await _buscarExistente(
            '${widget.baseUrl}/api/funcionario?empId=$empresaId', 'cpf', cpf)
        : null;
    if (funcionarioId != null) {
      await _put('${widget.baseUrl}/api/funcionario/$funcionarioId',
          {'id': funcionarioId, ...funcionarioPayload});
    } else {
      funcionarioId = _extractId(
          await _post('${widget.baseUrl}/api/funcionario', funcionarioPayload));
    }

    // funcionario.login_id já é vinculado via funcionarioPayload['login']
    // id_parceiro no login só deve ser preenchido se o usuário informar
    // explicitamente o campo parceiro na tela — não via import automático
    return funcionarioId ?? loginId;
  }

  Future<int?> _importarLoginCliente(Map<String, String> row) async {
    final nome = _valor(row, _ImportacaoCadastroTipo.loginsClientes, 'nome');
    final email = _valor(row, _ImportacaoCadastroTipo.loginsClientes, 'email')
        .trim()
        .toLowerCase();
    final documento = _digits(
        _valor(row, _ImportacaoCadastroTipo.loginsClientes, 'parceiro_cnpj'));
    if (nome.isEmpty) throw Exception('Nome do cliente obrigatorio');
    if (email.isEmpty) throw Exception('Email/login obrigatorio');
    if (documento.isEmpty) throw Exception('CNPJ/CPF do cliente obrigatorio');

    final empresaId = _empresaId(row, _ImportacaoCadastroTipo.loginsClientes);
    if (empresaId == null) {
      throw Exception(
          'Selecione a empresa destino ou informe empresa_id no CSV');
    }

    final parceiros = await _listarParceirosEmpresa(empresaId);
    final parceiro = _buscarParceiroNaLista(parceiros, documento: documento);
    if (parceiro == null) {
      final codigo = _valor(
          row, _ImportacaoCadastroTipo.loginsClientes, 'codigo_faturamento');
      throw Exception(codigo.isNotEmpty
          ? 'Cliente CNPJ $documento nao encontrado para codigo $codigo'
          : 'Cliente CNPJ $documento nao encontrado na empresa destino');
    }

    final senha =
        _valor(row, _ImportacaoCadastroTipo.loginsClientes, 'senha').isNotEmpty
            ? _valor(row, _ImportacaoCadastroTipo.loginsClientes, 'senha')
            : '123456';
    final tipoLogin =
        _valor(row, _ImportacaoCadastroTipo.loginsClientes, 'tipoLogin')
                .isNotEmpty
            ? _valor(row, _ImportacaoCadastroTipo.loginsClientes, 'tipoLogin')
            : 'APP_ABRACO';
    final appId =
        _toInt(_valor(row, _ImportacaoCadastroTipo.loginsClientes, 'app_id')) ??
            TenantContext.aplicativoId ??
            1;

    final payload = _compact({
      'email': email,
      'senha': senha,
      'nome': nome,
      'cpfCnpj': documento,
      'tipoLogin': tipoLogin,
      'empresa': {'id': empresaId},
      'parceiro': {'id': _extractId(parceiro)},
      'aplicativo': {'id': appId},
      'ativo': true,
      'trocarSenhaProximoLogin': false,
    });

    final atualizar =
        _atualizar[_ImportacaoCadastroTipo.loginsClientes] == true;
    final loginExistente =
        await _buscarExistente('${widget.baseUrl}/api/logins', 'email', email);
    if (loginExistente != null && !atualizar) {
      throw Exception(
          'Email $email ja existe. Ative "Atualizar se existir" para atualizar.');
    }
    if (loginExistente != null) {
      await _put('${widget.baseUrl}/api/logins/$loginExistente', payload);
      return loginExistente;
    }

    final body = await _post('${widget.baseUrl}/api/logins', payload);
    return _extractId(body);
  }

  Future<int?> _importarPlano(Map<String, String> row) async {
    if (_isFaturamentoServico(row)) {
      return _importarServicoContratadoFaturamento(row);
    }

    final nome = _valor(row, _ImportacaoCadastroTipo.planos, 'nome');
    if (nome.isEmpty) throw Exception('Nome do plano obrigatorio');

    final academia = _isPlanoAcademia(row);
    final endpoint = academia
        ? '${widget.baseUrl}/api/planos_academia'
        : '${widget.baseUrl}/api/planos';
    final payload = _compact({
      'nome': nome,
      'descricao': _valor(row, _ImportacaoCadastroTipo.planos, 'descricao'),
      'valor': _money(_valor(row, _ImportacaoCadastroTipo.planos, 'valor')),
      'dt_inicio':
          _dateOrNull(_valor(row, _ImportacaoCadastroTipo.planos, 'dt_inicio')),
      'dt_final':
          _dateOrNull(_valor(row, _ImportacaoCadastroTipo.planos, 'dt_final')),
      'qtd_aula': academia
          ? null
          : _toInt(_valor(row, _ImportacaoCadastroTipo.planos, 'qtd_aula')),
      'cod_personal': academia
          ? null
          : _toInt(_valor(row, _ImportacaoCadastroTipo.planos, 'cod_personal')),
      'cod_academia': academia
          ? _toInt(_valor(row, _ImportacaoCadastroTipo.planos, 'cod_academia'))
          : null,
    });

    final atualizar = _atualizar[_ImportacaoCadastroTipo.planos] == true;
    final existente =
        atualizar ? await _buscarExistente(endpoint, 'nome', nome) : null;
    if (existente != null) {
      await _put('$endpoint/$existente', {'id': existente, ...payload});
      return existente;
    }

    final body = await _post(endpoint, payload);
    return _extractId(body);
  }

  Future<int?> _importarServicoContratadoFaturamento(
      Map<String, String> row) async {
    final empresaId = _empresaId(row, _ImportacaoCadastroTipo.planos);
    if (empresaId == null) throw Exception('Empresa destino obrigatoria');

    final parceiro = await _resolverParceiroFaturamento(row, empresaId);
    final parceiroId = _extractId(parceiro);
    if (parceiroId == null) {
      throw Exception('Cliente/parceiro do faturamento nao encontrado');
    }

    final cliente = _nomeClienteFaturamento(row, parceiro);
    final nome = _nomeServicoFaturamento(row, cliente);
    final valor = _money(_valor(row, _ImportacaoCadastroTipo.planos, 'valor'));
    final descricao = _valor(row, _ImportacaoCadastroTipo.planos, 'descricao');
    final codigoFaturamento =
        _valor(row, _ImportacaoCadastroTipo.planos, 'codigo_faturamento');
    final documento = _documentoParceiro(parceiro);

    final payload = _compact({
      'nome': nome,
      'descricao': descricao.isNotEmpty
          ? descricao
          : [
              if (codigoFaturamento.isNotEmpty)
                'Codigo faturamento $codigoFaturamento',
              if (documento.isNotEmpty) 'CNPJ/CPF $documento',
            ].join(' - '),
      'valor': valor,
      'empresa': {'id': empresaId},
      'parceiro': {'id': parceiroId},
    });

    final existente =
        await _buscarServicoContratadoExistente(empresaId, parceiroId);
    final atualizar = _atualizar[_ImportacaoCadastroTipo.planos] == true;
    if (existente != null) {
      if (!atualizar) {
        throw Exception(
            'Plano/servico ja existe para este cliente nesta empresa');
      }
      await _put('${widget.baseUrl}/api/servico-contratado/$existente',
          {'id': existente, ...payload});
      return existente;
    }

    final body =
        await _post('${widget.baseUrl}/api/servico-contratado', payload);
    return _extractId(body);
  }

  bool _isFaturamentoServico(Map<String, String> row) {
    return _temColuna(row, 'codigo_faturamento') ||
        _temColuna(row, 'nome_faturamento') ||
        _temColuna(row, 'valor_mensal');
  }

  bool _temColuna(Map<String, String> row, String coluna) {
    final alvo = _normalizar(coluna);
    return row.keys.any((key) => _normalizar(key) == alvo);
  }

  Future<Map<String, dynamic>?> _resolverParceiroFaturamento(
      Map<String, String> row, int empresaId) async {
    final parceiroId =
        _toInt(_valor(row, _ImportacaoCadastroTipo.planos, 'parceiro_id')) ??
            _toInt(_parceiroIdSelecionado ?? '');
    final documento =
        _digits(_valor(row, _ImportacaoCadastroTipo.planos, 'cnpj'));
    final nomeCliente =
        _valor(row, _ImportacaoCadastroTipo.planos, 'nome_cliente');
    final parceiros = await _listarParceirosEmpresa(empresaId);

    if (parceiroId != null) {
      final porId = _buscarParceiroNaLista(parceiros, id: parceiroId);
      if (porId != null) return porId;
    }
    if (documento.isNotEmpty) {
      final porDocumento =
          _buscarParceiroNaLista(parceiros, documento: documento);
      if (porDocumento != null) return porDocumento;
      throw Exception(
          'Cliente/parceiro com CNPJ/CPF $documento nao encontrado na empresa destino');
    }
    if (nomeCliente.isNotEmpty) {
      final porNome = _buscarParceiroNaLista(parceiros, nome: nomeCliente);
      if (porNome != null) return porNome;
    }

    final codigo =
        _valor(row, _ImportacaoCadastroTipo.planos, 'codigo_faturamento');
    throw Exception(codigo.isNotEmpty
        ? 'Faturamento $codigo sem CNPJ no CSV e cliente nao localizado por nome'
        : 'Informe CNPJ/CPF, Parceiro ID ou nome do cliente para vincular o plano');
  }

  Future<List<Map<String, dynamic>>> _listarParceirosEmpresa(
      int empresaId) async {
    try {
      final resp = await http.get(
        Uri.parse('${widget.baseUrl}/api/parceiro/empresa/$empresaId'),
        headers: TenantContext.headers,
      );
      if (resp.statusCode == 200) return _extractList(jsonDecode(resp.body));
    } catch (_) {}
    return _parceiros
        .where((p) => (p['id']?.toString() ?? '').isNotEmpty)
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
  }

  Map<String, dynamic>? _buscarParceiroNaLista(
    List<Map<String, dynamic>> parceiros, {
    int? id,
    String? documento,
    String? nome,
  }) {
    final documentoDigits = _digits(documento ?? '');
    final nomeNorm = _normalizar(nome ?? '');
    for (final parceiro in parceiros) {
      if (id != null && _extractId(parceiro) == id) return parceiro;
      if (documentoDigits.isNotEmpty) {
        final cpf = _digits(parceiro['cpf']?.toString() ?? '');
        final codProdutor = _digits(parceiro['codProdutor']?.toString() ?? '');
        if (cpf == documentoDigits || codProdutor == documentoDigits) {
          return parceiro;
        }
      }
      if (nomeNorm.isNotEmpty) {
        final nomes = [
          parceiro['nome']?.toString() ?? '',
          parceiro['razaoSocial']?.toString() ?? '',
        ].map(_normalizar);
        if (nomes.any((n) => n == nomeNorm)) return parceiro;
      }
    }
    return null;
  }

  Future<int?> _buscarServicoContratadoExistente(
      int empresaId, int parceiroId) async {
    try {
      final resp = await TenantContext.get(
          '${widget.baseUrl}/api/servico-contratado?tamanho=10000');
      if (resp.statusCode != 200) return null;
      final lista = _extractList(jsonDecode(resp.body));
      for (final item in lista) {
        final itemEmpresaId = _extractRelatedId(item['empresa']);
        final itemParceiroId = _extractRelatedId(item['parceiro']);
        if (itemEmpresaId == empresaId && itemParceiroId == parceiroId) {
          return _extractId(item);
        }
      }
    } catch (_) {}
    return null;
  }

  int? _extractRelatedId(dynamic value) {
    if (value is Map) return _extractId(value);
    return _toInt(value?.toString() ?? '');
  }

  String _nomeClienteFaturamento(
      Map<String, String> row, Map<String, dynamic>? parceiro) {
    final csv = _valor(row, _ImportacaoCadastroTipo.planos, 'nome_cliente');
    if (csv.isNotEmpty) return csv;
    return parceiro?['nome']?.toString() ??
        parceiro?['razaoSocial']?.toString() ??
        '';
  }

  String _nomeServicoFaturamento(Map<String, String> row, String cliente) {
    final nome = _valor(row, _ImportacaoCadastroTipo.planos, 'nome');
    if (nome.isNotEmpty && !_temColuna(row, 'nome_faturamento')) return nome;
    if (cliente.isNotEmpty) return 'Mensalidade - $cliente';
    final codigo =
        _valor(row, _ImportacaoCadastroTipo.planos, 'codigo_faturamento');
    if (codigo.isNotEmpty) return 'Mensalidade - $codigo';
    throw Exception('Nome do plano/servico obrigatorio');
  }

  String _documentoParceiro(Map<String, dynamic>? parceiro) {
    if (parceiro == null) return '';
    final cpf = _digits(parceiro['cpf']?.toString() ?? '');
    if (cpf.isNotEmpty) return cpf;
    return _digits(parceiro['codProdutor']?.toString() ?? '');
  }

  Future<dynamic> _post(String url, Map<String, dynamic> body) async {
    final resp = await TenantContext.post(url, _compact(body));
    _ensureOk(resp);
    return _decode(resp.body);
  }

  Future<dynamic> _put(String url, Map<String, dynamic> body) async {
    final resp = await TenantContext.put(url, _compact(body));
    _ensureOk(resp);
    return _decode(resp.body);
  }

  void _ensureOk(http.Response resp) {
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception('HTTP ${resp.statusCode}: ${_shortBody(resp.body)}');
    }
  }

  Future<int?> _buscarExistente(String url, String campo, String valor) async {
    if (valor.trim().isEmpty) return null;
    try {
      http.Response resp;
      if (url.contains('/api/empresa')) {
        final appId = TenantContext.aplicativoId;
        final sep = url.contains('?') ? '&' : '?';
        final empresasUrl = '$url${appId != null ? '${sep}codApp=$appId' : ''}';
        resp = await http.get(Uri.parse(empresasUrl),
            headers: TenantContext.headers);
      } else {
        resp = await TenantContext.get(url);
      }
      if (resp.statusCode != 200) return null;
      final lista = _extractList(jsonDecode(resp.body));
      final valorDigits = _digits(valor);
      final valorNorm = _normalizar(valor);
      for (final item in lista) {
        final itemValor = item[campo]?.toString() ?? '';
        if (valorDigits.isNotEmpty && _digits(itemValor) == valorDigits)
          return _extractId(item);
        if (valorNorm.isNotEmpty && _normalizar(itemValor) == valorNorm)
          return _extractId(item);
      }
    } catch (_) {}
    return null;
  }

  int? _empresaId(Map<String, String> row, _ImportacaoCadastroTipo tipo) {
    return _toInt(_valor(row, tipo, 'empresa_id')) ??
        _toInt(_empresaIdSelecionada ?? '') ??
        TenantContext.empresaId;
  }

  String _valor(
      Map<String, String> row, _ImportacaoCadastroTipo tipo, String campo) {
    final coluna = _ctrl[tipo]?[campo]?.text.trim() ?? '';
    if (coluna.isNotEmpty && row.containsKey(coluna))
      return row[coluna]?.trim() ?? '';

    final candidatos = <String>{coluna.isNotEmpty ? coluna : campo};
    final config = _config(tipo);
    for (final field in config.campos) {
      if (field.key == campo) {
        candidatos
          ..add(field.key)
          ..addAll(field.sinonimos);
        break;
      }
    }
    final alvos =
        candidatos.map(_normalizar).where((c) => c.isNotEmpty).toSet();
    for (final entry in row.entries) {
      if (alvos.contains(_normalizar(entry.key))) return entry.value.trim();
    }
    return '';
  }

  bool _linhaVazia(Map<String, String> row) =>
      row.values.every((v) => v.trim().isEmpty);

  Map<String, dynamic> _compact(Map<String, dynamic> value) {
    final out = <String, dynamic>{};
    value.forEach((key, raw) {
      dynamic v = raw;
      if (v is Map<String, dynamic>) v = _compact(v);
      if (v is List) {
        v = v
            .map((e) => e is Map<String, dynamic> ? _compact(e) : e)
            .where((e) {
          if (e == null) return false;
          if (e is String) return e.trim().isNotEmpty;
          if (e is Map) return e.isNotEmpty;
          return true;
        }).toList();
      }
      if (v == null) return;
      if (v is String && v.trim().isEmpty) return;
      if (v is Map && v.isEmpty) return;
      if (v is List && v.isEmpty) return;
      out[key] = v;
    });
    return out;
  }

  dynamic _decode(String body) {
    if (body.trim().isEmpty) return {};
    try {
      return jsonDecode(body);
    } catch (_) {
      return {'body': body};
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic body) {
    dynamic data = body;
    if (data is Map && data['data'] != null) data = data['data'];
    if (data is Map && data['dados'] != null) data = data['dados'];
    if (data is Map && data['content'] != null) data = data['content'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  int? _extractId(dynamic body) {
    if (body is Map) {
      for (final key in ['id', 'codigo', 'cod']) {
        final id = _toInt(body[key]?.toString() ?? '');
        if (id != null) return id;
      }
      for (final key in ['data', 'dados', 'login', 'parceiro']) {
        final nested = body[key];
        if (nested is Map) {
          final id = _extractId(nested);
          if (id != null) return id;
        }
      }
    }
    return null;
  }

  String _shortBody(String body) {
    final clean = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 240) return clean;
    return '${clean.substring(0, 240)}...';
  }

  String _digits(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  int? _toInt(String value) {
    final digits = _digits(value);
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  double? _money(String value) {
    var clean = value.trim();
    if (clean.isEmpty) return null;
    clean = clean.replaceAll(RegExp(r'[^0-9,.-]'), '');
    if (clean.contains(',') && clean.contains('.')) {
      clean = clean.replaceAll('.', '').replaceAll(',', '.');
    } else {
      clean = clean.replaceAll(',', '.');
    }
    return double.tryParse(clean);
  }

  bool? _boolOrNull(String value) {
    final v = _normalizar(value);
    if (['s', 'sim', 'true', '1', 'ativo', 'a'].contains(v)) return true;
    if (['n', 'nao', 'false', '0', 'inativo', 'i'].contains(v)) return false;
    return null;
  }

  String? _dateOrNull(String value) {
    final v = value.trim();
    if (v.isEmpty) return null;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return v;
    final m = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$').firstMatch(v);
    if (m == null) return v;
    final d = m.group(1)!.padLeft(2, '0');
    final month = m.group(2)!.padLeft(2, '0');
    final y = m.group(3)!;
    return '$y-$month-$d';
  }

  int? _regimeId(String value) {
    final v = _normalizar(value);
    if (v.isEmpty) return null;
    if (v == '1' || v.contains('simples') || v == 'sn') return 1;
    if (v == '2' || v.contains('presumido') || v == 'lp') return 2;
    if (v == '3' || v.contains('real') || v == 'lr') return 3;
    return _toInt(value);
  }

  String? _status(String value) {
    final v = _normalizar(value);
    if (v.isEmpty) return null;
    if (['i', 'inativo', 'inativa', 'baixada'].contains(v)) return 'I';
    return 'A';
  }

  String? _ambiente(String value) {
    final v = _normalizar(value);
    if (v.isEmpty) return null;
    if (v.contains('prod')) return 'PRODUCAO';
    return 'HOMOLOGACAO';
  }

  bool _isPlanoAcademia(Map<String, String> row) {
    final tipo =
        _normalizar(_valor(row, _ImportacaoCadastroTipo.planos, 'tipo_plano'));
    final codAcademia =
        _valor(row, _ImportacaoCadastroTipo.planos, 'cod_academia');
    return tipo.contains('academia') || codAcademia.trim().isNotEmpty;
  }

  _CadastroImportConfig _config(_ImportacaoCadastroTipo tipo) =>
      _configs.firstWhere((c) => c.tipo == tipo);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.upload_file_outlined, color: _primary, size: 18),
        const SizedBox(width: 8),
        const Text('Importacao de Cadastros',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: _primary)),
        const Spacer(),
        if (_loadingEmpresas)
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.grey.shade600)),
      ]),
      const SizedBox(height: 8),
      _destinoCard(),
      const SizedBox(height: 10),
      for (final config in _configs) ...[
        _importCard(config),
        const SizedBox(height: 10),
      ],
    ]);
  }

  Widget _destinoCard() {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: _border)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.domain_add_outlined,
                color: Colors.grey.shade700, size: 18),
            const SizedBox(width: 8),
            const Text('Destino dos Cadastros',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            if (_loadingParceiros)
              SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.grey.shade600)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _empresaDropdown()),
            const SizedBox(width: 12),
            Expanded(child: _parceiroDropdown()),
          ]),
          const SizedBox(height: 6),
          Text(
            'Empresa nao precisa de destino. Para parceiros, funcionarios e logins, escolha a empresa; o cliente/parceiro e opcional.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ]),
      ),
    );
  }

  Widget _empresaDropdown() {
    return SearchableDropdownField(
      label: 'Empresa destino',
      value: _empresaIdSelecionada,
      items: _empresas,
      valueField: 'id',
      displayField: 'nome',
      hintText:
          _loadingEmpresas ? 'Carregando empresas...' : 'Selecione a empresa',
      onChanged: (v) {
        setState(() => _empresaIdSelecionada = v);
        _carregarParceiros(v);
      },
    );
  }

  Widget _parceiroDropdown() {
    return SearchableDropdownField(
      label: 'Cliente/Parceiro (opcional)',
      value: _parceiroIdSelecionado,
      items: _parceiros,
      valueField: 'id',
      displayField: 'nome',
      hintText: _empresaIdSelecionada == null
          ? 'Selecione uma empresa primeiro'
          : _loadingParceiros
              ? 'Carregando clientes...'
              : 'Nenhum cliente selecionado',
      nullable: true,
      nullLabel: 'Limpar cliente',
      enabled: _empresaIdSelecionada != null && !_loadingParceiros,
      onChanged: (v) => setState(() => _parceiroIdSelecionado = v),
    );
  }

  Widget _importCard(_CadastroImportConfig config) {
    final arquivo = _arquivos[config.tipo];
    final loading = _loading[config.tipo] == true;
    final colunas = _colunas[config.tipo] ?? [];
    final resultado = _resultados[config.tipo];
    final aviso = _avisosArquivo[config.tipo];
    final preview = _previews[config.tipo] ?? [];

    return Card(
      elevation: 0,
      color: config.color.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: config.color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: config.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(config.icon, color: config.color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(config.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(config.subtitle,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ])),
            OutlinedButton.icon(
              onPressed: loading ? null : () => _selecionarArquivo(config.tipo),
              icon: const Icon(Icons.folder_open, size: 15),
              label:
                  const Text('Selecionar CSV', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                  foregroundColor: config.color,
                  side: BorderSide(color: config.color)),
            ),
          ]),
          const SizedBox(height: 10),
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _border)),
            child: Row(children: [
              Icon(Icons.insert_drive_file_outlined,
                  size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                arquivo?.name ?? 'Nenhum arquivo selecionado',
                style: TextStyle(
                    fontSize: 11,
                    color: arquivo == null
                        ? Colors.grey.shade500
                        : Colors.grey.shade800),
                overflow: TextOverflow.ellipsis,
              )),
              if (colunas.isNotEmpty)
                Text('${colunas.length} colunas',
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            ]),
          ),
          if (aviso != null) ...[
            const SizedBox(height: 6),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.warning_amber_outlined,
                  size: 15, color: Colors.orange.shade800),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(aviso,
                      style: TextStyle(
                          fontSize: 11, color: Colors.orange.shade900))),
            ]),
          ],
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 8),
            _previewCard(preview, colunas, config.color),
          ],
          const SizedBox(height: 8),
          _mappingTile(config, colunas, arquivo != null),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: Row(children: [
              Icon(Icons.sync_alt, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                _atualizar[config.tipo] == true
                    ? 'Modo: Atualizar se existir'
                    : 'Modo: Apenas Inserir',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                _atualizar[config.tipo] == true
                    ? 'Busca por CNPJ, CPF, email ou nome antes de criar.'
                    : 'Cria novos registros e deixa duplicidades para a API validar.',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                overflow: TextOverflow.ellipsis,
              )),
            ])),
            Switch(
              value: _atualizar[config.tipo] == true,
              onChanged: loading
                  ? null
                  : (v) => setState(() => _atualizar[config.tipo] = v),
            ),
          ]),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton.icon(
              onPressed: arquivo == null || loading
                  ? null
                  : () => _importar(config.tipo),
              icon: loading
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.upload, size: 15),
              label: Text(loading ? 'Importando...' : 'Importar',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: config.color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
          if (resultado != null) ...[
            const SizedBox(height: 10),
            _resultadoCard(resultado, config.color),
          ],
        ]),
      ),
    );
  }

  Widget _previewCard(
      List<Map<String, String>> preview, List<String> colunas, Color color) {
    final visiveis = colunas.take(5).toList();
    if (visiveis.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.visibility_outlined, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            'Preview do CSV',
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Text(
            '${preview.length} linha(s) exibida(s)',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ]),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 28,
            dataRowMinHeight: 28,
            dataRowMaxHeight: 36,
            columnSpacing: 18,
            columns: visiveis
                .map((coluna) => DataColumn(
                      label: Text(
                        coluna,
                        style: const TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            rows: preview
                .map((row) => DataRow(
                      cells: visiveis
                          .map((coluna) => DataCell(SizedBox(
                                width: 150,
                                child: Text(
                                  row[coluna] ?? '',
                                  style: const TextStyle(fontSize: 10),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )))
                          .toList(),
                    ))
                .toList(),
          ),
        ),
        if (colunas.length > visiveis.length) ...[
          const SizedBox(height: 4),
          Text(
            '+ ${colunas.length - visiveis.length} coluna(s) no mapeamento abaixo',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ]),
    );
  }

  Widget _mappingTile(_CadastroImportConfig config, List<String> colunas,
      bool arquivoSelecionado) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        key: ValueKey(
            '${config.tipo}-${arquivoSelecionado ? 'arquivo' : 'vazio'}-${colunas.join('|')}'),
        initiallyExpanded: arquivoSelecionado,
        tilePadding: const EdgeInsets.symmetric(horizontal: 10),
        childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: config.color.withValues(alpha: 0.25))),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: config.color.withValues(alpha: 0.35))),
        title: Row(children: [
          Icon(Icons.tune, size: 14, color: config.color),
          const SizedBox(width: 6),
          Text('Mapeamento de colunas do CSV',
              style: TextStyle(fontSize: 11, color: config.color)),
        ]),
        children: [
          if (colunas.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Detectadas: ${colunas.join(', ')}',
                    style:
                        TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: config.campos
                .map((campo) => SizedBox(
                      width: 260,
                      child: TextField(
                        controller: _ctrl[config.tipo]![campo.key],
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          labelText: campo.label,
                          isDense: true,
                          border: const OutlineInputBorder(),
                          suffixIcon: _ctrl[config.tipo]![campo.key]!
                                  .text
                                  .isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 14),
                                  onPressed: () => setState(() =>
                                      _ctrl[config.tipo]![campo.key]!.clear()),
                                )
                              : null,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _resultadoCard(Map<String, dynamic> resultado, Color color) {
    final detalhes =
        (resultado['detalhes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final problemas = detalhes.where((d) => d['status'] != 'sucesso').toList();
    final textoProblemas = problemas
        .map((d) => 'Linha ${d['linha']} [${d['status']}]: ${d['mensagem']}')
        .join('\n');

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            _chipMini('Total', resultado['total'] ?? 0, Colors.grey.shade700),
            const SizedBox(width: 8),
            _chipMini(
                'Sucesso', resultado['sucesso'] ?? 0, Colors.green.shade700),
            const SizedBox(width: 8),
            _chipMini('Erros', resultado['erros'] ?? 0, Colors.red.shade700),
            const SizedBox(width: 8),
            _chipMini('Ignorados', resultado['ignorados'] ?? 0,
                Colors.orange.shade700),
            const Spacer(),
            if (problemas.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: textoProblemas));
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${problemas.length} problema(s) copiado(s)'),
                    duration: const Duration(seconds: 2),
                  ));
                },
                icon: const Icon(Icons.copy_all, size: 14),
                label:
                    const Text('Copiar erros', style: TextStyle(fontSize: 11)),
              ),
          ]),
        ),
        if (problemas.isNotEmpty) ...[
          const Divider(height: 1),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              itemCount: problemas.take(12).length,
              itemBuilder: (_, i) {
                final d = problemas.take(12).toList()[i];
                final erro = d['status'] == 'erro';
                final cor = erro ? Colors.red.shade700 : Colors.orange.shade700;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(erro ? Icons.cancel_outlined : Icons.info_outline,
                            size: 13, color: cor),
                        const SizedBox(width: 6),
                        Text('Linha ${d['linha']}: ',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cor)),
                        Expanded(
                            child: SelectableText(
                                d['mensagem']?.toString() ?? '',
                                style: TextStyle(fontSize: 11, color: cor))),
                      ]),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.notes_outlined,
                    size: 14, color: Colors.red.shade700),
                const SizedBox(width: 6),
                Text(
                  'Erros completos para enviar ao suporte',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700),
                ),
              ]),
              const SizedBox(height: 6),
              TextFormField(
                key: ValueKey(
                    'cadastro-import-erros-${textoProblemas.hashCode}'),
                initialValue: textoProblemas,
                readOnly: true,
                minLines: 4,
                maxLines: 8,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.red.shade50,
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.all(10),
                ),
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _chipMini(String label, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$value',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ]),
    );
  }
}
