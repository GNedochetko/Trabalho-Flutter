import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:api_giphy/config/app_config.dart';

class NewsService {
  NewsService({http.Client? client, this.apiKey = AppConfig.newsApiKey})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String apiKey;

  Future<List<Map<String, dynamic>>> getNews(String search) async {
    if (apiKey.isEmpty) {
      throw Exception(
        'Configure RAPIDAPI_KEY no .env e reinicie o aplicativo.',
      );
    }

    // O Search não tem offset. Guardamos este lote para mostrar 5 por vez.
    final url = Uri.https(AppConfig.newsHost, '/search', {
      'query': search,
      'limit': '100',
      'time_published': 'anytime',
      'country': AppConfig.country,
      'language': AppConfig.language,
    });
    final response = await _client
        .get(
          url,
          headers: {
            'X-RapidAPI-Key': apiKey,
            'X-RapidAPI-Host': AppConfig.newsHost,
          },
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar notícias: HTTP ${response.statusCode}.');
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (result['data'] is! List) {
      throw Exception('A API de notícias retornou uma resposta inválida.');
    }

    // Remove notícias repetidas pelo link sem mudar a ordem da API.
    final news = <Map<String, dynamic>>[];
    final links = <String>{};
    for (final item in result['data'] as List) {
      final article = Map<String, dynamic>.from(item as Map);
      final link = (article['link'] ?? '').toString();
      if (link.isEmpty || links.add(link)) news.add(article);
    }
    return news;
  }

  void close() => _client.close();
}
