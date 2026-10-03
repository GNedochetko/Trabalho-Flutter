import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:api_giphy/config/app_config.dart';

class GiphyService {
  GiphyService({http.Client? client, this.apiKey = AppConfig.giphyApiKey})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String apiKey;

  Future<List<Map<String, dynamic>>> getGifs(
    String search,
    int offset, {
    int limit = 5,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception(
        'Configure GIPHY_API_KEY no .env e reinicie o aplicativo.',
      );
    }
    final url = Uri.https(AppConfig.giphyHost, '/v1/gifs/search', {
      'api_key': apiKey,
      'q': search,
      'limit': '$limit',
      'offset': '$offset',
      'rating': 'g',
      'lang': AppConfig.language,
      'bundle': 'messaging_non_clips',
    });
    final response = await _client
        .get(url)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar GIFs: HTTP ${response.statusCode}.');
    }
    final result = jsonDecode(response.body) as Map<String, dynamic>;
    if (result['data'] is! List) {
      throw Exception('O Giphy retornou uma resposta inválida.');
    }
    return (result['data'] as List).cast<Map<String, dynamic>>();
  }

  void close() => _client.close();
}
