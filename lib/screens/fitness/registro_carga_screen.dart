// lib/screens/fitness/registro_carga_screen.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';

class RegistroCargaScreen extends StatefulWidget {
  const RegistroCargaScreen({super.key});

  @override
  State<RegistroCargaScreen> createState() => _RegistroCargaScreenState();
}

class _RegistroCargaScreenState extends State<RegistroCargaScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _serieSelecionada;
  final _pesoController = TextEditingController();

  final List<String> series = ['Série 1', 'Série 2', 'Série 3'];

  @override
  void dispose() {
    _pesoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Carga registrada: $_serieSelecionada - ${_pesoController.text} kg'),
        ),
      );
      _pesoController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Carga'),
        backgroundColor: GridColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _serieSelecionada,
                items: series
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _serieSelecionada = value);
                },
                decoration: InputDecoration(
                  labelText: 'Série',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione uma série';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Peso (kg)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite o peso';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Salvar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
