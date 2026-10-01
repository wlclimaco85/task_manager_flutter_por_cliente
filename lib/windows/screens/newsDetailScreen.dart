import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/noticias_model.dart';

class WindowsNewsDetailScreen extends StatelessWidget {
  final Data news;

  const WindowsNewsDetailScreen({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(news.titulo ?? 'Detalhes da Notícia'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news.titulo ?? 'Título não disponível',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                news.fonte != null ? "Fonte: ${news.fonte}" : '',
                style:
                    const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              Text(
                news.dtNoticia != null
                    ? "Data: ${DateFormat('dd/MM/yyyy HH:mm').format(news.dtNoticia!.toLocal())}"
                    : '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              Text(
                news.noticia ?? 'Notícia não disponível',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
