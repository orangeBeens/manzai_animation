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
                  CharacterSelect(
                    characterType: 'ボケ',
                    onImageSelected: viewModel.setBokeImage,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: viewModel.bokeVoice,
                    decoration: const InputDecoration(
                      labelText: '声',
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
                      labelText: '名前',
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
                  CharacterSelect(
                    characterType: 'ツッコミ',
                    onImageSelected: viewModel.setTsukkomiImage,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: viewModel.tsukkomiVoice,
                    decoration: const InputDecoration(
                      labelText: '声',
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
                      labelText: '名前',
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
                value: viewModel.selectedMusic,  // ViewModelから値を取得
                decoration: const InputDecoration(
                  labelText: '出囃子選択',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ScriptEditorViewModel.musicList.map((String path) {  // ViewModelのstaticリストを使用
                  return DropdownMenuItem<String>(
                    value: path,
                    child: Text(viewModel.getMusicDisplayName(path)),  // ViewModelのメソッドを使用
                  );
                }).toList(),
                onChanged: (value) {
                  viewModel.setSelectedMusic(value);  // ViewModelのメソッドを使用して更新
                },
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: viewModel.selectedMusic != null ? () => viewModel.playMusic() : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('再生'),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: viewModel.selectedMusic != null ? () => viewModel.stopMusic() : null,
              icon: const Icon(Icons.stop),
              label: const Text('停止'),
            ),
          ],
        ),
      ],
    );
  }
}