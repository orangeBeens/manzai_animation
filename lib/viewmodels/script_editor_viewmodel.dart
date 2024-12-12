import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/video_generator.dart';
import '../models/video_config.dart';
import '../models/script_line.dart';
import 'dart:html' as html;
import 'dart:convert';


class ScriptEditorViewModel extends ChangeNotifier {
  // 台本音声再生
    ScriptEditorViewModel() {
    _initTts(); // TTSの初期化メソッドを追加
  }
  // TTSの初期化
  Future<void> _initTts() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(1.0);
  }

  final FlutterTts _tts = FlutterTts();
  
  // 動画生成に関する状態管理
  final VideoGenerator _videoGenerator = VideoGenerator();
  bool _isGenerating = false;      // 生成中フラグ
  String? _errorMessage;           // エラーメッセージ
  String? _generatedVideoPath;     // 生成された動画のパス

  // 台本のデータモデルを管理
  final List<ScriptLine> _scriptLines = [];     // 台本の各行
  String _selectedCharacterType = 'ボケ';       // 現在選択中のキャラクター
  double _selectedTiming = 0.2;                 // 発話タイミング
  double _selectedSpeed = 1.0;                  // 発話速度
  String? _bokeImage;                          // ボケキャラの画像パス
  String? _tsukkomiImage;                      // ツッコミキャラの画像パス
  String _bokeName = '';                       // ボケの名前
  String _tsukkomiName = '';                   // ツッコミの名前
  String _combiName = '';                      // コンビ名


  // ゲッター
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  String? get generatedVideoPath => _generatedVideoPath;
  List<ScriptLine> get scriptLines => List.unmodifiable(_scriptLines);
  String get selectedCharacterType => _selectedCharacterType;
  double get selectedTiming => _selectedTiming;
  double get selectedSpeed => _selectedSpeed;
  String? get bokeImage => _bokeImage;
  String? get tsukkomiImage => _tsukkomiImage;
  String get bokeName => _bokeName;
  String get tsukkomiName => _tsukkomiName;
  String get combiName => _combiName;

  // セッター: 値の更新と画面の再描画を一緒に行う
  void setSelectedCharacterType(String type) {
    _selectedCharacterType = type;
    notifyListeners(); // Providerに変更を通知して画面を更新
  }

  void setSelectedTiming(double timing) {
    _selectedTiming = timing;
    notifyListeners();
  }

  void setSelectedSpeed(double speed) {
    _selectedSpeed = speed;
    notifyListeners();
  }

  void setBokeImage(String? path) {
    _bokeImage = path;
    notifyListeners();
  }

  void setTsukkomiImage(String? path) {
    _tsukkomiImage = path;
    notifyListeners();
  }

  void setBokeName(String name) {
    _bokeName = name;
    notifyListeners();
  }

  void setTsukkomiName(String name) {
    _tsukkomiName = name;
    notifyListeners();
  }

  void setCombiName(String name) {
    _combiName = name;
    notifyListeners();
  }

  // 台本操作メソッド
  void addScriptLine(String text) {
    if (text.isEmpty) return;
    
    _scriptLines.add(
      ScriptLine(
        characterType: _selectedCharacterType,
        timing: _selectedTiming,
        speed: _selectedSpeed,
        text: text,
      ),
    );
    notifyListeners();
  }

  void removeScriptLine(int index) {
    _scriptLines.removeAt(index);
    notifyListeners();
  }
  // 台本音声再生メソッド
  Future<void> playScript() async {
    for (var line in scriptLines) {
      if (line.timing > 0) {
        await Future.delayed(Duration(milliseconds: (line.timing * 1000).round()));
      }

      // ボケ、ツッコミで声の高さを変える
      await _tts.setPitch(line.characterType == 'ボケ' ? 1.3 : 0.8);
      await _tts.setSpeechRate(line.speed * 1.2);
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(line.text);
    }
    notifyListeners();
  }

  // 動画生成メソッド
  Future<void> generateVideo() async {
    try {
      _isGenerating = true;
      _errorMessage = null;
      _generatedVideoPath = null;
      notifyListeners();

      final config = VideoConfig(
        combiName: _combiName,
        bokeName: _bokeName,
        tsukkomiName: _tsukkomiName,
        bokeImagePath: _bokeImage,
        tsukkomiImagePath: _tsukkomiImage,
        scriptLines: _scriptLines,
      );

      final videoPath = await _videoGenerator.generate(config);
      _generatedVideoPath = videoPath;
      
      _isGenerating = false;
      notifyListeners();
      
    } catch (e) {
      _errorMessage = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }
  //台本csv保存メソッド
  Future<void> exportCsv() async {
    final csvContent = scriptLines.map((line) =>
      '${line.characterType},${line.text},${line.timing},${line.speed}'
    ).join('\n');
    
    final withHeader = 'キャラクター,セリフ,間(秒),スピード(x)\n$csvContent';
    final bytes = utf8.encode(withHeader);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', '台本_${DateTime.now().millisecondsSinceEpoch}.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}