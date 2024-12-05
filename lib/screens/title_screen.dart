// lib/screens/title_screen.dart
import 'package:flutter/material.dart';
import '../widgets/character_avatar.dart';
import 'creation_screen.dart';
import 'manzai_list_screen.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                '漫才作成app',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CharacterAvatar(
                      name: '太郎',
                      imagePath: 'assets/images/title.png',
                      role: 'ボケ',
                    ),
                    // const SizedBox(width: 20),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreationScreen(),
                        ),
                      );
                    },
                    child: const Text('漫才作成する'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManzaiListScreen(),
                        ),
                      );
                    },
                    child: const Text('漫才一覧'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}