import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:api_giphy/service/news_service.dart';
import 'package:api_giphy/service/giphy_service.dart';
import 'package:api_giphy/view/news_page.dart';
import 'package:api_giphy/view/gif_page.dart';
import 'package:api_giphy/view/widgets/remote_image.dart';
import 'package:api_giphy/utils/format_date.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.newsService, this.giphyService});

  final NewsService? newsService;
  final GiphyService? giphyService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late final NewsService _newsService;
  late final GiphyService _giphyService;
  final List<Map<String, dynamic>> _newsData = [];
  final List<Map<String, dynamic>?> _gifData = [];
  String _search = '';
  String? _error;
  String? _gifError;
  int _visibleCount = 0;
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    _newsService = widget.newsService ?? NewsService();
    _giphyService = widget.giphyService ?? GiphyService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _newsService.close();
    _giphyService.close();
    super.dispose();
  }

  String _errorMessage(Object error) {
    if (error is TimeoutException) {
      return 'A consulta demorou demais. Tente novamente.';
    }
    if (error is http.ClientException) {
      return 'Não foi possível conectar à API. Verifique sua internet.';
    }
    if (error is FormatException || error is TypeError) {
      return 'A API retornou dados em um formato inesperado.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _loadResults({bool more = false}) async {
    if (_loading) return;
    final query = more ? _search : _searchController.text.trim();
    if (query.isEmpty || query.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um termo de pesquisa com 1 a 50 caracteres.'),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _gifError = null;
      if (!more) {
        _search = query;
        _searched = true;
        _visibleCount = 0;
        _newsData.clear();
        _gifData.clear();
      }
    });
    if (!more && _scrollController.hasClients) _scrollController.jumpTo(0);

    try {
      if (!more) {
        final news = await _newsService.getNews(query);
        if (!mounted) return;
        _newsData.addAll(news);
      }
      final remaining = _newsData.length - _visibleCount;
      final count = remaining < 5 ? remaining : 5;
      if (count > 0) {
        List<Map<String, dynamic>> gifs = [];
        String? gifError;
        try {
          gifs = await _giphyService.getGifs(
            query,
            _visibleCount,
            limit: count,
          );
        } catch (error) {
          // Uma falha no Giphy não impede a leitura das notícias.
          gifError = _errorMessage(error);
        }
        if (!mounted) return;
        setState(() {
          // Posição 0 da notícia recebe posição 0 do GIF, e assim por diante.
          for (int i = 0; i < count; i++) {
            _gifData.add(i < gifs.length ? gifs[i] : null);
          }
          _visibleCount += count;
          _gifError = gifError;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = _errorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearSearch() {
    if (_loading) return;
    _searchController.clear();
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    setState(() {
      _search = '';
      _newsData.clear();
      _gifData.clear();
      _visibleCount = 0;
      _searched = false;
      _error = null;
      _gifError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notícias e GIFs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  enabled: !_loading,
                  maxLength: 50,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'Pesquisar notícias',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _loadResults(),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _loading ? null : () => _loadResults(),
                      child: const Text('Buscar'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _loading ? null : _clearSearch,
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_gifError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('GIFs indisponíveis: $_gifError'),
            ),
          Expanded(child: _buildResults()),
          if (_visibleCount > 0)
            Padding(
              padding: const EdgeInsets.all(8),
              child: _visibleCount < _newsData.length
                  ? ElevatedButton(
                      onPressed: _loading
                          ? null
                          : () => _loadResults(more: true),
                      child: const Text('Carregar mais'),
                    )
                  : const Text(
                      'Todos os resultados desta consulta foram exibidos.',
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
      );
    }
    if (_visibleCount == 0) {
      final message = _loading
          ? 'Pesquisando...'
          : _searched
          ? 'Nenhuma notícia encontrada.'
          : 'Digite um termo para buscar notícias e GIFs.';
      return Center(child: Text(message));
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: _visibleCount,
      itemBuilder: (context, index) => _buildResult(index),
    );
  }

  Widget _buildResult(int index) {
    final news = _newsData[index];
    final gif = _gifData[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${news['title'] ?? 'Sem título'}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text((news['source_name'] ?? 'Fonte não informada').toString()),
            Text(formatDate(news['published_datetime_utc'])),
            const SizedBox(height: 8),
            Text(
              (news['snippet'] ?? 'Sem resumo disponível.').toString(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (context) => NewsPage(news)),
              ),
              child: const Text('Ver notícia'),
            ),
            const Divider(),
            const Text('GIF relacionado à pesquisa • Powered by GIPHY'),
            if (gif == null)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nenhum GIF disponível para este resultado.'),
              )
            else ...[
              RemoteImage(
                url: (gif['images']?['fixed_height']?['url'] ?? '').toString(),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (context) => GifPage(gif)),
                ),
                child: const Text('Ver GIF'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
