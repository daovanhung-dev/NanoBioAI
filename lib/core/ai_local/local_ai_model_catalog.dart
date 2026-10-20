class LocalAiModelAsset {
  const LocalAiModelAsset({
    required this.id,
    required this.fileName,
    required this.sourceUrl,
    required this.sizeBytes,
    required this.sha256,
  });

  final String id;
  final String fileName;
  final String sourceUrl;
  final int sizeBytes;
  final String sha256;
}

class LocalAiTextModel {
  const LocalAiTextModel({
    required this.id,
    required this.name,
    required this.description,
    required this.asset,
    required this.license,
    required this.licenseUrl,
    required this.recommendedRamBytes,
    required this.contextSize,
  });

  final String id;
  final String name;
  final String description;
  final LocalAiModelAsset asset;
  final String license;
  final String licenseUrl;
  final int recommendedRamBytes;
  final int contextSize;

  String get formattedSize => _formatBytes(asset.sizeBytes);
  String get formattedRecommendedRam => _formatBytes(recommendedRamBytes);
}

const localAiDefaultModelId = 'qwen3-06b-q4';

const localAiTextModels = <LocalAiTextModel>[
  LocalAiTextModel(
    id: 'gemma3-270m-q4',
    name: 'Gemma 3 270M',
    description: 'Gọn nhẹ, phù hợp thiết bị có ít bộ nhớ.',
    asset: LocalAiModelAsset(
      id: 'gemma3-270m-q4',
      fileName: 'gemma-3-270m-it-q4_k_m.gguf',
      sourceUrl:
          'https://huggingface.co/gguf-org/gemma-3-270m-it-gguf/resolve/0845b7e54ef2673cc691ab508e3ac6da7e392ad9/gemma-3-270m-it-q4_k_m.gguf?download=true',
      sizeBytes: 253114880,
      sha256:
          '55aed1673d2f3014a739732c659c4995fc57abf6e4e9c68462fb2ceee820ea2f',
    ),
    license: 'Gemma Terms of Use',
    licenseUrl: 'https://ai.google.dev/gemma/terms',
    recommendedRamBytes: 2 * 1024 * 1024 * 1024,
    contextSize: 2048,
  ),
  LocalAiTextModel(
    id: localAiDefaultModelId,
    name: 'Qwen3 0.6B',
    description: 'Cân bằng giữa tốc độ và chất lượng. Nabi gợi ý model này.',
    asset: LocalAiModelAsset(
      id: localAiDefaultModelId,
      fileName: 'Qwen_Qwen3-0.6B-Q4_K_M.gguf',
      sourceUrl:
          'https://huggingface.co/bartowski/Qwen_Qwen3-0.6B-GGUF/resolve/60b85c0e3d8fe0f6474f406922a26d12aca4550d/Qwen_Qwen3-0.6B-Q4_K_M.gguf?download=true',
      sizeBytes: 484220320,
      sha256:
          '9acfc1e001311f34b4252001b626f2e466d592a42065f66571bff3790d4e1b14',
    ),
    license: 'Apache License 2.0',
    licenseUrl: 'https://huggingface.co/Qwen/Qwen3-0.6B/blob/main/LICENSE',
    recommendedRamBytes: 3 * 1024 * 1024 * 1024,
    contextSize: 2048,
  ),
  LocalAiTextModel(
    id: 'qwen3-17b-q4',
    name: 'Qwen3 1.7B',
    description: 'Model lớn hơn, thường cần thiết bị có nhiều bộ nhớ.',
    asset: LocalAiModelAsset(
      id: 'qwen3-17b-q4',
      fileName: 'Qwen_Qwen3-1.7B-Q4_K_M.gguf',
      sourceUrl:
          'https://huggingface.co/bartowski/Qwen_Qwen3-1.7B-GGUF/resolve/dcb19155b962dbb6389f4691a982043a8e651022/Qwen_Qwen3-1.7B-Q4_K_M.gguf?download=true',
      sizeBytes: 1282439584,
      sha256:
          '72c5c3cb38fa32d5256e2fe30d03e7a64c6c79e668ad84057e3bd66e250b24fb',
    ),
    license: 'Apache License 2.0',
    licenseUrl: 'https://huggingface.co/Qwen/Qwen3-1.7B/blob/main/LICENSE',
    recommendedRamBytes: 5 * 1024 * 1024 * 1024,
    contextSize: 2048,
  ),
];

const localAiVisionAssets = <LocalAiModelAsset>[
  LocalAiModelAsset(
    id: 'qwen2-vl-2b-q4',
    fileName: 'Qwen2-VL-2B-Instruct-Q4_K_M.gguf',
    sourceUrl:
        'https://huggingface.co/ggml-org/Qwen2-VL-2B-Instruct-GGUF/resolve/bb307c036e8a1ed7b663bbd0c35b41c4c9294cfd/Qwen2-VL-2B-Instruct-Q4_K_M.gguf?download=true',
    sizeBytes: 986046944,
    sha256: '5745685d2e607a82a0696c1118e56a2a1ae0901da450fd9cd4f161c6b62867d7',
  ),
  LocalAiModelAsset(
    id: 'qwen2-vl-2b-q4-mmproj',
    fileName: 'mmproj-Qwen2-VL-2B-Instruct-Q8_0.gguf',
    sourceUrl:
        'https://huggingface.co/ggml-org/Qwen2-VL-2B-Instruct-GGUF/resolve/bb307c036e8a1ed7b663bbd0c35b41c4c9294cfd/mmproj-Qwen2-VL-2B-Instruct-Q8_0.gguf?download=true',
    sizeBytes: 709883360,
    sha256: 'a0ad91f00a7a80dcf84d719a61b00ee2e07b71794f4ee2dfa81a254621a8c418',
  ),
];

const localAiVisionModelId = 'qwen2-vl-2b-q4';
const localAiVisionContextSize = 4096;
const localAiVisionDownloadBytes = 1695930304;
const localAiVisionRecommendedRamBytes = 6 * 1024 * 1024 * 1024;

LocalAiTextModel localAiTextModelById(String id) => localAiTextModels
    .firstWhere((model) => model.id == id, orElse: () => localAiTextModels[1]);

String _formatBytes(int bytes) {
  final gibibytes = bytes / (1024 * 1024 * 1024);
  if (gibibytes >= 1) return '${gibibytes.toStringAsFixed(2)} GB';
  return '${(bytes / (1024 * 1024)).round()} MB';
}
