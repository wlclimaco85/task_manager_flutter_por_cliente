import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/tenant_context.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_texts.dart';

/// Tela de gerenciamento do certificado digital A1 da empresa.
/// Permite upload do .pfx, visualização do status e remoção.
/// Funciona para empresa (empresaId) ou parceiro/cliente (parceiroId).
class CertificadoEmpresaScreen extends StatefulWidget {
  final int? empresaId;
  final int? parceiroId;
  final String empresaNome;

  const CertificadoEmpresaScreen({
    super.key,
    this.empresaId,
    this.parceiroId,
    required this.empresaNome,
  }) : assert(empresaId != null || parceiroId != null,
            'Informe empresaId ou parceiroId');

  @override
  State<CertificadoEmpresaScreen> createState() =>
      _CertificadoEmpresaScreenState();
}

class _CertificadoEmpresaScreenState extends State<CertificadoEmpresaScreen> {
  static const _primary = GridColors.primary;
  static const _success = GridColors.success;
  static const _warning = Color(0xFFF57F17);
  static const _error = GridColors.error;

  bool _loading = true;
  bool _uploading = false;
  List<Map<String, dynamic>> _certificados = [];

  // Upload state
  PlatformFile? _arquivoSelecionado;
  final _senhaCtrl = TextEditingController();
  bool _senhaVisivel = false;
  String? _erroUpload;
  String? _sucessoUpload;

  @override
  void initState() {
    super.initState();
    _carregarCertificados();
  }

  @override
  void dispose() {
    _senhaCtrl.dispose();
    super.dispose();
  }

