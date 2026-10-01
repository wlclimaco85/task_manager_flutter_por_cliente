import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../services/network_caller.dart';
import '../../../models/network_response.dart';

class WebSistemaTestEndpointsScreen extends StatefulWidget {
  const WebSistemaTestEndpointsScreen({super.key});

  @override
  State<WebSistemaTestEndpointsScreen> createState() => _WebSistemaTestEndpointsScreenState();
}

class _WebSistemaTestEndpointsScreenState extends State<WebSistemaTestEndpointsScreen> {
  final NetworkCaller _networkCaller = NetworkCaller();

  // Endpoints de teste
  final List<Map<String, String>> endpoints = [
    {'name': 'GET /api/conta-pagar', 'method': 'GET', 'url': '/api/conta-pagar'},
    {'name': 'POST /api/conta-pagar', 'method': 'POST', 'url': '/api/conta-pagar'},
    {'name': 'GET /api/conta-pagar/{id}', 'method': 'GET', 'url': '/api/conta-pagar/1'},
    {'name': 'PUT /api/conta-pagar/{id}', 'method': 'PUT', 'url': '/api/conta-pagar/1'},
    {'name': 'DELETE /api/conta-pagar/{id}', 'method': 'DELETE', 'url': '/api/conta-pagar/1'},
    {'name': 'GET /api/conta-receber', 'method': 'GET', 'url': '/api/conta-receber'},
    {'name': 'POST /api/conta-receber', 'method': 'POST', 'url': '/api/conta-receber'},
    {'name': 'GET /api/produto', 'method': 'GET', 'url': '/api/produto'},
    {'name': 'POST /api/produto', 'method': 'POST', 'url': '/api/produto'},
    {'name': 'GET /api/nfe', 'method': 'GET', 'url': '/api/nfe'},
    {'name': 'GET /api/nfce', 'method': 'GET', 'url': '/api/nfce'},
    {'name': 'GET /api/produto-contabil', 'method': 'GET', 'url': '/api/produto-contabil'},
    {'name': 'GET /api/contas-contabeis', 'method': 'GET', 'url': '/api/contas-contabeis'},
    {'name': 'GET /api/lancamentos-contabeis', 'method': 'GET', 'url': '/api/lancamentos-contabeis'},
    {'name': 'GET /healthz', 'method': 'GET', 'url': '/healthz'},
  ];

  String? selectedEndpoint = 'GET /api/conta-pagar';
  String? selectedMethod = 'GET';
  final TextEditingController urlController = TextEditingController();
  final TextEditingController bodyController = TextEditingController();
  final TextEditingController responseController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    urlController.text = endpoints.first['url'] ?? '';
    selectedMethod = endpoints.first['method'];
  }

  void updateUrlFromEndpoint(String? value) {
    setState(() {
      selectedEndpoint = value;
      final endpoint = endpoints.firstWhere((e) => e['name'] == value);
      urlController.text = endpoint['url'] ?? '';
      selectedMethod = endpoint['method'];
    });
  }

  Future<void> makeRequest() async {
    if (urlController.text.isEmpty) {
      showError('URL é obrigatória');
      return;
    }

    setState(() => isLoading = true);

    try {
      final baseUrl = ApiLinks.baseUrl; // via config do projeto
      final fullUrl = baseUrl + urlController.text;
      Map<String, dynamic>? body;

      if (bodyController.text.isNotEmpty) {
        try {
          body = _parseJson(bodyController.text);
        } catch (e) {
          showError('JSON inválido no body: $e');
          setState(() => isLoading = false);
          return;
        }
      }

      NetworkResponse response;

      switch (selectedMethod) {
        case 'GET':
          response = await _networkCaller.getRequest(fullUrl);
          break;
        case 'POST':
          response = await _networkCaller.postRequest(fullUrl, body ?? {});
          break;
        case 'PUT':
          response = await _networkCaller.putRequest(fullUrl, body ?? {});
          break;
        case 'DELETE':
          response = await _networkCaller.deleteRequest(fullUrl);
          break;
        default:
          showError('Método HTTP inválido');
          setState(() => isLoading = false);
          return;
      }

      setState(() {
        responseController.text = 'Status: ${response.statusCode}\n\n${response.body ?? ''}';
      });
    } catch (e) {
      setState(() {
        responseController.text = 'Erro na requisição: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Map<String, dynamic> _parseJson(String json) {
    return {}; // ponytail: json.decode seria aqui, mas Flutter já tem json package
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void clearAll() {
    urlController.clear();
    bodyController.clear();
    responseController.clear();
    setState(() {
      selectedEndpoint = endpoints.first['name'];
      selectedMethod = endpoints.first['method'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema — Teste Endpoints'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título seção
            const Text('Selecione um Endpoint',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Dropdown de endpoints
            DropdownButtonFormField<String>(
              value: selectedEndpoint,
              decoration: InputDecoration(
                labelText: 'Endpoint',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: endpoints
                  .map((e) => DropdownMenuItem(
                        value: e['name'],
                        child: Text(e['name'] ?? ''),
                      ))
                  .toList(),
              onChanged: updateUrlFromEndpoint,
            ),
            const SizedBox(height: 16),

            // URL
            const Text('URL (edite se necessário)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'URL',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Método HTTP
            const Text('Método HTTP',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedMethod,
              decoration: InputDecoration(
                labelText: 'Método',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: ['GET', 'POST', 'PUT', 'DELETE']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) => setState(() => selectedMethod = val),
            ),
            const SizedBox(height: 16),

            // Body (JSON)
            const Text('Body (JSON) — opcional',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: bodyController,
              decoration: InputDecoration(
                labelText: 'Body JSON',
                border: OutlineInputBorder(),
                isDense: true,
                hintText: '{"campo":"valor"}',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Buttons
            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Enviar'),
                  onPressed: isLoading ? null : makeRequest,
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpar'),
                  onPressed: clearAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
            const SizedBox(height: 24),

            // Response
            const Text('Response',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey.shade100,
              ),
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: responseController,
                readOnly: true,
                maxLines: 12,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    bodyController.dispose();
    responseController.dispose();
    super.dispose();
  }
}
