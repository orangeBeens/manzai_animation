import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // TextInputFormatter用
import 'package:provider/provider.dart';
import '../../viewmodels/script_editor_viewmodel.dart';
import '../../models/script_line.dart';

/// スクリプトのリストを表示・編集するウィジェット
class ScriptListSection extends StatelessWidget {
  const ScriptListSection({Key? key}) : super(key: key);

  // 定数の定義
  static const double _minTiming = 0.1;
  static const double _maxTiming = 10.0;
  static const double _minSpeed = 0.5;
  static const double _maxSpeed = 2.0;

  @override
  Widget build(BuildContext context) {
    // ViewModelのインスタンスを取得
    final viewModel = Provider.of<ScriptEditorViewModel>(context);
    
    return Expanded(
      child: ListView.builder(
        itemCount: viewModel.scriptLines.length,
        itemBuilder: (context, index) {
          final line = viewModel.scriptLines[index];
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              // キャラクタータイプを表示（ボケ/ツッコミ）
              leading: Container(
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
              title: Text(line.text),
              subtitle: Text(
                '間: ${line.timing.toStringAsFixed(1)}秒, スピード: ${line.speed.toStringAsFixed(2)}x',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 編集ボタン
                  IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'セリフを編集',
                    onPressed: () => _showEditDialog(context, viewModel, line, index),
                  ),
                  // 削除ボタン
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: 'セリフを削除',
                    onPressed: () => _showDeleteConfirmDialog(context, viewModel, index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 削除確認ダイアログを表示
  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    ScriptEditorViewModel viewModel,
    int index,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('確認'),
        content: const Text('このセリフを削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      viewModel.removeScriptLine(index);
    }
  }

  /// 編集ダイアログを表示
  Future<void> _showEditDialog(
    BuildContext context,
    ScriptEditorViewModel viewModel,
    ScriptLine line,
    int index,
  ) async {
    // TextEditingControllerの初期化
    final textController = TextEditingController(text: line.text);
    final timingController = TextEditingController(text: line.timing.toString());
    final speedController = TextEditingController(text: line.speed.toString());
    String selectedType = line.characterType;

    // TextEditingControllerのdispose用
    bool isDialogClosed = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('セリフを編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // キャラクター選択ドロップダウン
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'キャラクター',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'ボケ', child: Text('ボケ')),
                  DropdownMenuItem(value: 'ツッコミ', child: Text('ツッコミ')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
              ),
              const SizedBox(height: 16),
              // セリフ入力フィールド
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'セリフ',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // 間（タイミング）入力フィールド
              TextField(
                controller: timingController,
                decoration: InputDecoration(
                  labelText: '間（秒）',
                  helperText: '$_minTiming ~ $_maxTiming の範囲で入力',
                  border: const OutlineInputBorder(),
                  errorText: _validateTiming(timingController.text),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),
              const SizedBox(height: 16),
              // スピード入力フィールド
              TextField(
                controller: speedController,
                decoration: InputDecoration(
                  labelText: 'スピード（x）',
                  helperText: '$_minSpeed ~ $_maxSpeed の範囲で入力',
                  border: const OutlineInputBorder(),
                  errorText: _validateSpeed(speedController.text),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              isDialogClosed = true;
              Navigator.pop(context);
            },
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (_validateForm(
                textController.text,
                timingController.text,
                speedController.text,
                context,
              )) {
                // すべてのバリデーションをパスした場合のみ保存
                viewModel.editScriptLine(
                  index,
                  textController.text,
                  selectedType,
                  double.parse(timingController.text),
                  double.parse(speedController.text),
                );
                isDialogClosed = true;
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    ).then((_) {
      // ダイアログが閉じられたときのクリーンアップ
      if (!isDialogClosed) {
        textController.dispose();
        timingController.dispose();
        speedController.dispose();
      }
    });
  }

  /// タイミングの値をバリデーション
  String? _validateTiming(String value) {
    if (value.isEmpty) {
      return '値を入力してください';
    }
    try {
      final timing = double.parse(value);
      if (timing < _minTiming || timing > _maxTiming) {
        return '$_minTiming ~ $_maxTiming の範囲で入力してください';
      }
    } catch (e) {
      return '正しい数値を入力してください';
    }
    return null;
  }

  /// スピードの値をバリデーション
  String? _validateSpeed(String value) {
    if (value.isEmpty) {
      return '値を入力してください';
    }
    try {
      final speed = double.parse(value);
      if (speed < _minSpeed || speed > _maxSpeed) {
        return '$_minSpeed ~ $_maxSpeed の範囲で入力してください';
      }
    } catch (e) {
      return '正しい数値を入力してください';
    }
    return null;
  }

  /// フォーム全体のバリデーション
  bool _validateForm(
    String text,
    String timing,
    String speed,
    BuildContext context,
  ) {
    if (text.trim().isEmpty) {
      _showError(context, 'セリフを入力してください');
      return false;
    }

    final timingError = _validateTiming(timing);
    if (timingError != null) {
      _showError(context, timingError);
      return false;
    }

    final speedError = _validateSpeed(speed);
    if (speedError != null) {
      _showError(context, speedError);
      return false;
    }

    return true;
  }

  /// エラーメッセージを表示
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}