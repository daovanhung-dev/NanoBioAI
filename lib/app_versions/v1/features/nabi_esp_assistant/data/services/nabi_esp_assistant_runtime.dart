import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nano_app/services/backend/auth/current_backend_user.dart';
import 'package:permission_handler/permission_handler.dart';

import 'nabi_esp_android_bridge.dart';
import 'nabi_esp_server.dart';
import 'nabi_esp_voice_pipeline.dart';

enum NabiEspAssistantStatus {
  idle,
  preparingAi,
  startingHotspot,
  selectingHost,
  startingServer,
  scanningEsp,
  pairingRequired,
  provisioningEsp,
  waitingForEsp,
  connected,
  listening,
  processing,
  speaking,
  stopping,
  error,
}

class NabiEspHostCandidate {
  const NabiEspHostCandidate({
    required this.interfaceName,
    required this.address,
  });

  final String interfaceName;
  final InternetAddress address;

  @override
  String toString() => '${address.address} · $interfaceName';
}

/// App-owned Android session for Nabi's local XiaoZhi service.
class NabiEspAssistantRuntime extends ChangeNotifier {
  NabiEspAssistantRuntime._() {
    NabiEspAndroidBridge.initialize(
      onStopRequested: stop,
      onHotspotStopped: _handleHotspotStopped,
    );
  }

  static final NabiEspAssistantRuntime instance = NabiEspAssistantRuntime._();
  static const _networkWait = Duration(milliseconds: 400);

  final NabiEspVoicePipeline _voice = NabiEspVoicePipeline();
  NabiEspServer? _server;
  NabiEspHotspotCredentials? _hotspot;
  List<NabiEspHostCandidate> hostCandidates = const [];
  NabiEspAssistantStatus status = NabiEspAssistantStatus.idle;
  String? hostAddress;
  String? errorMessage;
  double? whisperProgress;

  bool get isRunning => _server?.isRunning == true;
  bool get isDeviceConnected => _server?.isDeviceConnected == true;
  bool get hasHotspot => _hotspot != null;
  String? get hotspotSsid => _hotspot?.ssid;
  String? get hotspotPassword => _hotspot?.password;
  String? get otaUrl => _server?.otaUrl;
  bool get isBusy => switch (status) {
    NabiEspAssistantStatus.preparingAi ||
    NabiEspAssistantStatus.startingHotspot ||
    NabiEspAssistantStatus.startingServer ||
    NabiEspAssistantStatus.scanningEsp ||
    NabiEspAssistantStatus.provisioningEsp ||
    NabiEspAssistantStatus.stopping => true,
    _ => false,
  };

  Future<void> start() async {
    if (isBusy || isRunning || hasHotspot) return;
    if (currentBackendUserIdOrNull() == null) {
      throw StateError(
        'Đăng nhập để dùng câu trả lời AI trên máy chủ NanoBio.',
      );
    }
    errorMessage = null;
    hostCandidates = const [];
    hostAddress = null;
    status = NabiEspAssistantStatus.preparingAi;
    notifyListeners();
    try {
      await _requestPermissions();
      await _voice.prepare(
        onWhisperProgress: (value) {
          whisperProgress = value;
          notifyListeners();
        },
      );

      final before = (await _listPrivateCandidates())
          .map(_candidateKey)
          .toSet();
      status = NabiEspAssistantStatus.startingHotspot;
      notifyListeners();
      await NabiEspAndroidBridge.startForegroundService();
      _hotspot = await NabiEspAndroidBridge.startLocalOnlyHotspot();
      hostCandidates = await _waitForNewHotspotAddress(before);
      if (hostCandidates.isEmpty) {
        throw StateError('Không tìm thấy địa chỉ IPv4 của hotspot Nabi.');
      }
      if (hostCandidates.length == 1) {
        await _startServer(hostCandidates.single.address);
      } else {
        final likelyAp = hostCandidates.where(
          (candidate) => RegExp(
            r'ap|softap|wlan1|swlan',
            caseSensitive: false,
          ).hasMatch(candidate.interfaceName),
        );
        if (likelyAp.length == 1) {
          await _startServer(likelyAp.single.address);
        } else {
          status = NabiEspAssistantStatus.selectingHost;
          await NabiEspAndroidBridge.updateForegroundNotification(
            title: 'Nabi đang chuẩn bị kết nối ESP',
            message: 'Chọn địa chỉ hotspot trong ứng dụng Nabi.',
          );
          notifyListeners();
        }
      }
    } on PlatformException catch (exception) {
      await _stopServerAfterFailedStart();
      await _releaseAndroidResources();
      _hotspot = null;
      hostAddress = null;
      errorMessage = _platformError(exception.code);
      status = NabiEspAssistantStatus.error;
      notifyListeners();
    } catch (exception) {
      await _stopServerAfterFailedStart();
      await _releaseAndroidResources();
      _hotspot = null;
      hostAddress = null;
      hostCandidates = const [];
      errorMessage = _safeStartError(exception);
      status = NabiEspAssistantStatus.error;
      notifyListeners();
    }
  }

