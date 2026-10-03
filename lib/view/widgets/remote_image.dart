import 'package:flutter/material.dart';

// Usado tanto para fotos das notícias quanto para GIFs.
class RemoteImage extends StatelessWidget {
  const RemoteImage({super.key, required this.url, this.height = 180});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    final valid =
        uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
    final placeholder = SizedBox(
      height: height,
      child: const Center(child: Text('Imagem indisponível')),
    );
    if (!valid) return placeholder;
    return Image.network(
      url,
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
