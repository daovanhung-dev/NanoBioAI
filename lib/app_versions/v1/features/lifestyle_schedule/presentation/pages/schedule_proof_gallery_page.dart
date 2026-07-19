import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/design_system.dart';
import 'package:nano_app/core/theme/medical_ui.dart';
import 'package:nano_app/shared/widgets/vietnamese_ui_text.dart';

import '../../application/schedule_proof_image_service.dart';
import '../../application/schedule_reward_online_gateway.dart';
import '../../domain/entities/schedule_completion_proof_entity.dart';
import '../../providers/lifestyle_schedule_provider.dart';

class ScheduleProofPreviewSection extends ConsumerWidget {
  final List<ScheduleCompletionProofEntity> proofs;

  const ScheduleProofPreviewSection({super.key, required this.proofs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (proofs.isEmpty) return const SizedBox.shrink();
    final preview = proofs.take(3).toList(growable: false);
    final service = ref.watch(scheduleProofImageServiceProvider);
    final rewardGateway = ref.watch(scheduleRewardOnlineGatewayProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Bằng chứng nhiệm vụ', style: AppTextStyles.heading2),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ScheduleProofGalleryPage(proofs: proofs),
                ),
              ),
              child: const Text('Xem tất cả'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacingTokens.itemSpacing),
        Text(
          'Ảnh được lưu riêng trong ứng dụng để bạn có thể xem lại.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
        SizedBox(
          height: 188,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: preview.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacingTokens.itemSpacingLarge),
            itemBuilder: (context, index) {
              final proof = preview[index];
              return SizedBox(
                width: 164,
                child: _ProofCard(
                  proof: proof,
                  service: service,
                  rewardGateway: rewardGateway,
                  compact: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ScheduleProofGalleryPage extends ConsumerWidget {
  final List<ScheduleCompletionProofEntity> proofs;

  const ScheduleProofGalleryPage({super.key, required this.proofs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(scheduleProofImageServiceProvider);
    final rewardGateway = ref.watch(scheduleRewardOnlineGatewayProvider);
    return MedicalPageScaffold(
      appBar: AppBar(title: const Text('Bằng chứng nhiệm vụ')),
      body: proofs.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacingTokens.pagePadding),
                child: Text('Bạn chưa có ảnh minh chứng nào.'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacingTokens.pagePadding),
              itemCount: proofs.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacingTokens.itemSpacingLarge),
              itemBuilder: (context, index) => _ProofCard(
                proof: proofs[index],
                service: service,
                rewardGateway: rewardGateway,
              ),
            ),
    );
  }
}

class _ProofCard extends StatelessWidget {
  final ScheduleCompletionProofEntity proof;
  final ScheduleProofImageService service;
  final ScheduleRewardOnlineGateway rewardGateway;
  final bool compact;

  const _ProofCard({
    required this.proof,
    required this.service,
    required this.rewardGateway,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openProof(context),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ProofImage(proof: proof, service: service),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(
                      AppSpacingTokens.itemSpacingLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _proofTitle(proof),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium,
                        ),
                        const SizedBox(height: AppSpacingTokens.itemSpacing),
                        Text(
                          _proofStatusLabel(proof),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: _ProofImage(proof: proof, service: service),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        AppSpacingTokens.cardPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _proofTitle(proof),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge,
                          ),
                          const SizedBox(height: AppSpacingTokens.itemSpacing),
                          Text(
                            '${_formatDate(proof.scheduleDate)} • ${_formatTime(proof.startTime)}',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacingTokens.itemSpacing),
                          Text(
                            _proofStatusLabel(proof),
                            style: AppTextStyles.caption.copyWith(
                              color: proof.isReversed
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _openProof(BuildContext context) async {
    final file = await service.resolveProofFile(proof.localPath);
    if (!context.mounted) return;
    if (!await file.exists()) {
      final cloudPath = proof.cloudObjectPath;
      if (cloudPath == null || cloudPath.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ảnh minh chứng không còn trên thiết bị này.'),
          ),
        );
        return;
      }
      try {
        final bytes = await rewardGateway.downloadProof(cloudPath);
        await service.restoreProofFromCloud(proof.localPath, bytes);
      } on ScheduleRewardException catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              vietnameseSystemUiText(
                error.message,
                fallback:
                    'Nabi chưa thể tải lại ảnh minh chứng lúc này. Bạn thử lại sau nhé.',
              ),
            ),
          ),
        );
        return;
      } on ScheduleProofException catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              vietnameseSystemUiText(
                error.message,
                fallback:
                    'Nabi chưa thể tải lại ảnh minh chứng lúc này. Bạn thử lại sau nhé.',
              ),
            ),
          ),
        );
        return;
      }
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ScheduleProofViewerPage(file: file, proof: proof),
      ),
    );
  }
}

class _ProofImage extends StatelessWidget {
  final ScheduleCompletionProofEntity proof;
  final ScheduleProofImageService service;

  const _ProofImage({required this.proof, required this.service});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: service.resolveProofFile(proof.localPath),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return const ColoredBox(
            color: Color(0xFFE8F1EF),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, existsSnapshot) {
            if (existsSnapshot.data != true) {
              return ColoredBox(
                color: Color(0xFFE8F1EF),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacingTokens.itemSpacing),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_download_outlined),
                        if (proof.cloudObjectPath != null) ...[
                          const SizedBox(height: AppSpacingTokens.itemSpacing),
                          Text(
                            'Chạm để tải lại ảnh',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFE8F1EF),
                child: Center(child: Icon(Icons.image_not_supported_outlined)),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScheduleProofViewerPage extends StatelessWidget {
  final File file;
  final ScheduleCompletionProofEntity proof;

  const _ScheduleProofViewerPage({required this.file, required this.proof});

  @override
  Widget build(BuildContext context) {
    return MedicalPageScaffold(
      ambientBackground: false,
      backgroundColor: Colors.black,
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.black,
        title: Text(_proofTitle(proof)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: Image.file(file, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

String _proofStatusLabel(ScheduleCompletionProofEntity proof) {
  if (proof.isReversed) return 'Đã hoàn tác';
  return switch (proof.rewardStatus) {
    ScheduleProofRewardStatuses.pending => 'Đang chờ xác nhận điểm',
    ScheduleProofRewardStatuses.confirmed => 'Đã xác nhận điểm',
    ScheduleProofRewardStatuses.legacyNonRedeemable =>
      'Bằng chứng cũ • không đổi điểm',
    _ => 'Đã lưu trên thiết bị',
  };
}

String _proofTitle(ScheduleCompletionProofEntity proof) {
  return vietnameseSystemUiText(
    proof.scheduleTitle,
    fallback: 'Nhiệm vụ chăm sóc sức khỏe',
  );
}

String _formatDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return 'Chưa xác định';
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatTime(String value) {
  final match = RegExp(r'^(\d{2}):(\d{2})').firstMatch(value.trim());
  if (match == null) return '--:--';
  final hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || hour > 23 || minute == null || minute > 59) {
    return '--:--';
  }
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}