  Future<void> selectHost(String address) async {
    if (status != NabiEspAssistantStatus.selectingHost) return;
    final candidate = hostCandidates
        .where((item) => item.address.address == address)
        .firstOrNull;
    if (candidate == null) return;
    try {
      await _startServer(candidate.address);
    } catch (_) {
      await _stopServerAfterFailedStart();
      await _releaseAndroidResources();
      _hotspot = null;
      hostAddress = null;
      hostCandidates = const [];
      errorMessage = 'Không mở được máy chủ trên địa chỉ mạng đã chọn.';
      status = NabiEspAssistantStatus.error;
      notifyListeners();
    }
  }

  Future<String?> sendListenControl({required bool start}) async {
    final server = _server;
    if (server == null || !server.isDeviceConnected) return null;
    return server.sendListenControl(start ? 'listen.start' : 'listen.stop');
  }

  Future<void> stop() async {
    if (!isRunning && !hasHotspot) {
      await _releaseAndroidResources();
      status = NabiEspAssistantStatus.idle;
      notifyListeners();
      return;
    }
    status = NabiEspAssistantStatus.stopping;
    notifyListeners();
    await _server?.stop();
    _server = null;
    await _voice.clearConversation();
    await _releaseAndroidResources();
    hostAddress = null;
    hostCandidates = const [];
    _hotspot = null;
    status = NabiEspAssistantStatus.idle;
    notifyListeners();
  }

  Future<void> _startServer(InternetAddress address) async {
    status = NabiEspAssistantStatus.startingServer;
    hostAddress = address.address;
    notifyListeners();
    final server = NabiEspServer();
    await server.start(
      bindAddress: address,
      processTurn: _voice.process,
      onStateChanged: _handleServerState,
    );
    _server = server;
    status = NabiEspAssistantStatus.waitingForEsp;
    await NabiEspAndroidBridge.updateForegroundNotification(
      title: 'Nabi đang chờ ESP',
      message:
          'Đang tìm ESP qua Bluetooth; câu trả lời AI dùng máy chủ NanoBio.',
    );
    notifyListeners();
    unawaited(_attemptBleProvisioning());
  }

  Future<void> retryEspProvisioning({String? pairingCode}) async {
    if (_server == null || !hasHotspot || isBusy) return;
    await _attemptBleProvisioning(pairingCode: pairingCode);
  }

