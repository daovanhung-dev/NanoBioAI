import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/nabi/domain/nabi_context.dart';
import 'package:nano_app/app_versions/v1/features/nabi/domain/nabi_visual_state.dart';
import 'package:nano_app/app_versions/v1/features/nabi/providers/nabi_provider.dart';

/// Mixin cho [ConsumerState] – cho phép trang khai báo state Nabi của mình.
///
/// ### Cách dùng
/// ```dart
/// class _DashboardPageState extends ConsumerState<DashboardPage>
///     with NabiPageMixin {
///   @override
///   NabiContext get NabiContext => NabiContext(
///         routePath: V1RoutePaths.dashboard,
///         hasScheduleToday: _hasSchedule,
///         dailyProgress: _progress,
///       );
/// }
/// ```
///
/// Mixin tự gọi `applyNabiContext()` trong `initState` và mỗi khi
/// `setState` được gọi. Không cần gọi thủ công.
mixin NabiPageMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Khai báo [NabiContext] của trang này. Override trong subclass.
  NabiContext get nabiContext => const NabiContext();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    _apply();
  }

  /// Áp dụng context của trang này lên provider.
  void applyNabiContext() => _apply();

  void _apply() {
    if (!mounted) return;
    ref.read(nabiContextProvider.notifier).update((_) => nabiContext);
  }
}

/// Extension tiện ích trên [WidgetRef] để cập nhật Nabi nhanh.
extension NabiRefExtension on WidgetRef {
  NabiContextNotifier get nabi => read(nabiContextProvider.notifier);

  /// Đặt route cho Nabi ngay lập tức.
  void setNabiRoute(String route) => nabi.setRoute(route);

  /// Nabi bắt đầu hoặc dừng chat typing.
  void setNabiChatTyping({required bool typing}) =>
      nabi.setChatTyping(typing: typing);

  /// Nabi có câu trả lời rồi.
  void setNabiChatReady() => nabi.setChatAnswerReady();

  /// Người dùng vừa hoàn thành task.
  void setNabiTaskDone({double? progress}) =>
      nabi.notifyTaskCompleted(newProgress: progress);

  /// Người dùng bỏ qua task.
  void setNabiTaskSkip() => nabi.notifyTaskSkipped();

  /// Force một trạng thái tạm thời.
  void forceNabiState(NabiVisualState state) =>
      nabi.update((ctx) => ctx.copyWith(forceState: state));

  /// Xoá trạng thái tạm thời.
  void clearNabiTransient() => nabi.clearTransientState();
}
