import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';  // テキスト読み上げ用
import 'package:flutter/services.dart';  // TextInputFormatter用
import 'dart:html' as html;  // Web用の機能
import 'dart:convert';  // 文字エンコーディング用
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';  // 動画生成用

import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

// 必要なウィジェットとモデルのインポート
import '../views/widgets/animation_dialog_section.dart';
import '../models/script_line.dart';

/// スクリプトエディタのViewModel - 状態管理とビジネスロジックを担当
class ScriptEditorViewModel extends ChangeNotifier {
  // コンストラクタ - ViewModelの初期化時にTTSも初期化
  ScriptEditorViewModel() {
    _initTts();
  }

  // === 定数定義 ===
  static const double minTiming = 0.0;  // 最小の間（秒）
  static const double maxTiming = 10.0;  // 最大の間（秒）
  static const double minSpeed = 0.5;  // 最小の速度
  static const double maxSpeed = 2.0;  // 最大の速度
  static const double maxVolume = 10.0;  // 最大の音量
  static const double minVolume = 0.5;  // 最小の音量
  static const double maxPitch = 0.15;  // 最大の声高
  static const double minPitch = -0.15;  // 最小の声高
  static const double maxIntonation = 3.0;  // 最小の抑揚
  static const double minIntonation = 0.0;  // 最小の抑揚


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
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String? _errorMessage;
  String? _generatedVideoPath;

  final AudioPlayer _audioPlayer = AudioPlayer(); // 音声再生用

  // スクリプト関連の状態
  final List<ScriptLine> _scriptLines = [];
  String _selectedCharacterType = 'ボケ';
  double _selectedTiming = 0.1;
  double _selectedSpeed = 1.0;
  double _selectedVolume = 1.0;
  double _selectedPitch = 0.0;
  double _selectedIntonation = 0.0;
  String? _bokeImage;
  String? _tsukkomiImage;
  String _bokeName = '';
  String _tsukkomiName = '';
  String _combiName = '';
  String _scriptName = '';
  int _bokeVoice = 1;
  int _tsukkomiVoice = 2;
  String? _selectedMusic;

    // 音楽再生関連のフィールドを追加
  html.AudioElement? _audioElement;
  bool _isPlaying = false;

  // 利用可能な音楽のリスト
  static const List<String> musicList = [
    'assets/music/2_23_AM.mp3',
    'assets/music/ALIVE_inst_FreeVer.mp3',
    'assets/music/CountdownToVictory_Free_Ver.mp3',
    'assets/music/FreeBGM_machine_head_remix.mp3',
    'assets/music/honey-remon350ml.mp3',
    'assets/music/honwaka-puppu.mp3',
    'assets/music/kaeruno-piano_2.mp3',
    'assets/music/kaeruno-piano.mp3',
    'assets/music/kakekko-kyoso.mp3',
    'assets/music/keen-fire-jean-drop-235365.mp3',
    'assets/music/maou_41_honeybaby_magicalgirl.mp3',
    'assets/music/noraneko-uchu.mp3',
    'assets/music/souzoushin.mp3',
    'assets/music/spinning-head-27171.mp3',
    'assets/music/vlog-music-beat-trailer-showreel.mp3',
    'assets/music/maou_short_14_shining_star.mp3',
    'assets/music/maou_short_19_12345.mp3',
    'assets/music/MusMus_BGM_061.mp3',
    'assets/music/MusMus_BGM_113.mp3',
    'assets/music/MusMus_BGM_136.mp3'
  ];

  // === ゲッター ===
  bool get isGenerating => _isGenerating;
  String? get errorMessage => _errorMessage;
  String? get generatedVideoPath => _generatedVideoPath;
  List<ScriptLine> get scriptLines => List.unmodifiable(_scriptLines);
  String get selectedCharacterType => _selectedCharacterType;
  double get selectedTiming => _selectedTiming;
  double get selectedSpeed => _selectedSpeed;
  double get selectedVolume => _selectedVolume;
  double get selectedPitch => _selectedPitch;
  double get selectedIntonation => _selectedIntonation;
  String? get bokeImage => _bokeImage;
  String? get tsukkomiImage => _tsukkomiImage;
  String get bokeName => _bokeName;
  String get tsukkomiName => _tsukkomiName;
  String get combiName => _combiName;
  double get generationProgress => _generationProgress;
  int get bokeVoice => _bokeVoice;
  int get tsukkomiVoice => _tsukkomiVoice;
  String? get selectedMusic => _selectedMusic;
  bool get isPlaying => _isPlaying;

