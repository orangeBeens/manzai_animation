import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/script_editor_viewmodel.dart';
import './widgets/character_input_section.dart';
import './widgets/script_input_section.dart';
import './widgets/timing_control_section.dart';
import './widgets/script_list_section.dart';
import './widgets/action_buttons_section.dart';

class ScriptEditorView extends StatelessWidget {
  final Map<String, dynamic>? scriptData;
  const ScriptEditorView({super.key, this.scriptData});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScriptEditorViewModel(
          scriptData:
              scriptData), //ここのコードにより、セリフ追加/再生ボタンなどすべての子widgetがviewmodelにアクセスできるようになる。
      child: Scaffold(
        appBar: AppBar(
          title: const Text('漫才台本エディタ'),
        ),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CharacterInputSection(), //キャラクター、コンビ名入力
              SizedBox(height: 16),
              ScriptInputSection(), //台本入力
              SizedBox(height: 16),
              TimingControlSection(), //間とスピードの入力
              SizedBox(height: 16),
              ScriptListSection(), //台本表示
              ActionButtonsSection(), //台本再生、動画生成
            ],
          ),
        ),
      ),
    );
  }
}
