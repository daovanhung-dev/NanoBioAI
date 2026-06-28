import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/router/v2_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:nano_app/services/supabase/sale/sale_participation_service.dart';
import 'package:nano_app/services/supabase/sale/sale_terms.dart';

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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Cung NanoBio phat trien'),
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

      if (!mounted) return;
      if (updatedState.isActive) {
        context.go(V2RoutePaths.sale);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Da ghi nhan yeu cau Sale. Vui long cho Admin duyet.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chua the gui yeu cau Sale luc nay. Ban thu lai sau.'),
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
              colors: const [Color(0xFF0F766E), Color(0xFF2563EB)],
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
                  SaleTerms.title,
                  style: AppTextStyles.heading2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  SaleTerms.introduction,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: .92),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...SaleTerms.sections.map(
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
            CheckboxListTile(
              value: accepted,
              onChanged: submitting
                  ? null
                  : (value) => onAcceptedChanged(value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Toi da doc, hieu va chap nhan dieu le phien ban ${SaleTerms.currentVersion}.',
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
                  authenticated ? 'Gui yeu cau Sale' : 'Dang nhap de tham gia',
                ),
              ),
            ),
          ],
          if (!authenticated) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ban can dang nhap de he thong luu dieu le va tao yeu cau cho dung tai khoan.',
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
        return 'Tai khoan cua ban da co quyen Sale. Ban co the mo khong gian Sale tu Cai dat.';
      case SaleStatus.suspended:
        return 'Quyen Sale dang tam dung. Ban can lien he ho tro truoc khi tham gia lai.';
      case SaleStatus.closed:
        return 'Quyen Sale da dong. Ban can lien he ho tro neu muon duoc xem xet lai.';
      case SaleStatus.pending:
        return 'Yeu cau Sale dang cho Admin duyet. Ban chua co ma gioi thieu cho den khi duoc duyet.';
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
