import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../../models/script_line.dart';

class AnimationDialog extends StatefulWidget {
  final List<ScriptLine> dialogues;
  final VoidCallback onComplete;
  final String bokeImagePath;
  final String tsukkomiImagePath;
  final int bokeVoice;
  final int tsukkomiVoice;
  final String bokeName;
  final String tsukkomiName;
  final String combiName;
  final String scriptName;
  final String? musicPath;

  const AnimationDialog({
    Key? key,
    required this.dialogues,
    required this.onComplete,
    required this.bokeImagePath,
    required this.tsukkomiImagePath,
    required this.bokeVoice,
    required this.tsukkomiVoice,
    required this.bokeName,
    required this.tsukkomiName,
    required this.combiName,
    required this.scriptName,
    this.musicPath,
  }) : super(key: key);

  @override
  State<AnimationDialog> createState() => _AnimationDialogState();
}

class _AnimationDialogState extends State<AnimationDialog> {
  static const int _audioPlayerPoolSize = 3;
  static const int _prefetchCount = 2;
  
  late final List<AudioPlayer> _audioPlayerPool;
  final Map<int, BytesSource> _audioCache = {};
  final Map<int, Completer<void>> _audioCompleters = {};
  final Set<int> _prefetchingIndices = {};
  
  int _currentIndex = 0;
  bool _isAnimating = false;
  int _currentPlayerIndex = 0;
  bool _isDisposed = false;

  // タイトル表示用の状態
  bool _showInitialTitle = true;
  bool _showNetaTitle = false;
  Duration? _musicDuration;
  AudioPlayer? _bgmPlayer;
  bool _isDialogueStarted = false;

