import 'package:flutter/material.dart';
import 'package:api_giphy/view/home_page.dart';

void main() {
  runApp(
    MaterialApp(
      home: const HomePage(),
      title: 'Notícias e GIFs',
      debugShowCheckedModeBanner: false,
    ),
  );
}
