import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:nano_app/services/supabase/sale/sale_participation_service.dart';
import 'package:nano_app/services/supabase/sale/sale_terms.dart';

/// Bản sao nội dung hiển thị dành riêng cho giao diện.
/// Giữ nguyên SaleTerms ở tầng dịch vụ để không tác động điều khoản/version nghiệp vụ.
const _saleTermsTitle = 'Điều lệ cộng tác viên';
const _saleTermsIntroduction =
    'Giới thiệu đúng thông tin NanoBio, không cam kết thu nhập.';
const _saleTermsSummaryBullets = <String>[
  'Chỉ tài khoản Plus hoặc FamilyPlus được gửi yêu cầu.',
  'Điểm phát sinh từ khách trực tiếp thanh toán hợp lệ.',
  'Điểm khả dụng sau 24 giờ và có thể bị điều chỉnh.',
  'Cần CCCD và tài khoản ngân hàng trước khi rút tiền.',
  'NanoBio có thể tạm dừng khi có dấu hiệu vi phạm.',
];

class SaleParticipationPage extends ConsumerStatefulWidget {
  const SaleParticipationPage({super.key});

  @override
  ConsumerState<SaleParticipationPage> createState() =>
      _SaleParticipationPageState();
}

class _SaleParticipationPageState extends ConsumerState<SaleParticipationPage> {
  bool _accepted = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final saleState = ref.watch(saleStateProvider);
    final authenticated = currentSupabaseUserIdOrNull() != null;

    return MedicalPageScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Đồng hành phát triển cùng NanoBio'),
      ),
      body: SafeArea(
        top: false,
        child: saleState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _BuildTermsBody(
            authenticated: authenticated,
            accepted: _accepted,
            submitting: _submitting,
            state: SaleState.none,
            onAcceptedChanged: (value) => setState(() => _accepted = value),
            onSubmit: _submit,
          ),
          data: (state) => _BuildTermsBody(
            authenticated: authenticated,
            accepted: _accepted,
            submitting: _submitting,
            state: state,
            onAcceptedChanged: (value) => setState(() => _accepted = value),
            onSubmit: _submit,
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final authenticated = currentSupabaseUserIdOrNull() != null;
    if (!authenticated) {
      if (!mounted) return;
      context.go(V2RoutePaths.login);
      return;
    }
    if (!_accepted || _submitting) return;

    setState(() => _submitting = true);
    try {
      final updatedState = await ref
          .read(saleParticipationServiceProvider)
          .requestParticipation(termsVersion: SaleTerms.currentVersion);
      ref.invalidate(saleStateProvider);
      ref.invalidate(saleDashboardProvider);
      ref.invalidate(saleDirectCustomersProvider);
      ref.invalidate(salePointLedgerProvider);
      ref.invalidate(saleConversionsProvider);
      ref.invalidate(salePayoutProfileProvider);

      if (!mounted) return;
      if (updatedState.isActive) {
        context.go(V2RoutePaths.sale);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã ghi nhận yêu cầu cộng tác viên. Vui lòng chờ quản trị viên duyệt.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa thể gửi yêu cầu cộng tác viên lúc này. Bạn thử lại sau.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _BuildTermsBody extends StatelessWidget {
  final bool authenticated;
  final bool accepted;
  final bool submitting;
  final SaleState state;
  final ValueChanged<bool> onAcceptedChanged;
  final Future<void> Function() onSubmit;

  const _BuildTermsBody({
    required this.authenticated,
    required this.accepted,
    required this.submitting,
    required this.state,
    required this.onAcceptedChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final canJoin =
        state.status == SaleStatus.none || state.status == SaleStatus.pending;
    final stateNote = _stateNote(state.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pagePadding,
        AppSpacing.sm,
        AppSpacing.pagePadding,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: AppDecoration.gradient(
              colors: AppGradients.ai.colors,
              radius: AppRadius.xxl,
              shadows: AppShadows.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.volunteer_activism_rounded,
                  color: Colors.white,
                  size: 34,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _saleTermsTitle,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _saleTermsIntroduction,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: .92),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          MedicalSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tóm tắt điều lệ', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.sm),
                for (final item in _saleTermsSummaryBullets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(item, style: AppTextStyles.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _showFullTerms(context),
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Xem điều lệ đầy đủ'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (stateNote != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _StatusNotice(message: stateNote),
          ],
          const SizedBox(height: AppSpacing.md),
          if (canJoin) ...[
            const _StatusNotice(
              message:
                  'Cần gói Plus hoặc FamilyPlus. Admin sẽ duyệt trước khi cấp mã.',
            ),
            const SizedBox(height: AppSpacing.sm),
            CheckboxListTile(
              value: accepted,
              onChanged: submitting
                  ? null
                  : (value) => onAcceptedChanged(value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Tôi đã đọc, hiểu và chấp nhận điều lệ phiên bản ${SaleTerms.currentVersion}.',
                style: AppTextStyles.bodyMedium.copyWith(height: 1.45),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: !authenticated || !accepted || submitting
                    ? null
                    : onSubmit,
                icon: submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        authenticated
                            ? Icons.rocket_launch_rounded
                            : Icons.login_rounded,
                      ),
                label: Text(
                  authenticated
                      ? 'Gửi yêu cầu cộng tác viên'
                      : 'Đăng nhập để tham gia',
                ),
              ),
            ),
          ],
          if (!authenticated) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Đăng nhập để lưu điều lệ và tạo đúng yêu cầu.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String? _stateNote(SaleStatus status) {
    switch (status) {
      case SaleStatus.active:
        return 'Bạn đã là cộng tác viên. Mở không gian này từ Cài đặt.';
      case SaleStatus.suspended:
        return 'Quyền cộng tác viên đang tạm dừng. Vui lòng liên hệ hỗ trợ.';
      case SaleStatus.closed:
        return 'Quyền cộng tác viên đã đóng. Hãy liên hệ hỗ trợ nếu cần.';
      case SaleStatus.pending:
        return 'Yêu cầu đang chờ duyệt. Mã giới thiệu sẽ mở sau khi duyệt.';
      case SaleStatus.none:
        return null;
    }
  }

  void _showFullTerms(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(SaleTerms.title),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(SaleTerms.introduction),
                const SizedBox(height: AppSpacing.md),
                for (final section in SaleTerms.sections) ...[
                  Text(section.title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(section.body),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  final String message;

  const _StatusNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
