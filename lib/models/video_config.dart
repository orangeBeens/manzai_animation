import 'script_line.dart';

class VideoConfig {
  final String combiName;
  final String bokeName;
  final String tsukkomiName;
  final String? bokeImagePath;
  final String? tsukkomiImagePath;
  final List<ScriptLine> scriptLines;

  VideoConfig({
    required this.combiName,
    required this.bokeName,
    required this.tsukkomiName,
    this.bokeImagePath,
    this.tsukkomiImagePath,
    required this.scriptLines,
  });
}