  // ── Carregar certificados da empresa ─────────────────────────────────────
  Future<void> _carregarCertificados() async {
    setState(() {
      _loading = true;
    });
    try {
      final token = AuthUtility.userInfo?.token;
      final param = widget.empresaId != null
          ? 'empresaId=${widget.empresaId}'
          : 'parceiroId=${widget.parceiroId}';
      final resp = await http.get(
        Uri.parse('${ApiLinks.baseUrl}/api/certificados?$param'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final dados = body['data']?['dados'] as List? ?? [];
        setState(() {
          _certificados =
              dados.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      }
    } catch (_) {
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // ── Selecionar arquivo .pfx ───────────────────────────────────────────────
  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pfx', 'p12'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _arquivoSelecionado = result.files.first;
        _erroUpload = null;
        _sucessoUpload = null;
      });
    }
  }

  // ── Fazer upload do certificado ───────────────────────────────────────────
  Future<void> _fazerUpload() async {
    if (_arquivoSelecionado == null) {
      setState(() {
        _erroUpload = 'Selecione o arquivo .pfx do certificado.';
      });
      return;
    }
    if (_senhaCtrl.text.trim().isEmpty) {
      setState(() {
        _erroUpload = GridTexts.certificatePasswordRequired;
      });
      return;
    }

    setState(() {
      _uploading = true;
      _erroUpload = null;
      _sucessoUpload = null;
    });

    try {
      final token = AuthUtility.userInfo?.token;
      final bytes = _arquivoSelecionado!.bytes ?? Uint8List(0);

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiLinks.baseUrl}/api/certificados/upload'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (widget.empresaId != null) {
        request.fields['empresaId'] = widget.empresaId.toString();
      } else {
        request.fields['parceiroId'] = widget.parceiroId.toString();
      }
      request.fields['senha'] = _senhaCtrl.text.trim();
      request.fields['tipo'] = 'A1';
      request.files.add(http.MultipartFile.fromBytes(
        'arquivo',
        bytes,
        filename: _arquivoSelecionado!.name,
      ));

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final body = jsonDecode(resp.body);

      if (resp.statusCode == 200) {
        final cert = body['data'] as Map<String, dynamic>?;
        final validade = cert?['validade'] ?? '';
        final status = cert?['statusValidade'] ?? '';
        final dias = cert?['diasParaVencer'] ?? 0;
        setState(() {
          _sucessoUpload = 'Certificado enviado com sucesso!\n'
              'Validade: $validade  |  Status: $status  |  $dias dias restantes';
          _arquivoSelecionado = null;
          _senhaCtrl.clear();
        });
        await _carregarCertificados();
      } else {
        setState(() {
          _erroUpload = body['message'] ?? 'Erro ao enviar certificado.';
        });
      }
    } catch (e) {
      setState(() {
        _erroUpload = 'Erro de conexão: $e';
      });
    } finally {
      setState(() {
        _uploading = false;
      });
    }
  }

  // ── Deletar certificado ───────────────────────────────────────────────────
  Future<void> _deletar(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover certificado'),
        content: const Text(
            'Tem certeza? A empresa não poderá emitir NF-e sem um certificado ativo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final token = AuthUtility.userInfo?.token;
    await http.delete(
      Uri.parse('${ApiLinks.baseUrl}/api/certificados/$id'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    await _carregarCertificados();
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Certificado Digital',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(widget.empresaNome,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: _carregarCertificados,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Certificados existentes ──────────────────────────────
                  if (_certificados.isNotEmpty) ...[
                    _sectionTitle('Certificados Cadastrados'),
                    const SizedBox(height: 12),
                    ..._certificados.map(_buildCertCard),
                    const SizedBox(height: 32),
                  ],

                  // ── Upload novo certificado ──────────────────────────────
                  _sectionTitle('Enviar Novo Certificado A1'),
                  const SizedBox(height: 4),
                  Text(
                    'Selecione o arquivo .pfx ou .p12 do certificado digital e informe a senha. '
                    'A data de validade será extraída automaticamente.',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Seleção do arquivo
                  _buildFileSelector(),
                  const SizedBox(height: 16),

                  // Senha
                  TextFormField(
                    controller: _senhaCtrl,
                    obscureText: !_senhaVisivel,
                    decoration: InputDecoration(
                      labelText: 'Senha do certificado *',
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: _primary),
                      suffixIcon: IconButton(
                        icon: Icon(_senhaVisivel
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _senhaVisivel = !_senhaVisivel),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mensagens
                  if (_erroUpload != null)
                    _buildAlert(_erroUpload!, _error, Icons.error_outline),
                  if (_sucessoUpload != null)
                    _buildAlert(
                        _sucessoUpload!, _success, Icons.check_circle_outline),

                  const SizedBox(height: 8),

                  // Botão upload
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _uploading ? null : _fazerUpload,
                      icon: _uploading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.upload_file),
                      label: Text(
                          _uploading ? 'Enviando...' : 'Enviar Certificado'),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildInfoBox(),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1a1a1a)),
      );

  Widget _buildFileSelector() {
    return InkWell(
      onTap: _selecionarArquivo,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: _arquivoSelecionado != null ? _primary : Colors.grey[400]!,
            width: _arquivoSelecionado != null ? 2 : 1,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _arquivoSelecionado != null
              ? const Color(0xFFFFF3E0)
              : Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(
              _arquivoSelecionado != null
                  ? Icons.description
                  : Icons.upload_file,
              color: _arquivoSelecionado != null ? _primary : Colors.grey[500],
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _arquivoSelecionado != null
                        ? _arquivoSelecionado!.name
                        : 'Clique para selecionar o arquivo .pfx ou .p12',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _arquivoSelecionado != null
                          ? _primary
                          : Colors.grey[600],
                    ),
                  ),
                  if (_arquivoSelecionado != null)
                    Text(
                      '${(_arquivoSelecionado!.size / 1024).toStringAsFixed(1)} KB',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    )
                  else
                    Text(
                      'Formatos aceitos: .pfx, .p12',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                ],
              ),
            ),
            if (_arquivoSelecionado != null)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => setState(() => _arquivoSelecionado = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertCard(Map<String, dynamic> cert) {
    final status = cert['statusValidade'] as String? ?? 'DESCONHECIDO';
    final dias = cert['diasParaVencer'] as int? ?? 0;
    final validade = cert['validade'] as String? ?? '—';
    final ativo = cert['ativo'] as bool? ?? false;
    final nome = cert['nomeArquivo'] as String? ?? 'certificado.pfx';
    final cnpj = cert['cnpjCert'] as String? ?? '';
    final id = cert['id'] as int;

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case 'VENCIDO':
        statusColor = _error;
        statusIcon = Icons.cancel;
        statusLabel = 'VENCIDO';
        break;
      case 'VENCE_EM_BREVE':
        statusColor = _warning;
        statusIcon = Icons.warning_amber;
        statusLabel = 'Vence em $dias dias';
        break;
      default:
        statusColor = _success;
        statusIcon = Icons.verified;
        statusLabel = 'Válido — $dias dias restantes';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border:
            Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.5),
        borderRadius: BorderRadius.circular(10),
        color: statusColor.withValues(alpha: 0.04),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.security, color: statusColor),
        ),
        title: Row(
          children: [
            Expanded(
                child: Text(nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14))),
            if (ativo)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: _success, borderRadius: BorderRadius.circular(12)),
                child: const Text('ATIVO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 2),
            Text(
                'Validade: $validade${cnpj.isNotEmpty ? '  |  CNPJ: $cnpj' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Remover certificado',
          onPressed: () => _deletar(id),
        ),
      ),
    );
  }

  Widget _buildAlert(String msg, Color color, IconData icon) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg, style: TextStyle(color: color, fontSize: 13))),
          ],
        ),
      );

  Widget _buildInfoBox() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text('Sobre o Certificado Digital',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.blue[700])),
            ]),
            const SizedBox(height: 8),
            ...[
              '• O certificado A1 é um arquivo .pfx ou .p12 protegido por senha.',
              '• Ele é necessário para assinar e enviar NF-e à SEFAZ.',
              '• A data de validade é extraída automaticamente do arquivo.',
              '• Você receberá alertas quando o certificado estiver próximo do vencimento.',
              '• Ao enviar um novo certificado, o anterior é desativado automaticamente.',
            ].map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    t,
                    style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                  ),
                )),
          ],
        ),
      );
}

