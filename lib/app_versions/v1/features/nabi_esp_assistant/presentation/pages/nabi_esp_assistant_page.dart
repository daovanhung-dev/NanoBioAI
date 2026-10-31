import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/services/backend/auth/current_backend_user.dart';

import '../../data/services/nabi_esp_assistant_runtime.dart';

class NabiEspAssistantPage extends StatefulWidget {
  const NabiEspAssistantPage({super.key});

  @override
  State<NabiEspAssistantPage> createState() => _NabiEspAssistantPageState();
}

class _NabiEspAssistantPageState extends State<NabiEspAssistantPage> {
  final _runtime = NabiEspAssistantRuntime.instance;
  final _pairingCode = TextEditingController();
  bool _showHotspotPassword = false;

  @override
  void dispose() {
    _pairingCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _runtime,
    builder: (context, _) => Scaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(title: const Text('Nabi - Siêu trợ lý AI')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            _statusCard(context),
            const SizedBox(height: AppSpacing.md),
            if (_runtime.errorMessage case final message?) ...[
              _errorCard(context, message),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_runtime.status == NabiEspAssistantStatus.preparingAi &&
                _runtime.whisperProgress != null) ...[
              _downloadProgressCard(context),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_runtime.status == NabiEspAssistantStatus.selectingHost) ...[
              _hostSelectionCard(context),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_runtime.status == NabiEspAssistantStatus.pairingRequired) ...[
              _pairingCard(context),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_runtime.hasHotspot) ...[
              _hotspotCard(context),
              const SizedBox(height: AppSpacing.md),
            ],
            _controls(context),
            const SizedBox(height: AppSpacing.md),
            _setupNotes(context),
          ],
        ),
      ),
    ),
  );

  Widget _statusCard(BuildContext context) {
    final status = _runtime.status;
    final icon = switch (status) {
      NabiEspAssistantStatus.connected => Icons.link_rounded,
      NabiEspAssistantStatus.listening => Icons.hearing_rounded,
      NabiEspAssistantStatus.processing => Icons.psychology_rounded,
      NabiEspAssistantStatus.speaking => Icons.volume_up_rounded,
      NabiEspAssistantStatus.error => Icons.error_outline_rounded,
      _ => Icons.memory_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.semanticColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: context.semanticColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 30, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Trạng thái kết nối',
                  style: AppTextStyles.heading4,
                ),
              ),
              _StatusPill(label: _statusLabel(status)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _statusDescription(status),
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.semanticColors.textSecondary,
            ),
          ),
          if (_runtime.otaUrl case final url?) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Địa chỉ cấu hình OTA', style: AppTextStyles.labelLarge),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(url, style: AppTextStyles.bodySmall),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _copy(url, 'Đã sao chép địa chỉ OTA.'),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Sao chép'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _downloadProgressCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.semanticColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Đang chuẩn bị Whisper tiếng Việt'),
        const SizedBox(height: AppSpacing.sm),
        LinearProgressIndicator(value: _runtime.whisperProgress),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${((_runtime.whisperProgress ?? 0) * 100).round()}%',
          style: AppTextStyles.bodySmall,
        ),
      ],
    ),
  );

  Widget _hostSelectionCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.semanticColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chọn địa chỉ của hotspot Nabi', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        for (final candidate in _runtime.hostCandidates)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wifi_tethering_rounded),
            title: Text(candidate.address.address),
            subtitle: Text(candidate.interfaceName),
            onTap: () => _runtime.selectHost(candidate.address.address),
          ),
      ],
    ),
  );

  Widget _hotspotCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.pastelBlue,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mạng cục bộ của Nabi', style: AppTextStyles.heading4),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Mạng này chỉ kết nối điện thoại với ESP, không cấp Internet cho ESP.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _SecretRow(
          label: 'Tên Wi-Fi',
          value: _runtime.hotspotSsid ?? '',
          onCopy: () =>
              _copy(_runtime.hotspotSsid ?? '', 'Đã sao chép tên Wi-Fi.'),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mật khẩu Wi-Fi', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  SelectableText(
                    _showHotspotPassword
                        ? _runtime.hotspotPassword ?? ''
                        : '••••••••••••',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: _showHotspotPassword ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
              onPressed: () =>
                  setState(() => _showHotspotPassword = !_showHotspotPassword),
              icon: Icon(
                _showHotspotPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Sao chép mật khẩu',
              onPressed: () => _copy(
                _runtime.hotspotPassword ?? '',
                'Đã sao chép mật khẩu Wi-Fi.',
              ),
              icon: const Icon(Icons.copy_rounded),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _controls(BuildContext context) {
    final canStart = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final connected = _runtime.isDeviceConnected;
    return Column(
      children: [
        if (!_runtime.isRunning)
          FilledButton.icon(
            key: const Key('nabi-esp-connect-button'),
            onPressed: canStart && kDebugMode && !_runtime.isBusy
                ? _startAssistant
                : null,
            icon: _runtime.isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.link_rounded),
            label: Text(kDebugMode ? 'Kết nối Nabi' : 'Bản thử nghiệm nội bộ'),
          )
        else ...[
          if (!connected &&
              _runtime.status != NabiEspAssistantStatus.pairingRequired &&
              !_runtime.isBusy) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _runtime.retryEspProvisioning,
                icon: const Icon(Icons.bluetooth_searching_rounded),
                label: const Text('Tìm ESP'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: connected
                      ? () => _sendListenControl(start: true)
                      : null,
                  icon: const Icon(Icons.hearing_rounded),
                  label: const Text('Bắt đầu nghe'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: connected
                      ? () => _sendListenControl(start: false)
                      : null,
                  icon: const Icon(Icons.hearing_disabled_rounded),
                  label: const Text('Dừng nghe'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _runtime.stop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Dừng server Nabi'),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _startAssistant() async {
    if (currentBackendUserIdOrNull() == null) {
      await context.push(AuthRoutePaths.login);
      return;
    }
    await _runtime.start();
  }

  Widget _setupNotes(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.semanticColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: context.semanticColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cần chuẩn bị ESP lần đầu', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Kết nối Nabi có thể tải Whisper tiếng Việt để nhận dạng lời nói trên điện thoại, rồi mở hotspot và dịch vụ kết nối cho ESP. '
          'Câu trả lời AI được tạo trên máy chủ NanoBio qua HTTPS nên cần Internet và đăng nhập; lời nói được nhận dạng trên điện thoại. '
          'Bật ESP để Nabi tìm thiết bị qua Bluetooth. Lần đầu, nhập mã 8 chữ số hiển thị trên màn hình ESP; '
          'Nabi sẽ lưu khóa ghép an toàn và tự gửi thông tin hotspot mới ở những lần sau.',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.semanticColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _pairingCard(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.semanticColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: context.semanticColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ghép ESP lần đầu', style: AppTextStyles.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Bật OSTB 3ST, đọc mã dùng một lần trên màn hình rồi nhập tại đây.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('nabi-esp-pairing-code'),
          controller: _pairingCode,
          keyboardType: TextInputType.number,
          maxLength: 8,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Mã ghép đôi',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _runtime.isBusy ? null : _submitPairingCode,
            icon: const Icon(Icons.bluetooth_connected_rounded),
            label: const Text('Ghép và kết nối Wi-Fi'),
          ),
        ),
      ],
    ),
  );

  Future<void> _submitPairingCode() async {
    final code = _pairingCode.text.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(code)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập đủ 8 chữ số trên màn hình ESP.')),
      );
      return;
    }
    _pairingCode.clear();
    await _runtime.retryEspProvisioning(pairingCode: code);
  }

  Widget _errorCard(BuildContext context, String message) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.pastelRose,
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message, style: AppTextStyles.bodyMedium)),
      ],
    ),
  );

  Future<void> _sendListenControl({required bool start}) async {
    final state = await _runtime.sendListenControl(start: start);
    if (!mounted) return;
    final message = state == null
        ? 'ESP chưa xác nhận lệnh. Hãy cập nhật firmware XiaoZhi có hỗ trợ Nabi control.'
        : start
        ? 'ESP đã bắt đầu nghe.'
        : 'ESP đã dừng nghe.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(String value, String message) async {
    if (value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(NabiEspAssistantStatus status) => switch (status) {
    NabiEspAssistantStatus.idle => 'Chưa kết nối',
    NabiEspAssistantStatus.preparingAi => 'Đang chuẩn bị AI',
    NabiEspAssistantStatus.startingHotspot => 'Đang mở Wi-Fi',
    NabiEspAssistantStatus.selectingHost => 'Chọn mạng',
    NabiEspAssistantStatus.startingServer => 'Đang mở server',
    NabiEspAssistantStatus.scanningEsp => 'Đang tìm ESP',
    NabiEspAssistantStatus.pairingRequired => 'Chờ mã ghép đôi',
    NabiEspAssistantStatus.provisioningEsp => 'Đang cấu hình ESP',
    NabiEspAssistantStatus.waitingForEsp => 'Chờ ESP',
    NabiEspAssistantStatus.connected => 'Đã kết nối',
    NabiEspAssistantStatus.listening => 'Đang nghe',
    NabiEspAssistantStatus.processing => 'Đang xử lý',
    NabiEspAssistantStatus.speaking => 'Đang trả lời',
    NabiEspAssistantStatus.stopping => 'Đang dừng',
    NabiEspAssistantStatus.error => 'Cần xử lý',
  };

  String _statusDescription(NabiEspAssistantStatus status) => switch (status) {
    NabiEspAssistantStatus.idle =>
      'ESP gửi âm thanh qua mạng nội bộ; câu trả lời AI được tạo trên máy chủ NanoBio.',
    NabiEspAssistantStatus.preparingAi =>
      'Đang chuẩn bị nhận dạng tiếng Việt, kết nối máy chủ AI và giọng TTS ngoại tuyến.',
    NabiEspAssistantStatus.startingHotspot =>
      'Android đang tạo mạng LAN-only và giữ dịch vụ nền.',
    NabiEspAssistantStatus.selectingHost =>
      'Điện thoại có nhiều địa chỉ mạng phù hợp; chọn địa chỉ của hotspot.',
    NabiEspAssistantStatus.startingServer =>
      'Đang mở dịch vụ kết nối Nabi theo giao thức WebSocket v3.',
    NabiEspAssistantStatus.scanningEsp =>
      'Kết nối thoại cục bộ sẵn sàng; đang quét thiết bị OSTB 3ST qua Bluetooth. Cần Internet và đăng nhập để nhận câu trả lời AI.',
    NabiEspAssistantStatus.pairingRequired =>
      'Nhập mã ghép đôi đang hiển thị trên ESP. Khóa sẽ được lưu để tự ghép lần sau.',
    NabiEspAssistantStatus.provisioningEsp =>
      'Đang gửi thông tin hotspot qua phiên BLE được mã hóa.',
    NabiEspAssistantStatus.waitingForEsp =>
      'Kết nối điện thoại sẵn sàng. Bật ESP hoặc chọn tìm lại; cần Internet và đăng nhập để dùng AI.',
    NabiEspAssistantStatus.connected => 'ESP đã bắt tay với server Nabi.',
    NabiEspAssistantStatus.listening => 'ESP đang gửi âm thanh để nhận dạng.',
    NabiEspAssistantStatus.processing =>
      'Whisper nhận dạng lời nói trên điện thoại; máy chủ NanoBio tạo câu trả lời.',
    NabiEspAssistantStatus.speaking => 'Nabi đang gửi âm thanh trả lời về ESP.',
    NabiEspAssistantStatus.stopping => 'Đang đóng socket, server và hotspot.',
    NabiEspAssistantStatus.error => 'Không thể hoàn tất bước kết nối vừa rồi.',
  };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.pastelMint,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    ),
  );
}

class _SecretRow extends StatelessWidget {
  const _SecretRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.labelMedium),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(value, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Sao chép $label',
        onPressed: onCopy,
        icon: const Icon(Icons.copy_rounded),
      ),
    ],
  );
}
