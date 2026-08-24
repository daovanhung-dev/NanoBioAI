import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/providers/nutrition_provider.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/app_versions/v3/router/v3_route_paths.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/membership/presentation/membership_upgrade_navigation.dart';

import '../../domain/entities/food_scan_models.dart';
import '../../providers/food_scan_providers.dart';

class FoodScanPage extends ConsumerWidget {
  const FoodScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(foodScanAccessProvider);
    return access.when(
      loading: () => const MedicalPageScaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => MedicalScrollPage(
        eyebrow: 'FOOD SCAN',
        title: 'Nabi chưa xác nhận được quyền',
        subtitle: 'Bạn thử lại sau một chút nhé.',
        icon: Icons.error_outline_rounded,
        children: [
          MedicalEmptyState(
            icon: Icons.refresh_rounded,
            title: 'Không tải được quyền sử dụng',
            message: 'Kết nối hoặc phiên đăng nhập có thể chưa sẵn sàng.',
            action: FilledButton(
              onPressed: () => ref.invalidate(foodScanAccessProvider),
              child: const Text('Thử lại'),
            ),
          ),
        ],
      ),
      data: (value) => switch (value.status) {
        FoodScanAccessStatus.authRequired => _AccessRequired(
          icon: Icons.lock_outline_rounded,
          title: 'Cần đăng nhập',
          message: 'Quét món ăn cần tài khoản NanoBio để lưu nhật ký dinh dưỡng.',
          actionLabel: 'Đăng nhập',
          onAction: () => context.push(V2RoutePaths.login),
        ),
        FoodScanAccessStatus.plusRequired => _AccessRequired(
          icon: Icons.workspace_premium_rounded,
          title: 'Dành riêng cho Plus',
          message:
              'Food Scan phân tích ảnh, dinh dưỡng và mức độ phù hợp với sức khỏe không giới hạn cho tài khoản Plus.',
          actionLabel: membershipUpgradeActionLabel(MembershipUpgradePlan.plus),
          onAction: () => openMembershipUpgrade(
            context,
            planCode: MembershipUpgradePlan.plus,
          ),
        ),
        FoodScanAccessStatus.allowed => _FoodScanWorkbench(userId: value.userId!),
      },
    );
  }
}

class _AccessRequired extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _AccessRequired({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalScrollPage(
      eyebrow: 'FOOD SCAN',
      title: title,
      subtitle: message,
      icon: icon,
      gradient: AppGradients.premium,
      children: [
        MedicalEmptyState(
          icon: icon,
          title: title,
          message: message,
          action: FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ),
      ],
    );
  }
}

class _FoodScanWorkbench extends ConsumerWidget {
  final String userId;

