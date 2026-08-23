enum VoiceChatRole { user, model }

class VoiceChatMessage {
  final VoiceChatRole role;
  final String text;

  const VoiceChatMessage({required this.role, required this.text});

  Map<String, String> toJson() => {'role': role.name, 'text': text};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceChatMessage && role == other.role && text == other.text;

  @override
  int get hashCode => Object.hash(role, text);
}
