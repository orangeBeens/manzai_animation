// viewmodels/animation_dialog_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';  // Completerを使用するために必要
import 'dart:convert';  // 文字エンコーディング用
import '../models/script_line.dart';

class AnimationDialogViewModel extends ChangeNotifier {
  final List<ScriptLine> dialogues;
  final FlutterTts tts;
  final VoidCallback onComplete;

  // 複数のAudioPlayerを管理
  final List<AudioPlayer> _audioPlayers = [
    AudioPlayer(),
    AudioPlayer(),
  ];
  int _currentPlayerIndex = 0;

  // 音声データのキャッシュ
  final Map<int, BytesSource> _audioCache = {};
  
  int _currentIndex = 0;
  bool _isAnimating = false;
  bool _isPrefetching = false;
  
  int get currentIndex => _currentIndex;
  bool get isAnimating => _isAnimating;
  bool get isCompleted => _currentIndex >= dialogues.length;
  
  ScriptLine? get currentLine => 
    isCompleted ? null : dialogues[_currentIndex];

  AnimationDialogViewModel({
    required this.dialogues,
    required this.tts,
    required this.onComplete,
  }) {
    // 初期化時に最初の音声をプリフェッチ
    _prefetchNextAudio();
  }

  // 次の音声をプリフェッチする
  Future<void> _prefetchNextAudio() async {
    if (_isPrefetching || isCompleted || _currentIndex >= dialogues.length - 1) return;
    
    _isPrefetching = true;
    
    try {
      final nextIndex = _currentIndex + 1;
      if (!_audioCache.containsKey(nextIndex)) {
        final audio = await _synthesizeAudio(dialogues[nextIndex]);
        _audioCache[nextIndex] = audio;
      }
      
      // 古いキャッシュをクリア
      _audioCache.removeWhere((key, value) => key < _currentIndex);
    } finally {
      _isPrefetching = false;
    }
  }

  Future<BytesSource> _synthesizeAudio(ScriptLine line) async {
    final response = await http.post(
      Uri.parse('http://localhost:8000/synthesis'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': line.text,
        'speaker_id': 20,
      }),
    );

    if (response.statusCode == 200) {
      return BytesSource(response.bodyBytes);
    } else {
      throw Exception('音声合成に失敗しました');
    }
  }

  Future<void> startAnimation() async {
    if (isCompleted) {
      onComplete();
      return;
    }

    _isAnimating = true;
    notifyListeners();

    final line = currentLine!;
    
    if (line.timing > 0) {
      await Future.delayed(
        Duration(milliseconds: (line.timing * 1000).round())
      );
    }

    try {
      // キャッシュから音声を取得するか、なければ新規取得
      BytesSource audioSource;
      if (_audioCache.containsKey(_currentIndex)) {
        audioSource = _audioCache[_currentIndex]!;
      } else {
        audioSource = await _synthesizeAudio(line);
        _audioCache[_currentIndex] = audioSource;
      }

      await _playAudio(line, audioSource);
      
      _currentIndex++;
      _isAnimating = false;
      notifyListeners();

      // 次の音声をバックグラウンドでプリフェッチ
      _prefetchNextAudio();

      await Future.delayed(const Duration(milliseconds: 300));
      startAnimation();
    } catch (e) {
      _isAnimating = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _playAudio(ScriptLine line, BytesSource audioSource) async {
    // 非同期処理の完了を待つためのCompleterを作成
    final completer = Completer<void>();
    // 現在使用するAudioPlayerを取得
    final currentPlayer = _audioPlayers[_currentPlayerIndex];
    
    try {
      // まず再生中の音声があれば停止
      await currentPlayer.stop();
      
      // 音声再生完了時のイベントリスナーを設定
      final subscription = currentPlayer.onPlayerComplete.listen((_) {
        // まだcompleteしていない場合のみ完了を通知
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      // ★ここが重要な変更点1★
      // 以前: final playResult = await currentPlayer.play(audioSource);
      // playの戻り値を変数に入れようとしていたのを修正
      await currentPlayer.play(audioSource);
      
      // ★ここが重要な変更点2★
      // play()の完了を待ってから速度を設定することで
      // 再生速度の変更が確実に反映されるようになった
      await currentPlayer.setPlaybackRate(line.speed);
      
      // 次回使用するプレイヤーのインデックスを更新
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _audioPlayers.length;
      
      // 音声再生の完了を待つ
      await completer.future;
      
      // タイミング指定がある場合は待機
      if (line.timing > 0) {
        await Future.delayed(Duration(milliseconds: (line.timing * 1000).round()));
      }
      
      // イベントリスナーをクリーンアップ
      subscription.cancel();
    } catch (e) {
      print('Error in _playAudio: $e');
      if (!completer.isCompleted) {
        completer.complete();
      }
      rethrow;
    }
  }

  double getProgressValue() {
    return _currentIndex / dialogues.length;
  }

  bool isCharacterActive(bool isBoke) {
    if (currentLine == null) return false;
    return (currentLine!.characterType == 'ボケ') == isBoke;
  }

  @override
  void dispose() {
    for (var player in _audioPlayers) {
      player.dispose();
    }
    _audioCache.clear();
    tts.stop();
    super.dispose();
  }
}