import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/script_line.dart';
import '../../viewmodels/animation_dialog_viewmodel.dart';

class AnimationDialog extends StatefulWidget {
  final List<ScriptLine> dialogues;
  final FlutterTts tts;
  final VoidCallback onComplete;
  final String bokeImagePath;
  final String tsukkomiImagePath;

  const AnimationDialog({
    Key? key,
    required this.dialogues,
    required this.tts,
    required this.onComplete,
    required this.bokeImagePath,
    required this.tsukkomiImagePath,
  }) : super(key: key);

  @override
  State<AnimationDialog> createState() => _AnimationDialogState();
}

class _AnimationDialogState extends State<AnimationDialog> {
  late AnimationDialogViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AnimationDialogViewModel(
      dialogues: widget.dialogues,
      tts: widget.tts,
      onComplete: widget.onComplete,
    );
    _viewModel.startAnimation();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        if (_viewModel.isCompleted) {
          return const SizedBox.shrink();
        }

        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Stack(
              children: [
                _buildCharacters(),
                _buildDialogueSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacters() {
    return Positioned.fill(
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCharacterImage(
                true,
                isActive: _viewModel.isCharacterActive(true),
              ),
              const SizedBox(width: 80),
              _buildCharacterImage(
                false,
                isActive: _viewModel.isCharacterActive(false),
              ),
            ],
          ),
          Center(
            child: Image.asset(
              'assets/images/center_mike.png',
              width: 100,
              height: 500,
              fit: BoxFit.contain,
            ),
          ),
        ],
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
    ).animate(target: isActive ? 1 : 0)
      .scale(
        duration: const Duration(milliseconds: 800),
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.05, 1.05),
      );
  }

  Widget _buildDialogueSection() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialogueBox(),
          const SizedBox(height: 16),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildDialogueBox() {
    return Container(
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
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        _viewModel.currentLine?.text ?? '',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .slideY(
        begin: 0.3,
        duration: 500.ms,
        curve: Curves.easeOutQuad,
      );
  }

  Widget _buildProgressBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: LinearProgressIndicator(
        value: _viewModel.getProgressValue(),
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
      ),
    );
  }
}