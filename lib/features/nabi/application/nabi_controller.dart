import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/nabi_expression.dart';
import 'nabi_expression_resolver.dart';
import 'nabi_state.dart';

/// Riverpod controller dùng chung cho toàn ứng dụng.
///
/// Không chứa điều hướng, gọi API hay logic feature. Các feature chỉ cần gửi
/// event vào đây để NaBi phản ứng nhất quán trên mọi màn hình.
class NabiController extends Notifier<NabiState> {
  @override
  NabiState build() => NabiState.initial();

  void dispatch(NabiEvent event, {String? detail}) {
    final resolved = NabiExpressionResolver.fromEvent(
      event,
      fallbackContext: state.context,
      detail: detail,
    );

    state = state.copyWith(
      context: resolved.context,
      emotion: resolved.emotion,
      bubbleText: resolved.bubbleText,
      isChatOpen: resolved.context == NabiContext.aiChat,
      isVisible: true,
    );
  }

  /// Dùng khi route đổi nhưng không có event nghiệp vụ cụ thể.
  void setContext(NabiContext context, {String? detail}) {
    final resolved = NabiExpressionResolver.fromContext(context);
    state = state.copyWith(
      context: resolved.context,
      emotion: resolved.emotion,
      bubbleText: detail?.trim().isNotEmpty == true
          ? detail!.trim()
          : resolved.bubbleText,
      isChatOpen: context == NabiContext.aiChat,
      isVisible: true,
    );
  }

  void setChatThinking() => dispatch(NabiEvent.aiThinking);

  void setChatResponded({String? detail}) =>
      dispatch(NabiEvent.aiResponded, detail: detail);

  void setChatFailed() => dispatch(NabiEvent.aiFailed);

  void toggleMinimized() {
    state = state.copyWith(isMinimized: !state.isMinimized);
  }

  void show() {
    state = state.copyWith(isVisible: true);
  }

  void hide() {
    state = state.copyWith(isVisible: false);
  }
}

final nabiControllerProvider = NotifierProvider<NabiController, NabiState>(
  NabiController.new,
);
