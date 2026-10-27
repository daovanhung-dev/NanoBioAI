import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/nabi_esp_assistant/data/services/nabi_esp_server.dart';

void main() {
  test(
    'serves health and protocol v3 OTA, and rejects an invalid WebSocket token',
    () async {
      final server = NabiEspServer(port: 0, initializeCodec: () async {});
      final deviceKey = 'a' * 64;
      server.setDeviceKey(deviceKey);
      final client = HttpClient();
      await server.start(
        bindAddress: InternetAddress.loopbackIPv4,
        processTurn: (Int16List _) async => null,
        onStateChanged: (_) {},
      );
      addTearDown(() async {
        client.close(force: true);
        await server.stop();
      });

      final healthRequest = await client.getUrl(
        Uri.parse(server.websocketUrl).replace(scheme: 'http', path: '/health'),
      );
      final healthResponse = await healthRequest.close();
      final health =
          jsonDecode(await healthResponse.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      expect(health['ok'], isTrue);
      expect(health['protocol'], 3);

      final rejectedOtaRequest = await client.getUrl(Uri.parse(server.otaUrl));
      rejectedOtaRequest.headers.set('X-Nabi-Device-Key', 'wrong');
      final rejectedOtaResponse = await rejectedOtaRequest.close();
      expect(rejectedOtaResponse.statusCode, HttpStatus.unauthorized);
      await rejectedOtaResponse.drain<void>();

      final otaRequest = await client.getUrl(Uri.parse(server.otaUrl));
      otaRequest.headers.set('X-Nabi-Device-Key', deviceKey);
      final otaResponse = await otaRequest.close();
      final ota =
          jsonDecode(await otaResponse.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      final websocket = ota['websocket'] as Map<String, dynamic>;
      expect(websocket['version'], 3);
      expect(Uri.parse(server.otaUrl).path, '/nabi/ota/');
      expect(Uri.parse(server.websocketUrl).path, '/nabi/v1/');
      expect(websocket['url'], server.websocketUrl);
      expect(websocket['token'], isA<String>());

      final invalidRequest = await client.getUrl(
        Uri.parse(server.websocketUrl).replace(scheme: 'http'),
      );
      invalidRequest.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer invalid',
      );
      final invalidResponse = await invalidRequest.close();
      expect(invalidResponse.statusCode, HttpStatus.unauthorized);
      await invalidResponse.drain<void>();
    },
  );
}
