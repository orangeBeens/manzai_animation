import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:html' as html;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'dart:ui' as ui;
import 'dart:io';
import '../models/video_generator.dart';
import '../models/video_config.dart';
import '../models/script_line.dart';



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
  double _generationProgress = 0.0; //生成プログレス
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
  double get generationProgress => _generationProgress;

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

  // 動画生成
  Future<void> generateVideo() async {
    if (_scriptLines.isEmpty) return;
    
    try {
      _isGenerating = true;
      notifyListeners();

      final tempDir = await getTemporaryDirectory();
      final framesPaths = <String>[];

      // フレーム生成
      for (var i = 0; i < _scriptLines.length; i++) {
        _generationProgress = i / _scriptLines.length;
        notifyListeners();

        final frame = await _generateFrame(_scriptLines[i]);
        final path = '${tempDir.path}/frame_$i.png';
        
        // フレームを保存
        final byteData = await frame.toByteData(
          format: ui.ImageByteFormat.png
        );
        await File(path).writeAsBytes(
          byteData!.buffer.asUint8List()
        );
        
        framesPaths.add(path);
      }

      // FFmpegで動画生成
      final outputPath = '${await getApplicationDocumentsDirectory()}/manzai_${DateTime.now().millisecondsSinceEpoch}.mp4';
      
      await FFmpegKit.execute(
        '-framerate 30 -i ${tempDir.path}/frame_%d.png '
        '-c:v libx264 -pix_fmt yuv420p $outputPath'
      );

    } finally {
      _isGenerating = false;
      _generationProgress = 0.0;
      notifyListeners();
    }
  }
  Future<ui.Image> _generateFrame(ScriptLine line) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = const Size(1280, 720);

    // 背景を白で描画
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.white,
    );

    // キャラクター画像の描画（ボケとツッコミ）
    if (_bokeImage != null || _tsukkomiImage != null) {
      await _drawCharacters(canvas, size, line);
    }

    // セリフの描画
    _drawDialog(canvas, size, line);

    return recorder.endRecording().toImage(
      size.width.toInt(),
      size.height.toInt(),
    );
  }
  Future<void> _drawCharacters(Canvas canvas, Size size, ScriptLine line) async {
    final characterImage = line.characterType == 'ボケ' ? _bokeImage : _tsukkomiImage;
    if (characterImage == null) return;

    try {
      final file = File(characterImage);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      final destRect = Rect.fromLTWH(
        line.characterType == 'ボケ' ? 100 : size.width - 300,
        size.height - 400,
        200,
        300,
      );

      canvas.drawImageRect(
        frame.image,
        Rect.fromLTWH(0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
        destRect,
        Paint(),
      );
    } catch (e) {
      debugPrint('キャラクター画像の描画エラー: $e');
    }
  }
  void _drawDialog(Canvas canvas, Size size, ScriptLine line) {
    final textSpan = TextSpan(
      text: line.text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width * 0.6);

    // 吹き出しの背景
    final bubbleRect = Rect.fromLTWH(
      size.width * 0.2,
      50,
      size.width * 0.6,
      textPainter.height + 40,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(bubbleRect, const Radius.circular(20)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..strokeWidth = 2,
    );

    // テキスト描画
    textPainter.paint(
      canvas,
      Offset(size.width * 0.2 + 20, 70),
    );
  }
}