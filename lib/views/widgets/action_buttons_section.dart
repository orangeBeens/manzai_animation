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
        // 台本保存ボタン
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.exportCsv,
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
                Text('台本保存'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 動画生成ボタン
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.isGenerating
              ? null
              : () async {
                  try {
                    // アニメーションダイアログを表示
                    viewModel.startAnimation(context);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('アニメーションを開始しました')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('エラーが発生しました: $e')),
                    );
                  }
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
                Text(viewModel.isGenerating ? '再生中...' : 'アニメーションを再生'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}