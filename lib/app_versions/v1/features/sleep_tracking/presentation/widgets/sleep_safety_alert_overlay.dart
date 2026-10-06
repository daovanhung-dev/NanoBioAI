import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/services/sleep_safety_state_machine.dart';
import 'sleep_safety_countdown.dart';

class SleepSafetyAlertOverlay extends StatefulWidget {
  const SleepSafetyAlertOverlay({
    super.key,
    required this.startedAt,
    required this.onOk,
    required this.onNeedHelp,
    required this.dispatching,
    this.dispatchFailed = false,
    this.dispatchError,
    this.manualHelpPending = false,
    this.manualHelpFailed = false,
    this.manualHelpError,
    this.onRetryHelp,
    this.requiresContactSetup = false,
    this.onRetry,
    this.onManageContacts,
    this.onCallContact,
    this.onNextContact,
    this.dispatchNotice,
    this.phoneFallbackName,
    this.phoneFallbackMessage,
  });
  final DateTime startedAt;
  final VoidCallback onOk;
  final VoidCallback onNeedHelp;
  final bool dispatching;
  final bool dispatchFailed;
  final String? dispatchError;
  final bool manualHelpPending;
  final bool manualHelpFailed;
  final String? manualHelpError;
  final VoidCallback? onRetryHelp;
  final bool requiresContactSetup;
  final VoidCallback? onRetry;
  final VoidCallback? onManageContacts;
  final VoidCallback? onCallContact;
  final VoidCallback? onNextContact;
  final String? dispatchNotice;
  final String? phoneFallbackName;
  final String? phoneFallbackMessage;
  @override
  State<SleepSafetyAlertOverlay> createState() =>
      _SleepSafetyAlertOverlayState();
}

class _SleepSafetyAlertOverlayState extends State<SleepSafetyAlertOverlay> {
  Timer? _timer;
  int _seconds = SleepSafetyMachineState.noResponseEscalationSeconds;
  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final limit = SleepSafetyMachineState.noResponseEscalationSeconds;
    final value = limit - DateTime.now().difference(widget.startedAt).inSeconds;
    if (mounted) setState(() => _seconds = value.clamp(0, limit));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.black54,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.health_and_safety_rounded,
                  size: 58,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 14),
                Text(
                  'Bạn có ổn không?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nabi vừa nhận thấy một âm thanh bất thường cần được chú ý.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (widget.manualHelpPending)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Nabi đang chuẩn bị cuộc gọi…'),
                    ],
                  )
                else if (widget.manualHelpFailed) ...[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.manualHelpError ??
                        'Chưa thể khởi tạo cuộc gọi. Hãy thử lại hoặc mở danh bạ.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: widget.onRetryHelp,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Thử gọi lại'),
                  ),
                  if (widget.onManageContacts != null)
                    TextButton.icon(
                      onPressed: widget.onManageContacts,
                      icon: const Icon(Icons.contacts_outlined),
                      label: const Text('Mở danh bạ'),
                    ),
                ] else if (widget.dispatching)
                  const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Nabi đang mở cuộc gọi người hỗ trợ…'),
                    ],
                  )
                else if (widget.dispatchFailed) ...[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 44,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.dispatchError ?? 'Chưa thể liên hệ người hỗ trợ.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  if (widget.requiresContactSetup)
                    OutlinedButton.icon(
                      onPressed: widget.onManageContacts,
                      icon: const Icon(Icons.contacts_outlined),
                      label: const Text('Mở danh bạ'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Thử gọi lại'),
                    ),
                  if (widget.dispatchNotice != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.dispatchNotice!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onOk,
                          child: const Text('Tôi ổn'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: widget.onNeedHelp,
                          child: const Text('Tôi cần hỗ trợ'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  SleepSafetyCountdown(seconds: _seconds),
                  const SizedBox(height: 8),
                  const Text(
                    'Nếu bạn không phản hồi, Nabi sẽ liên hệ người hỗ trợ đã thiết lập.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onOk,
                          child: const Text('Tôi ổn'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: widget.onNeedHelp,
                          child: const Text('Tôi cần hỗ trợ'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.onCallContact != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.onCallContact,
                      icon: const Icon(Icons.call_outlined),
                      label: Text(
                        'Gọi ngay ${widget.phoneFallbackName ?? 'người liên hệ'}',
                      ),
                    ),
                  ),
                  if (widget.onNextContact != null)
                    TextButton(
                      onPressed: widget.onNextContact,
                      child: const Text('Gọi người tiếp theo'),
                    ),
                ],
                if (widget.phoneFallbackMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.phoneFallbackMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