  Future<void> _attemptBleProvisioning({String? pairingCode}) async {
    final hotspot = _hotspot;
    final server = _server;
    if (hotspot == null || server == null) return;
    errorMessage = null;
    status = pairingCode == null
        ? NabiEspAssistantStatus.scanningEsp
        : NabiEspAssistantStatus.provisioningEsp;
    notifyListeners();
    try {
      final result = await NabiEspAndroidBridge.provisionEsp(
        ssid: hotspot.ssid,
        password: hotspot.password,
        pairingCode: pairingCode,
      );
      if (result['status'] == 'pairing_required') {
        status = NabiEspAssistantStatus.pairingRequired;
        notifyListeners();
        return;
      }
      final deviceKey = result['deviceKey'];
      if (deviceKey is! String) {
        throw PlatformException(code: 'pairing_key_missing');
      }
      server.setDeviceKey(deviceKey);
      status = NabiEspAssistantStatus.waitingForEsp;
      await NabiEspAndroidBridge.updateForegroundNotification(
        title: 'Nabi sẵn sàng',
        message: 'Hotspot đang chờ ESP; cần Internet và đăng nhập để dùng AI.',
      );
      notifyListeners();
    } on PlatformException catch (exception) {
      switch (exception.code) {
        case 'esp_not_found':
          status = NabiEspAssistantStatus.waitingForEsp;
          errorMessage = 'Chưa tìm thấy ESP. Bật thiết bị rồi chọn “Tìm ESP”.';
          break;
        case 'pairing_failed':
          status = NabiEspAssistantStatus.pairingRequired;
          errorMessage =
              'Mã không đúng hoặc đã hết hạn. Khởi động lại ESP để tạo mã mới.';
          break;
        case 'bluetooth_disabled':
          status = NabiEspAssistantStatus.waitingForEsp;
          errorMessage =
              'Hãy bật Bluetooth trên điện thoại rồi thử tìm ESP lại.';
          break;
        default:
          status = NabiEspAssistantStatus.waitingForEsp;
          errorMessage = 'Không cấu hình được ESP qua Bluetooth. Hãy thử lại.';
          break;
      }
      notifyListeners();
    } catch (_) {
      status = NabiEspAssistantStatus.waitingForEsp;
      errorMessage = 'Không cấu hình được ESP qua Bluetooth. Hãy thử lại.';
      notifyListeners();
    }
  }

  void _handleServerState(String value) {
    status = switch (value) {
      'connected' => NabiEspAssistantStatus.connected,
      'listening' => NabiEspAssistantStatus.listening,
      'processing' => NabiEspAssistantStatus.processing,
      'speaking' => NabiEspAssistantStatus.speaking,
      'disconnected' => NabiEspAssistantStatus.waitingForEsp,
      'stopped' => NabiEspAssistantStatus.idle,
      _ => NabiEspAssistantStatus.error,
    };
    if (value == 'error') {
      errorMessage = 'Kết nối mạng bị gián đoạn. Hãy thử kết nối lại.';
    }
    notifyListeners();
  }

  Future<void> _handleHotspotStopped() async {
    if (_server == null ||
        status == NabiEspAssistantStatus.stopping ||
        status == NabiEspAssistantStatus.idle) {
      return;
    }
    await _stopServerAfterFailedStart();
    await _voice.clearConversation();
    await _releaseAndroidResources();
    _hotspot = null;
    hostAddress = null;
    hostCandidates = const [];
    errorMessage =
        'Android đã dừng hotspot Nabi. Hãy bấm Kết nối Nabi để thử lại.';
    status = NabiEspAssistantStatus.error;
    notifyListeners();
  }

  Future<void> _stopServerAfterFailedStart() async {
    final server = _server;
    _server = null;
    await server?.stop();
  }

