import 'package:flutter/material.dart';
import 'youtube_share_screen.dart';

class PlaybackScreen extends StatelessWidget {
  final int manzaiId;

  const PlaybackScreen({super.key, required this.manzaiId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('漫才再生 #$manzaiId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text('漫才再生画面'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.pause),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => YoutubeShareScreen(manzaiId: manzaiId),
                  ),
                );
              },
              child: const Text('YouTubeで共有する'),
            ),
          ),
        ],
      ),
    );
  }
}