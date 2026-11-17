import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nano_app/core/network/backend_api_client.dart';
import 'package:nano_app/core/storage/nabi_esp_credential_vault.dart';

import 'nabi_esp_android_bridge.dart';
import 'nabi_esp_cloud_contract.g.dart';
import 'nabi_esp_device_service.dart';

enum NabiEspAssistantStatus {
  idle,
  scanningEsp,
  provisioningEsp,
  provisionAccepted,
  connected,
  error,
}

/// Local-AP provisioning and owner-side device management for Nabi ESP.
/// Account sign-in happens in the app before the phone joins the ESP Wi-Fi.
class NabiEspAssistantRuntime extends ChangeNotifier {
  NabiEspAssistantRuntime._();

  static final NabiEspAssistantRuntime instance = NabiEspAssistantRuntime._();

  final NabiEspDeviceService _devices = NabiEspDeviceService();
  NabiEspAssistantStatus status = NabiEspAssistantStatus.idle;
  List<NabiEspDevice> devices = const [];
  String? errorMessage;
  String? pairedDeviceId;
  bool _disposed = false;

  bool get isBusy => switch (status) {
    NabiEspAssistantStatus.scanningEsp ||
    NabiEspAssistantStatus.provisioningEsp => true,
    _ => false,
  };

  Future<void> loadDevices() async {
    if (!kDebugMode) {
      devices = const [];
      _notify();
      return;
    }
    if (BackendApiClient.shared.session == null) {
      devices = const [];
      _notify();
      return;
    }
    // The phone has no Internet route while attached to Nabi's local AP.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        if (await NabiEspAndroidBridge.isEspApConnected()) return;
      } on PlatformException {
        // A platform check failure should not block the normal online request.
      }
    }
    try {
      devices = await _devices.listDevices();
      final configured = pairedDeviceId;
      if (configured != null &&
          devices.any((device) => device.id == configured)) {
        final device = devices.firstWhere((item) => item.id == configured);
        status = device.connected
            ? NabiEspAssistantStatus.connected
            : NabiEspAssistantStatus.provisionAccepted;
      }
      errorMessage = null;
      _notify();
    } on BackendApiException catch (error) {
      errorMessage = _friendlyBackendError(error);
      _notify();
    } catch (_) {
      errorMessage = 'Chưa tải được danh sách thiết bị Nabi.';
      _notify();
    }
  }

  Future<void> setupDevice({
    required String ssid,
    required String wifiPassword,
  }) async {
    _requireInternalPilot();
    if (isBusy) return;
    final session = BackendApiClient.shared.session;
    if (session == null) {
      errorMessage = 'Đăng nhập vào ứng dụng trước khi cấu hình ESP.';
      status = NabiEspAssistantStatus.error;
      _notify();
      return;
    }
    final normalizedSsid = ssid.trim();
    if (normalizedSsid.isEmpty ||
        normalizedSsid.length > 32 ||
        wifiPassword.length < 8 ||
        wifiPassword.length > 63) {
      errorMessage = 'Nhập đúng Wi-Fi 2.4 GHz và mật khẩu từ 8–63 ký tự.';
      status = NabiEspAssistantStatus.error;
      _notify();
      return;
    }

    NabiEspAccountCredential? credential;
    try {
      credential = await NabiEspCredentialVault.instance.read(session.userId);
    } on PlatformException {
      errorMessage =
          'Không đọc được thông tin đăng nhập đã lưu. Hãy đăng nhập lại.';
      status = NabiEspAssistantStatus.error;
      _notify();
      return;
    } catch (_) {
      errorMessage =
          'Không đọc được thông tin đăng nhập đã lưu. Hãy đăng nhập lại.';
      status = NabiEspAssistantStatus.error;
      _notify();
      return;
    }
    if (credential == null) {
      errorMessage =
          'Chưa có thông tin đăng nhập được lưu trên điện thoại. Hãy kết nối Internet, đăng xuất rồi đăng nhập lại trước khi cấu hình ESP.';
      status = NabiEspAssistantStatus.error;
      _notify();
      return;
    }

    errorMessage = null;
    pairedDeviceId = null;
    status = NabiEspAssistantStatus.scanningEsp;
    _notify();
    try {
      final localStatus = await NabiEspAndroidBridge.getEspLocalStatus();
      final deviceId = localStatus['device_id'];
      if (deviceId is! String ||
          !RegExp(r'^[a-f0-9]{32}$').hasMatch(deviceId)) {
        throw PlatformException(code: 'device_id_missing');
      }
      if (localStatus['contract_version'] !=
              NabiEspCloudContract.contractVersion ||
          localStatus['protocol_version'] !=
              NabiEspCloudContract.protocolVersion) {
        throw PlatformException(code: 'esp_contract_mismatch');
      }

      status = NabiEspAssistantStatus.provisioningEsp;
      _notify();
      final result = await NabiEspAndroidBridge.provisionEspLocal(
        ssid: normalizedSsid,
        wifiPassword: wifiPassword,
        identifierType: credential.identifierType,
        identifier: credential.identifier,
        accountPassword: credential.password,
      );
      if (result['status'] != 'accepted' || result['device_id'] != deviceId) {
        throw PlatformException(code: 'esp_provision_rejected');
      }
      pairedDeviceId = deviceId;
      status = NabiEspAssistantStatus.provisionAccepted;
      errorMessage = null;
      _notify();
    } on PlatformException catch (exception) {
      status = NabiEspAssistantStatus.error;
      errorMessage = _friendlySetupError(exception);
      _notify();
    } catch (exception) {
      status = NabiEspAssistantStatus.error;
      if (exception is StateError) {
        errorMessage = exception.message.toString();
      } else {
        errorMessage = 'Không hoàn tất được cấu hình ESP. Hãy thử lại.';
      }
      _notify();
    }
  }

  Future<void> updateConsent(
    NabiEspDevice device,
    NabiEspDeviceConsent consent,
  ) async {
    _requireInternalPilot();
    await _devices.updateConsent(device.id, consent);
    await loadDevices();
  }

  Future<void> renameDevice(NabiEspDevice device, String name) async {
    _requireInternalPilot();
    if (name.trim().isEmpty) return;
    await _devices.rename(device.id, name);
    await loadDevices();
  }

  Future<void> unlockSensitiveContext(NabiEspDevice device) async {
    _requireInternalPilot();
    await _devices.unlockSensitiveContext(device.id);
  }

  Future<void> unbindDevice(NabiEspDevice device) async {
    _requireInternalPilot();
    await _devices.unbind(device.id);
    devices = devices.where((item) => item.id != device.id).toList();
    if (pairedDeviceId == device.id) {
      pairedDeviceId = null;
      status = NabiEspAssistantStatus.idle;
    }
    _notify();
  }

  String _friendlySetupError(PlatformException error) => switch (error.code) {
    'esp_not_found' =>
      'Chưa thấy Nabi trên Wi-Fi này. Kết nối điện thoại với Wi-Fi Nabi rồi thử lại.',
    'device_id_missing' => 'Không đọc được thông tin của ESP. Hãy thử lại.',
    'esp_contract_mismatch' =>
      'Firmware ESP cần được cập nhật trước khi cấu hình bằng ứng dụng.',
    'esp_provision_rejected' =>
      'ESP chưa nhận được cấu hình. Kết nối lại Wi-Fi Nabi rồi thử lại.',
    'wifi_config_invalid' => 'Thông tin Wi-Fi chưa hợp lệ.',
    'nabi_network_error' =>
      error.message ??
          'Không kết nối được tới ESP. Kiểm tra Wi-Fi Nabi rồi thử lại.',
    _ => 'Không cấu hình được ESP. Kiểm tra Wi-Fi Nabi rồi thử lại.',
  };

  String _friendlyBackendError(BackendApiException error) =>
      switch (error.businessCode) {
        'AUTHENTICATION_REQUIRED' || 'INVALID_ACCESS_TOKEN' =>
          'Phiên đăng nhập đã hết hạn. Đăng nhập lại rồi thử tiếp.',
        _ => error.message,
      };

  void _requireInternalPilot() {
    if (!kDebugMode) {
      throw StateError('Thiết lập Nabi ESP đang chờ duyệt nội bộ.');
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
