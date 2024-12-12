import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';

class ActionButtonsSection extends StatelessWidget {
  const ActionButtonsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScriptEditorViewModel>(context);
    
    return Row(
      children: [
        //再生ボタン
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.playScript,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow),
                SizedBox(width: 8),
                Text('再生'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        //動画生成ボタン
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await viewModel.exportCsv();
              // 他の動画生成処理
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink, 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.movie),
                const SizedBox(width: 8),
                Text(viewModel.isGenerating ? '生成中...' : '動画を生成する'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}