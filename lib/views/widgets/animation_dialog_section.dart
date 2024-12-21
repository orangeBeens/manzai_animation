import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/script_line.dart';

class AnimationDialog extends StatefulWidget {
  final List<ScriptLine> dialogues;
  final VoidCallback onComplete;
  final String bokeImagePath;
  final String tsukkomiImagePath;
  final int bokeVoice;
  final int tsukkomiVoice;

  const AnimationDialog({
    Key? key,
    required this.dialogues,
    required this.onComplete,
    required this.bokeImagePath,
    required this.tsukkomiImagePath,
    required this.bokeVoice,
    required this.tsukkomiVoice,
  }) : super(key: key);

  @override
  State<AnimationDialog> createState() => _AnimationDialogState();
}

class _AnimationDialogState extends State<AnimationDialog> {
  int currentIndex = 0;
  bool isAnimating = false;
  final List<AudioPlayer> _audioPlayers = [AudioPlayer(), AudioPlayer()];
  int _currentPlayerIndex = 0;
  final Map<int, BytesSource> _audioCache = {};
  bool _isPrefetching = false;

  @override
  void initState() {
    super.initState();
    _prefetchNextAudio();
    _startAnimation();
  }

  Future<void> _prefetchNextAudio() async {
    if (_isPrefetching || currentIndex >= widget.dialogues.length - 1) return;
    
    _isPrefetching = true;
    try {
      final nextIndex = currentIndex + 1;
      if (!_audioCache.containsKey(nextIndex)) {
        final audio = await _synthesizeAudio(widget.dialogues[nextIndex]);
        _audioCache[nextIndex] = audio;
      }
      _audioCache.removeWhere((key, value) => key < currentIndex);
    } finally {
      _isPrefetching = false;
    }
  }

  Future<BytesSource> _synthesizeAudio(ScriptLine line) async {
    final speakerId = line.characterType == 'ボケ' ? widget.bokeVoice : widget.tsukkomiVoice;
    
    final response = await http.post(
      Uri.parse('http://localhost:8000/synthesis'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': line.text,
        'speaker_id': speakerId,
      }),
    );

    if (response.statusCode == 200) {
      return BytesSource(response.bodyBytes);
    } else {
      throw Exception('音声合成に失敗しました');
    }
  }

  Future<void> _playAudio(ScriptLine line, BytesSource audioSource) async {
    final currentPlayer = _audioPlayers[_currentPlayerIndex];
    
    try {
      await currentPlayer.stop();
      await currentPlayer.play(audioSource);
      await currentPlayer.setPlaybackRate(line.speed);
      
      _currentPlayerIndex = (_currentPlayerIndex + 1) % _audioPlayers.length;
      
      // 音声再生の完了を待つ
      await currentPlayer.onPlayerComplete.first;
      
      if (line.timing > 0) {
        await Future.delayed(Duration(milliseconds: (line.timing * 1000).round()));
      }
    } catch (e) {
      print('Error in _playAudio: $e');
      rethrow;
    }
  }

  Future<void> _startAnimation() async {
    if (currentIndex >= widget.dialogues.length) {
      widget.onComplete();
      return;
    }

    setState(() => isAnimating = true);

    final currentLine = widget.dialogues[currentIndex];
    
    if (currentLine.timing > 0) {
      await Future.delayed(Duration(milliseconds: (currentLine.timing * 1000).round()));
    }

    try {
      BytesSource audioSource;
      if (_audioCache.containsKey(currentIndex)) {
        audioSource = _audioCache[currentIndex]!;
      } else {
        audioSource = await _synthesizeAudio(currentLine);
        _audioCache[currentIndex] = audioSource;
      }

      await _playAudio(currentLine, audioSource);
      
      setState(() {
        isAnimating = false;
        currentIndex++;
      });

      _prefetchNextAudio();
      await Future.delayed(const Duration(milliseconds: 300));
      _startAnimation();
    } catch (e) {
      setState(() => isAnimating = false);
      print('Error in _startAnimation: $e');
    }
  }

  @override
  void dispose() {
    for (var player in _audioPlayers) {
      player.dispose();
    }
    _audioCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentIndex >= widget.dialogues.length) {
      return const SizedBox.shrink();
    }

    final currentLine = widget.dialogues[currentIndex];
    final isBokeCharacter = currentLine.characterType == 'ボケ';

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCharacterImage(
                        true,
                        isActive: isBokeCharacter,
                      ),
                      const SizedBox(width: 80),
                      _buildCharacterImage(
                        false,
                        isActive: !isBokeCharacter,
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
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      currentLine.text,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.3, duration: 500.ms, curve: Curves.easeOutQuad),

                  const SizedBox(height: 16),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: LinearProgressIndicator(
                      value: currentIndex / widget.dialogues.length,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
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