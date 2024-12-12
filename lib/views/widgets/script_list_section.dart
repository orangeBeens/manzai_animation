// 必要なパッケージをインポート
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ViewModelクラスをインポート（状態管理用）
import '../../viewmodels/script_editor_viewmodel.dart';

// スクリプトのリストを表示するウィジェットを定義
class ScriptListSection extends StatelessWidget {
  // コンストラクタ。key はウィジェットの一意の識別子として使用
  const ScriptListSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Providerを使用してViewModelのインスタンスを取得
    // これにより状態（データ）にアクセスできる
    final viewModel = Provider.of<ScriptEditorViewModel>(context);
    
    // Expandedは親ウィジェットの残りのスペースを全て使用
    return Expanded(
      // ListView.builderは効率的なスクロール可能リストを作成
      // 画面に表示される項目のみを生成する
      child: ListView.builder(
        // リストの項目数を指定
        itemCount: viewModel.scriptLines.length,
        // 各項目のUIを構築するビルダー関数
        itemBuilder: (context, index) {
          // 現在の行のデータを取得
          final line = viewModel.scriptLines[index];
          
          // CardウィジェットでマテリアルデザインのカードUIを作成
          return Card(
            // ListTileは行アイテムの標準的なレイアウトを提供
            child: ListTile(
              // leadingは行の先頭に表示される要素
              leading: Text(line.characterType),
              // titleは主要なテキスト
              title: Text(line.text),
              // subtitleは補足情報
              // 文字列補間を使用してタイミングとスピードを表示
              subtitle: Text(
                '間: ${line.timing}秒, スピード: ${line.speed}x',
              ),
              // trailingは行の末尾に表示される要素
              trailing: IconButton(
                // 削除アイコンを表示
                icon: const Icon(Icons.delete),
                // タップ時の処理を定義
                // indexで指定された行を削除
                onPressed: () => viewModel.removeScriptLine(index),
              ),
            ),
          );
        },
      ),
    );
  }
}