import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';
import 'character_selector.dart';
import 'dart:html' as html;

class CharacterInputSection extends StatefulWidget {
  const CharacterInputSection({Key? key}) : super(key: key);

  @override
  State<CharacterInputSection> createState() => _CharacterInputSectionState();
}

class _CharacterInputSectionState extends State<CharacterInputSection> {
  bool isSwapped = false;
  String? selectedMusic;
  html.AudioElement? _audioElement;

  // 利用可能な音楽のリスト
  static const List<String> musicList = [
    'assets/music/2_23_AM.mp3',
    'assets/music/ALIVE_inst_FreeVer.mp3',
    'assets/music/CountdownToVictory_Free_Ver.mp3',
    'assets/music/FreeBGM_machine_head_remix.mp3',
    'assets/music/honey-remon350ml.mp3',
    'assets/music/honwaka-puppu.mp3',
    'assets/music/kaeruno-piano_2.mp3',
    'assets/music/kaeruno-piano.mp3',
    'assets/music/kakekko-kyoso.mp3',
    'assets/music/keen-fire-jean-drop-235365.mp3',
    'assets/music/maou_41_honeybaby_magicalgirl.mp3',
    'assets/music/noraneko-uchu.mp3',
    'assets/music/souzoushin.mp3',
    'assets/music/spinning-head-27171.mp3',
    'assets/music/vlog-music-beat-trailer-showreel.mp3',
  ];

  @override
  void dispose() {
    _audioElement?.pause();
    _audioElement = null;
    super.dispose();
  }

  void swapCharacters(ScriptEditorViewModel viewModel) {
    setState(() {
      final tempImage = viewModel.bokeImage;
      viewModel.setBokeImage(viewModel.tsukkomiImage);
      viewModel.setTsukkomiImage(tempImage);
      
      final tempVoice = viewModel.bokeVoice;
      viewModel.setBokeVoice(viewModel.tsukkomiVoice);
      viewModel.setTsukkomiVoice(tempVoice);
      
      final tempName = viewModel.bokeName;
      viewModel.setBokeName(viewModel.tsukkomiName);
      viewModel.setTsukkomiName(tempName);
      
      isSwapped = !isSwapped;
    });
  }

  void playMusic() {
    if (selectedMusic != null) {
      _audioElement?.pause();
      _audioElement = html.AudioElement(selectedMusic);
      _audioElement?.play();
    }
  }

  void stopMusic() {
    _audioElement?.pause();
    if (_audioElement != null) {
      _audioElement!.currentTime = 0;
    }
  }

  String getMusicDisplayName(String path) {
    final fileName = path.split('/').last;
    return fileName.replaceAll('.mp3', '').replaceAll('_', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScriptEditorViewModel>(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ボケのキャラクター設定
            SizedBox(
              width: 280,
              child: Column(
                children: [
                  const Text('ボケ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  CharacterSelect(
                    characterType: 'ボケ',
                    onImageSelected: viewModel.setBokeImage,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: viewModel.bokeVoice,
                    decoration: const InputDecoration(
                      labelText: 'ボケの声',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ScriptEditorViewModel.voiceTypeItems,
                    onChanged: (value) => viewModel.setBokeVoice(value!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: viewModel.setBokeName,
                    decoration: const InputDecoration(
                      labelText: 'ボケの名前',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            
            // マイク画像
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () => swapCharacters(viewModel),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Image.asset(
                        'assets/images/center_mike.png',
                        width: 120,
                        height: 120,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // ツッコミのキャラクター設定
            SizedBox(
              width: 280,
              child: Column(
                children: [
                  const Text('ツッコミ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  CharacterSelect(
                    characterType: 'ツッコミ',
                    onImageSelected: viewModel.setTsukkomiImage,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: viewModel.tsukkomiVoice,
                    decoration: const InputDecoration(
                      labelText: 'ツッコミの声',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ScriptEditorViewModel.voiceTypeItems,
                    onChanged: (value) => viewModel.setTsukkomiVoice(value!),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    onChanged: viewModel.setTsukkomiName,
                    decoration: const InputDecoration(
                      labelText: 'ツッコミの名前',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // コンビ名とネタ名の入力欄
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: viewModel.setCombiName,
                decoration: const InputDecoration(
                  labelText: 'コンビ名',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                onChanged: viewModel.setScriptName, 
                decoration: const InputDecoration(
                  labelText: 'ネタ名',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // BGM選択と再生コントロール
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: selectedMusic,
                decoration: const InputDecoration(
                  labelText: '出囃子選択',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: musicList.map((String path) {
                  return DropdownMenuItem<String>(
                    value: path,
                    child: Text(getMusicDisplayName(path)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMusic = value;
                    print('Music selected: $selectedMusic'); // 値が正しく更新されているか確認
                    stopMusic();
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: selectedMusic != null ? playMusic : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('再生'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: selectedMusic != null ? stopMusic : null,
              icon: const Icon(Icons.stop),
              label: const Text('停止'),
            ),
          ],
        ),
      ],
    );
  }
}