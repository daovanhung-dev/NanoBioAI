import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/app_versions/v3/router/v3_route_paths.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/membership/presentation/membership_upgrade_navigation.dart';

import '../../domain/entities/food_scan_models.dart';
import '../../providers/food_scan_providers.dart';

class FoodScanHistoryPage extends ConsumerWidget {
  const FoodScanHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(foodScanAccessProvider);
    return access.when(
      loading: () => const MedicalPageScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => MedicalScrollPage(
        title: 'Lịch sử Food Scan',
        subtitle: 'Nabi chưa tải được quyền sử dụng.',
        icon: Icons.history_rounded,
        children: [
          MedicalEmptyState(
            icon: Icons.refresh_rounded,
            title: 'Chưa tải được dữ liệu',
            message: 'Bạn thử lại nhé.',
            action: FilledButton(
              onPressed: () => ref.invalidate(foodScanAccessProvider),
              child: const Text('Thử lại'),
            ),
          ),
        ],
      ),
      data: (value) {
        if (value.status == FoodScanAccessStatus.authRequired) {
          return _LockedHistory(
            title: 'Cần đăng nhập',
            message: 'Đăng nhập để xem lịch sử Food Scan trên thiết bị này.',
            label: 'Đăng nhập',
            onPressed: () => context.push(V2RoutePaths.login),
          );
        }
        if (value.status == FoodScanAccessStatus.plusRequired) {
          return _LockedHistory(
            title: 'Dành riêng cho Plus',
            message: 'Lịch sử phân tích món ăn là một phần của Food Scan Plus.',
            label: membershipUpgradeActionLabel(MembershipUpgradePlan.plus),
            onPressed: () => openMembershipUpgrade(
              context,
              planCode: MembershipUpgradePlan.plus,
            ),
          );
        }
        return _HistoryBody(userId: value.userId!);
      },
    );
  }
}

class _LockedHistory extends StatelessWidget {
  final String title;
  final String message;
  final String label;
  final VoidCallback onPressed;

  const _LockedHistory({
    required this.title,
    required this.message,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalScrollPage(
      eyebrow: 'FOOD SCAN',
      title: title,
      subtitle: message,
      icon: Icons.history_rounded,
      children: [
        MedicalEmptyState(
          icon: Icons.lock_outline_rounded,
          title: title,
          message: message,
          action: FilledButton(onPressed: onPressed, child: Text(label)),
        ),
      ],
    );
  }
}

class _HistoryBody extends ConsumerWidget {
  final String userId;

  const _HistoryBody({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(foodScanHistoryProvider(userId));
    return MedicalScrollPage(
      eyebrow: 'LƯU TRÊN THIẾT BỊ',
      title: 'Lịch sử Food Scan',
      subtitle:
          'Ảnh và phân tích chi tiết chỉ ở trên thiết bị này, tách riêng theo tài khoản.',
      icon: Icons.history_rounded,
      gradient: AppGradients.primary,
      children: [
        history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => MedicalEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Chưa mở được lịch sử',
            message: 'Bạn thử làm mới nhé.',
            action: FilledButton(
              onPressed: () => ref.invalidate(foodScanHistoryProvider(userId)),
              child: const Text('Thử lại'),
            ),
          ),
          data: (items) => items.isEmpty
              ? MedicalEmptyState(
                  icon: Icons.no_food_rounded,
                  title: 'Chưa có lần quét nào',
                  message: 'Ảnh bạn phân tích sẽ xuất hiện ở đây.',
                  action: FilledButton.icon(
                    onPressed: () => context.go(V3RoutePaths.foodScan),
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: const Text('Quét món ăn'),
                  ),
                )
              : Column(
                  children: [
                    for (final item in items) ...[
                      _HistoryCard(
                        result: item,
                        onOpen: () {
                          ref
                              .read(foodScanControllerProvider.notifier)
                              .loadHistoryResult(item);
                          context.go(V3RoutePaths.foodScan);
                        },
                        onDelete: () => _delete(context, ref, item),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FoodScanResult result,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa lịch sử quét?'),
        content: const Text(
          'Ảnh và bản phân tích local sẽ bị xóa. Nhật ký dinh dưỡng đã xác nhận trước đó vẫn được giữ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(foodScanServiceProvider).deleteHistory(
          userId: userId,
          result: result,
        );
    ref.invalidate(foodScanHistoryProvider(userId));
  }
}

class _HistoryCard extends StatelessWidget {
  final FoodScanResult result;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.result,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(result.imageLocalPath);
    final colors = context.semanticColors;
    return MedicalSurfaceCard(
      onTap: onOpen,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 88,
              height: 88,
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : ColoredBox(
                      color: colors.surfaceSoft,
                      child: Icon(Icons.image_not_supported_outlined, color: colors.textMuted),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.displayedCalories} kcal',
                  style: AppTextStyles.heading4,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  result.items.map((item) => item.name).take(4).join(' + '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatDate(result.createdAt),
                  style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
                ),
                if (result.nutritionLogId != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const MedicalStatusPill(
                    label: 'Đã ghi dinh dưỡng',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Xóa lịch sử',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')} • '
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
