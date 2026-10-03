import 'package:flutter/material.dart';
import 'package:api_giphy/view/widgets/remote_image.dart';

class GifPage extends StatelessWidget {
  const GifPage(this.gifData, {super.key});

  final Map<String, dynamic> gifData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do GIF')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            (gifData['title'] ?? 'GIF').toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          RemoteImage(
            url:
                (gifData['images']?['original']?['url'] ??
                        gifData['images']?['fixed_height']?['url'] ??
                        '')
                    .toString(),
            height: 300,
          ),
          const SizedBox(height: 12),
          Text(
            'Autor: ${(gifData['username'] ?? '').toString().isEmpty ? 'Não informado' : gifData['username']}',
          ),
          Text('Classificação: ${gifData['rating'] ?? 'Não informada'}'),
          SelectableText('Link: ${gifData['url'] ?? 'Não informado'}'),
          const SizedBox(height: 12),
          const Text('Powered by GIPHY'),
        ],
      ),
    );
  }
}
