import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:api_giphy/view/widgets/remote_image.dart';
import 'package:api_giphy/utils/format_date.dart';

class NewsPage extends StatelessWidget {
  const NewsPage(this.newsData, {super.key});

  final Map<String, dynamic> newsData;

  Future<void> _openArticle(BuildContext context) async {
    try {
      final url = Uri.tryParse((newsData['link'] ?? '').toString());
      if (url == null ||
          url.host.isEmpty ||
          (url.scheme != 'http' && url.scheme != 'https')) {
        throw Exception('Link inválido');
      }
      if (await launchUrl(url, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // A mensagem abaixo também cobre falhas ao abrir o navegador.
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir a notícia.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authors = (newsData['authors'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes da notícia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            (newsData['title'] ?? 'Sem título').toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          RemoteImage(
            url: (newsData['photo_url'] ?? newsData['thumbnail_url'] ?? '')
                .toString(),
          ),
          const SizedBox(height: 12),
          Text('Fonte: ${newsData['source_name'] ?? 'Não informada'}'),
          Text(
            'Publicado em: ${formatDate(newsData['published_datetime_utc'])}',
          ),
          Text(
            'Autores: ${authors.isEmpty ? 'Não informados' : authors.join(', ')}',
          ),
          const SizedBox(height: 16),
          Text((newsData['snippet'] ?? 'Sem resumo disponível.').toString()),
          const SizedBox(height: 12),
          const Text('Leia o texto completo no site da fonte.'),
          SelectableText((newsData['link'] ?? '').toString()),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _openArticle(context),
            child: const Text('Abrir notícia original'),
          ),
        ],
      ),
    );
  }
}
