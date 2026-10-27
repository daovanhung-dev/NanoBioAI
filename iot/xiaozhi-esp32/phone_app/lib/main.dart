import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart'
    show ChatMessage;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/local_model.dart';
import 'services/local_ai_service.dart';
import 'services/model_service.dart';
import 'services/phone_server_lifecycle.dart';
import 'services/voice_service.dart';
import 'services/xiaozhi_server.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XiaoZhiLocalAiApp());
}

class XiaoZhiLocalAiApp extends StatelessWidget {
  const XiaoZhiLocalAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'XiaoZhi Local AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff086c63)),
        scaffoldBackgroundColor: const Color(0xfff5f7f6),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final ModelService _models;
  late final LocalAiService _ai;
  late final VoiceService _voice;
  late final XiaozhiServer _server;
  var _index = 0;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _models = ModelService();
    _ai = LocalAiService(_models);
    _voice = VoiceService();
    _server = XiaozhiServer(ai: _ai, voice: _voice);
    PhoneServerLifecycle.initialize(onStopRequested: _server.stop);
    unawaited(_server.refreshAddresses());
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await _models.restore();
    await _voice.initialize();
    if (_models.hasModel && mounted) unawaited(_ai.loadSelectedModel());
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('whisper_installed') == true) {
      unawaited(_ai.installSpeechModel());
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    unawaited(_server.stop());
    _server.dispose();
    _ai.dispose();
    _models.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      _ChatPage(ai: _ai, models: _models),
      _ModelsPage(models: _models, ai: _ai, server: _server),
      _ConnectionPage(server: _server, ai: _ai, voice: _voice),
      _SettingsPage(voice: _voice),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'XiaoZhi Local AI',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: ListenableBuilder(
                listenable: _server,
                builder: (context, _) => _StatusBadge(
                  label: _server.isRunning ? 'LOCAL ON' : 'LOCAL OFF',
                  active: _server.isRunning,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory),
            label: 'Model',
          ),
          NavigationDestination(
            icon: Icon(Icons.router_outlined),
            selectedIcon: Icon(Icons.router),
            label: 'ESP',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune),
            selectedIcon: Icon(Icons.tune),
            label: 'Cài đặt',
          ),
        ],
      ),
    );
  }
}

class _ChatPage extends StatefulWidget {
  const _ChatPage({required this.ai, required this.models});
  final LocalAiService ai;
  final ModelService models;

