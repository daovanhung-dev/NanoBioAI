import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/ai_local/local_ai_model_catalog.dart';

void main() {
  test('vision model assets are pinned and fit the mobile download budget', () {
    expect(localAiVisionModelId, 'smolvlm-500m-q8');
    expect(localAiVisionAssets.map((asset) => asset.fileName), [
      'SmolVLM-500M-Instruct-Q8_0.gguf',
      'mmproj-SmolVLM-500M-Instruct-Q8_0.gguf',
    ]);
    expect(
      localAiVisionAssets.fold<int>(0, (sum, asset) => sum + asset.sizeBytes),
      localAiVisionDownloadBytes,
    );
    expect(localAiVisionDownloadBytes, lessThan(600 * 1024 * 1024));
    expect(
      localAiVisionAssets.every((asset) => asset.sha256.length == 64),
      isTrue,
    );
    expect(
      localAiVisionAssets.every(
        (asset) => asset.sourceUrl.contains(
          '/ggml-org/SmolVLM-500M-Instruct-GGUF/resolve/72e986006ef53e37cdd3f6d4241c90b0f01df376/',
        ),
      ),
      isTrue,
    );
  });
}