  // === 声のタイプ（VoiceVox) ===
  static const List<DropdownMenuItem<int>> voiceTypeItems = [
    DropdownMenuItem(value: 1, child: Text('ずんだもん')),
    DropdownMenuItem(value: 2, child: Text('四国めたん')),
    DropdownMenuItem(value: 13, child: Text('青山龍星')),
    DropdownMenuItem(value: 30, child: Text('アナウンサー')),
    DropdownMenuItem(value: 40, child: Text('玄野武宏')),
    DropdownMenuItem(value: 42, child: Text('ちび式じい')),
    DropdownMenuItem(value: 45, child: Text('櫻歌ミコ')),
    DropdownMenuItem(value: 47, child: Text('ナースロボ＿タイプＴ')),
    DropdownMenuItem(value: 51, child: Text('†聖騎士 紅桜†')),
    DropdownMenuItem(value: 52, child: Text('雀松朱司')),
    DropdownMenuItem(value: 53, child: Text('麒ヶ島宗麟')),
    DropdownMenuItem(value: 67, child: Text('栗田まろん')),
    DropdownMenuItem(value: 69, child: Text('満別花丸')),
    DropdownMenuItem(value: 74, child: Text('琴詠ニア')),
    DropdownMenuItem(value: 88, child: Text('後鬼')),
  ];

  // === バリデーションメソッド ===
  // タイミングの値が適切な範囲内かチェック
  bool validateTiming(double timing) {
    return timing >= minTiming && timing <= maxTiming;
  }

  // スピードの値が適切な範囲内かチェック
  bool validateSpeed(double speed) {
    return speed >= minSpeed && speed <= maxSpeed;
  }

  // 声量の値が適切な範囲内かチェック
  bool validateVolume(double volume) {
    return volume >= minVolume && volume <= maxVolume;
  }

  // 音高の値が適切な範囲内かチェック
  bool validatePitch(double pitch) {
    return pitch >= minPitch && pitch <= maxPitch;
  }

  // 音高の値が適切な範囲内かチェック
  bool validateIntonation(double intonation) {
    return intonation >= minIntonation && intonation <= maxIntonation;
  }

  // テキストが空でないかチェック
  bool validateText(String text) {
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
    if (validateTiming(timing)) {
      _selectedTiming = timing;
      notifyListeners();
    }
  }

  // スピードの設定
  void setSelectedSpeed(double speed) {
    if (validateSpeed(speed)) {
      _selectedSpeed = speed;
      notifyListeners();
    }
  }

  //声量の設定
  void setSelectedVolume(double volume){
    if (validateVolume(volume)) {
      _selectedVolume = volume;
      notifyListeners();
    }
  }

  //声の高さ の設定
  void setSelectedPitch(double pitch){
    if (validatePitch(pitch)) {
      _selectedPitch = pitch;
      notifyListeners();
    }
  }