  Future<void> _requestPermissions() async {
    final sdk = await NabiEspAndroidBridge.androidSdkInt();
    if (sdk <= 32) {
      final location = await Permission.locationWhenInUse.request();
      if (!location.isGranted) {
        throw const _NabiEspStartFailure(
          'Cần quyền vị trí khi dùng app để mở hotspot cục bộ.',
        );
      }
    } else {
      final nearby = await Permission.nearbyWifiDevices.request();
      if (!nearby.isGranted) {
        throw const _NabiEspStartFailure(
          'Cần quyền thiết bị Wi-Fi lân cận để mở hotspot cục bộ.',
        );
      }
    }
    if (sdk >= 33) {
      final notification = await Permission.notification.request();
      if (!notification.isGranted) {
        throw const _NabiEspStartFailure(
          'Cần cho phép thông báo để giữ dịch vụ AI hoạt động.',
        );
      }
    }
    if (sdk >= 31) {
      final scan = await Permission.bluetoothScan.request();
      final connect = await Permission.bluetoothConnect.request();
      if (!scan.isGranted || !connect.isGranted) {
        throw const _NabiEspStartFailure(
          'Cần quyền Bluetooth để tìm và ghép ESP.',
        );
      }
    }
  }

  Future<List<NabiEspHostCandidate>> _waitForNewHotspotAddress(
    Set<String> addressesBefore,
  ) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final candidates = await _listPrivateCandidates();
      final newAddresses = candidates
          .where(
            (candidate) => !addressesBefore.contains(_candidateKey(candidate)),
          )
          .toList();
      if (newAddresses.isNotEmpty) return newAddresses;
      await Future<void>.delayed(_networkWait);
    }
    return const [];
  }

  String _candidateKey(NabiEspHostCandidate candidate) =>
      '${candidate.interfaceName}:${candidate.address.address}';

  Future<List<NabiEspHostCandidate>> _listPrivateCandidates() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    final candidates = <NabiEspHostCandidate>[];
    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      if (name.contains('p2p') ||
          name.contains('vpn') ||
          name.contains('tun') ||
          name == 'lo') {
        continue;
      }
      for (final address in interface.addresses) {
        if (_isPrivateIpv4(address.address) && !address.isLoopback) {
          candidates.add(
            NabiEspHostCandidate(
              interfaceName: interface.name,
              address: address,
            ),
          );
        }
      }
    }
    candidates.sort((left, right) {
      final byInterface = left.interfaceName.compareTo(right.interfaceName);
      return byInterface != 0
          ? byInterface
          : left.address.address.compareTo(right.address.address);
    });
    return candidates;
  }

  bool _isPrivateIpv4(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    final octets = parts.map(int.tryParse).toList();
    if (octets.any((part) => part == null || part < 0 || part > 255)) {
      return false;
    }
    final first = octets[0]!;
    final second = octets[1]!;
    return first == 10 ||
        first == 192 && second == 168 ||
        first == 172 && second >= 16 && second <= 31;
  }

  Future<void> _releaseAndroidResources() async {
    try {
      await NabiEspAndroidBridge.stopLocalOnlyHotspot();
    } catch (_) {
      // The platform may already have released its reservation.
    }
    try {
      await NabiEspAndroidBridge.stopForegroundService();
    } catch (_) {
      // Continue clearing the in-memory session after native cleanup failures.
    }
  }

  String _platformError(String code) => switch (code) {
    'hotspot_unsupported' => 'Điện thoại không hỗ trợ LocalOnlyHotspot.',
    'hotspot_busy' =>
      'Hotspot đang được một ứng dụng hoặc hệ thống khác sử dụng.',
    'hotspot_permission' => 'Android chưa cấp quyền để tạo hotspot cục bộ.',
    'hotspot_failed' =>
      'Android không tạo được hotspot. Hãy tắt hotspot hệ thống rồi thử lại.',
    _ => 'Không thể khởi động kết nối Nabi trên điện thoại.',
  };

  String _safeStartError(Object exception) {
    if (exception is _NabiEspStartFailure) return exception.message;
    if (exception is StateError) return exception.message.toString();
    return 'Không thể chuẩn bị nhận dạng giọng nói hoặc khởi tạo kết nối.';
  }
}

class _NabiEspStartFailure implements Exception {
  const _NabiEspStartFailure(this.message);

  final String message;
}
