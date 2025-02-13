import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';
import '../../utils/logger_config.dart';

class ActionButtonsSection extends StatelessWidget {
  static final _logger = LoggerConfig.getLogger('ActionButtonsSection');

  const ActionButtonsSection({Key? key}) : super(key: key);

  Future<void> _handleError(BuildContext context, String action, Object error,
      StackTrace? stackTrace) {
    _logger.severe('Error during $action', error, stackTrace);
    return Future.value(ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${action}に失敗しました'))));
  }

  Future<void> _executeAction(BuildContext context, String action,
      Future<void> Function() operation) async {
    try {
      _logger.info('Starting $action');
      await operation();
      _logger.info('Completed $action');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${action}が完了しました')));
    } catch (e, stackTrace) {
      await _handleError(context, action, e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScriptEditorViewModel>(context);

    return Row(
      children: [
        // 台本保存ボタン
        Expanded(
          child: ElevatedButton(
            onPressed: () => _executeAction(
              context,
              '台本保存',
              () => viewModel.exportMarkdown(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_alt),
                SizedBox(width: 8),
                Text('台本保存'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // 音声保存(mp3)
        Expanded(
          child: ElevatedButton(
            onPressed: () => _executeAction(
              context,
              'MP3保存',
              () => viewModel.createAudioFile(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_alt),
                SizedBox(width: 8),
                Text('mp3保存'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // アニメ動画生成ボタン
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.isGenerating
                ? null
                : () => _executeAction(
                      context,
                      'アニメーション再生',
                      () async {
                        await viewModel.startAnimation(context);
                      },
                    ),
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
        const SizedBox(width: 16),
        // 漫才保存
        Expanded(
          child: ElevatedButton(
            onPressed: () => _executeAction(
              context,
              '漫才保存',
              () => viewModel.saveManzaiData(context),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_alt),
                SizedBox(width: 8),
                Text('漫才保存'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
