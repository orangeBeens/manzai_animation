// lib/screens/youtube_share_screen.dart
import 'package:flutter/material.dart';
import '../widgets/character_avatar.dart';

class YoutubeShareScreen extends StatelessWidget {
  final int manzaiId;

  const YoutubeShareScreen({super.key, required this.manzaiId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube共有'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // キャラクター表示部分
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const CharacterAvatar(
                      name: '太郎',
                      imagePath: 'assets/taro.png',
                      role: 'ボケ',
                    ),
                    // マイクのアイコン
                    Container(
                      width: 40,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const CharacterAvatar(
                      name: '次郎',
                      imagePath: 'assets/jiro.png',
                      role: 'ツッコミ',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // タイトル入力
            TextField(
              decoration: InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // 説明入力
            TextField(
              decoration: InputDecoration(
                labelText: '説明',
                hintText: '動画の説明を入力してください',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            
            // 公開設定
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('公開設定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio(
                          value: '非公開',
                          groupValue: '非公開',
                          onChanged: (value) {},
                        ),
                        const Text('非公開'),
                        const SizedBox(width: 16),
                        Radio(
                          value: '公開',
                          groupValue: '非公開',
                          onChanged: (value) {},
                        ),
                        const Text('公開'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // 注意書き
            const Text(
              '・著作権等の問題に注意してください。\n・不適切なコンテンツは削除される場合があります。',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // 共有ボタン
            ElevatedButton.icon(
              onPressed: () {
                // シェア処理
              },
              icon: const Icon(Icons.share),
              label: const Text('YouTubeに共有する'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}