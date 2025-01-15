import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/script_line.dart';
import '../../viewmodels/script_editor_viewmodel.dart';

class AnimationDialog extends StatelessWidget {
  final ScriptEditorViewModel viewModel;
  final VoidCallback onComplete;

  const AnimationDialog({
    Key? key,
    required this.viewModel,
    required this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, child) {
        if (viewModel.dialogueCurrentIndex >= viewModel.scriptLines.length) {
          onComplete();
          return const SizedBox.shrink();
        }

        final currentLine = viewModel.scriptLines[viewModel.dialogueCurrentIndex];
        final isBokeCharacter = currentLine.characterType == 'ボケ';

        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            color: Colors.white,
            child: Stack(
              children: [
                _buildCharacters(isBokeCharacter),
                if (viewModel.showInitialTitle) 
                  _buildInitialTitle(),
                if (viewModel.showNetaTitle) 
                  _buildNetaTitle(),
                _buildProgressBar(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacters(bool isBokeCharacter) {
    return Positioned.fill(
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCharacterImage(
                true,
                isActive: isBokeCharacter && !viewModel.showInitialTitle,
              ),
              const SizedBox(width: 80),
              _buildCharacterImage(
                false,
                isActive: !isBokeCharacter && !viewModel.showInitialTitle,
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
                  isBoke ? viewModel.bokeImage! : viewModel.tsukkomiImage!
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
    ).animate(target: isActive ? 1 : 0).scale(
      duration: const Duration(milliseconds: 800),
      begin: const Offset(0.95, 0.95),
      end: const Offset(1.05, 1.05),
    );
  }

  Widget _buildInitialTitle() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              viewModel.combiName,
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
                  viewModel.bokeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ).animate()
                 .fadeIn(duration: 800.ms)
                 .slideX(begin: -0.3, duration: 800.ms),
                const Text(
                  ' / ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
                Text(
                  viewModel.tsukkomiName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ).animate()
                 .fadeIn(duration: 800.ms)
                 .slideX(begin: 0.3, duration: 800.ms),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeOut(
      duration: 500.ms,
      curve: Curves.easeOut,
      delay: viewModel.musicDuration != null 
        ? Duration(milliseconds: viewModel.musicDuration!.inMilliseconds - 1500)
        : 7500.ms
    );
  }

  Widget _buildNetaTitle() {
    return Positioned(
      top: 350,
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
            viewModel.scriptName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 1000.ms)
      .slideY(begin: -0.3, duration: 1000.ms)
      .fadeOut(
        duration: 500.ms,
        curve: Curves.easeOut,
        delay: viewModel.musicDuration != null 
          ? Duration(milliseconds: viewModel.musicDuration!.inMilliseconds - 1500)
          : 7500.ms
      );
  }

  Widget _buildProgressBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 20,
      child: StreamBuilder<double>(
        stream: viewModel.dialogueProgress,
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
    );
  }
}