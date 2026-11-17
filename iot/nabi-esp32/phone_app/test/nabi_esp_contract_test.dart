import 'package:flutter_test/flutter_test.dart';
import 'package:nabi_local_ai/nabi_esp_contract.g.dart';

void main() {
  test('phone server uses the shared Nabi OTA and audio endpoints', () {
    expect(NabiEspContract.port, 8386);
    expect(NabiEspContract.otaUrl('192.168.49.1'),
        'http://192.168.49.1:8386/nabi/ota/');
    expect(NabiEspContract.websocketUrl('192.168.49.1'),
        'ws://192.168.49.1:8386/nabi/v1/');
    expect(NabiEspContract.protocolVersion, 3);
  });
}
