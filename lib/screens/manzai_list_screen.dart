import 'package:flutter/material.dart';
import 'creation_screen.dart';
import 'playback_screen.dart';

class ManzaiListScreen extends StatelessWidget {
  const ManzaiListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('作品一覧'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        itemCount: 3, // サンプルデータ
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('漫才作品${index + 1}'),
            subtitle: Text('作成日: 2024/03/${index + 1}'),
            trailing: const Icon(Icons.play_arrow),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaybackScreen(manzaiId: index),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreationScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}