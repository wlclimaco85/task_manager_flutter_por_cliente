// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'package:flutter/material.dart';
import '../../../models/parceiro_model.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';


import 'package:task_manager_flutter/utils/app_logger.dart';
class LocalizacaoWidget extends StatefulWidget {
  final Function(Pais?, Estado?, Cidade?) onChanged; // Renomeado para onChanged
  final bool required;

  const LocalizacaoWidget({
    super.key,
    required this.onChanged, // Alterado para onChanged
    this.required = false,
  });

  @override
  _LocalizacaoWidgetState createState() => _LocalizacaoWidgetState();
}

class _LocalizacaoWidgetState extends State<LocalizacaoWidget> {
  Pais? selectedPais;
  Estado? selectedEstado;
  Cidade? selectedCidade;

  List<Pais> paises = [];
  List<Estado> estados = [];
  List<Cidade> cidades = [];

  bool isLoadingPaises = false;
  bool isLoadingEstados = false;
  bool isLoadingCidades = false;

  @override
  void initState() {
    super.initState();
    fetchPaises();
    fetchEstados('1');
  }

  Future<void> fetchPaises() async {
    setState(() => isLoadingPaises = true);
    //  final NetworkResponse response =
    //     await NetworkCaller().getRequest(ApiLinks.fecthAllPaises);
    // if (response.statusCode == 200 && response.body != null) {
    setState(() {
      paises.add(Pais(
          id: 1,
          nome: "Brasil",
          nomePt: "Brasil",
          iso2: "BR",
          iso3: "BRA",
          bacen: 1058));
      isLoadingPaises = false;
    });
    // }
  }

  Future<void> fetchEstados(String? paisId) async {
    if (paisId == null) return;
    setState(() => isLoadingEstados = true);
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.fecthEstadoByPais + paisId);
    EstadoModel model;
    if (response.statusCode == 200 && response.body != null) {
      setState(() {
        model = EstadoModel.fromJson(response.body!);
        estados.addAll(model.estados ?? []);
        selectedEstado = null;
        selectedCidade = null;
        isLoadingEstados = false;
      });
    }
  }

  Future<void> fetchCidades(String? estadoId) async {
    if (estadoId == null) return;
    setState(() => isLoadingCidades = true);
    final NetworkResponse response = await NetworkCaller()
        .getRequest(ApiLinks.fecthCidadeByEstado + estadoId);
    CidadeModel model;
    if (response.statusCode == 200) {
      setState(() {
        model = CidadeModel.fromJson(response.body!);
        cidades.addAll(model.estados ?? []);
        selectedCidade = null;
        isLoadingCidades = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPaisDropdown(),
        const SizedBox(height: 16),
        _buildEstadoDropdown(),
        const SizedBox(height: 16),
        _buildCidadeDropdown(),
      ],
    );
  }

  Widget _buildPaisDropdown() {
    return Stack(
      children: [
        DropdownButtonFormField<Pais>(
          decoration: const InputDecoration(
            labelText: 'País',
            border: OutlineInputBorder(),
          ),
          initialValue: selectedPais,
          items: paises
              .map((pais) => DropdownMenuItem<Pais>(
                    value: pais,
                    child: Text(pais.nomePt),
                  ))
              .toList(),
          onChanged: isLoadingPaises
              ? null
              : (Pais? newValue) {
                  setState(() {
                    selectedPais = newValue;
                    estados = [];
                    cidades = [];
                    selectedEstado = null;
                    selectedCidade = null;
                  });
                  if (newValue != null) {
                    fetchEstados(newValue.id.toString());
                  }
                  // Chama onChanged aqui, passando os objetos
                  widget.onChanged(
                      selectedPais, selectedEstado, selectedCidade);
                },
          validator: (value) =>
              widget.required && value == null ? 'Selecione um país' : null,
        ),
        const SizedBox(height: 16),
        if (isLoadingPaises)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildEstadoDropdown() {
    return Stack(
      children: [
        DropdownButtonFormField<Estado>(
          decoration: const InputDecoration(
            labelText: 'Estado',
            border: OutlineInputBorder(),
          ),
          initialValue: selectedEstado,
          items: estados
              .map((estado) => DropdownMenuItem<Estado>(
                    value: estado,
                    child: Text('${estado.nome} (${estado.uf})'),
                  ))
              .toList(),
          onChanged: isLoadingEstados
              ? null
              : (Estado? newValue) {
                  setState(() {
                    selectedEstado = newValue;
                    cidades = [];
                    selectedCidade = null;
                  });
                  if (newValue != null) {
                    fetchCidades(newValue.id.toString());
                  }
                  // Chama onChanged aqui, passando os objetos
                  widget.onChanged(
                      selectedPais, selectedEstado, selectedCidade);
                },
          // ... (seu código existente)
          validator: (value) =>
              widget.required && value == null ? 'Selecione um estado' : null,
        ),
        const SizedBox(height: 16),
        if (isLoadingEstados)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        // ... (seu código existente)
      ],
    );
  }

  Widget _buildCidadeDropdown() {
    return Stack(
      children: [
        DropdownButtonFormField<Cidade>(
          decoration: const InputDecoration(
            labelText: 'Cidade',
            border: OutlineInputBorder(),
          ),
          initialValue: selectedCidade,
          items: cidades
              .map((cidade) => DropdownMenuItem<Cidade>(
                    value: cidade,
                    child: Text(cidade.nome),
                  ))
              .toList(),
          onChanged: isLoadingCidades
              ? null
              : (Cidade? newValue) {
                  setState(() {
                    selectedCidade = newValue;
                  });
                  // Chama onChanged aqui, passando os objetos
                  widget.onChanged(
                      selectedPais, selectedEstado, selectedCidade);
                },
          // ... (seu código existente)
          validator: (value) =>
              widget.required && value == null ? 'Selecione uma cidade' : null,
        ),
        if (isLoadingCidades)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
        // ... (seu código existente)
      ],
    );
  }
}

// Exemplo de uso no widget pai:
class MeuWidgetPai extends StatefulWidget {
  const MeuWidgetPai({super.key});

  @override
  _MeuWidgetPaiState createState() => _MeuWidgetPaiState();
}

class _MeuWidgetPaiState extends State<MeuWidgetPai> {
  Pais? paisSelecionado;
  Estado? estadoSelecionado;
  Cidade? cidadeSelecionada;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LocalizacaoWidget(
          onChanged: (pais, estado, cidade) {
            paisSelecionado = pais;
            estadoSelecionado = estado;
            cidadeSelecionada = cidade;

            // Use os objetos selecionados aqui
            if (paisSelecionado != null) {
              L.d("País selecionado: ${paisSelecionado!.nome}");
            }
            if (estadoSelecionado != null) {
              L.d("Estado selecionado: ${estadoSelecionado!.nome}");
            }
            if (cidadeSelecionada != null) {
              L.d("Cidade selecionada: ${cidadeSelecionada!.nome}");
            }
          },
          required: true,
        ),
        // ... (resto do seu widget)
      ],
    );
  }
}