  //抑揚の設定
  void setSelectedIntonation(double intonation){
    if (validateIntonation(intonation)) {
      _selectedIntonation = intonation;
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
  void setScriptName(String name) {
    _scriptName = name;
    notifyListeners();
  }
  void setTsukkomiVoice(int speaker_id){
    _tsukkomiVoice = speaker_id;
    notifyListeners();
  }
  void setBokeVoice(int speaker_id){
    _bokeVoice = speaker_id;
    notifyListeners();
  }
  void setSelectedMusic(String? path) {
    stopMusic();
    _selectedMusic = path;
    notifyListeners();
  }

  

  // === 台本編集メソッド ===
  /// スクリプトラインの編集
  /// @param index 編集する行のインデックス
  /// @param text セリフ
  /// @param characterType キャラクタータイプ（ボケ/ツッコミ）
  /// @param timing 間（秒）
  /// @param speed 速度
  void editScriptLine(
      int index,
      String text,
      String characterType,
      double timing,
      double speed,
      double volume,
      double pitch,
      double intonation,
    ) {
    // 入力値のバリデーション
    if (!validateText(text)) {
      _errorMessage = 'セリフを入力してください';
      notifyListeners();
      return;
    }

    if (!validateTiming(timing)) {
      _errorMessage = '間は $minTiming ~ $maxTiming の範囲で入力してください';
      notifyListeners();
      return;
    }

    if (!validateSpeed(speed)) {
      _errorMessage = 'スピードは $minSpeed ~ $maxSpeed の範囲で入力してください';
      notifyListeners();
      return;
    }

    if (!validateVolume(volume)) {
      _errorMessage = '声量は $minVolume ~ $maxVolume の範囲で入力してください';
      notifyListeners();
      return;
    }

    if (!validatePitch(pitch)) {
      _errorMessage = '音高は $minPitch ~ $maxPitch の範囲で入力してください';
      notifyListeners();
      return;
    }

    if (!validateIntonation(pitch)) {
      _errorMessage = '抑揚は $minIntonation ~ $maxIntonation の範囲で入力してください';
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
        volume: volume,
        pitch: pitch,
        intonation: intonation
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

    print("_selectedSpeed:$_selectedSpeed ");
    print("_selectedVolume:$_selectedVolume ");
    print("_selectedPitch:$_selectedPitch ");
    _scriptLines.add(
      ScriptLine(
        characterType: _selectedCharacterType,
        timing: _selectedTiming,
        speed: _selectedSpeed,
        volume: _selectedVolume,
        pitch: _selectedPitch,
        intonation: _selectedIntonation,
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
      await playScriptLine(line);
    }
  } 
  
  
  // 1行だけ再生
  Future<void> playScriptLine(ScriptLine line) async {
    try {
      final speakerId = line.characterType == 'ボケ' ? bokeVoice : tsukkomiVoice;
      print("line.speed:${line.speed}");
      // FastAPIサーバーに音声合成リクエストを送信
      final response = await http.post(
        Uri.parse('http://localhost:8000/synthesis'),  // FastAPIサーバーのURL
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': line.text,
          'speaker_id': speakerId,
          'speed_scale': line.speed,
          'volume_scale': line.volume,
          'pitch_scale': line.pitch,
          'intonation_scale': line.intonation,
        }),
      );
      if (response.statusCode == 200) {
        // レスポンスの音声データをバイトデータとして取得
        final bytes = response.bodyBytes;
        
        // タイミング（間）の設定
        await Future.delayed(Duration(milliseconds: (line.timing * 1000).round()));
        // BytesSourceからAudioSourceを作成
        final audioSource = BytesSource(bytes);
        // 音声を再生
        await _audioPlayer.play(audioSource);
        // 音声の再生速度を設定（再生の後にすることで設定が反映される）
        // await _audioPlayer.setPlaybackRate(line.speed); //voicevox側で処理する。
        
        
      } else {
        throw Exception('音声合成に失敗しました');
      }
    } catch (e) {
      _errorMessage = '音声再生に失敗しました: ${e.toString()}';
      notifyListeners();
    }
  }
  // リソースの解放
  @override
  void dispose() {
    stopMusic();
    _audioElement = null;
    _tts.stop();
    _audioPlayer.dispose();  // AudioPlayerのdisposeも必要
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
            onComplete: () => Navigator.of(context).pop(),
            bokeImagePath: _bokeImage ?? '',
            tsukkomiImagePath: _tsukkomiImage ?? '',
            bokeVoice: _bokeVoice,
            tsukkomiVoice: _tsukkomiVoice,
            bokeName: _bokeName,
            tsukkomiName: _tsukkomiName,
            combiName: _combiName,
            scriptName: _scriptName,  // scriptNameをnetaNameとして使用
            musicPath: _selectedMusic,
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
  // == 台本編集画面関連 ==
  /// 削除確認ダイアログを表示
  Future<void> showDeleteConfirmDialog(
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
    Future<void> showEditDialog(
      BuildContext context,
      ScriptEditorViewModel viewModel,
      ScriptLine line,
      int index,
    ) async {
      // TextEditingControllerの初期化
      final textController = TextEditingController(text: line.text);
      final timingController = TextEditingController(text: line.timing.toString());
      final speedController = TextEditingController(text: line.speed.toString());
      final volumeController = TextEditingController(text: line.volume.toString());
      final pitchController = TextEditingController(text: line.pitch.toString());
      final intonationController = TextEditingController(text: line.intonation.toString());
      
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
                    helperText: '$minTiming ~ $maxTiming の範囲で入力',
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
                    helperText: '$minSpeed ~ $maxSpeed の範囲で入力',
                    border: const OutlineInputBorder(),
                    errorText: _validateSpeed(speedController.text),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                ),
                const SizedBox(height: 16),
                // 声量入力フィールド
                TextField(
                  controller: volumeController,
                  decoration: InputDecoration(
                    labelText: '声量（倍）',
                    helperText: '$minVolume ~ $maxVolume の範囲で入力',
                    border: const OutlineInputBorder(),
                    errorText: _validateSpeed(volumeController.text),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                ),
                const SizedBox(height: 16),
                // 声の高さ 入力フィールド
                TextField(
                  controller: pitchController,
                  decoration: InputDecoration(
                    labelText: '声の高さ（倍）',
                    helperText: '$minPitch ~ $maxPitch の範囲で入力',
                    border: const OutlineInputBorder(),
                    errorText: _validatePitch(pitchController.text),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                ),
                const SizedBox(height: 16),
                // 抑揚 入力フィールド
                TextField(
                  controller: intonationController,
                  decoration: InputDecoration(
                    labelText: '抑揚（倍）',
                    helperText: '$minIntonation ~ $maxIntonation の範囲で入力',
                    border: const OutlineInputBorder(),
                    errorText: _validateIntonation(intonationController.text),
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
                if (validateForm(
                  textController.text,
                  timingController.text,
                  speedController.text,
                  volumeController.text,
                  pitchController.text,
                  intonationController.text,
                  context,
                )) {
                  // すべてのバリデーションをパスした場合のみ保存
                  viewModel.editScriptLine(
                    index,
                    textController.text,
                    selectedType,
                    double.parse(timingController.text),
                    double.parse(speedController.text),
                    double.parse(volumeController.text),
                    double.parse(pitchController.text),
                    double.parse(intonationController.text),
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
      if (timing < minTiming || timing > maxTiming) {
        return '$minTiming ~ $maxTiming の範囲で入力してください';
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
      if (speed < minSpeed || speed > maxSpeed) {
        return '$minSpeed ~ $maxSpeed の範囲で入力してください';
      }
    } catch (e) {
      return '正しい数値を入力してください';
    }
    return null;
  }

  /// 声量の値をバリデーション
  String? _validateVolume(String value) {
    if (value.isEmpty) {
      return '値を入力してください';
    }
    try {
      final volume = double.parse(value);
      if (volume < minVolume || volume > maxVolume) {
        return '$minVolume ~ $maxVolume の範囲で入力してください';
      }
    } catch (e) {
      return '正しい数値を入力してください';
    }
    return null;
  }

  /// 声の高さ の値をバリデーション
  String? _validatePitch(String value) {
    if (value.isEmpty) {
      return '値を入力してください';
    }
    try {
      final pitch = double.parse(value);
      if (pitch < minPitch || pitch > maxPitch) {
        return '$minPitch ~ $maxPitch の範囲で入力してください';
      }
    } catch (e) {
      return '正しい数値を入力してください';
    }
    return null;
  }

  /// 抑揚の値をバリデーション
  String? _validateIntonation(String value) {
    if (value.isEmpty) {
      return '値を入力してください';
    }
    try {
      final intonation = double.parse(value);
      if (intonation < minIntonation || intonation > maxIntonation) {
        return '$minIntonation ~ $maxIntonation の範囲で入力してください';
      }
    } catch (e) {
      return '正しい数値を入力してください';
    }
    return null;
  }

  /// フォーム全体のバリデーション
  bool validateForm(
    String text,
    String timing,
    String speed,
    String volume,
    String pitch,
    String intonation,
    BuildContext context,
  ) {
    if (text.trim().isEmpty) {
      showError(context, 'セリフを入力してください');
      return false;
    }

    final timingError = _validateTiming(timing);
    if (timingError != null) {
      showError(context, timingError);
      return false;
    }

    final speedError = _validateSpeed(speed);
    if (speedError != null) {
      showError(context, speedError);
      return false;
    }

    final volumeError = _validateVolume(volume);
    if (volumeError != null) {
      showError(context, volumeError);
      return false;
    }

    final pitchError = _validatePitch(pitch);
    if (pitchError != null) {
      showError(context, pitchError);
      return false;
    }

    final intonationError = _validateIntonation(intonation);
    if (intonationError != null) {
      showError(context, intonationError);
      return false;
    }

    return true;
  }

  /// エラーメッセージを表示
  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 音楽再生
  void playMusic() {
    if (_selectedMusic != null) {
      _audioElement?.pause();
      _audioElement = html.AudioElement(_selectedMusic);
      _audioElement?.play();
      _isPlaying = true;
      notifyListeners();
    }
  }

  // 音楽停止
  void stopMusic() {
    _audioElement?.pause();
    if (_audioElement != null) {
      _audioElement!.currentTime = 0;
      _isPlaying = false;
      notifyListeners();
    }
  }
  // 表示用の音楽名を取得
  String getMusicDisplayName(String path) {
    final fileName = path.split('/').last;
    return fileName.replaceAll('.mp3', '').replaceAll('_', ' ');
  }  
}