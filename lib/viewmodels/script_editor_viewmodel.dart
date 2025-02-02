import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';  // テキスト読み上げ用
import 'package:flutter/services.dart';  // TextInputFormatter用
import 'dart:html' as html;  // Web用の機能
import 'dart:async';
import 'dart:convert';  // 文字エンコーディング用
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';  // 動画生成用

import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';

import 'package:shared_preferences/shared_preferences.dart';

// 必要なウィジェットとモデルのインポート
import '../views/widgets/animation_dialog_section.dart';
import '../models/script_line.dart';

/// スクリプトエディタのViewModel - 状態管理とビジネスロジックを担当
class ScriptEditorViewModel extends ChangeNotifier {
  // コンストラクタ - ViewModelの初期化時にTTSも初期化
  ScriptEditorViewModel({Map<String, dynamic>? scriptData}) {
    _initTts();
    if (scriptData != null) {
      // タイトルと名前の設定
      _scriptName = scriptData['title'];           
      _combiName = scriptData['combi_name'];         
      _bokeName = scriptData['left_chara'];          
      _tsukkomiName = scriptData['right_chara'];     
      
      // 画像パスの設定
      _bokeImage = scriptData['left_chara_path'];    
      _tsukkomiImage = scriptData['right_chara_path'];
      
      // BGMの設定
      _selectedMusic = scriptData['selectedMusic']; 
      print('Loaded script data: $scriptData'); // JSONデータの確認
      print('Initialized title: $_scriptName'); // 初期化された値の確認
      print('Initialized combi name: $_combiName');
      print('Initialized boke name: $_bokeName');
      print('Initialized tsukkomi name: $_tsukkomiName');

      // vvox speaker_idの設定
      if (scriptData['voices']?.isNotEmpty == true) {
        final voices = scriptData['voices'] as List<dynamic>;
        final bokeVoice = voices.firstWhere(
          (v) => v['characterType'] == 'left',
          orElse: () => {'speaker_id': 1}
        );
        final tsukkomiVoice = voices.firstWhere(
          (v) => v['characterType'] == 'right',
          orElse: () => {'speaker_id': 2}
        );
        
        _bokeVoice = bokeVoice['speaker_id'] ?? 1;
        _tsukkomiVoice = tsukkomiVoice['speaker_id'] ?? 2;
      }

      // 台本データの初期化
      final voices = scriptData['voices'] as List<dynamic>;
      _scriptLines.clear();
      for (var voice in voices) {
        _scriptLines.add(ScriptLine(
          text: voice['text'] ?? '',
          characterType: voice['characterType'] == 'left' ? 'ボケ' : 'ツッコミ',
          timing: voice['pre_phoneme_length']?.toDouble() ?? 0.1,
          speed: voice['speed_scale']?.toDouble() ?? 1.0,
          volume: voice['volume_scale']?.toDouble() ?? 1.0,
          pitch: voice['pitch_scale']?.toDouble() ?? 0.0,
          intonation: voice['intonation_scale']?.toDouble() ?? 0.0,
        ));
      }
      print('Initialized state - Title: $_scriptName, Combi: $_combiName');  // デバッグ用
      notifyListeners();
    }
    
  }

  // === 定数定義 ===
  static const double minTiming = -1.0;  // 最小の間（秒）
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

  // アニメーションダイアログの状態管理
  bool _isDisposed = false;
  bool _isDialogueAnimating = false;
  int _dialogueCurrentIndex = 0;
  bool _showInitialTitle = true;
  bool _showNetaTitle = false;
  bool _isDialogueStarted = false;
  StreamController<double>? _dialogueProgressController;
  Duration? _musicDuration;
  AudioPlayer? _bgmPlayer;

  // オーディオプール管理
  static const int _audioPlayerPoolSize = 3;
  late final List<AudioPlayer> _audioPlayerPool;
  final Map<int, BytesSource> _audioCache = {};
  final Map<int, Completer<void>> _audioCompleters = {};
  final Set<int> _prefetchingIndices = {};
  int _currentPlayerIndex = 0;


  

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
  String get scriptName => _scriptName;

