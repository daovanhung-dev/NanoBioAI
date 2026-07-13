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
const _saleTermsTitle = 'Điều lệ tham gia chương trình cộng tác viên cùng NanoBio';
const _saleTermsIntroduction =
    'Bạn tham gia với vai trò giới thiệu đúng thông tin về NanoBio. '
    'Đây không phải cam kết việc làm hay cam kết thu nhập.';
const _saleTermsSections = <_SaleTermsSectionView>[
  _SaleTermsSectionView(
    title: '1. Cách ghi nhận kết quả',
    body:
        'Chỉ thành viên đang có gói Plus hoặc FamilyPlus hợp lệ mới được gửi yêu cầu cộng tác viên. '
        'Điểm giao dịch cộng tác viên chỉ phát sinh từ thanh toán hợp lệ của khách trực tiếp, tính 10% theo giá niêm yết của chủ gói.',
  ),
  _SaleTermsSectionView(
    title: '2. Thông tin phải trung thực',
    body:
        'Bạn không được cam kết kết quả sức khỏe, thu nhập, ưu đãi hoặc quyền lợi khác ngoài nội dung NanoBio đã công bố. '
        'Không dùng tên, hình ảnh, dữ liệu khách hàng hoặc mã giới thiệu để gây hiểu nhầm.',
  ),
  _SaleTermsSectionView(
    title: '3. Bảo vệ khách hàng và dữ liệu',
    body:
        'Chỉ chia sẻ mã giới thiệu của chính bạn. Mã chỉ được gắn trong lúc đăng ký tài khoản và có thể bị chặn khi trùng email, số điện thoại, thiết bị hoặc lịch sử thanh toán. '
        'Không gửi thư rác, quấy rối hoặc liên hệ ngoài sự đồng ý của người nhận.',
  ),
  _SaleTermsSectionView(
    title: '4. Điều kiện đối soát',
    body:
        'Điểm giao dịch cộng tác viên hiển thị ngay sau khi thanh toán được duyệt nhưng chỉ khả dụng sau 24 giờ. '
        'Nếu hoàn tiền, hủy đơn hoặc tranh chấp, điểm giao dịch sẽ bị trừ ngay và có thể làm số dư âm.',
  ),
  _SaleTermsSectionView(
    title: '5. Quyền quản lý của NanoBio',
    body:
        'Bạn cần cập nhật số căn cước công dân và tài khoản ngân hàng trước khi vào không gian cộng tác viên hoặc rút tiền. '
        'Điểm giao dịch được quy đổi 1 điểm = 1 VND theo cấu hình quản trị; điểm thưởng chuyên cần chỉ dùng cho ưu đãi và không rút tiền. '
        'NanoBio có thể tạm dừng hoặc đóng quyền cộng tác viên khi phát hiện dấu hiệu gian lận, giả mạo, vi phạm chính sách hoặc theo yêu cầu của pháp luật. '
        'Các điều khoản có thể được cập nhật; phiên bản mới sẽ được hiển thị trước khi bạn tiếp tục sử dụng.',
  ),
];

class _SaleTermsSectionView {
  final String title;
  final String body;

  const _SaleTermsSectionView({required this.title, required this.body});
}

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
          content: Text('Đã ghi nhận yêu cầu cộng tác viên. Vui lòng chờ quản trị viên duyệt.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa thể gửi yêu cầu cộng tác viên lúc này. Bạn thử lại sau.'),
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
          ..._saleTermsSections.map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: AppDecoration.card(
                  radius: AppRadius.xl,
                  shadows: AppShadows.soft,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.title, style: AppTextStyles.labelLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      section.body,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (stateNote != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _StatusNotice(message: stateNote),
          ],
          const SizedBox(height: AppSpacing.md),
          if (canJoin) ...[
            const _StatusNotice(
              message:
                  'Điều kiện tham gia: tài khoản phải có gói Plus hoặc FamilyPlus đang hoạt động. Quản trị viên sẽ duyệt thủ công trước khi cấp mã cộng tác viên.',
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
                  authenticated ? 'Gửi yêu cầu cộng tác viên' : 'Đăng nhập để tham gia',
                ),
              ),
            ),
          ],
          if (!authenticated) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Bạn cần đăng nhập để hệ thống lưu điều lệ và tạo yêu cầu cho đúng tài khoản.',
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
        return 'Tài khoản của bạn đã có quyền cộng tác viên. Bạn có thể mở không gian cộng tác viên từ Cài đặt.';
      case SaleStatus.suspended:
        return 'Quyền cộng tác viên đang tạm dừng. Bạn cần liên hệ hỗ trợ trước khi tham gia lại.';
      case SaleStatus.closed:
        return 'Quyền cộng tác viên đã đóng. Bạn cần liên hệ hỗ trợ nếu muốn được xem xét lại.';
      case SaleStatus.pending:
        return 'Yêu cầu cộng tác viên đang chờ quản trị viên duyệt. Bạn chưa có mã giới thiệu cho đến khi được duyệt.';
      case SaleStatus.none:
        return null;
    }
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
