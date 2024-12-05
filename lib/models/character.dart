// lib/models/character.dart などのファイルを作成
class Character {
  final String name;
  final String expression;
  final String imagePath;

  Character({
    required this.name,
    required this.expression,
    required this.imagePath,
  });

  bool get isEmpty => name.isEmpty;
  bool get isNotEmpty => name.isNotEmpty;
}