import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:api_giphy/service/news_service.dart';
import 'package:api_giphy/service/giphy_service.dart';

void main() {
  test(
    'notícias: envia autenticação e mantém a ordem sem links repetidos',
    () async {
      final service = NewsService(
        apiKey: 'test-key',
        client: MockClient((request) async {
          expect(request.url.path, '/search');
          expect(request.url.queryParameters['query'], 'tecnologia & ciência');
          expect(request.url.queryParameters['limit'], '100');
          expect(request.url.queryParameters['country'], 'BR');
          expect(request.url.queryParameters['language'], 'pt');
          expect(request.url.queryParameters.containsKey('offset'), isFalse);
          expect(request.headers['X-RapidAPI-Key'], 'test-key');
          expect(request.headers['X-RapidAPI-Host'], request.url.host);
          return http.Response(
            jsonEncode({
              'data': [
                {'title': 'Primeira', 'link': 'https://example.com/1'},
                {'title': 'Repetida', 'link': 'https://example.com/1'},
                {'title': 'Segunda', 'link': 'https://example.com/2'},
              ],
            }),
            200,
          );
        }),
      );
      final news = await service.getNews('tecnologia & ciência');
      expect(news.map((item) => item['title']), ['Primeira', 'Segunda']);
      service.close();
    },
  );

  test('GIFs: pede cinco resultados a partir do offset informado', () async {
    final service = GiphyService(
      apiKey: 'test-key',
      client: MockClient((request) async {
        expect(request.url.path, '/v1/gifs/search');
        expect(request.url.queryParameters['api_key'], 'test-key');
        expect(request.url.queryParameters['q'], 'ciência & tecnologia');
        expect(request.url.queryParameters['limit'], '5');
        expect(request.url.queryParameters['offset'], '10');
        expect(request.url.queryParameters['lang'], 'pt');
        return http.Response('{"data": [{"id": "gif11"}]}', 200);
      }),
    );
    expect(
      (await service.getGifs('ciência & tecnologia', 10)).first['id'],
      'gif11',
    );
    service.close();
  });

  test('sem chave, os serviços não fazem requisição', () async {
    int calls = 0;
    http.Client client() => MockClient((request) async {
      calls++;
      return http.Response('{"data": []}', 200);
    });
    final news = NewsService(apiKey: '', client: client());
    final gifs = GiphyService(apiKey: '', client: client());
    await expectLater(news.getNews('tema'), throwsException);
    await expectLater(gifs.getGifs('tema', 0), throwsException);
    expect(calls, 0);
    news.close();
    gifs.close();
  });

  test('serviços rejeitam erro HTTP e resposta sem lista de dados', () async {
    final news = NewsService(
      apiKey: 'test',
      client: MockClient((_) async => http.Response('{}', 403)),
    );
    final gifs = GiphyService(
      apiKey: 'test',
      client: MockClient((_) async => http.Response('{"data": null}', 200)),
    );
    await expectLater(news.getNews('tema'), throwsException);
    await expectLater(gifs.getGifs('tema', 0), throwsException);
    news.close();
    gifs.close();
  });
}
