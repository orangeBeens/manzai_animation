import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';

/// スクリプトのリストを表示・編集するウィジェット
class ScriptListSection extends StatelessWidget {
  const ScriptListSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ScriptEditorViewModel>(context);
    
    return Expanded(
      child: ReorderableListView.builder(
        itemCount: viewModel.scriptLines.length,
        onReorder: (oldIndex, newIndex) {
          // ReorderableListViewは、移動先のインデックスが
          // 元の位置より後ろの場合、削除前の位置を考慮して
          // インデックスを1つ減らす必要がある
          if (newIndex > oldIndex) {
            newIndex -= 1;
          }
          viewModel.reorderScriptLine(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final line = viewModel.scriptLines[index];
          
          return Card(
            key: ValueKey(index), // ReorderableListViewには一意のkeyが必要
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              // ドラッグハンドルを追加
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ドラッグハンドル
                  const Icon(Icons.drag_handle),
                  const SizedBox(width: 8),
                  // キャラクタータイプ表示
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: line.characterType == 'ボケ' ? Colors.blue[100] : Colors.red[100],
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
                '間: ${line.timing.toStringAsFixed(1)}秒, スピード: ${line.speed.toStringAsFixed(2)}x',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 再生ボタン
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    tooltip: 'このセリフを再生',
                    onPressed: () => viewModel.playScriptLine(line),
                  ),
                  // 編集ボタン
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'セリフを編集',
                    onPressed: () => viewModel.showEditDialog(context, viewModel, line, index),
                  ),
                  // 削除ボタン
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'セリフを削除',
                    onPressed: () => viewModel.showDeleteConfirmDialog(context, viewModel, index),
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