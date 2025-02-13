import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';

class ScriptInputSection extends StatefulWidget {
  const ScriptInputSection({Key? key}) : super(key: key);

  @override
  State<ScriptInputSection> createState() => _ScriptInputSectionState();
}

class _ScriptInputSectionState extends State<ScriptInputSection> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScriptEditorViewModel>(context);

    return Column(
      children: [
        //ボケツッコミ選択のドロップダウン
        DropdownButtonFormField<String>(
          value: viewModel.selectedCharacterType,
          decoration: const InputDecoration(
            labelText: 'キャラクター',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'ボケ', child: Text('左')),
            DropdownMenuItem(value: 'ツッコミ', child: Text('右')),
          ],
          onChanged: (value) => viewModel.setSelectedCharacterType(value!),
        ),
        const SizedBox(height: 16),
        //セリフ（textfield)、追加ボタンのrow
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'セリフ',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                viewModel.addScriptLine(_textController.text);
                _textController.clear(); // 入力欄をクリア
              },
              child: const Text('追加'),
            ),
          ],
        ),
      ],
    );
  }
}
