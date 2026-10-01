// lib/screens/fitness/anamnese_screen.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';

class AnamneseScreen extends StatefulWidget {
  const AnamneseScreen({super.key});

  @override
  State<AnamneseScreen> createState() => _AnamneseScreenState();
}

class _AnamneseScreenState extends State<AnamneseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idadeController = TextEditingController();
  final _alturaController = TextEditingController();
  final _pesoController = TextEditingController();
  final _objetivoController = TextEditingController();
  final _frequenciaController = TextEditingController();

  int _passoAtual = 1;

  @override
  void dispose() {
    _idadeController.dispose();
    _alturaController.dispose();
    _pesoController.dispose();
    _objetivoController.dispose();
    _frequenciaController.dispose();
    super.dispose();
  }

  void _proximoPasso() {
    if (_formKey.currentState!.validate()) {
      if (_passoAtual < 5) {
        setState(() => _passoAtual++);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anamnese completada!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anamnese'),
        backgroundColor: GridColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Container(
                padding: const EdgeInsets.all(12),
                color: GridColors.primary.withOpacity(0.1),
                child: Text('Passo $_passoAtual de 5'),
              ),
              const SizedBox(height: 24),

              // Step 1: Idade, Altura, Peso
              if (_passoAtual == 1) ...[
                TextFormField(
                  controller: _idadeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Idade',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite sua idade';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _alturaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Altura (cm)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite sua altura';
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
                      return 'Digite seu peso';
                    }
                    return null;
                  },
                ),
              ],

              // Step 2: Objetivo
              if (_passoAtual == 2) ...[
                TextFormField(
                  controller: _objetivoController,
                  decoration: InputDecoration(
                    labelText: 'Objetivo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite seu objetivo';
                    }
                    return null;
                  },
                ),
              ],

              // Step 3+: Frequência (e demais)
              if (_passoAtual >= 3) ...[
                TextFormField(
                  controller: _frequenciaController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Frequência semanal',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Digite a frequência';
                    }
                    return null;
                  },
                ),
              ],

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _proximoPasso,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_passoAtual < 5 ? 'Próximo Passo' : 'Finalizar'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
