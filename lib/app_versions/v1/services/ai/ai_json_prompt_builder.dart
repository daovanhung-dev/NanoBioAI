class AIJsonPromptBuilder {
  const AIJsonPromptBuilder._();

  static String buildArrayPrompt(String prompt) {
    return '''
Return exactly one JSON object: {"items":[...]}. No markdown or extra text.
Use only the requested fields and allowed catalog codes. Do not invent codes.

$prompt
''';
  }
}
