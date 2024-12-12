import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'dart:ui';
import 'dart:io';
import 'script_line.dart';
import 'video_config.dart';

class VideoGenerator {
  Future<String> generate(VideoConfig config) async {
    const outputPath = 'output.mp4';
    
    // 背景画像の生成
    final bgPath = await _createBackgroundImage();
    
    // フィルタースクリプトの生成
    final filterScript = _generateFilterScript(
      config.scriptLines,
      config.bokeImagePath,
      config.tsukkomiImagePath,
      bgPath
    );

    // FFmpegコマンドの実行
    await FFmpegKit.execute(
      '-f lavfi -i anullsrc=r=44100:cl=stereo ' +
      '-i $bgPath ' +
      '-filter_complex "$filterScript" ' +
      '-t ${_calculateVideoDuration(config.scriptLines)} ' +
      '-c:v libx264 ' +
      '-pix_fmt yuv420p ' +
      outputPath
    );

    return outputPath;
  }

  Future<String> _createBackgroundImage() async {
    const bgPath = 'bg.png';
    
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1280, 720), paint);
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(1280, 720);
    final pngBytes = await image.toByteData(format: ImageByteFormat.png);
    
    await File(bgPath).writeAsBytes(pngBytes!.buffer.asUint8List());
    return bgPath;
  }

  String _generateFilterScript(
    List<ScriptLine> lines,
    String? bokeImage,
    String? tsukkomiImage,
    String bgPath
  ) {
    final StringBuffer script = StringBuffer();
    var currentTime = 0.0;
    
    // キャラクター画像のオーバーレイ設定
    if (bokeImage != null) {
      script.write('[0:v][1:v]overlay=x=100:y=100[boke];');
    }
    if (tsukkomiImage != null) {
      script.write('[boke][2:v]overlay=x=800:y=100[chars];');
    }
    
    // 字幕の追加
    for (final line in lines) {
      final duration = _calculateLineDuration(line);
      
      script.write(
        'drawtext=text=\'${line.text}\':'
        'fontfile=/System/Library/Fonts/ヒラギノ角ゴシック W3.ttc:'
        'fontsize=40:'
        'fontcolor=black:'
        'x=(w-text_w)/2:'
        'y=h-120:'
        'enable=\'between(t,$currentTime,${currentTime + duration})\''
      );
      
      currentTime += duration + (line.timing ?? 0.0);
    }
    
    return script.toString();
  }

  double _calculateVideoDuration(List<ScriptLine> lines) {
    return lines.fold(0.0, (total, line) {
      return total + _calculateLineDuration(line) + (line.timing ?? 0.0);
    });
  }

  double _calculateLineDuration(ScriptLine line) {
    return (line.text.length * 0.2) / (line.speed ?? 1.0);
  }
}