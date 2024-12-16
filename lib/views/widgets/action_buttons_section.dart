import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;

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
            onPressed: viewModel.isGenerating 
              ? null  // 生成中は押せないように
              : () async {
                  try {
                    // 権限チェック（Android用）
                    if (Platform.isAndroid) {
                      final status = await Permission.storage.request();
                      if (!status.isGranted) return;
                    }
                    
                    // 動画生成開始
                    await viewModel.generateVideo();
                    
                    // 成功通知
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('動画を生成しました！')),
                    );
                  } catch (e) {
                    // エラー通知
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
                Text(viewModel.isGenerating ? '生成中...' : '動画を生成する'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}