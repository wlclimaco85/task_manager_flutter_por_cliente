import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/auth_utility.dart';
import '../services/network_caller.dart';
import '../utils/api_links.dart';
import '../utils/grid_colors.dart';

/// Modal "Meu Perfil" — compartilhado entre Web e Windows (ambos usam
/// user_banners.dart). Permite ao usuário logado trocar nome e foto.
class MeuPerfilDialog extends StatefulWidget {
  const MeuPerfilDialog({super.key});

  @override
  State<MeuPerfilDialog> createState() => _MeuPerfilDialogState();
}

class _MeuPerfilDialogState extends State<MeuPerfilDialog> {
  late final TextEditingController _nomeController;
  String? _novaFotoBase64;
  bool _salvando = false;
  String? _nomeErro;

  @override
  void initState() {
    super.initState();
    _nomeController =
        TextEditingController(text: AuthUtility.userInfo?.login?.nome ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Uint8List? _decodeFoto(String? base64String) {
    if (base64String == null || base64String.trim().isEmpty) return null;
    try {
      final UriData? data =
          Uri.parse("data:image/png;base64,$base64String").data;
      return data?.contentAsBytes();
    } catch (_) {
      return null;
    }
  }

  Future<void> _selecionarFoto() async {
    final XFile? arquivo =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (arquivo == null) return;

    final bytes = await arquivo.readAsBytes();
    setState(() {
      _novaFotoBase64 = base64Encode(bytes);
    });
  }

  Future<void> _salvar() async {
    if (_nomeController.text.trim().isEmpty) {
      setState(() => _nomeErro = 'Informe o nome.');
      return;
    }
    setState(() => _nomeErro = null);

    final login = AuthUtility.userInfo?.login;
    if (login?.id == null) return;

    setState(() => _salvando = true);

    final body = <String, dynamic>{
      'nome': _nomeController.text.trim(),
      if (_novaFotoBase64 != null) 'foto': _novaFotoBase64,
    };

    final response = await NetworkCaller().putRequest(
      ApiLinks.updateLogin(login!.id.toString()),
      body,
    );

    if (!mounted) return;

    if (response.isSuccess) {
      AuthUtility.userInfo!.login!.nome = _nomeController.text.trim();
      if (_novaFotoBase64 != null) {
        AuthUtility.userInfo!.login!.foto = _novaFotoBase64;
      }
      await AuthUtility.setUserInfo(AuthUtility.userInfo!);
      Navigator.of(context).pop(true);
    } else {
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o perfil. Tente novamente.'),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }

  Widget _campoSomenteLeitura(String label, String valor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GridColors.surfaceMuted,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: GridColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: GridColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 14,
              color: GridColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final login = AuthUtility.userInfo?.login;

    final Uint8List? fotoAtual = _novaFotoBase64 != null
        ? _decodeFoto(_novaFotoBase64)
        : _decodeFoto(login?.foto);

    return Dialog(
      backgroundColor: GridColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Meu Perfil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GridColors.textSecondary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: GridColors.textMuted),
                    onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: _salvando ? null : _selecionarFoto,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: GridColors.primarySoft,
                        backgroundImage:
                            fotoAtual != null ? MemoryImage(fotoAtual) : null,
                        child: fotoAtual == null
                            ? const Icon(Icons.person,
                                size: 48, color: GridColors.primary)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: GridColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nomeController,
                enabled: !_salvando,
                decoration: InputDecoration(
                  labelText: 'Nome',
                  border: const OutlineInputBorder(),
                  errorText: _nomeErro,
                ),
              ),
              const SizedBox(height: 12),
              _campoSomenteLeitura('Email', login?.email ?? '-'),
              const SizedBox(height: 12),
              _campoSomenteLeitura(
                login?.parceiro != null ? 'Parceiro' : 'Empresa',
                login?.parceiro != null
                    ? (login?.parceiro?.nome?.trim().isNotEmpty == true
                        ? login!.parceiro!.nome!.trim()
                        : (login?.parceiro?.razaoSocial?.trim().isNotEmpty == true
                            ? login!.parceiro!.razaoSocial!.trim()
                            : (login?.nome?.trim().isNotEmpty == true
                                ? login!.nome!.trim()
                                : '-')))
                    : (login?.empresa?.nome?.trim().isNotEmpty == true
                        ? login!.empresa!.nome!.trim()
                        : (login?.empresa?.razaoSocial?.trim().isNotEmpty == true
                            ? login!.empresa!.razaoSocial!.trim()
                            : '-')),
              ),
              const SizedBox(height: 12),
              _campoSomenteLeitura(
                  'Tipo de acesso', login?.tipoLogin?.label ?? '-'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _salvando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
