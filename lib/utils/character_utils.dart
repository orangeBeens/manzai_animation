class CharacterAssets {
  static const Map<String, List<String>> expressions = {
    'moeko': ['normal'],
    'akari': ['normal'],
  };

  static String getCharacterImagePath(String characterName, String expression) {
    return 'assets/images/character/$characterName/$expression.png';
  }

  static List<String> getAvailableExpressions(String characterName) {
    return expressions[characterName] ?? ['normal'];
  }
}