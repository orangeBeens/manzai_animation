import 'package:flutter/material.dart';
import 'screens/title_screen.dart';
import 'screens/creation_screen.dart';
import 'screens/manzai_list_screen.dart';
import 'screens/playback_screen.dart';
import 'screens/youtube_share_screen.dart';

void main() {
  runApp(const MangaCreatorApp());
}

class MangaCreatorApp extends StatelessWidget {
  const MangaCreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '漫才作成アプリ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TitleScreen(),
    );
  }
}