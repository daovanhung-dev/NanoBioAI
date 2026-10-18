class LocalModel {
  const LocalModel({
    required this.id,
    required this.name,
    required this.url,
    required this.sizeBytes,
    required this.description,
    this.sha256,
    this.contextSize = 2048,
    this.template = 'chatml',
  });

  final String id;
  final String name;
  final Uri url;
  final int sizeBytes;
  final String description;
  final String? sha256;
  final int contextSize;
  final String template;

  String get sizeLabel => '${(sizeBytes / 1024 / 1024).round()} MB';

  static final catalog = <LocalModel>[
    LocalModel(
      id: 'qwen3-0.6b-q4_0',
      name: 'Qwen3 0.6B · Q4_0',
      url: Uri.parse(
        'https://huggingface.co/ggml-org/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q4_0.gguf',
      ),
      sizeBytes: 429 * 1024 * 1024,
      sha256:
          'da2572f16c06133561ce56accaa822216f2391ef4d37fba427801cd6736417d4',
      description:
          'Bản gọn, đa ngôn ngữ; lựa chọn mặc định cho điện thoại 4 GB RAM.',
    ),
    LocalModel(
      id: 'qwen2.5-0.5b-instruct-q4_0',
      name: 'Qwen2.5 0.5B Instruct · Q4_0',
      url: Uri.parse(
        'https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_0.gguf',
      ),
      sizeBytes: 429 * 1024 * 1024,
      sha256:
          '7671c0c304e6ce5a7fc577bcb12aba01e2c155cc2efd29b2213c95b18edaf6ed',
      description: 'Model instruct nhỏ, tương thích ChatML; một lựa chọn thay thế Qwen3.',
    ),
    LocalModel(
      id: 'qwen3-0.6b-q8_0',
      name: 'Qwen3 0.6B · Q8_0',
      url: Uri.parse(
        'https://huggingface.co/ggml-org/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf',
      ),
      sizeBytes: 805 * 1024 * 1024,
      sha256:
          '361cc68159042c36ebff7715dc5a2e4612153e88f3e9c9c234820849d6dc9e1d',
      description: 'Bản Q8 giữ độ chính xác cao hơn, tải 805 MiB và cần nhiều RAM hơn Q4_0.',
    ),
  ];
}
