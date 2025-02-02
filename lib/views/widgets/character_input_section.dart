import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';
import '../../utils/logger_config.dart';
import 'character_selector.dart';
import 'dart:html' as html;

class CharacterInputSection extends StatefulWidget {
  const CharacterInputSection({Key? key}) : super(key: key);

  @override
  State<CharacterInputSection> createState() => _CharacterInputSectionState();
}

class _CharacterInputSectionState extends State<CharacterInputSection> {
  static final _logger = LoggerConfig.getLogger('CharacterInputSection');
  bool isSwapped = false;

  void swapCharacters(ScriptEditorViewModel viewModel) {
    try {
      _logger.info('Swapping character positions');
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
      _logger.info('Characters swapped successfully');
    } catch (e, stackTrace) {
      _logger.severe('Error swapping characters', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('キャラクターの入れ替えに失敗しました')),
      );
    }
  }

  void _handleMusicAction(String action, VoidCallback operation) {
    try {
      _logger.info('Executing music action: $action');
      operation();
      _logger.info('Music action completed: $action');
    } catch (e, stackTrace) {
      _logger.severe('Error during music $action', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('音楽の${action}に失敗しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScriptEditorViewModel>(context);
    final bokeNameController = TextEditingController(text: viewModel.bokeName);
    final tsukkomiNameController =
        TextEditingController(text: viewModel.tsukkomiName);
    final combiNameController =
        TextEditingController(text: viewModel.combiName);
    final scriptNameController =
        TextEditingController(text: viewModel.scriptName);

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
                    onImageSelected: (image) {
                      try {
                        viewModel.setBokeImage(image);
                        _logger.info('ボケのイメージを更新しました');
                      } catch (e, stackTrace) {
                        _logger.severe(
                            'Error setting boke image', e, stackTrace);
                      }
                    },
                    initialImage: viewModel.bokeImage,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: viewModel.bokeVoice,
                    decoration: const InputDecoration(
                      labelText: '声',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: ScriptEditorViewModel.voiceTypeItems,
                    onChanged: (value) {
                      if (value != null) {
                        viewModel.setBokeVoice(value);
                        _logger.info('ボケの声を変更: $value');
                      }
                    },
                  ),
                  // ... 残りのボケ設定
                ],
              ),
            ),

            // ... マイク画像部分

            // ツッコミ設定 (ボケと同様のエラーハンドリングを実装)
          ],
        ),

        // BGM選択と再生コントロール
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: viewModel.selectedMusic,
                decoration: const InputDecoration(
                  labelText: '出囃子選択',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: ScriptEditorViewModel.musicList.map((String path) {
                  return DropdownMenuItem<String>(
                    value: path,
                    child: Text(viewModel.getMusicDisplayName(path)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    viewModel.setSelectedMusic(value);
                    _logger.info(
                        '選択された音楽: ${viewModel.getMusicDisplayName(value)}');
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: viewModel.selectedMusic != null
                  ? () => _handleMusicAction('再生', viewModel.playMusic)
                  : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('再生'),
            ),
            ElevatedButton.icon(
              onPressed: viewModel.selectedMusic != null
                  ? () => _handleMusicAction('停止', viewModel.stopMusic)
                  : null,
              icon: const Icon(Icons.stop),
              label: const Text('停止'),
            ),
          ],
        ),
      ],
    );
  }
}
