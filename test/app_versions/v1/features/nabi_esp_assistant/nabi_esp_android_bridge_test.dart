import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/nabi_esp_assistant/data/services/nabi_esp_android_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.nanobioai.app/nabi_esp');
  final calls = <MethodCall>[];
  Map<Object?, Object?>? provisionArguments;

  setUp(() {
    calls.clear();
    provisionArguments = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'getEspLocalStatus' => {
              'contract_version': 4,
              'protocol_version': 3,
              'device_id': '0123456789abcdef0123456789abcdef',
              'claimed': false,
            },
            'provisionEspLocal' => _captureProvision(call, (arguments) {
              provisionArguments = arguments;
            }),
            'isEspApConnected' => true,
            'encryptNabiCredential' => {
              'ciphertext': 'ciphertext-value',
              'iv': 'initialization-vector',
            },
            'decryptNabiCredential' => '{"version":1}',
            _ => null,
          };
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'uses only the ESP local AP and sends saved account credentials',
    () async {
      final status = await NabiEspAndroidBridge.getEspLocalStatus();
      final result = await NabiEspAndroidBridge.provisionEspLocal(
        ssid: 'Home Wi-Fi',
        wifiPassword: 'home-wifi-secret',
        identifierType: 'phone',
        identifier: '+84912345678',
        accountPassword: 'account-secret',
      );

      expect(status['device_id'], '0123456789abcdef0123456789abcdef');
      expect(status['contract_version'], 4);
      expect(result['status'], 'accepted');
      expect(calls.map((call) => call.method), [
        'getEspLocalStatus',
        'provisionEspLocal',
      ]);
      expect(provisionArguments, {
        'ssid': 'Home Wi-Fi',
        'wifiPassword': 'home-wifi-secret',
        'identifierType': 'phone',
        'identifier': '+84912345678',
        'accountPassword': 'account-secret',
      });
      expect(provisionArguments!.keys, isNot(contains('pairingToken')));
    },
  );

  test(
    'detects the local AP and wraps Android credential encryption',
    () async {
      expect(await NabiEspAndroidBridge.isEspApConnected(), isTrue);
      final encrypted = await NabiEspAndroidBridge.encryptNabiCredential(
        '{"version":1}',
      );
      final decrypted = await NabiEspAndroidBridge.decryptNabiCredential(
        ciphertext: encrypted['ciphertext']!,
        iv: encrypted['iv']!,
      );

      expect(encrypted, {
        'ciphertext': 'ciphertext-value',
        'iv': 'initialization-vector',
      });
      expect(decrypted, '{"version":1}');
    },
  );
}

Object? _captureProvision(
  MethodCall call,
  void Function(Map<Object?, Object?> arguments) capture,
) {
  capture(Map<Object?, Object?>.from(call.arguments as Map));
  return {
    'status': 'accepted',
    'device_id': '0123456789abcdef0123456789abcdef',
  };
}
