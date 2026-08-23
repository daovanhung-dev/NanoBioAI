import '../../domain/entities/voice_chat_message.dart';
import '../../domain/repositories/ai_voice_repository.dart';
import '../../domain/voice_chat_exception.dart';
import '../datasources/voice_chat_turn_datasource.dart';

class AiVoiceRepositoryImpl implements AiVoiceRepository {
  static const maxUserMessageCharacters = 6000;
  static const maxResponseCharacters = 2000;
  static const maxHistoryMessages = 12;

  final VoiceChatTurnDatasource _datasource;
  final List<VoiceChatMessage> _history = [];
  int _sessionGeneration = 0;

  AiVoiceRepositoryImpl(this._datasource);

  @override
  Future<String> sendTurn(String message) async {
    final generation = _sessionGeneration;
    final normalized = message.trim();
    if (!_isBoundedText(normalized, maxUserMessageCharacters)) {
      throw const VoiceChatException(VoiceChatFailure.invalidRequest);
    }

    final response = (await _datasource.sendTurn(
      message: normalized,
      history: List<VoiceChatMessage>.unmodifiable(_history),
    )).trim();
    if (!_isBoundedText(response, maxResponseCharacters)) {
      throw const VoiceChatException(VoiceChatFailure.invalidResponse);
    }

    if (generation == _sessionGeneration) {
      _history
        ..add(VoiceChatMessage(role: VoiceChatRole.user, text: normalized))
        ..add(VoiceChatMessage(role: VoiceChatRole.model, text: response));
      if (_history.length > maxHistoryMessages) {
        _history.removeRange(0, _history.length - maxHistoryMessages);
      }
    }
    return response;
  }

  @override
  void resetSession() {
    _sessionGeneration++;
    _history.clear();
  }

  bool _isBoundedText(String value, int maxCharacters) {
    return value.isNotEmpty && value.runes.length <= maxCharacters;
  }
}