  const _FoodScanWorkbench({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foodScanControllerProvider);
    final consent = ref.watch(foodScanConsentProvider(userId));
    final colors = context.semanticColors;

    return MedicalScrollPage(
      eyebrow: 'PLUS • KHÔNG GIỚI HẠN',
      title: 'Quét món ăn cùng Nabi',
      subtitle:
          'Chụp món ăn để ước tính calo, dưỡng chất và xem mức độ phù hợp với hồ sơ sức khỏe của bạn.',
      icon: Icons.document_scanner_rounded,
      gradient: AppGradients.premium,
      actions: [
        OutlinedButton.icon(
          onPressed: state.busy
              ? null
              : () => context.push(V3RoutePaths.foodScanHistory),
          icon: const Icon(Icons.history_rounded),
          label: const Text('Lịch sử'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onBrand,
            side: BorderSide(color: colors.onBrand.withValues(alpha: .5)),
          ),
        ),
      ],
      children: [
        consent.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ConsentCard(
            onAccept: () async {
              await ref.read(foodScanGrantConsentProvider)(userId);
            },
          ),
          data: (accepted) => accepted
              ? _SourceCard(userId: userId, state: state)
              : _ConsentCard(
                  onAccept: () async {
                    await ref.read(foodScanGrantConsentProvider)(userId);
                  },
                ),
        ),
        if (state.imagePath != null) _ImagePreview(userId: userId, state: state),
        if (state.busy) _AnalysisProgress(phase: state.phase),
        if (state.errorMessage != null)
          _MessageCard(
            icon: Icons.info_outline_rounded,
            title: 'Nabi cần bạn kiểm tra lại',
            message: state.errorMessage!,
            color: colors.warning,
          ),
        if (state.result != null)
          _FoodScanResultView(
            userId: userId,
            state: state,
          ),
        MedicalSurfaceCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.privacy_tip_outlined, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Ảnh và lịch sử quét được giữ trên thiết bị. Trước khi gửi ảnh tới AI, Nabi mã hóa lại ảnh JPEG để loại metadata EXIF/GPS. Kết quả là ước tính, không thay thế bác sĩ hoặc chuyên gia dinh dưỡng.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConsentCard extends StatelessWidget {
  final Future<void> Function() onAccept;

  const _ConsentCard({required this.onAccept});

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Phân tích món ăn bằng AI', style: AppTextStyles.heading4),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nabi sẽ gửi ảnh món ăn bạn chọn tới dịch vụ AI để nhận diện thực phẩm và ước tính dinh dưỡng. Để cá nhân hóa đánh giá, Nabi cũng gửi phần hồ sơ sức khỏe liên quan như bệnh đã khai báo, dị ứng, thuốc/điều trị, chỉ số sức khỏe và mục tiêu dinh dưỡng; không gửi email, số điện thoại, token hay khóa API. Ảnh được loại metadata vị trí trước khi gửi. Kết quả có thể sai lệch vì ảnh không cho biết chính xác khối lượng, dầu, đường, sốt hoặc nguyên liệu bị che.',
            style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: () async => onAccept(),
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Đồng ý và tiếp tục'),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends ConsumerWidget {
  final String userId;
  final FoodScanState state;

  const _SourceCard({required this.userId, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(foodScanControllerProvider.notifier);
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Thêm ảnh món ăn', style: AppTextStyles.heading4),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Đặt toàn bộ phần ăn trong khung hình, đủ sáng và hạn chế vật che món.',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.semanticColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 480;
              final camera = FilledButton.icon(
                onPressed: state.busy
                    ? null
                    : () => controller.pickCamera(userId),
                icon: const Icon(Icons.photo_camera_rounded),
                label: const Text('Chụp ảnh'),
              );
              final gallery = OutlinedButton.icon(
                onPressed: state.busy
                    ? null
                    : () => controller.pickGallery(userId),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Thư viện'),
              );
              return compact
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        camera,
                        const SizedBox(height: AppSpacing.sm),
                        gallery,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: camera),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: gallery),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class _ImagePreview extends ConsumerWidget {
  final String userId;
  final FoodScanState state;

  const _ImagePreview({required this.userId, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePath = state.imagePath!;
    final file = File(imagePath);
    final controller = ref.read(foodScanControllerProvider.notifier);
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: file.existsSync()
                  ? Image.file(file, fit: BoxFit.cover)
                  : Container(
                      alignment: Alignment.center,
                      color: context.semanticColors.surfaceSoft,
                      child: const Text('Ảnh không còn trên thiết bị'),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.result == null)
            FilledButton.icon(
              onPressed: state.busy
                  ? null
                  : () => controller.analyze(userId),
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Phân tích món ăn'),
            ),
        ],
      ),
    );
  }
}

class _AnalysisProgress extends StatelessWidget {
  final FoodScanPhase phase;

  const _AnalysisProgress({required this.phase});

  @override
  Widget build(BuildContext context) {
    final label = switch (phase) {
      FoodScanPhase.selectingImage => 'Nabi đang chuẩn bị ảnh…',
      FoodScanPhase.analyzingVision => 'Nabi đang nhận diện món ăn…',
      FoodScanPhase.resolvingNutrition => 'Nabi đang tính dưỡng chất…',
      FoodScanPhase.evaluatingHealth => 'Nabi đang đối chiếu hồ sơ sức khỏe…',
      FoodScanPhase.saving => 'Nabi đang lưu bữa ăn và đồng bộ…',
      _ => 'Nabi đang xử lý…',
    };
    return MedicalSurfaceCard(
      child: Row(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}

class _FoodScanResultView extends ConsumerWidget {
  final String userId;
  final FoodScanState state;

  const _FoodScanResultView({required this.userId, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = state.result!;
    final colors = context.semanticColors;
    final controller = ref.read(foodScanControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MedicalSurfaceCard(
          gradient: LinearGradient(
            colors: [colors.primarySoft, colors.card],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Ước tính bữa ăn', style: AppTextStyles.heading4),
                  ),
                  MedicalStatusPill(
                    label: result.inputType,
                    icon: Icons.restaurant_rounded,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '${result.displayedCalories} kcal',
                style: AppTextStyles.heading1.copyWith(
                  color: colors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Một con số ước tính từ ảnh • ${result.items.length} thành phần được nhận diện',
                style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
              ),
              if (result.analysisConfidence < .65) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Nabi chưa chắc chắn về một số thành phần. Bạn nên chỉnh tên món hoặc khối lượng trước khi lưu.',
                  style: AppTextStyles.bodySmall.copyWith(color: colors.warning),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final item in result.items) ...[
          _FoodItemCard(
            item: item,
            onEdit: () => _editItem(context, ref, userId, item),
            onDelete: result.items.length <= 1 || state.busy
                ? null
                : () => controller.removeItem(userId: userId, itemId: item.id),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _NutritionCard(nutrition: result.totalNutrition),
        const SizedBox(height: AppSpacing.md),
        _HealthCard(
          health: result.healthEvaluation,
          needsRefresh: state.healthNeedsRefresh,
          onRefresh: state.busy
              ? null
              : () => controller.reevaluateHealth(userId),
        ),
        if (result.healthEvaluation.dailyGoalSummary.isNotEmpty ||
            result.healthEvaluation.dailyGoalNotes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _DailyGoalCard(health: result.healthEvaluation),
        ],
        if (result.healthEvaluation.allergyWarnings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _WarningList(
            title: 'Cảnh báo dị ứng / hạn chế',
            warnings: result.healthEvaluation.allergyWarnings,
            color: colors.error,
          ),
        ],
        if (result.healthEvaluation.suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _WarningList(
            title: 'Gợi ý điều chỉnh',
            warnings: result.healthEvaluation.suggestions,
            color: colors.success,
          ),
        ],
        if (result.assumptions.isNotEmpty || result.warnings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _WarningList(
            title: 'Giả định & lưu ý',
            warnings: [...result.warnings, ...result.assumptions],
            color: colors.warning,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        MedicalSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (result.nutritionLogId != null)
                const MedicalStatusPill(
                  label: 'Đã ghi vào dinh dưỡng hôm nay',
                  icon: Icons.cloud_done_rounded,
                )
              else
                FilledButton.icon(
                  onPressed: state.busy
                      ? null
                      : () async {
                          final saved = await controller.confirmConsumed(userId);
                          if (saved == null) return;
                          ref.invalidate(nutritionSummaryProvider);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Đã ghi bữa ăn. Nabi đang đồng bộ dữ liệu dinh dưỡng với Supabase.',
                              ),
                            ),
                          );
                        },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Xác nhận đã ăn'),
                ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Xác nhận sẽ cộng calo/protein/carb/chất béo vào nhật ký dinh dưỡng. Nếu mất mạng, dữ liệu vẫn lưu local và Outbox sẽ thử đồng bộ lại.',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editItem(
    BuildContext context,
    WidgetRef ref,
    String userId,
    FoodScanItem item,
  ) async {
    final name = TextEditingController(text: item.name);
    final grams = TextEditingController(
      text: item.confirmedWeightGrams.toStringAsFixed(0),
    );
    final portion = TextEditingController(text: item.portionDescription);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chỉnh món ăn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Tên món'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: grams,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Khối lượng',
                  suffixText: 'g',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: portion,
                decoration: const InputDecoration(labelText: 'Mô tả khẩu phần'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    final weight = double.tryParse(grams.text.trim().replaceAll(',', '.'));
    if (weight == null || weight <= 0 || weight > 5000) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khối lượng cần nằm trong khoảng 1–5000 g.')),
      );
      return;
    }
    await ref.read(foodScanControllerProvider.notifier).updateItem(
          userId: userId,
          itemId: item.id,
          name: name.text,
          weightGrams: weight,
          portionDescription: portion.text.trim(),
        );
    if (!context.mounted) return;
    await ref.read(foodScanControllerProvider.notifier).reevaluateHealth(userId);
  }
}

class _FoodItemCard extends StatelessWidget {
  final FoodScanItem item;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _FoodItemCard({
    required this.item,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: AppTextStyles.heading4),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${item.confirmedWeightGrams.toStringAsFixed(0)} g'
                      '${item.portionDescription.isEmpty ? '' : ' • ${item.portionDescription}'}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              MedicalStatusPill(
                label: item.nutritionSource == 'internal_catalog'
                    ? 'Dữ liệu nội bộ'
                    : 'AI ước tính',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              Text('${item.nutrition.caloriesKcal.round()} kcal'),
              Text('P ${item.nutrition.proteinG.toStringAsFixed(1)}g'),
              Text('C ${item.nutrition.carbohydratesG.toStringAsFixed(1)}g'),
              Text('F ${item.nutrition.fatG.toStringAsFixed(1)}g'),
            ],
          ),
          if (item.ingredients.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Nguyên liệu khả kiến: ${item.ingredients.join(', ')}',
              style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Chỉnh sửa'),
              ),
              const Spacer(),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Xóa món nhận diện sai',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final NutritionEstimate nutrition;

  const _NutritionCard({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Năng lượng', '${nutrition.caloriesKcal.round()} kcal'),
      ('Protein', '${nutrition.proteinG.toStringAsFixed(1)} g'),
      ('Carbohydrate', '${nutrition.carbohydratesG.toStringAsFixed(1)} g'),
      ('Chất béo', '${nutrition.fatG.toStringAsFixed(1)} g'),
      if (nutrition.fiberG != null) ('Chất xơ', '${nutrition.fiberG!.toStringAsFixed(1)} g'),
      if (nutrition.sugarG != null) ('Đường', '${nutrition.sugarG!.toStringAsFixed(1)} g'),
      if (nutrition.sodiumMg != null) ('Natri', '${nutrition.sodiumMg!.round()} mg'),
      if (nutrition.saturatedFatG != null)
        ('Chất béo bão hòa', '${nutrition.saturatedFatG!.toStringAsFixed(1)} g'),
      if (nutrition.monounsaturatedFatG != null)
        ('Chất béo không bão hòa đơn', '${nutrition.monounsaturatedFatG!.toStringAsFixed(1)} g'),
      if (nutrition.polyunsaturatedFatG != null)
        ('Chất béo không bão hòa đa', '${nutrition.polyunsaturatedFatG!.toStringAsFixed(1)} g'),
      if (nutrition.transFatG != null) ('Trans fat', '${nutrition.transFatG!.toStringAsFixed(1)} g'),
      if (nutrition.cholesterolMg != null) ('Cholesterol', '${nutrition.cholesterolMg!.round()} mg'),
      if (nutrition.potassiumMg != null) ('Kali', '${nutrition.potassiumMg!.round()} mg'),
      if (nutrition.calciumMg != null) ('Canxi', '${nutrition.calciumMg!.round()} mg'),
      if (nutrition.ironMg != null) ('Sắt', '${nutrition.ironMg!.toStringAsFixed(1)} mg'),
      if (nutrition.magnesiumMg != null) ('Magie', '${nutrition.magnesiumMg!.round()} mg'),
      if (nutrition.phosphorusMg != null) ('Phốt pho', '${nutrition.phosphorusMg!.round()} mg'),
      if (nutrition.zincMg != null) ('Kẽm', '${nutrition.zincMg!.toStringAsFixed(1)} mg'),
      if (nutrition.copperMg != null) ('Đồng', '${nutrition.copperMg!.toStringAsFixed(1)} mg'),
      if (nutrition.manganeseMg != null) ('Mangan', '${nutrition.manganeseMg!.toStringAsFixed(1)} mg'),
      if (nutrition.seleniumMcg != null) ('Selen', '${nutrition.seleniumMcg!.toStringAsFixed(1)} µg'),
      if (nutrition.vitaminAMcgRae != null) ('Vitamin A', '${nutrition.vitaminAMcgRae!.round()} µg RAE'),
      if (nutrition.vitaminCMg != null) ('Vitamin C', '${nutrition.vitaminCMg!.toStringAsFixed(1)} mg'),
      if (nutrition.vitaminDMcg != null) ('Vitamin D', '${nutrition.vitaminDMcg!.toStringAsFixed(1)} µg'),
      if (nutrition.vitaminEMg != null) ('Vitamin E', '${nutrition.vitaminEMg!.toStringAsFixed(1)} mg'),
      if (nutrition.vitaminKMcg != null) ('Vitamin K', '${nutrition.vitaminKMcg!.toStringAsFixed(1)} µg'),
      if (nutrition.vitaminB1Mg != null) ('Vitamin B1', '${nutrition.vitaminB1Mg!.toStringAsFixed(2)} mg'),
      if (nutrition.vitaminB2Mg != null) ('Vitamin B2', '${nutrition.vitaminB2Mg!.toStringAsFixed(2)} mg'),
      if (nutrition.vitaminB3Mg != null) ('Vitamin B3', '${nutrition.vitaminB3Mg!.toStringAsFixed(1)} mg'),
      if (nutrition.vitaminB5Mg != null) ('Vitamin B5', '${nutrition.vitaminB5Mg!.toStringAsFixed(1)} mg'),
      if (nutrition.vitaminB6Mg != null) ('Vitamin B6', '${nutrition.vitaminB6Mg!.toStringAsFixed(2)} mg'),
      if (nutrition.biotinB7Mcg != null) ('Vitamin B7', '${nutrition.biotinB7Mcg!.toStringAsFixed(1)} µg'),
      if (nutrition.folateB9Mcg != null) ('Vitamin B9', '${nutrition.folateB9Mcg!.round()} µg'),
      if (nutrition.vitaminB12Mcg != null) ('Vitamin B12', '${nutrition.vitaminB12Mcg!.toStringAsFixed(1)} µg'),
      if (nutrition.cholineMg != null) ('Choline', '${nutrition.cholineMg!.round()} mg'),
      if (nutrition.omega3G != null) ('Omega-3', '${nutrition.omega3G!.toStringAsFixed(2)} g'),
      if (nutrition.omega6G != null) ('Omega-6', '${nutrition.omega6G!.toStringAsFixed(2)} g'),
      if (nutrition.waterG != null) ('Nước', '${nutrition.waterG!.round()} g'),
    ];
    return MedicalSurfaceCard(
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: true,
        title: Text('Dinh dưỡng bữa ăn', style: AppTextStyles.heading4),
        subtitle: Text('${rows.length} chỉ số có dữ liệu'),
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Expanded(child: Text(row.$1)),
                  const SizedBox(width: AppSpacing.md),
                  Text(row.$2, style: AppTextStyles.labelMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final FoodHealthEvaluation health;
  final bool needsRefresh;
  final VoidCallback? onRefresh;

  const _HealthCard({
    required this.health,
    required this.needsRefresh,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final (label, color) = switch (health.status) {
      'suitable' => ('Phù hợp', colors.success),
      'mostlySuitable' => ('Khá phù hợp', colors.success),
      'consider' => ('Cần cân nhắc', colors.warning),
      'limit' => ('Nên hạn chế', colors.warning),
      'notSuitable' => ('Không phù hợp', colors.error),
      _ => ('Chưa đủ dữ liệu', colors.textSecondary),
    };
    return MedicalSurfaceCard(
      borderColor: color.withValues(alpha: .25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Phù hợp với sức khỏe của bạn', style: AppTextStyles.heading4)),
              MedicalStatusPill(
                label: label,
                foregroundColor: color,
                backgroundColor: color.withValues(alpha: .1),
              ),
            ],
          ),
          if (health.suitabilityScore != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              '${health.suitabilityScore} / 100',
              style: AppTextStyles.heading2.copyWith(color: color),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(health.summary, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
          if (health.conditionReviews.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            for (final review in health.conditionReviews.take(10)) ...[
              Text(
                review['condition_name']?.toString() ?? 'Tình trạng sức khỏe',
                style: AppTextStyles.labelLarge,
              ),
              for (final reason in _reviewReasons(review['reasons']))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text('• $reason'),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
          if (needsRefresh) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Cập nhật đánh giá sức khỏe'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  final FoodHealthEvaluation health;

  const _DailyGoalCard({required this.health});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return MedicalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes_rounded, color: colors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'So với mục tiêu dinh dưỡng hôm nay',
                  style: AppTextStyles.heading4,
                ),
              ),
            ],
          ),
          if (health.dailyGoalSummary.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              health.dailyGoalSummary,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
            ),
          ],
          for (final note in health.dailyGoalNotes)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '• $note',
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WarningList extends StatelessWidget {
  final String title;
  final List<String> warnings;
  final Color color;

  const _WarningList({
    required this.title,
    required this.warnings,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      borderColor: color.withValues(alpha: .25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading4.copyWith(color: color)),
          const SizedBox(height: AppSpacing.sm),
          for (final item in warnings.take(20)) ...[
            Text('• $item', style: AppTextStyles.bodySmall.copyWith(height: 1.45)),
            const SizedBox(height: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalEmptyState(
      icon: icon,
      title: title,
      message: message,
      color: color,
    );
  }
}
List<Object?> _reviewReasons(Object? value) {
  return value is List ? List<Object?>.from(value) : const <Object?>[];
}

