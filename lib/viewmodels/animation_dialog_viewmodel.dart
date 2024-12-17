// viewmodels/animation_dialog_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/script_line.dart';

class AnimationDialogViewModel extends ChangeNotifier {
  final List<ScriptLine> dialogues;
  final FlutterTts tts;
  final VoidCallback onComplete;
  
  int _currentIndex = 0;
  bool _isAnimating = false;
  
  int get currentIndex => _currentIndex;
  bool get isAnimating => _isAnimating;
  bool get isCompleted => _currentIndex >= dialogues.length;
  
  ScriptLine? get currentLine => 
    isCompleted ? null : dialogues[_currentIndex];

  AnimationDialogViewModel({
    required this.dialogues,
    required this.tts,
    required this.onComplete,
  });

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

    await _configureTTS(line);
    await _speakLine(line);

    _currentIndex++;
    _isAnimating = false;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    startAnimation();
  }

  Future<void> _configureTTS(ScriptLine line) async {
    await tts.setPitch(line.characterType == 'ボケ' ? 1.3 : 0.8);
    await tts.setSpeechRate(line.speed);
    await tts.awaitSpeakCompletion(true);
  }

  Future<void> _speakLine(ScriptLine line) async {
    await tts.speak(line.text);
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
    tts.stop();
    super.dispose();
  }
}

