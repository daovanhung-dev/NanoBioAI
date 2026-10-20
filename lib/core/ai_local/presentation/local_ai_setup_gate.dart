import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../core/theme/theme.dart';
import '../local_ai_model_catalog.dart';
import '../local_ai_runtime_service.dart';

class LocalAiSetupGate extends StatefulWidget {
  const LocalAiSetupGate({super.key, required this.child});

  final Widget child;

  @override
  State<LocalAiSetupGate> createState() => _LocalAiSetupGateState();
}

class _LocalAiSetupGateState extends State<LocalAiSetupGate> {
  bool _checking = true;
  String? _selectedModelId;
  String? _startupMessage;

  @override
  void initState() {
    super.initState();
    _prepareSelectedModel();
  }

  Future<void> _prepareSelectedModel() async {
    try {
      final runtime = LocalAiRuntimeService.instance;
      final modelId = await runtime.selectedModelId();
      if (!mounted) return;
      if (modelId == null) {
        setState(() {
          _checking = false;
          _selectedModelId = localAiDefaultModelId;
        });
        return;
      }

      final ready = await runtime.loadSelectedTextModel();
      if (!mounted) return;
      setState(() {
        _checking = false;
        _selectedModelId = modelId;
        if (!ready) {
          _startupMessage =
              'Nabi chưa mở được model đã chọn. Bạn có thể tải lại hoặc chọn model khác.';
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _checking = false;
          _selectedModelId = localAiDefaultModelId;
          _startupMessage =
              'Nabi chưa kiểm tra được model đã lưu. Hãy chọn model và tải lại để tiếp tục.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return widget.child;
    if (!_checking && LocalAiRuntimeService.instance.loadedModelId != null) {
      return widget.child;
    }
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: _checking
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : LocalAiModelSetupPage(
              initialModelId: _selectedModelId ?? localAiDefaultModelId,
              startupMessage: _startupMessage,
              onInstalled: () => setState(() => _checking = false),
            ),
    );
  }
}

class LocalAiModelSetupPage extends StatefulWidget {
  const LocalAiModelSetupPage({
    super.key,
    required this.initialModelId,
    required this.onInstalled,
    this.startupMessage,
  });

  final String initialModelId;
  final String? startupMessage;
  final VoidCallback onInstalled;

  @override
  State<LocalAiModelSetupPage> createState() => _LocalAiModelSetupPageState();
}

class _LocalAiModelSetupPageState extends State<LocalAiModelSetupPage> {
  late String _selectedModelId = widget.initialModelId;
  bool _working = false;
  String? _errorMessage;

  Future<void> _downloadAndContinue() async {
    setState(() {
      _working = true;
      _errorMessage = null;
    });
    try {
      await LocalAiRuntimeService.instance.installAndSelectTextModel(
        _selectedModelId,
      );
      if (mounted) widget.onInstalled();
    } on LocalAiDownloadCancelledException {
      if (mounted) {
        setState(
          () =>
              _errorMessage = 'Tải model đã dừng. Bạn có thể tiếp tục tải sau.',
        );
      }
    } on LocalAiInsufficientStorageException {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Thiết bị không đủ dung lượng cho model này. Hãy giải phóng bộ nhớ rồi thử lại.',
        );
      }
    } on LocalAiDownloadFailedException {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Chưa tải xong model. Kiểm tra kết nối rồi tiếp tục tải lại.',
        );
      }
    } on LocalAiModelIntegrityException {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Tệp model không khớp SHA-256. Hãy thử tải model lại.',
        );
      }
    } on LocalAiModelLoadException {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Thiết bị chưa mở được model này. Hãy chọn model nhẹ hơn hoặc kiểm tra RAM còn trống.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage =
              'Chưa tải hoặc mở được model. Kiểm tra kết nối và dung lượng trống rồi thử lại nhé.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _cancelDownload() async {
    await LocalAiRuntimeService.instance.cancelDownload(_selectedModelId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final runtimeProgress = LocalAiRuntimeService.instance.progress;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.smart_toy_outlined,
                        color: colors.primary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Chuẩn bị Nabi trên thiết bị',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Chọn một model để Nabi xử lý AI ngay trên thiết bị. Model chỉ tải một lần; sau khi cài đặt, các câu hỏi không cần API key.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    RadioGroup<String>(
                      groupValue: _selectedModelId,
                      onChanged: (value) {
                        if (!_working && value != null) {
                          setState(() => _selectedModelId = value);
                        }
                      },
                      child: Column(
                        children: [
                          for (final model in localAiTextModels)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: Card(
                                clipBehavior: Clip.antiAlias,
                                child: RadioListTile<String>(
                                  value: model.id,
                                  title: Text(model.name),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSpacing.xs,
                                    ),
                                    child: Text(
                                      '${model.description}\n${model.formattedSize} tải xuống • RAM khuyến nghị ${model.formattedRecommendedRam}',
                                      style: AppTextStyles.bodySmall.copyWith(
                                        height: 1.45,
                                        color: colors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.xs,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (widget.startupMessage != null || _errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          _errorMessage ?? widget.startupMessage!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.warning,
                          ),
                        ),
                      ),
                    if (_working)
                      ValueListenableBuilder<LocalAiRuntimeProgress?>(
                        valueListenable: runtimeProgress,
                        builder: (context, value, _) {
                          final fraction = value?.fraction;
                          final percent = fraction == null
                              ? null
                              : (fraction.clamp(0, 1) * 100).round();
                          return Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.md,
                              bottom: AppSpacing.sm,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(switch (value?.stage) {
                                  LocalAiRuntimeStage.loading =>
                                    'Nabi đang mở model…',
                                  LocalAiRuntimeStage.warming =>
                                    'Nabi đang chuẩn bị model…',
                                  _ =>
                                    percent == null
                                        ? 'Đang tải model…'
                                        : 'Đang tải model… $percent%',
                                }, style: AppTextStyles.bodySmall),
                                const SizedBox(height: AppSpacing.sm),
                                LinearProgressIndicator(value: fraction),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: _working ? null : _downloadAndContinue,
                      icon: _working
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      label: Text(
                        _working ? 'Đang chuẩn bị…' : 'Tải model và tiếp tục',
                      ),
                    ),
                    if (_working)
                      TextButton(
                        onPressed: _cancelDownload,
                        child: const Text('Dừng tải'),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Model được tải từ Hugging Face và dùng để suy luận trên thiết bị. Tốc độ phản hồi phụ thuộc vào model và cấu hình máy.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
