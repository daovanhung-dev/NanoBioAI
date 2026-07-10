import 'package:flutter/widgets.dart';

import 'nabi_assistant_overlay.dart';

/// Bọc body dùng chung của app/ShellRoute để Nabi luôn nổi trên mọi màn hình.
///
/// Đặt widget này đúng một lần ở app shell. Không gắn Nabi vào Dashboard để
/// tránh bị mất khi chuyển tab, mở AI Chat hoặc đi vào flow onboarding.
class NabiAppShell extends StatelessWidget {
  const NabiAppShell({
    required this.child,
    super.key,
    this.config = const NabiOverlayConfig(),
  });

  final Widget child;
  final NabiOverlayConfig config;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        child,
        NabiAssistantOverlay(config: config),
      ],
    );
  }
}
