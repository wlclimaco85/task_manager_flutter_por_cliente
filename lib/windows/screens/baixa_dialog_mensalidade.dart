import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../models/auth_utility.dart';
import '../../../models/mensalidade_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';

class WebBaixaDialogMensalidade extends StatefulWidget {
  final dynamic mensalidade;

  const WebBaixaDialogMensalidade({super.key, required this.mensalidade});

  @override
  State<WebBaixaDialogMensalidade> createState() =>
      _WebBaixaDialogMensalidadeState();
}

class _WebBaixaDialogMensalidadeState extends State<WebBaixaDialogMensalidade> {
  final _dataController = TextEditingController();
  bool _isLoading = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _dataController.text = DateTime.now().toIso8601String().split('T')[0];
  }

  Mensalidade? get _casted {
    if (widget.mensalidade is Mensalidade) return widget.mensalidade as Mensalidade;
    if (widget.mensalidade is Map<String, dynamic>) {
      return Mensalidade.fromJson(widget.mensalidade as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> _confirmarBaixa() async {
    final m = _casted;
    if (m?.id == null) {
      setState(() => _erro = 'ID da mensalidade não encontrado');
      return;
    }

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      final token = AuthUtility.userInfo?.token;
      final headers = {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final url = TenantContext.applyToUrl('${ApiLinks.baseUrl}/api/mensalidades/${m!.id}/baixa');
      final body = jsonEncode({
        'dataBaixa': _dataController.text,
        'valorBaixa': m!.valor,
      });

      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _erro = 'Erro ao registrar baixa: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => _erro = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _casted;
    return AlertDialog(
      title: const Text('Confirmar Baixa'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (m != null) ...[
              if (m.id != null) Text('Mensalidade #${m.id}'),
              if (m.valor != null) Text('Valor: R\$${m.valor!.toStringAsFixed(2)}'),
              if (m.alunoId != null) Text('Aluno ID: ${m.alunoId}'),
              const SizedBox(height: 16),
              TextField(
                controller: _dataController,
                decoration: const InputDecoration(labelText: 'Data da Baixa'),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    _dataController.text = date.toIso8601String().split('T')[0];
                  }
                },
              ),
            ] else
              const Text('Dados da mensalidade não disponíveis.'),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmarBaixa,
          child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Confirmar Baixa'),
        ),
      ],
    );
  }
}