  @override
  State<_ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<_ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatLine> _messages = [];
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    if (!widget.ai.llmReady) {
      _addMessage('system', 'Chọn hoặc cài model trong mục Model trước.');
      return;
    }
    _input.clear();
    setState(() {
      _busy = true;
      _messages.add(_ChatLine('user', text));
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final language = prefs.getString('response_language') ?? 'vi';
      final prompt = prefs.getString('system_prompt')?.trim() ?? '';
      final temperature = prefs.getDouble('temperature') ?? 0.7;
      final system =
          '${_languageInstruction(language)} ${prompt.isEmpty ? '' : '\n$prompt'}';
      final historyLines = _messages
          .where((line) => line.role == 'user' || line.role == 'assistant')
          .toList();
      final previousLines = historyLines.length > 12
          ? historyLines.sublist(
              historyLines.length - 13,
              historyLines.length - 1,
            )
          : historyLines.sublist(0, historyLines.length - 1);
      final history = previousLines
          .map((line) => ChatMessage(role: line.role, content: line.text))
          .toList();
      final answer = await widget.ai.answer(
        userText: text,
        systemPrompt: system,
        previousMessages: history,
        temperature: temperature,
      );
      _addMessage(
        'assistant',
        answer.isEmpty ? '(Không có nội dung trả lời)' : answer,
      );
    } catch (value) {
      _addMessage('system', 'Không chạy được model local: $value');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _addMessage(String role, String text) {
    if (!mounted) return;
    setState(() => _messages.add(_ChatLine(role, text)));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _languageInstruction(String language) => switch (language) {
    'en' => 'Reply in English.',
    'auto' => 'Reply in the same language as the user.',
    _ => 'Trả lời bằng tiếng Việt tự nhiên, ngắn gọn.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InfoCard(
          icon: Icons.phone_android,
          title: 'AI chạy ngay trên điện thoại',
          subtitle: widget.ai.llmReady
              ? 'Đang dùng ${widget.models.modelPath?.split('/').last ?? 'model local'}'
              : 'Cài hoặc nhập model GGUF để bắt đầu.',
        ),
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Text('Thử chat local trước khi kết nối ESP.'),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      _ChatBubble(line: _messages[index]),
                ),
        ),
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Nhắn với model trên điện thoại…',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _busy ? null : _send,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModelsPage extends StatelessWidget {
  const _ModelsPage({
    required this.models,
    required this.ai,
    required this.server,
  });
  final ModelService models;
  final LocalAiService ai;
  final XiaozhiServer server;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoCard(
          icon: Icons.storage,
          title: 'Model nằm trong bộ nhớ riêng của ứng dụng',
          subtitle: 'Chọn model trong catalog, nhập GGUF ChatML, hoặc tải model vào app. Inference chạy trên điện thoại.',
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: Listenable.merge([models, ai, server]),
          builder: (context, _) => _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  models.hasModel ? 'Model đã chọn' : 'Chưa có model',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  models.modelPath?.split('/').last ??
                      'Nhập file GGUF hoặc cài một model trong danh sách.',
                ),
                if (models.availableModels.length > 1) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    key: ValueKey(models.modelPath),
                    initialValue: models.modelPath,
                    decoration: const InputDecoration(
                      labelText: 'Model đã cài',
                      border: OutlineInputBorder(),
                    ),
                    items: models.availableModels
                        .map(
                          (path) => DropdownMenuItem(
                            value: path,
                            child: Text(
                              path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: models.downloading || server.isRunning
                        ? null
                        : (path) {
                            if (path != null) {
                              unawaited(
                                _activateModel(
                                  context: context,
                                  path: path,
                                  models: models,
                                  ai: ai,
                                  server: server,
                                ),
                              );
                            }
                          },
                  ),
                ],
                if (server.isRunning) ...[
                  const SizedBox(height: 6),
                  const Text('Dừng server trước khi đổi hoặc nhập model.'),
                ],
                if (models.downloading) ...[
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: models.downloadProgress == 0
                        ? null
                        : models.downloadProgress,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(models.downloadProgress * 100).round()}%  ·  ${models.status ?? ''}',
                  ),
                ] else if (models.status != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    models.status!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (models.error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    models.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (ai.error != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    ai.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: models.downloading || server.isRunning
                          ? null
                          : () async {
                              await ai.unloadLanguageModel();
                              await models.chooseExistingModel();
                              if (models.hasModel) await ai.loadSelectedModel();
                            },
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Nhập GGUF'),
                    ),
                    if (models.downloading)
                      OutlinedButton.icon(
                        onPressed: models.cancelDownload,
                        icon: const Icon(Icons.close),
                        label: const Text('Hủy tải'),
                      )
                    else if (models.hasModel && !ai.llmReady)
                      FilledButton.icon(
                        onPressed: ai.loadingLlm ? null : ai.loadSelectedModel,
                        icon: const Icon(Icons.play_arrow),
                        label: Text(ai.loadingLlm ? 'Đang nạp…' : 'Nạp model'),
                      )
                    else if (ai.llmReady)
                      const Chip(
                        avatar: Icon(Icons.check_circle, size: 18),
                        label: Text('Model đang chạy'),
                      ),
                  ],
                ),
                if (models.hasModel) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: server.isRunning || ai.loadingLlm
                        ? null
                        : () async {
                            await ai.unloadLanguageModel();
                            await models.clearSelection();
                          },
                    child: const Text('Bỏ chọn model'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...LocalModel.catalog.map(
          (model) => _ModelDownloadCard(
            model: model,
            service: models,
            ai: ai,
            server: server,
          ),
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: ai,
          builder: (context, _) => _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhận dạng giọng nói tiếng Việt',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Whisper tiny Q5 · 31 MiB · chỉ xử lý âm thanh trong máy.',
                ),
                const SizedBox(height: 12),
                if (ai.whisperReady)
                  const Chip(
                    avatar: Icon(Icons.check_circle, size: 18),
                    label: Text('Đã cài và nạp Whisper'),
                  )
                else
                  FilledButton.tonalIcon(
                    onPressed: ai.loadingWhisper ? null : ai.installSpeechModel,
                    icon: const Icon(Icons.download),
                    label: Text(
                      ai.loadingWhisper
                          ? 'Đang cài ${(ai.whisperDownloadProgress * 100).round()}%'
                          : 'Tải và cài Whisper',
                    ),
                  ),
                if (ai.loadingWhisper) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: ai.whisperDownloadProgress == 0
                        ? null
                        : ai.whisperDownloadProgress,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ModelDownloadCard extends StatelessWidget {
  const _ModelDownloadCard({
    required this.model,
    required this.service,
    required this.ai,
    required this.server,
  });
  final LocalModel model;
  final ModelService service;
  final LocalAiService ai;
  final XiaozhiServer server;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([service, ai, server]),
      builder: (context, _) {
        final installedPath = service.installedPathFor(model);
        final selected =
            installedPath != null && installedPath == service.modelPath;
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.memory),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      model.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(model.sizeLabel),
                ],
              ),
              const SizedBox(height: 8),
              Text(model.description),
              const SizedBox(height: 8),
              if (installedPath == null)
                FilledButton.tonalIcon(
                  onPressed:
                      service.downloading || server.isRunning || ai.loadingLlm
                      ? null
                      : () async {
                          await ai.unloadLanguageModel();
                          await service.download(model);
                          if (service.hasModel) await ai.loadSelectedModel();
                        },
                  icon: const Icon(Icons.download),
                  label: const Text('Tải từ Hugging Face'),
                )
              else if (selected && ai.llmReady)
                const Chip(
                  avatar: Icon(Icons.check_circle, size: 18),
                  label: Text('Model đang chạy'),
                )
              else
                FilledButton.tonalIcon(
                  onPressed:
                      service.downloading || server.isRunning || ai.loadingLlm
                      ? null
                      : () => _activateModel(
                          context: context,
                          path: installedPath,
                          models: service,
                          ai: ai,
                          server: server,
                        ),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    ai.loadingLlm && selected
                        ? 'Đang nạp…'
                        : selected
                        ? 'Nạp model'
                        : 'Chọn model này',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _activateModel({
  required BuildContext context,
  required String path,
  required ModelService models,
  required LocalAiService ai,
  required XiaozhiServer server,
}) async {
  if (server.isRunning || ai.loadingLlm) return;
  try {
    await ai.unloadLanguageModel();
    await models.selectModel(path);
    await ai.loadSelectedModel();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Không nạp được model: $error')));
    }
  }
}

class _ConnectionPage extends StatelessWidget {
  const _ConnectionPage({
    required this.server,
    required this.ai,
    required this.voice,
  });
  final XiaozhiServer server;
  final LocalAiService ai;
  final VoiceService voice;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoCard(
          icon: Icons.hub_outlined,
          title: 'Điện thoại là máy chủ AI nội bộ',
          subtitle: 'ESP gửi âm thanh qua LAN. Whisper và LLM chạy trên điện thoại; giọng đọc dùng Android TTS.',
        ),
        const SizedBox(height: 12),
        ListenableBuilder(
          listenable: Listenable.merge([server, ai]),
          builder: (context, _) => _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      server.isRunning
                          ? Icons.wifi_tethering
                          : Icons.wifi_tethering_off,
                      color: server.isRunning ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        server.isRunning
                            ? 'Server nội bộ đang chạy'
                            : 'Server nội bộ đang dừng',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _ReadinessRow(label: 'Model ngôn ngữ', ready: ai.llmReady),
                _ReadinessRow(
                  label: 'Nhận dạng giọng nói',
                  ready: ai.whisperReady,
                ),
                _ReadinessRow(label: 'Android TTS', ready: voice.isReady),
                _ReadinessRow(
                  label: 'Voice chạy offline',
                  ready: voice.selectedVoiceIsOffline,
                ),
                if (server.hostAddress != null) ...[
                  const Divider(height: 24),
                  Text('Địa chỉ nội bộ: ${server.hostAddress}:8765'),
                  const SizedBox(height: 8),
                  Text(
                    'OTA URL cho ESP',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  SelectableText(
                    server.otaUrl,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: server.otaUrl),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã sao chép OTA URL'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Sao chép'),
                    ),
                  ),
                ],
                if (!server.isRunning) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          server.availableAddresses.isEmpty
                              ? 'Chưa thấy địa chỉ IPv4 hotspot'
                              : 'Chọn địa chỉ hotspot của điện thoại',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Quét lại địa chỉ mạng',
                        onPressed: server.refreshAddresses,
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  if (server.availableAddresses.isNotEmpty)
                    DropdownButtonFormField<String>(
                      initialValue: server.selectedAddress,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'IPv4 và interface',
                      ),
                      hint: const Text('Chọn interface hotspot'),
                      items: server.availableAddresses
                          .map(
                            (candidate) => DropdownMenuItem(
                              value: candidate.address,
                              child: Text(candidate.toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (address) {
                        if (address != null) server.selectAddress(address);
                      },
                    ),
                ],
                if (server.error != null)
                  Text(
                    server.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: server.isRunning
                        ? server.stop
                        : ai.llmReady && ai.whisperReady && voice.isReady
                        ? server.start
                        : null,
                    icon: Icon(
                      server.isRunning ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      server.isRunning
                          ? 'Dừng server'
                          : ai.llmReady && ai.whisperReady && voice.isReady
                          ? 'Khởi chạy server AI local'
                          : 'Nạp model, Whisper và chọn voice trước',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kết nối firmware',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '1. Kết nối điện thoại và ESP vào cùng Wi-Fi hoặc dùng hotspot của điện thoại.',
              ),
              Text(
                '2. Mở trang cấu hình Wi-Fi của ESP và nhập OTA URL phía trên vào ô Custom OTA URL.',
              ),
              Text(
                '3. Lưu cấu hình, khởi động lại ESP. Firmware lấy OTA URL đã lưu trong NVS khi khởi động.',
              ),
              SizedBox(height: 8),
              Text(
                'Server chạy trong notification khi bạn chuyển app xuống nền hoặc tắt màn hình. Giữ điện thoại cắm sạc trong phiên; một số máy vẫn có thể hoãn mạng nội bộ khi vào Doze.',
              ),
              SizedBox(height: 8),
              Text(
                'Nếu địa chỉ hotspot đổi, chọn URL mới, cập nhật Custom OTA URL trên ESP rồi khởi động lại ESP. Chỉ kết nối ESP vào hotspot riêng; luồng hiện tại không mã hóa HTTP/WebSocket.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({required this.voice});
  final VoiceService voice;

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  final _prompt = TextEditingController();
  String _language = 'vi';
  double _temperature = 0.7;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _prompt.text = prefs.getString('system_prompt') ?? '';
      _language = prefs.getString('response_language') ?? 'vi';
      _temperature = prefs.getDouble('temperature') ?? 0.7;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('system_prompt', _prompt.text.trim());
    await prefs.setString('response_language', _language);
    await prefs.setDouble('temperature', _temperature);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã lưu tuỳ chỉnh AI')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _InfoCard(
          icon: Icons.tune,
          title: 'Ngữ cảnh và giọng nói',
          subtitle: 'Ngôn ngữ/ngữ cảnh áp dụng cho model local. Chọn voice Android TTS có nhãn offline để giọng đọc không cần Internet.',
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ngôn ngữ trả lời',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _language,
                items: const [
                  DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(
                    value: 'auto',
                    child: Text('Theo ngôn ngữ người hỏi'),
                  ),
                ],
                onChanged: (value) => setState(() => _language = value ?? 'vi'),
              ),
              const SizedBox(height: 16),
              Text(
                'Ngữ cảnh / chỉ dẫn cho AI',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _prompt,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: Bạn là trợ lý trong gia đình, ưu tiên câu trả lời ngắn…',
                ),
              ),
              const SizedBox(height: 12),
              Text('Độ sáng tạo: ${_temperature.toStringAsFixed(1)}'),
              Slider(
                value: _temperature,
                min: 0.1,
                max: 1.2,
                divisions: 11,
                label: _temperature.toStringAsFixed(1),
                onChanged: (value) => setState(() => _temperature = value),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('Lưu thiết lập'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giọng đọc trên ESP',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (widget.voice.voices.isEmpty)
                const Text(
                  'Android chưa trả về danh sách giọng. Kiểm tra Text-to-Speech engine trong cài đặt hệ thống.',
                )
              else
                DropdownButtonFormField<String>(
                  initialValue:
                      widget.voice.voices.any(
                        (voice) =>
                            voice['name'] == widget.voice.selectedVoiceName,
                      )
                      ? widget.voice.selectedVoiceName
                      : widget.voice.voices.first['name'],
                  isExpanded: true,
                  items: widget.voice.voices
                      .map(
                        (voice) => DropdownMenuItem(
                          value: voice['name'],
                          child: Text(
                            '${voice['name']} (${voice['locale']}) · ${voice['network_required'] == '0' ? 'offline' : 'cần mạng'}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (name) {
                    final chosen = widget.voice.voices
                        .where((voice) => voice['name'] == name)
                        .firstOrNull;
                    if (chosen != null) {
                      setState(
                        () => unawaited(widget.voice.selectVoice(chosen)),
                      );
                    }
                  },
                ),
              const SizedBox(height: 12),
              Text('Tốc độ: ${widget.voice.speechRate.toStringAsFixed(2)}'),
              Slider(
                value: widget.voice.speechRate,
                min: 0.25,
                max: 0.75,
                onChanged: (value) =>
                    setState(() => widget.voice.setRate(value)),
              ),
              Text('Cao độ: ${widget.voice.pitch.toStringAsFixed(2)}'),
              Slider(
                value: widget.voice.pitch,
                min: 0.7,
                max: 1.4,
                onChanged: (value) =>
                    setState(() => widget.voice.setPitch(value)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatLine {
  const _ChatLine(this.role, this.text);
  final String role;
  final String text;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.line});
  final _ChatLine line;

  @override
  Widget build(BuildContext context) {
    final user = line.role == 'user';
    final system = line.role == 'system';
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: system
              ? Colors.amber.shade100
              : user
              ? const Color(0xffd8eee8)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(line.text),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: active ? const Color(0xffd9eee5) : Colors.black12,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: active ? const Color(0xff07594e) : Colors.black54,
      ),
    ),
  );
}

class _ReadinessRow extends StatelessWidget {
  const _ReadinessRow({required this.label, required this.ready});
  final String label;
  final bool ready;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(
          ready ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: ready ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => _Card(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 25, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.black.withAlpha(12)),
    ),
    child: child,
  );
}
