import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/nabi/nabi.dart';

void main() {
  test('NabiCharacter maps every public emotion to a catalog animation', () {
    expect(
      NabiCharacter.animationFor(NabiEmotion.idle),
      NabiAnimationType.idle,
    );
    expect(
      NabiCharacter.animationFor(NabiEmotion.greeting),
      NabiAnimationType.greeting,
    );
    expect(
      NabiCharacter.animationFor(NabiEmotion.listening),
      NabiAnimationType.listening,
    );
    expect(
      NabiCharacter.animationFor(NabiEmotion.thinking),
      NabiAnimationType.thinking,
    );
    expect(
      NabiCharacter.animationFor(NabiEmotion.encouraging),
      NabiAnimationType.happy,
    );
    expect(
      NabiCharacter.animationFor(NabiEmotion.happy),
      NabiAnimationType.happy,
    );
    expect(
      NabiCharacter.animationFor(NabiEmotion.celebrating),
      NabiAnimationType.cheering,
    );
    expect(
      NabiCharacter.animationFor(NabiEmotion.concerned),
      NabiAnimationType.error,
    );
    expect(
      NabiCharacter.animationFor(NabiEmotion.sleepy),
      NabiAnimationType.reminder,
    );
  });
}
