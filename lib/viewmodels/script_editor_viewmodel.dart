import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';  // テキスト読み上げ用
import 'dart:html' as html;  // Web用の機能
import 'dart:convert';  // 文字エンコーディング用
import 'package:path_provider/path_provider.dart';  // ファイルパス取得用
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';  // 動画生成用
import 'dart:ui' as ui;  // UI関連の機能
import 'dart:io';  // ファイル操作用

// 必要なウィジェットとモデルのインポート
import '../views/widgets/animation_dialog_section.dart';
import '../models/video_generator.dart';
import '../models/script_line.dart';

/// スクリプトエディタのViewModel - 状態管理とビジネスロジックを担当
class ScriptEditorViewModel extends ChangeNotifier {
  // コンストラクタ - ViewModelの初期化時にTTSも初期化
  ScriptEditorViewModel() {
    _initTts();
  }

  // === 定数定義 ===
  static const double minTiming = 0.1;  // 最小の間（秒）
  static const double maxTiming = 10.0;  // 最大の間（秒）
  static const double minSpeed = 0.5;  // 最小の速度
  static const double maxSpeed = 2.0;  // 最大の速度

  // TTSの初期化メソッド
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ja-JP');  // 日本語に設定
      await _tts.setPitch(1.0);         // 声の高さを標準に
      await _tts.setSpeechRate(1.0);    // 話速を標準に
    } catch (e) {
      _errorMessage = 'TTSの初期化に失敗しました';
      notifyListeners();
    }
  }

  // === インスタンス変数 ===
  final FlutterTts _tts = FlutterTts();
  final VideoGenerator _videoGenerator = VideoGenerator();
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String? _errorMessage;
  String? _generatedVideoPath;

  // スクリプト関連の状態
  final List<ScriptLine> _scriptLines = [];
  String _selectedCharacterType = 'ボケ';
  double _selectedTiming = 0.2;
  double _selectedSpeed = 1.0;
  String? _bokeImage;
  String? _tsukkomiImage;
  String _bokeName = '';
  String _tsukkomiName = '';
  String _combiName = '';

  // === ゲッター ===
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
  double get generationProgress => _generationProgress;

  // === バリデーションメソッド ===
  // タイミングの値が適切な範囲内かチェック
  bool _validateTiming(double timing) {
    return timing >= minTiming && timing <= maxTiming;
  }

  // スピードの値が適切な範囲内かチェック
  bool _validateSpeed(double speed) {
    return speed >= minSpeed && speed <= maxSpeed;
  }

  // テキストが空でないかチェック
  bool _validateText(String text) {
    return text.trim().isNotEmpty;
  }

  // === セッター ===
  // キャラクタータイプの設定
  void setSelectedCharacterType(String type) {
    if (type == 'ボケ' || type == 'ツッコミ') {
      _selectedCharacterType = type;
      notifyListeners();
    }
  }

  // タイミングの設定
  void setSelectedTiming(double timing) {
    if (_validateTiming(timing)) {
      _selectedTiming = timing;
      notifyListeners();
    }
  }

  // スピードの設定
  void setSelectedSpeed(double speed) {
    if (_validateSpeed(speed)) {
      _selectedSpeed = speed;
      notifyListeners();
    }
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

  // === 台本編集メソッド ===
  /// スクリプトラインの編集
  /// @param index 編集する行のインデックス
  /// @param text セリフ
  /// @param characterType キャラクタータイプ（ボケ/ツッコミ）
  /// @param timing 間（秒）
  /// @param speed 速度
  void editScriptLine(int index, String text, String characterType, double timing, double speed) {
    // 入力値のバリデーション
    if (!_validateText(text)) {
      _errorMessage = 'セリフを入力してください';
      notifyListeners();
      return;
    }

    if (!_validateTiming(timing)) {
      _errorMessage = '間は $minTiming ~ $maxTiming の範囲で入力してください';
      notifyListeners();
      return;
    }

    if (!_validateSpeed(speed)) {
      _errorMessage = 'スピードは $minSpeed ~ $maxSpeed の範囲で入力してください';
      notifyListeners();
      return;
    }

    try {
      // インデックスの範囲チェック
      if (index < 0 || index >= _scriptLines.length) {
        throw RangeError('無効なインデックスです: $index');
      }

      // スクリプトラインの更新
      _scriptLines[index] = ScriptLine(
        text: text.trim(),
        characterType: characterType,
        timing: timing,
        speed: speed,
      );

      // エラーメッセージをクリアして更新を通知
      _errorMessage = null;
      notifyListeners();

    } catch (e) {
      _errorMessage = '台本の更新に失敗しました';
      notifyListeners();
    }
  }

  // スクリプトラインの並び替え
  void reorderScriptLine(int oldIndex, int newIndex) {
    if (oldIndex < 0 || newIndex < 0 || 
        oldIndex >= _scriptLines.length || 
        newIndex >= _scriptLines.length) {
      return;
    }
    
    final line = _scriptLines.removeAt(oldIndex);
    _scriptLines.insert(newIndex, line);
    notifyListeners();
  }

  // スクリプトラインの追加
  void addScriptLine(String text) {
    if (text.trim().isEmpty) return;
    
    _scriptLines.add(
      ScriptLine(
        characterType: _selectedCharacterType,
        timing: _selectedTiming,
        speed: _selectedSpeed,
        text: text.trim(),
      ),
    );
    notifyListeners();
  }

  // スクリプトラインの削除
  void removeScriptLine(int index) {
    if (index < 0 || index >= _scriptLines.length) return;
    
    _scriptLines.removeAt(index);
    notifyListeners();
  }

  // === 台本音声再生 ===
  Future<void> playScript() async {
    for (var line in _scriptLines) {
      if (line.timing > 0) {
        await Future.delayed(Duration(milliseconds: (line.timing * 1000).round()));
      }

      await _tts.setPitch(line.characterType == 'ボケ' ? 1.3 : 0.8);
      await _tts.setSpeechRate(line.speed);
      await _tts.speak(line.text);
    }
  }

  // リソースの解放
  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // === アニメーションダイアログ ===
  void startAnimation(BuildContext context) {
    if (_scriptLines.isEmpty) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: AnimationDialog(
            dialogues: _scriptLines,
            tts: _tts,
            onComplete: () => Navigator.of(context).pop(),
            bokeImagePath: _bokeImage ?? '',
            tsukkomiImagePath: _tsukkomiImage ?? '',
          ),
        );
      },
    );
  }

  // === CSV出力 ===
  Future<void> exportCsv() async {
    final csvContent = _scriptLines.map((line) =>
      '${line.characterType},${line.text},${line.timing},${line.speed}'
    ).join('\n');
    
    final withHeader = 'キャラクター,セリフ,間(秒),スピード(x)\n$csvContent';
    final bytes = utf8.encode(withHeader);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // ダウンロードリンクの作成と実行
    html.AnchorElement(href: url)
      ..setAttribute('download', '台本_${DateTime.now().millisecondsSinceEpoch}.csv')
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}