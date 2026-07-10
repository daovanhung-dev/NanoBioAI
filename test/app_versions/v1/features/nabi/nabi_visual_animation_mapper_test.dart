import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/nabi/nabi.dart';
import 'package:nano_app/features/nabi/nabi.dart';

void main() {
  group('NabiVisualAnimationMapper', () {
    test('maps chat loading, success, and error states', () {
      expect(
        NabiVisualAnimationMapper.fromVisualState(NabiVisualState.chatTyping),
        NabiAnimationType.loading,
      );
      expect(
        NabiVisualAnimationMapper.fromVisualState(
          NabiVisualState.chatAnswerReady,
        ),
        NabiAnimationType.talking,
      );
      expect(
        NabiVisualAnimationMapper.fromVisualState(NabiVisualState.syncRetry),
        NabiAnimationType.error,
      );
    });

    test('maps route-derived visual states to mascot animations', () {
      expect(
        NabiVisualAnimationMapper.fromVisualState(NabiVisualState.chatGreet),
        NabiAnimationType.listening,
      );
      expect(
        NabiVisualAnimationMapper.fromVisualState(NabiVisualState.chatMealTip),
        NabiAnimationType.thinking,
      );
      expect(
        NabiVisualAnimationMapper.fromVisualState(NabiVisualState.exercise),
        NabiAnimationType.cheering,
      );
      expect(
        NabiVisualAnimationMapper.fromVisualState(
          NabiVisualState.notificationReminder,
        ),
        NabiAnimationType.reminder,
      );
      expect(
        NabiVisualAnimationMapper.fromVisualState(
          NabiVisualState.premiumUnlocked,
        ),
        NabiAnimationType.membership,
      );
    });
  });
}
