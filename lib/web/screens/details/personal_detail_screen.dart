import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../widgets/generic_detail_form_screen.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show SecurityCheck;

class PersonalDetailScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final SecurityCheck hasPermission;

  const PersonalDetailScreen({
    super.key,
    required this.item,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    final personalId = item['id'];
    return GenericDetailFormScreen(
      item: item,
      telaNome: 'personal',
      hasPermission: hasPermission,
      relatedTabs: [
        RelatedGridTab(
          title: 'Alunos',
          icon: Icons.people,
          customWidget: _AlunosTab(personalId: personalId),
        ),
      ],
    );
  }
}

class _AlunosTab extends StatefulWidget {
  final dynamic personalId;

  const _AlunosTab({required this.personalId});

  @override
  State<_AlunosTab> createState() => _AlunosTabState();
}

class _AlunosTabState extends State<_AlunosTab> {
  bool _carregando = true;
  List<Map<String, dynamic>> _alunos = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  Future<void> _carregarAlunos() async {
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/personal/${widget.personalId}/alunos');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final lista = body is Map ? (body['data'] ?? []) : body;
        setState(() {
          _alunos = List<Map<String, dynamic>>.from(lista ?? []);
          _carregando = false;
        });
      } else {
        setState(() {
          _carregando = false;
          _erro = 'Erro ao carregar alunos (${resp.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = 'Erro: $e';
      });
    }
  }

  Future<void> _desvincularAluno(int alunoId) async {
    final url = TenantContext.applyToUrl(
        '${ApiLinks.baseUrl}/api/personal/${widget.personalId}/alunos/$alunoId');
    final token = AuthUtility.userInfo?.token;
    final resp = await http.delete(
      Uri.parse(url),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (resp.statusCode == 200) {
      await _carregarAlunos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aluno desvinculado com sucesso')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao desvincular (${resp.statusCode})')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Text(_erro!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_alunos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nenhum aluno vinculado a este personal.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _alunos.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final aluno = _alunos[index];
        final alunoId = aluno['id'];
        final dados = aluno['codDadosPessoal'] as Map<String, dynamic>?;
        final nome = dados?['nome'] ?? 'Aluno #$alunoId';
        final email = dados?['email'] ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: GridColors.primary,
            child: Text(
              nome.isNotEmpty ? nome[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(nome),
          subtitle: email.isNotEmpty ? Text(email) : null,
          trailing: IconButton(
            icon: const Icon(Icons.link_off, color: Colors.red),
            tooltip: 'Desvincular aluno',
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Desvincular aluno'),
                  content: Text('Desvincular "$nome" deste personal?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Desvincular',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmar == true) await _desvincularAluno(alunoId);
            },
          ),
        );
      },
    );
  }
}