  StreamController<double>? _progressController;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayers();
    _progressController = StreamController<double>.broadcast();
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
    if (widget.musicPath != null) {
      _bgmPlayer = AudioPlayer();
      try {
        final musicPath = widget.musicPath!.replaceAll('assets/', '');
        await _bgmPlayer!.setSource(AssetSource(musicPath));
        await _bgmPlayer!.setVolume(1.0);
        
        final duration = await _bgmPlayer!.getDuration();
        if (!_isDisposed) {
          setState(() {
            _musicDuration = duration;
          });
        }

        // ダイアログ表示と同時に音楽を再生
        await _bgmPlayer!.play(AssetSource(musicPath));
        
        // タイトルシーケンスを開始
        _startTitleSequence();
      } catch (e) {
        print('BGM initialization error: $e');
      }
    } else {
      // 音楽がない場合でもタイトルシーケンスを開始
      _startTitleSequence();
    }
  }

  void _startTitleSequence() {
    setState(() {
      _showInitialTitle = true;
      _showNetaTitle = false;
    });

    // 5秒後にネタ名を表示
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _showNetaTitle = true;
      });
      
      // ネタ名表示後にダイアログを開始
      if (!_isDialogueStarted) {
        _isDialogueStarted = true;
        _startPrefetching();
        _startAnimation();
      }
    });
  }

  Future<void> _startPrefetching() async {
    for (var i = 0; i < _prefetchCount; i++) {
      final nextIndex = _currentIndex + i;
      if (nextIndex < widget.dialogues.length) {
        _prefetchAudio(nextIndex);
      }
    }
  }

  Future<void> _prefetchAudio(int index) async {
    if (_audioCache.containsKey(index) || 
        _prefetchingIndices.contains(index) || 
        index >= widget.dialogues.length) {
      return;
    }

    _prefetchingIndices.add(index);
    try {
      final audio = await _synthesizeAudio(widget.dialogues[index]);
      if (!_isDisposed) {
        _audioCache[index] = audio;
      }
    } catch (e) {
      print('Prefetch error for index $index: $e');
    } finally {
      _prefetchingIndices.remove(index);
    }
  }

  Future<BytesSource> _synthesizeAudio(ScriptLine line) async {
    final speakerId = line.characterType == 'ボケ' ? widget.bokeVoice : widget.tsukkomiVoice;
    
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8000/synthesis'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': line.text,
          'speaker_id': speakerId,
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

  Future<void> _playAudio(ScriptLine line, BytesSource audioSource) async {
    final completer = Completer<void>();
    _audioCompleters[_currentIndex] = completer;

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
      await currentPlayer.setPlaybackRate(line.speed);
      
      await completer.future;
      subscription.cancel();

      if (line.timing > 0) {
        await Future.delayed(Duration(milliseconds: (line.timing * 1000).round()));
      }
    } catch (e) {
      print('Audio playback error: $e');
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }
  }

  Future<void> _startAnimation() async {
    if (_currentIndex >= widget.dialogues.length) {
      widget.onComplete();
      return;
    }

    if (_isDisposed) return;

    setState(() => _isAnimating = true);
    
    final currentLine = widget.dialogues[_currentIndex];

    try {
      BytesSource? audioSource = _audioCache[_currentIndex];
      if (audioSource == null) {
        audioSource = await _synthesizeAudio(currentLine);
        _audioCache[_currentIndex] = audioSource;
      }

      await _playAudio(currentLine, audioSource);

      if (_isDisposed) return;

      setState(() {
        _isAnimating = false;
        _currentIndex++;
      });

      _progressController?.add(_currentIndex / widget.dialogues.length);
      
      _audioCache.removeWhere((key, _) => key < _currentIndex - 1);
      
      _prefetchAudio(_currentIndex + _prefetchCount);

      await Future.delayed(const Duration(milliseconds: 300));
      _startAnimation();
    } catch (e) {
      if (!_isDisposed) {
        setState(() => _isAnimating = false);
        print('Animation error: $e');
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bgmPlayer?.dispose();
    for (var player in _audioPlayerPool) {
      player.dispose();
    }
    for (var completer in _audioCompleters.values) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _progressController?.close();
    _audioCache.clear();
    _audioCompleters.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.dialogues.length) {
      return const SizedBox.shrink();
    }

    final currentLine = widget.dialogues[_currentIndex];
    final isBokeCharacter = currentLine.characterType == 'ボケ';

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            // キャラクター表示
            Positioned.fill(
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCharacterImage(
                        true,
                        isActive: isBokeCharacter && !_showInitialTitle,
                      ),
                      const SizedBox(width: 80),
                      _buildCharacterImage(
                        false,
                        isActive: !isBokeCharacter && !_showInitialTitle,
                      ),
                    ],
                  ),
                  Center(
                    child: Image.asset(
                      'assets/images/center_mike.png',
                      width: 100,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // タイトル表示のオーバーレイ
            if (_showInitialTitle)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.combiName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn(duration: 800.ms),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.bokeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                            ),
                          ).animate().fadeIn(duration: 800.ms).slideX(
                            begin: -0.3,
                            duration: 800.ms,
                          ),
                          const Text(
                            ' / ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                            ),
                          ),
                          Text(
                            widget.tsukkomiName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                            ),
                          ).animate().fadeIn(duration: 800.ms).slideX(
                            begin: 0.3,
                            duration: 800.ms,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // ネタ名表示
            if (_showNetaTitle)
              Positioned(
                top: 300,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.scriptName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 1000.ms).slideY(
                begin: -0.3,
                duration: 1000.ms,
              ),

            // 台詞とプログレスバー
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_showInitialTitle) Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentLine.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ).animate()
                   .fadeIn(duration: 50.ms)
                   .slideY(begin: 0.3, duration: 200.ms, curve: Curves.easeOutQuad),

                  const SizedBox(height: 16),

                  StreamBuilder<double>(
                    stream: _progressController?.stream,
                    initialData: 0.0,
                    builder: (context, snapshot) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        child: LinearProgressIndicator(
                          value: snapshot.data,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterImage(bool isBoke, {required bool isActive}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    isBoke ? widget.bokeImagePath : widget.tsukkomiImagePath
                  ),
                  fit: BoxFit.contain,
                ),
              ),
              child: Container(
                color: isActive ? null : Colors.black.withOpacity(0.3),
              ),
            ),
          ),
        ),
      )
      .animate(target: isActive ? 1 : 0)
      .scale(
        duration: const Duration(milliseconds: 800),
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.05, 1.05),
      );
    }
  }