/// Entrada de menu para o certificado digital do próprio
/// tenant logado. CertificadoEmpresaScreen exige empresaId OU parceiroId no
/// construtor (é reaproveitada dentro das abas de Empresa/Parceiro, onde
/// esses dados já vêm carregados do registro aberto); aqui resolvemos qual
/// dos dois é o dono do certificado antes de delegar para a tela real.
///
/// Prioridade: se o login logado tem parceiroId (é um parceiro/cliente
/// específico, não a empresa como um todo), o certificado é o DO PARCEIRO —
/// nunca o da empresa. O certificado da empresa só é exibido quando não há
/// parceiroId no login (ex.: usuário master/empresa logado diretamente).
class MeuCertificadoDigitalScreen extends StatefulWidget {
  const MeuCertificadoDigitalScreen({super.key});

  @override
  State<MeuCertificadoDigitalScreen> createState() =>
      _MeuCertificadoDigitalScreenState();
}

class _MeuCertificadoDigitalScreenState
    extends State<MeuCertificadoDigitalScreen> {
  bool _carregando = true;
  String? _erro;
  int? _empresaId;
  int? _parceiroId;
  String _nome = '';

  @override
  void initState() {
    super.initState();
    _carregarDadosDoTenant();
  }

  Future<void> _carregarDadosDoTenant() async {
    final parceiroId = TenantContext.parceiroId;
    if (parceiroId != null) {
      await _carregarNomeParceiro(parceiroId);
      return;
    }
    await _carregarNomeEmpresa();
  }

  Future<void> _carregarNomeParceiro(int parceiroId) async {
    try {
      final response =
          await TenantContext.get('${ApiLinks.baseUrl}/api/parceiro/$parceiroId');
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final dados = body['data'] as Map<String, dynamic>?;
        if (dados == null) {
          setState(() {
            _carregando = false;
            _erro = 'Parceiro não encontrado.';
          });
          return;
        }
        setState(() {
          _parceiroId = parceiroId;
          _nome = (dados['nome'] ?? dados['razaoSocial'] ?? 'Parceiro')
              .toString();
          _carregando = false;
        });
      } else {
        setState(() {
          _carregando = false;
          _erro = 'Falha ao carregar dados do parceiro.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint(
          'MeuCertificadoDigitalScreen: falha ao carregar parceiro $parceiroId: $e');
      setState(() {
        _carregando = false;
        _erro = 'Falha ao carregar dados do parceiro.';
      });
    }
  }

  Future<void> _carregarNomeEmpresa() async {
    final empresaId = TenantContext.empresaId;
    if (empresaId == null) {
      setState(() {
        _carregando = false;
        _erro = 'Empresa não identificada.';
      });
      return;
    }
    try {
      final response =
          await TenantContext.get(ApiLinks.empresaById(empresaId.toString()));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _empresaId = empresaId;
          _nome =
              (dados['nome'] ?? dados['razaoSocial'] ?? 'Empresa').toString();
          _carregando = false;
        });
      } else {
        setState(() {
          _carregando = false;
          _erro = 'Falha ao carregar dados da empresa.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('MeuCertificadoDigitalScreen: falha ao carregar empresa $empresaId: $e');
      setState(() {
        _carregando = false;
        _erro = 'Falha ao carregar dados da empresa.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null || (_empresaId == null && _parceiroId == null)) {
      return Center(
          child: Text(_erro ?? 'Empresa não identificada.',
              style: const TextStyle(color: GridColors.error)));
    }
    return CertificadoEmpresaScreen(
        empresaId: _empresaId, parceiroId: _parceiroId, empresaNome: _nome);
  }
}

