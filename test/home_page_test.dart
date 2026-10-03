import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:api_giphy/service/news_service.dart';
import 'package:api_giphy/service/giphy_service.dart';
import 'package:api_giphy/view/home_page.dart';
import 'package:api_giphy/view/news_page.dart';
import 'package:api_giphy/view/gif_page.dart';

List<Map<String, dynamic>> newsItems(int count, {String prefix = 'Notícia'}) =>
    List.generate(
      count,
      (i) => {
        'title': '$prefix ${i + 1}',
        'link': 'https://example.com/$prefix/${i + 1}',
        'snippet': 'Resumo ${i + 1}',
        'source_name': 'Fonte ${i + 1}',
        'authors': ['Autor ${i + 1}'],
      },
    );

http.Response jsonResponse(List<Map<String, dynamic>> data) => http.Response(
  jsonEncode({'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> showHome(
  WidgetTester tester,
  http.Client news,
  http.Client gifs,
) async {
  // Altura suficiente para verificar a sequência dos itens da lista.
  await tester.binding.setSurfaceSize(const Size(600, 10000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: HomePage(
        newsService: NewsService(client: news, apiKey: 'test'),
        giphyService: GiphyService(client: gifs, apiKey: 'test'),
      ),
    ),
  );
}

Future<void> search(WidgetTester tester, String term) async {
  await tester.enterText(find.byType(TextField), term);
  await tester.tap(find.text('Buscar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pesquisa vazia não consulta as APIs', (tester) async {
    int calls = 0;
    http.Client client() => MockClient((_) async {
      calls++;
      return jsonResponse([]);
    });
    await showHome(tester, client(), client());
    expect(calls, 0);
    await search(tester, '   ');
    expect(
      find.text('Digite um termo de pesquisa com 1 a 50 caracteres.'),
      findsOneWidget,
    );
    expect(calls, 0);
  });

  testWidgets(
    'pareia resultados, carrega 5 por vez e reinicia em outra busca',
    (tester) async {
      final newsQueries = <String>[];
      final gifOffsets = <int>[];
      final gifLimits = <int>[];
      final gifQueries = <String>[];
      await showHome(
        tester,
        MockClient((request) async {
          final query = request.url.queryParameters['query']!;
          newsQueries.add(query);
          return jsonResponse(
            newsItems(
              query == 'tecnologia' ? 12 : 3,
              prefix: query == 'tecnologia' ? 'Notícia' : 'Outra',
            ),
          );
        }),
        MockClient((request) async {
          final offset = int.parse(request.url.queryParameters['offset']!);
          final limit = int.parse(request.url.queryParameters['limit']!);
          gifOffsets.add(offset);
          gifLimits.add(limit);
          gifQueries.add(request.url.queryParameters['q']!);
          return jsonResponse(
            List.generate(
              limit,
              (i) => {
                'id': 'gif${offset + i + 1}',
                'title': 'GIF ${offset + i + 1}',
                'username': 'autor',
                'images': <String, dynamic>{},
              },
            ),
          );
        }),
      );

      await search(tester, 'tecnologia');
      expect(find.text('5. Notícia 5'), findsOneWidget);
      expect(find.text('6. Notícia 6'), findsNothing);
      await tester.tap(find.text('Ver notícia').first);
      await tester.pumpAndSettle();
      expect(find.byType(NewsPage), findsOneWidget);
      expect(find.text('Notícia 1'), findsOneWidget);
      expect(find.text('Autores: Autor 1'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();
      expect(find.text('10. Notícia 10'), findsOneWidget);
      expect(find.text('11. Notícia 11'), findsNothing);
      await tester.tap(find.text('Ver GIF').at(5));
      await tester.pumpAndSettle();
      expect(find.byType(GifPage), findsOneWidget);
      expect(find.text('GIF 6'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Carregar mais'));
      await tester.pumpAndSettle();
      expect(find.text('12. Notícia 12'), findsOneWidget);
      expect(find.text('Carregar mais'), findsNothing);
      expect(newsQueries, ['tecnologia']);
      expect(gifOffsets, [0, 5, 10]);
      expect(gifLimits, [5, 5, 2]);

      await search(tester, 'esportes');
      expect(find.text('1. Outra 1'), findsOneWidget);
      expect(find.text('1. Notícia 1'), findsNothing);
      expect(newsQueries, ['tecnologia', 'esportes']);
      expect(gifOffsets.last, 0);
      expect(gifQueries.last, 'esportes');
      await tester.tap(find.text('Limpar'));
      await tester.pumpAndSettle();
      expect(find.text('1. Outra 1'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(
        find.text('Digite um termo para buscar notícias e GIFs.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('falha nas notícias libera a tela e permite tentar novamente', (
    tester,
  ) async {
    int calls = 0;
    await showHome(
      tester,
      MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('{}', 403)
            : jsonResponse(newsItems(1));
      }),
      MockClient((_) async => jsonResponse([])),
    );
    await search(tester, 'tema');
    expect(find.text('Erro ao buscar notícias: HTTP 403.'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await search(tester, 'tema');
    expect(find.text('1. Notícia 1'), findsOneWidget);
    expect(find.text('Erro ao buscar notícias: HTTP 403.'), findsNothing);
  });

  testWidgets('GIFs em menor quantidade não deslocam o pareamento', (
    tester,
  ) async {
    await showHome(
      tester,
      MockClient((_) async => jsonResponse(newsItems(7))),
      MockClient((request) async {
        final offset = int.parse(request.url.queryParameters['offset']!);
        return jsonResponse([
          {'title': 'GIF ${offset + 1}', 'images': <String, dynamic>{}},
        ]);
      }),
    );
    await search(tester, 'tema');
    expect(
      find.text('Nenhum GIF disponível para este resultado.'),
      findsNWidgets(4),
    );
    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver GIF').last);
    await tester.pumpAndSettle();
    expect(find.text('GIF 6'), findsOneWidget);
  });

  testWidgets('falha no Giphy mantém as notícias visíveis', (tester) async {
    await showHome(
      tester,
      MockClient((_) async => jsonResponse(newsItems(5))),
      MockClient((_) async => http.Response('{}', 429)),
    );
    await search(tester, 'tema');
    expect(find.text('5. Notícia 5'), findsOneWidget);
    expect(find.textContaining('GIFs indisponíveis:'), findsOneWidget);
    expect(
      find.text('Nenhum GIF disponível para este resultado.'),
      findsNWidgets(5),
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('consulta sem notícias não chama o Giphy', (tester) async {
    int gifCalls = 0;
    await showHome(
      tester,
      MockClient((_) async => jsonResponse([])),
      MockClient((_) async {
        gifCalls++;
        return jsonResponse([]);
      }),
    );
    await search(tester, 'tema');
    expect(find.text('Nenhuma notícia encontrada.'), findsOneWidget);
    expect(gifCalls, 0);
    expect(find.text('Carregar mais'), findsNothing);
  });

  testWidgets('bloqueia novas consultas enquanto aguarda a resposta', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    int calls = 0;
    await showHome(
      tester,
      MockClient((_) {
        calls++;
        return pending.future;
      }),
      MockClient((_) async => jsonResponse([])),
    );
    await tester.enterText(find.byType(TextField), 'tema');
    await tester.tap(find.text('Buscar'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(
      tester
          .widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Buscar'))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Limpar'))
          .onPressed,
      isNull,
    );
    expect(calls, 1);
    pending.complete(jsonResponse([]));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });
  testWidgets('telas funcionam em uma largura de celular', (tester) async {
    await showHome(
      tester,
      MockClient((_) async => jsonResponse(newsItems(6))),
      MockClient(
        (_) async => jsonResponse([
          {'title': 'GIF 1', 'images': <String, dynamic>{}},
        ]),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(320, 640));
    await search(tester, 'tema');
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Ver notícia').first);
    await tester.pumpAndSettle();
    expect(find.byType(NewsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver GIF').first);
    await tester.pumpAndSettle();
    expect(find.byType(GifPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