  bool get isDialogueAnimating => _isDialogueAnimating;
  Duration? get musicDuration => _musicDuration;
  int get dialogueCurrentIndex => _dialogueCurrentIndex;
  bool get showInitialTitle => _showInitialTitle;
  bool get showNetaTitle => _showNetaTitle;
  bool get isDialogueStarted => _isDialogueStarted;
  Stream<double>? get dialogueProgress => _dialogueProgressController?.stream;


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

  // === 音声をmp3で保存 ===
  Future<void> createAudioFile() async {
    const String serverUrl = "http://localhost:8000";
    
    try {
      final script_dict = createVoicevoxScript();
      final response = await http.post(
        Uri.parse('$serverUrl/concat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(script_dict),
      );

      if (response.statusCode == 200) {
        // 成功時の処理
        print('音声結合API呼び出しが成功しました');
        // 
        print('response: ${response.body}');

        // responseDataを使用した処理を記述
      } else {
        print('APIエラー: ${response.statusCode}');
        throw Exception('Failed to call Voicevox API');
      }
    } catch (e) {
      print('エラーが発生しました: $e');
      rethrow;
    }
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
          viewModel: this,
          onComplete: () => Navigator.of(context).pop(),
        ),
      );
    },
  );
  
  // アニメーションダイアログの初期化を呼び出し
  initializeAnimationDialog();
}

  // === 漫才アニメ保存 ===
  Future<void> saveManzaiData(BuildContext context) async {
    try {
      final manzaiData = {
        "title": _scriptName,
        "combi_name": _combiName,
        "left_chara": _bokeName,
        "right_chara": _tsukkomiName,
        "left_chara_path": _bokeImage,
        "right_chara_path": _tsukkomiImage,
        "selectedMusic": _selectedMusic,
        "voices": _scriptLines.map((line) => {
          "text": line.text,
          "speaker_id": line.characterType == 'ボケ' ? _bokeVoice : _tsukkomiVoice,
          "characterType": line.characterType == 'ボケ' ? "left" : "right",
          "speed_scale": line.speed,
          "volume_scale": line.volume,
          "pitch_scale": line.pitch,
          "intonation_scale": line.intonation,
          "pre_phoneme_length": line.timing,
          "post_phoneme_length": 0.0
        }).toList()
      };

      final response = await http.post(
        Uri.parse('http://localhost:8000/save_manzai_script'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(manzaiData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('漫才データを保存しました'))
        );
      } else {
        throw Exception('サーバーエラー: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e'), backgroundColor: Colors.red)
      );
    }
  }
  // === 台本出力（.md） ===
  Future<void> exportMarkdown() async {
    final mdScript = StringBuffer();
    mdScript.writeln('# タイトル:$_scriptName');
    mdScript.writeln('\n');
    mdScript.writeln('# コンビ: $_combiName');
    mdScript.writeln('  * $_bokeName');
    mdScript.writeln('  * $_tsukkomiName');
    mdScript.writeln('\n');
    mdScript.writeln('# 台本:');
    for (var line in _scriptLines) {
      // キャラクター名と台詞を追加
      mdScript.writeln('* ${line.characterType == "ボケ" ? _bokeName : _tsukkomiName}: ${line.text}');
      // パラメータ情報を追加
      mdScript.writeln('  * スピード:${line.speed}x, 間:${line.timing}秒, 声量:${line.volume}, 声高:${line.pitch},抑揚:${line.intonation}');
    }
    // 2. ダウンロード用の設定
    final blob = html.Blob([utf8.encode(mdScript.toString())]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    html.AnchorElement()
      ..href = url
      ..download = '漫才台本_${_scriptName}_${_combiName}.md'
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
                    errorText: _validateVolume(volumeController.text),
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


  Future<void> generateVideo() async {
    if (_scriptLines.isEmpty) return;
    
    _isGenerating = true;
    _generationProgress = 0.0;
    notifyListeners();

    try {
      // 1. キャンバスとレコーダーの準備
      final canvas = html.CanvasElement(width: 1280, height: 720);
      final ctx = canvas.context2D;
      final recorder = html.MediaRecorder(canvas.captureStream());
      final List<html.Blob> chunks = []; // Changed from List<html.File> to List<html.Blob>
      
      final completer = Completer<void>();

      // 画像の読み込み
      html.ImageElement? bokeImage;
      html.ImageElement? tsukkomiImage;
      
      if (_bokeImage != null) {
        bokeImage = await _loadImage(_bokeImage!);
      }
      if (_tsukkomiImage != null) {
        tsukkomiImage = await _loadImage(_tsukkomiImage!);
      }

      // イベントリスナーの設定
      recorder.addEventListener('dataavailable', (html.Event event) {
        if (event is html.BlobEvent && event.data != null) {
          chunks.add(event.data!); // Add Blob directly instead of converting to File
        }
      });

      recorder.addEventListener('stop', (html.Event _) async {
        await _downloadVideo(chunks);
        completer.complete();
      });

      // 録画開始
      recorder.start();

      // 5. アニメーション再生
      var currentLine = 0;
      var startTime = DateTime.now();

      void animate() {
        if (currentLine >= _scriptLines.length) {
          recorder.stop();
          return;
        }

        // 現在のセリフを描画
        _drawFrame(ctx, _scriptLines[currentLine], bokeImage, tsukkomiImage);

        // 次のセリフに進むかチェック
        var elapsed = DateTime.now().difference(startTime).inMilliseconds / 1000;
        if (elapsed >= _scriptLines[currentLine].timing + 2.0) {
          currentLine++;
          startTime = DateTime.now();
          _generationProgress = currentLine / _scriptLines.length;
          notifyListeners();
        }

        html.window.requestAnimationFrame((_) => animate());
      }

      animate();
      await completer.future;

    } catch (e) {
      _errorMessage = '動画生成中にエラーが発生しました: $e';
    } finally {
      _isGenerating = false;
      _generationProgress = 1.0;
      notifyListeners();
    }
  }

  // 画像読み込み用のヘルパー
  Future<html.ImageElement> _loadImage(String src) async {
    final imageElement = html.ImageElement();
    final completer = Completer<html.ImageElement>();
    
    imageElement.onLoad.listen((_) => completer.complete(imageElement));
    imageElement.src = src;  // srcの設定を後にする
    
    return completer.future;
  }

  // フレーム描画用のヘルパー
  void _drawFrame(html.CanvasRenderingContext2D ctx, ScriptLine line,
      html.ImageElement? bokeImg, html.ImageElement? tsukkomiImg) {
    // 背景をクリア
    ctx.fillStyle = '#FFFFFF';
    ctx.fillRect(0, 0, ctx.canvas.width!, ctx.canvas.height!);

    // キャラクター画像を描画
    if (line.characterType == 'ボケ' && bokeImg != null) {
      ctx.drawImage(bokeImg, 100, 160);
    } else if (line.characterType == 'ツッコミ' && tsukkomiImg != null) {
      ctx.drawImage(tsukkomiImg, 880, 160);
    }

    // セリフを描画
    ctx.font = '32px Arial';
    ctx.fillStyle = '#000000';
    ctx.textAlign = 'center';
    ctx.fillText(line.text, ctx.canvas.width! / 2, ctx.canvas.height! * 0.8);
  }

  // 動画ダウンロード用のヘルパー
  Future<void> _downloadVideo(List<html.Blob> chunks) async {
    final blob = html.Blob(chunks, 'video/webm');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    html.AnchorElement()
      ..href = url
      ..download = '${_scriptName}_${DateTime.now().millisecondsSinceEpoch}.webm'
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  // アニメーションダイアログの初期化
  void initializeAnimationDialog() {
    _initializeAudioPlayers();
    _dialogueProgressController = StreamController<double>.broadcast();
    _initializeAndStartBGM();
  }

  void _initializeAudioPlayers() {
    _audioPlayerPool = List.generate(_audioPlayerPoolSize, (_) {
      final player = AudioPlayer();
      player.setReleaseMode(ReleaseMode.stop);
      return player;
    });
  }
  Future<void> _initializeAndStartBGM() async {
  if (_selectedMusic != null) {
    _bgmPlayer = AudioPlayer();
    try {
      final musicPath = _selectedMusic!.replaceAll('assets/', '');
      await _bgmPlayer!.setSource(AssetSource(musicPath));
      await _bgmPlayer!.setVolume(1.0);
      
      final duration = await _bgmPlayer!.getDuration();
      if (!_isDisposed) {
        _musicDuration = duration;
        notifyListeners();

        _bgmPlayer!.onPositionChanged.listen((Duration position) {
          if (duration != null && !_isDialogueStarted) {
            if (position.inMilliseconds >= duration.inMilliseconds - 1000) {
              if (!_isDialogueStarted) {
                _updateDialogueState(
                  showInitialTitle: false,
                  showNetaTitle: false,
                  isDialogueStarted: true,
                );
                _startPrefetching();
                _startAnimation();
              }
            }
          }
        });
      }

      _startTitleSequence();
      await _bgmPlayer!.play(AssetSource(musicPath));
      
    } catch (e) {
      print('BGM initialization error: $e');
      _startTitleSequenceWithoutMusic();
    }
  } else {
    _startTitleSequenceWithoutMusic();
  }
}

void _startTitleSequence() {
  _updateDialogueState(
    showInitialTitle: true,
    showNetaTitle: false,
  );

  Future.delayed(const Duration(seconds: 5), () {
    if (!_isDisposed) {
      _updateDialogueState(showNetaTitle: true);
    }
  });
}

void _startTitleSequenceWithoutMusic() {
  _updateDialogueState(
    showInitialTitle: true,
    showNetaTitle: false,
  );

  Future.delayed(const Duration(seconds: 5), () {
    if (!_isDisposed) {
      _updateDialogueState(showNetaTitle: true);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (!_isDisposed) {
          _updateDialogueState(
            showInitialTitle: false,
            showNetaTitle: false,
            isDialogueStarted: true,
          );
          _startPrefetching();
          _startAnimation();
        }
      });
    }
  });
}

void _updateDialogueState({
  bool? isAnimating,
  int? currentIndex,
  bool? showInitialTitle,
  bool? showNetaTitle,
  bool? isDialogueStarted,
}) {
  if (isAnimating != null) _isDialogueAnimating = isAnimating;
  if (currentIndex != null) _dialogueCurrentIndex = currentIndex;
  if (showInitialTitle != null) _showInitialTitle = showInitialTitle;
  if (showNetaTitle != null) _showNetaTitle = showNetaTitle;
  if (isDialogueStarted != null) _isDialogueStarted = isDialogueStarted;
  notifyListeners();
}

Future<void> _startPrefetching() async {
  const int _prefetchCount = 2;
  for (var i = 0; i < _prefetchCount; i++) {
    final nextIndex = _dialogueCurrentIndex + i;
    if (nextIndex < _scriptLines.length) {
      _prefetchAudio(nextIndex);
    }
  }
}

// === 変数からvoicevox用に台本全体を作成 ===  
Map<String, dynamic> createVoicevoxScript() {
  // voicesリストの作成
  final List<Map<String, dynamic>> voices = _scriptLines.map((line) => {
    "text": line.text,
    "speaker_id": line.characterType == 'ボケ' ? _bokeVoice : _tsukkomiVoice,
    "characterType": line.characterType == 'ボケ' ? "left" : "right",
    "speed_scale": _selectedSpeed,
    "volume_scale": _selectedVolume,
    "pitch_scale": _selectedPitch,
    "intonation_scale": _selectedIntonation,
    "pre_phoneme_length": _selectedTiming,
    "post_phoneme_length": 0.0
  }).toList();

  // 最終的なスクリプト構造の作成
  return {
    "title": _scriptName,
    "combi_name": _combiName,
    "left_chara": _bokeName,
    "right_chara": _tsukkomiName,
    "left_chara_path": _bokeImage,
    "right_chara_path": _tsukkomiImage,
    "voices": voices
  };
}

Future<void> _prefetchAudio(int index) async {
  if (_audioCache.containsKey(index) || 
      _prefetchingIndices.contains(index) || 
      index >= _scriptLines.length) {
    return;
  }

  _prefetchingIndices.add(index);
  try {
    final audio = await _synthesizeAnimationAudio(_scriptLines[index]);
    if (!_isDisposed) {
      _audioCache[index] = audio;
    }
  } catch (e) {
    print('Prefetch error for index $index: $e');
  } finally {
    _prefetchingIndices.remove(index);
  }
}

Future<BytesSource> _synthesizeAnimationAudio(ScriptLine line) async {
  final speakerId = line.characterType == 'ボケ' ? _bokeVoice : _tsukkomiVoice;
  
  try {
    final response = await http.post(
      Uri.parse('http://localhost:8000/synthesis'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': line.text,
        'speaker_id': speakerId,
        'speed_scale': line.speed,
        'volume_scale': line.volume,
        'pitch_scale': line.pitch,
        'intonation_scale': line.intonation,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return BytesSource(response.bodyBytes);
    }
    throw Exception('音声合成エラー: ${response.statusCode}');
  } catch (e) {
    throw Exception('音声合成リクエストエラー: $e');
  }
}

Future<void> _startAnimation() async {
  if (_dialogueCurrentIndex >= _scriptLines.length || _isDisposed) {
    return;
  }

  _updateDialogueState(isAnimating: true);
  
  final currentLine = _scriptLines[_dialogueCurrentIndex];

  try {
    BytesSource? audioSource = _audioCache[_dialogueCurrentIndex];
    if (audioSource == null) {
      audioSource = await _synthesizeAnimationAudio(currentLine);
      _audioCache[_dialogueCurrentIndex] = audioSource;
    }

    await _playAnimationAudio(currentLine, audioSource);

    if (_isDisposed) return;

    _updateDialogueState(
      isAnimating: false,
      currentIndex: _dialogueCurrentIndex + 1,
    );

    _dialogueProgressController?.add(_dialogueCurrentIndex / _scriptLines.length);
    
    _audioCache.removeWhere((key, _) => key < _dialogueCurrentIndex - 1);
    
    _prefetchAudio(_dialogueCurrentIndex + 2);

    await Future.delayed(const Duration(milliseconds: 300));
    _startAnimation();
  } catch (e) {
    if (!_isDisposed) {
      _updateDialogueState(isAnimating: false);
      print('Animation error: $e');
    }
  }
}
Future<void> _playAnimationAudio(ScriptLine line, BytesSource audioSource) async {
  final completer = Completer<void>();
  _audioCompleters[_dialogueCurrentIndex] = completer;

  final currentPlayer = _audioPlayerPool[_currentPlayerIndex];
  _currentPlayerIndex = (_currentPlayerIndex + 1) % _audioPlayerPool.length;

  try {
    await currentPlayer.stop();
    final subscription = currentPlayer.onPlayerComplete.listen((_) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    await currentPlayer.play(audioSource);
    
    await Future.wait([
      completer.future,
      if (line.timing > 0)
        Future.delayed(Duration(milliseconds: (line.timing * 1000).round())),
    ]);
    
    subscription.cancel();
  } catch (e) {
    print('Audio playback error: $e');
    if (!completer.isCompleted) {
      completer.completeError(e);
    }
  }
}

}