import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

import '../../data/services/nabi_esp_assistant_runtime.dart';
import '../../data/services/nabi_esp_device_service.dart';

class NabiEspAssistantPage extends StatefulWidget {
  const NabiEspAssistantPage({super.key});

  @override
  State<NabiEspAssistantPage> createState() => _NabiEspAssistantPageState();
}

class _NabiEspAssistantPageState extends State<NabiEspAssistantPage> {
  final _runtime = NabiEspAssistantRuntime.instance;
  final _ssid = TextEditingController();
  final _wifiPassword = TextEditingController();
  bool _obscureWifiPassword = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_runtime.loadDevices());
  }

  @override
  void dispose() {
    _ssid.dispose();
    _wifiPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _runtime,
    builder: (context, _) => Scaffold(
      backgroundColor: context.semanticColors.background,
      appBar: AppBar(
        title: const Text('Nabi ESP'),
        actions: [
          IconButton(
            tooltip: 'Tải lại thiết bị',
            onPressed: _runtime.loadDevices,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
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
            _setupCard(context),
            const SizedBox(height: AppSpacing.md),
            _deviceListCard(context),
            const SizedBox(height: AppSpacing.md),
            _privacyCard(context),
          ],
        ),
      ),
    ),
  );

  bool get _signedIn => BackendApiClient.shared.session != null;
  bool get _canConfigure =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android && kDebugMode;

  Widget _statusCard(BuildContext context) {
    final status = _runtime.status;
    final icon = switch (status) {
      NabiEspAssistantStatus.connected => Icons.check_circle_outline_rounded,
      NabiEspAssistantStatus.provisionAccepted => Icons.cloud_sync_rounded,
      NabiEspAssistantStatus.scanningEsp => Icons.wifi_find_rounded,
      NabiEspAssistantStatus.provisioningEsp => Icons.settings_rounded,
      NabiEspAssistantStatus.error => Icons.error_outline_rounded,
      _ => Icons.memory_rounded,
    };
    return _surface(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 30, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Thiết lập Nabi', style: AppTextStyles.heading4),
              ),
              _StatusPill(label: _statusLabel(status)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _statusDescription(status),
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.semanticColors.textSecondary,
            ),
          ),
          if (!_signedIn) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () => context.push(AuthRoutePaths.login),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Đăng nhập để liên kết thiết bị'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _setupCard(BuildContext context) => _surface(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kết nối Wi-Fi lần đầu', style: AppTextStyles.heading4),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Đăng nhập ứng dụng trước, rồi kết nối điện thoại với Wi-Fi Nabi đang hiện trên ESP. Không cần dữ liệu di động để cấu hình. Sau khi gửi, ESP sẽ tự kết nối Wi-Fi nhà và đăng nhập dịch vụ AI.',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.semanticColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('nabi-esp-wifi-ssid'),
          controller: _ssid,
          textInputAction: TextInputAction.next,
          maxLength: 32,
          decoration: const InputDecoration(
            labelText: 'Tên Wi-Fi (SSID)',
            counterText: '',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const Key('nabi-esp-wifi-password'),
          controller: _wifiPassword,
          obscureText: _obscureWifiPassword,
          textInputAction: TextInputAction.done,
          maxLength: 63,
          decoration: InputDecoration(
            labelText: 'Mật khẩu Wi-Fi',
            counterText: '',
            suffixIcon: IconButton(
              tooltip: _obscureWifiPassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              onPressed: () => setState(() {
                _obscureWifiPassword = !_obscureWifiPassword;
              }),
              icon: Icon(
                _obscureWifiPassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const Key('nabi-esp-setup-button'),
            onPressed:
                !_signedIn || !_canConfigure || _runtime.isBusy || _loading
                ? null
                : _setup,
            icon: _runtime.isBusy || _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_rounded),
            label: const Text('Gửi thông tin Wi-Fi cho Nabi'),
          ),
        ),
        if (!_canConfigure) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Thiết lập Nabi ESP hiện chỉ mở trong bản Android thử nghiệm nội bộ.',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
            ),
          ),
        ],
      ],
    ),
  );

  Widget _deviceListCard(BuildContext context) => _surface(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Thiết bị của tôi', style: AppTextStyles.heading4),
            ),
            Text(
              '${_runtime.devices.length}',
              style: AppTextStyles.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!_signedIn)
          Text(
            'Đăng nhập để xem và quản lý thiết bị đã liên kết.',
            style: AppTextStyles.bodySmall,
          )
        else if (_runtime.devices.isEmpty)
          Text(
            'Chưa có ESP nào được liên kết với tài khoản này.',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
            ),
          )
        else
          for (final device in _runtime.devices) ...[
            if (device != _runtime.devices.first)
              Divider(color: context.semanticColors.outline),
            _deviceCard(context, device),
          ],
      ],
    ),
  );

  Widget _deviceCard(BuildContext context, NabiEspDevice device) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(
            device.connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: device.connected
                ? AppColors.primary
                : context.semanticColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.name, style: AppTextStyles.labelLarge),
                Text(
                  device.connected ? 'Đang kết nối' : 'Đang ngoại tuyến',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.semanticColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Đổi tên thiết bị',
            onPressed: () => _rename(device),
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            tooltip: 'Hủy liên kết',
            onPressed: () => _unbind(device),
            icon: const Icon(Icons.link_off_rounded),
          ),
        ],
      ),
      Text(
        'Mã thiết bị: ${device.id}',
        style: AppTextStyles.bodySmall.copyWith(
          color: context.semanticColors.textSecondary,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _consentSwitch(
        device,
        title: 'Tên tài khoản',
        subtitle: 'Cho phép Nabi gọi tên bạn.',
        current: device.consent.identity,
        next: NabiEspDeviceConsent(
          identity: !device.consent.identity,
          profileGoals: device.consent.profileGoals,
          sensitiveHealth: device.consent.sensitiveHealth,
          recentTracking: device.consent.recentTracking,
        ),
      ),
      _consentSwitch(
        device,
        title: 'Hồ sơ và mục tiêu',
        subtitle: 'Dùng thông tin hồ sơ cơ bản và mục tiêu đã lưu.',
        current: device.consent.profileGoals,
        next: NabiEspDeviceConsent(
          identity: device.consent.identity,
          profileGoals: !device.consent.profileGoals,
          sensitiveHealth: device.consent.sensitiveHealth,
          recentTracking: device.consent.recentTracking,
        ),
      ),
      _consentSwitch(
        device,
        title: 'Thông tin sức khỏe nhạy cảm',
        subtitle: 'Chỉ dùng trong phiên đã mở khóa riêng.',
        current: device.consent.sensitiveHealth,
        next: NabiEspDeviceConsent(
          identity: device.consent.identity,
          profileGoals: device.consent.profileGoals,
          sensitiveHealth: !device.consent.sensitiveHealth,
          recentTracking: device.consent.recentTracking,
        ),
      ),
      _consentSwitch(
        device,
        title: 'Dữ liệu theo dõi gần đây',
        subtitle: 'Chỉ dùng trong phiên đã mở khóa riêng.',
        current: device.consent.recentTracking,
        next: NabiEspDeviceConsent(
          identity: device.consent.identity,
          profileGoals: device.consent.profileGoals,
          sensitiveHealth: device.consent.sensitiveHealth,
          recentTracking: !device.consent.recentTracking,
        ),
      ),
      if (device.connected &&
          (device.consent.sensitiveHealth || device.consent.recentTracking))
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _unlockSensitive(device),
            icon: const Icon(Icons.lock_open_rounded),
            label: const Text('Mở dữ liệu trong 5 phút'),
          ),
        ),
    ],
  );

  Widget _consentSwitch(
    NabiEspDevice device, {
    required String title,
    required String subtitle,
    required bool current,
    required NabiEspDeviceConsent next,
  }) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(title, style: AppTextStyles.labelMedium),
    subtitle: Text(subtitle, style: AppTextStyles.bodySmall),
    value: current,
    onChanged: _loading ? null : (_) => _updateConsent(device, next),
  );

  Widget _privacyCard(BuildContext context) => _surface(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quyền riêng tư', style: AppTextStyles.heading4),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Ứng dụng lưu thông tin đăng nhập đã mã hóa bằng Android Keystore đến khi bạn đăng xuất. Khi cấu hình, ứng dụng gửi thông tin này qua Wi-Fi Nabi bảo vệ bằng WPA2; ESP lưu tài khoản và mật khẩu trong bộ nhớ để tự đăng nhập máy chủ. Lời nói được gửi qua kết nối mã hóa tới dịch vụ AI của NanoBio. Chia sẻ hồ sơ mặc định tắt và có thể đổi riêng cho từng ESP.',
          style: AppTextStyles.bodySmall.copyWith(
            color: context.semanticColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _surface(BuildContext context, Widget child) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.semanticColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: context.semanticColors.outline),
    ),
    child: child,
  );

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

  Future<void> _setup() async {
    setState(() => _loading = true);
    await _runtime.setupDevice(
      ssid: _ssid.text,
      wifiPassword: _wifiPassword.text,
    );
    if (_runtime.status == NabiEspAssistantStatus.provisionAccepted ||
        _runtime.status == NabiEspAssistantStatus.connected) {
      _wifiPassword.clear();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _updateConsent(
    NabiEspDevice device,
    NabiEspDeviceConsent consent,
  ) async {
    setState(() => _loading = true);
    try {
      await _runtime.updateConsent(device, consent);
    } catch (error) {
      _showMessage(
        'Chưa lưu được lựa chọn quyền riêng tư. ${_safeError(error)}',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _rename(NabiEspDevice device) async {
    final controller = TextEditingController(text: device.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi tên thiết bị'),
        content: TextField(
          controller: controller,
          maxLength: 80,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Tên thiết bị'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await _runtime.renameDevice(device, name);
    } catch (error) {
      _showMessage('Chưa đổi được tên thiết bị. ${_safeError(error)}');
    }
  }

  Future<void> _unlockSensitive(NabiEspDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mở dữ liệu sức khỏe?'),
        content: const Text(
          'Nabi sẽ được phép dùng những nhóm dữ liệu sức khỏe bạn đã bật cho thiết bị này trong 5 phút của phiên đang kết nối.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Mở trong 5 phút'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _runtime.unlockSensitiveContext(device);
      _showMessage('Dữ liệu được mở cho phiên Nabi đang kết nối trong 5 phút.');
    } catch (error) {
      _showMessage('Không mở được dữ liệu. ${_safeError(error)}');
    }
  }

  Future<void> _unbind(NabiEspDevice device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy liên kết ESP?'),
        content: Text(
          'Thao tác này thu hồi token của “${device.name}”. ESP sẽ không dùng được dịch vụ Nabi cho tới khi được ghép lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ liên kết'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy liên kết'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _runtime.unbindDevice(device);
    } catch (error) {
      _showMessage('Chưa hủy liên kết được. ${_safeError(error)}');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _safeError(Object error) => error is BackendApiException
      ? error.message
      : 'Vui lòng kiểm tra kết nối rồi thử lại.';

  String _statusLabel(NabiEspAssistantStatus status) => switch (status) {
    NabiEspAssistantStatus.idle => 'Sẵn sàng',
    NabiEspAssistantStatus.scanningEsp => 'Kiểm tra kết nối',
    NabiEspAssistantStatus.provisioningEsp => 'Đang cấu hình',
    NabiEspAssistantStatus.provisionAccepted => 'Đang kết nối',
    NabiEspAssistantStatus.connected => 'Đã liên kết',
    NabiEspAssistantStatus.error => 'Cần xử lý',
  };

  String _statusDescription(NabiEspAssistantStatus status) => switch (status) {
    NabiEspAssistantStatus.idle =>
      'Đăng nhập ứng dụng trước khi bắt đầu. Kết nối điện thoại với Wi-Fi Nabi; việc gửi cấu hình diễn ra tại chỗ và không cần dữ liệu di động.',
    NabiEspAssistantStatus.scanningEsp =>
      'Đang kiểm tra điện thoại đã nối Wi-Fi Nabi chưa.',
    NabiEspAssistantStatus.provisioningEsp =>
      'Đang gửi Wi-Fi nhà bạn tới ESP qua kết nối riêng tại chỗ.',
    NabiEspAssistantStatus.provisionAccepted =>
      'ESP đã nhận cấu hình và đang kết nối Wi-Fi nhà để đăng nhập máy chủ. Khi điện thoại có Internet, hãy làm mới danh sách thiết bị.',
    NabiEspAssistantStatus.connected =>
      'Thiết bị đã được liên kết. Có thể đóng ứng dụng; ESP tự kết nối khi khởi động.',
    NabiEspAssistantStatus.error => 'Không hoàn tất được bước vừa rồi.',
  };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.pastelBlue,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(label, style: AppTextStyles.labelSmall),
  );
}
