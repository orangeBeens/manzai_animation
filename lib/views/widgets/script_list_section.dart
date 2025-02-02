import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';
import '../../utils/logger_config.dart';

/// スクリプトのリストを表示・編集するウィジェット
class ScriptListSection extends StatelessWidget {
  static final _logger = LoggerConfig.getLogger('ScriptListSection');

  const ScriptListSection({Key? key}) : super(key: key);

  /// エラー処理を統一的に扱うメソッド
  Future<void> _handleError(BuildContext context, String action, Object error,
      StackTrace? stackTrace) {
    _logger.severe('Error during $action', error, stackTrace);
    return Future.value(ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${action}に失敗しました'))));
  }

  /// アクション実行を統一的に扱うメソッド
  Future<void> _executeAction(BuildContext context, String action,
      Future<void> Function() operation) async {
    try {
      _logger.info('Starting $action');
      await operation();
      _logger.info('Completed $action');
    } catch (e, stackTrace) {
      await _handleError(context, action, e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScriptEditorViewModel>(context);
    _logger.info(
        'Building ScriptListSection with ${viewModel.scriptLines.length} lines');

    return Expanded(
      child: ReorderableListView.builder(
        itemCount: viewModel.scriptLines.length,
        onReorder: (oldIndex, newIndex) {
          try {
            _logger.info('Reordering script line from $oldIndex to $newIndex');
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            viewModel.reorderScriptLine(oldIndex, newIndex);
            _logger.info('Successfully reordered script line');
          } catch (e, stackTrace) {
            _handleError(context, '台本の並び替え', e, stackTrace);
          }
        },
        itemBuilder: (context, index) {
          final line = viewModel.scriptLines[index];

          return Card(
            key: ValueKey(index),
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.drag_handle),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: line.characterType == 'ボケ'
                          ? Colors.blue[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      line.characterType,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              title: Text(line.text),
              subtitle: Text(
                '間: ${line.timing.toStringAsFixed(1)}秒, スピード: ${line.speed.toStringAsFixed(2)}x, '
                '声量: ${line.volume.toStringAsFixed(2)}, 声の高さ: ${line.pitch.toStringAsFixed(2)}, '
                '抑揚: ${line.intonation.toStringAsFixed(2)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'このセリフを再生',
                    onPressed: () => _executeAction(
                      context,
                      'セリフの再生',
                      () => viewModel.playScriptLine(line),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'セリフを編集',
                    onPressed: () => _executeAction(
                      context,
                      'セリフの編集',
                      () => viewModel.showEditDialog(
                          context, viewModel, line, index),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'セリフを削除',
                    onPressed: () => _executeAction(
                      context,
                      'セリフの削除',
                      () => viewModel.showDeleteConfirmDialog(
                          context, viewModel, index),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
