import 'package:nano_app/app_versions/admin/features/admin_panel/domain/entities/admin_models.dart';

/// Nguồn copy tập trung cho khu vực quản trị.
///
/// Mục tiêu là không để mã quyền, mã trạng thái, tên thao tác backend hoặc
/// đường dẫn lưu trữ xuất hiện trực tiếp với người vận hành.
abstract final class AdminUiCopy {
  static String sectionLabel(AdminPanelSection section) {
    return switch (section) {
      AdminPanelSection.dashboard => 'Tổng quan',
      AdminPanelSection.users => 'Người dùng',
      AdminPanelSection.payments => 'Thanh toán',
      AdminPanelSection.sales => 'Cộng tác viên',
      AdminPanelSection.saleConversions => 'Chi trả cộng tác viên',
      AdminPanelSection.wellnessRewards => 'Điểm chăm sóc',
      AdminPanelSection.reconciliation => 'Đối soát',
      AdminPanelSection.plans => 'Gói dịch vụ',
      AdminPanelSection.reports => 'Báo cáo',
      AdminPanelSection.audit => 'Lịch sử thao tác',
      AdminPanelSection.config => 'Thiết lập',
    };
  }

  static String sectionDescription(AdminPanelSection section) {
    return switch (section) {
      AdminPanelSection.dashboard =>
        'Theo dõi tình hình vận hành và các việc cần ưu tiên.',
      AdminPanelSection.users =>
        'Tìm kiếm và quản lý trạng thái tài khoản người dùng.',
      AdminPanelSection.payments =>
        'Đối chiếu giao dịch trước khi duyệt hoặc từ chối.',
      AdminPanelSection.sales =>
        'Xử lý hồ sơ và trạng thái hoạt động của cộng tác viên.',
      AdminPanelSection.saleConversions =>
        'Kiểm tra yêu cầu quy đổi và xác nhận việc chi trả.',
      AdminPanelSection.wellnessRewards =>
        'Quản lý ưu đãi và kho mã dành cho người dùng.',
      AdminPanelSection.reconciliation =>
        'Theo dõi sai lệch và ghi nhận kết quả đối soát.',
      AdminPanelSection.plans =>
        'Quản lý các gói dịch vụ đang áp dụng.',
      AdminPanelSection.reports =>
        'Tạo và theo dõi yêu cầu xuất báo cáo.',
      AdminPanelSection.audit =>
        'Xem lại các thao tác quan trọng đã được ghi nhận.',
      AdminPanelSection.config =>
        'Cập nhật thiết lập vận hành theo phạm vi được cấp.',
    };
  }

  static String permissionLabel(String permission) {
    return switch (permission.trim().toLowerCase()) {
      'view_dashboard' || 'dashboard.read' => 'xem tổng quan',
      'manage_users' || 'users.write' => 'quản lý người dùng',
      'manage_payments' || 'payments.write' => 'quản lý thanh toán',
      'manage_sales' || 'sales.write' => 'quản lý cộng tác viên',
      'manage_sale_conversions' => 'quản lý chi trả cộng tác viên',
      'wellness_rewards.read' => 'xem Điểm chăm sóc',
      'wellness_rewards.write' => 'quản lý Điểm chăm sóc',
      'manage_reconciliation' || 'reconciliation.write' => 'quản lý đối soát',
      'manage_plans' || 'plans.write' => 'quản lý gói dịch vụ',
      'export_reports' || 'reports.write' => 'xuất báo cáo',
      'view_audit' || 'audit.read' => 'xem lịch sử thao tác',
      'manage_config' || 'config.write' => 'quản lý thiết lập',
      _ => 'phù hợp với khu vực này',
    };
  }

  static String statusLabel(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.contains('awaiting_transfer')) {
      return 'Chờ chuyển khoản';
    }
    if (normalized.contains('pending_review')) return 'Chờ duyệt';
    if (normalized.contains('needs_follow_up')) return 'Cần theo dõi';
    if (normalized.contains('requested')) return 'Đã tiếp nhận';
    if (normalized.contains('pending')) return 'Đang chờ';
    if (normalized.contains('succeeded')) return 'Hoàn tất';
    if (normalized.contains('approved')) return 'Đã duyệt';
    if (normalized.contains('active')) return 'Đang hoạt động';
    if (normalized.contains('suspended')) return 'Tạm dừng';
    if (normalized.contains('closed')) return 'Đã đóng';
    if (normalized.contains('cancelled') || normalized.contains('canceled')) {
      return 'Đã hủy';
    }
    if (normalized.contains('refunded')) return 'Đã hoàn tiền';
    if (normalized.contains('chargeback')) return 'Đang khiếu nại';
    if (normalized.contains('failed')) return 'Chưa hoàn tất';
    if (normalized.contains('rejected')) return 'Đã từ chối';
    if (normalized.contains('paid')) return 'Đã chi trả';
    if (normalized.contains('resolved')) return 'Đã đối soát';
    if (normalized.contains('adjusted')) return 'Đã điều chỉnh';
    if (normalized.contains('dismissed')) return 'Đã bỏ qua';
    if (normalized.contains('ready')) return 'Sẵn sàng';
    if (normalized.contains('draft')) return 'Bản nháp';
    if (normalized.contains('archived')) return 'Đã lưu trữ';
    if (normalized.contains('open')) return 'Đang mở';
    if (normalized.contains('generating')) return 'Đang chuẩn bị';
    return 'Đang cập nhật';
  }

  static String metricLabel(AdminDashboardMetric metric) {
    return switch (metric.key) {
      'users_total' => 'Người dùng',
      'payments_pending' => 'Thanh toán chờ duyệt',
      'sales_active' => 'Cộng tác viên đang hoạt động',
      'commission_available' => 'Điểm có thể quy đổi',
      _ => _safeLabel(metric.label, fallback: 'Chỉ số vận hành'),
    };
  }

  static String auditAction(String action) {
    return switch (action) {
      'admin_update_user_status' => 'Cập nhật trạng thái người dùng',
      'admin_review_payment' => 'Xử lý thanh toán',
      'admin_refund_or_cancel_payment' => 'Hoàn hoặc hủy thanh toán',
      'admin_review_sale_profile' => 'Xử lý hồ sơ cộng tác viên',
      'admin_upsert_config_version' => 'Cập nhật thiết lập',
      'admin_request_report_export' => 'Yêu cầu xuất báo cáo',
      'admin_adjust_sale_points' => 'Điều chỉnh điểm cộng tác viên',
      'admin_create_reconciliation_run' => 'Bắt đầu đối soát',
      'admin_update_reconciliation_discrepancy_status' =>
        'Cập nhật kết quả đối soát',
      'admin_review_sale_point_conversion' => 'Xử lý yêu cầu quy đổi điểm',
      'admin_upsert_reward_offer' => 'Cập nhật ưu đãi Điểm chăm sóc',
      'admin_import_reward_codes' => 'Bổ sung mã ưu đãi',
      'admin_cancel_reward_redemption' => 'Hủy lượt dùng ưu đãi',
      _ => 'Thao tác quản trị',
    };
  }

  static String auditTarget(String target) {
    final normalized = target.trim().toLowerCase();
    if (normalized.isEmpty) return 'Đối tượng quản trị';
    if (normalized.contains('reward_offer')) return 'Ưu đãi Điểm chăm sóc';
    if (normalized.contains('reward_code')) return 'Kho mã ưu đãi';
    if (normalized.contains('redemption')) return 'Lượt dùng ưu đãi';
    if (normalized.contains('payment')) return 'Giao dịch thanh toán';
    if (normalized.contains('sale')) return 'Hồ sơ cộng tác viên';
    if (normalized.contains('user') || normalized.contains('profile')) {
      return 'Tài khoản người dùng';
    }
    if (normalized.contains('config') || normalized.contains('plan')) {
      return 'Thiết lập hệ thống';
    }
    return 'Đối tượng quản trị';
  }

  static String auditReason(String reason) {
    final value = reason.trim();
    if (value.isEmpty) return 'Không có mô tả';
    return switch (value.toLowerCase()) {
      'system' => 'Do hệ thống thực hiện',
      'manual review' => 'Đã kiểm tra thủ công',
      'user request' => 'Theo yêu cầu của người dùng',
      _ => _safeLabel(value, fallback: 'Đã ghi nhận lý do'),
    };
  }

  static String emptyTitle({required bool hasQuery}) {
    return hasQuery ? 'Không tìm thấy kết quả' : 'Chưa có việc cần xử lý';
  }

  static String emptyMessage({
    required AdminPanelSection section,
    required bool hasQuery,
  }) {
    if (hasQuery) {
      return 'Hãy thử từ khóa ngắn hơn hoặc xóa nội dung tìm kiếm.';
    }
    return 'Các mục mới trong ${sectionLabel(section).toLowerCase()} sẽ xuất hiện tại đây.';
  }

  static String safeNotice(String? message) {
    final value = message?.trim() ?? '';
    if (value.isEmpty || containsTechnicalToken(value)) {
      return 'Thao tác đã được ghi nhận.';
    }
    return value;
  }

  static bool containsTechnicalToken(String value) {
    final normalized = value.toLowerCase();
    const blocked = <String>[
      'database',
      'table',
      'query',
      'parser',
      'exception',
      'stack trace',
      'rpc',
      'rls',
      'uuid',
      'webhook',
      'api',
      'http',
      'sql',
      'json',
      'supabase',
      'permission code',
      'action key',
      'status code',
      'trace id',
      'payment_proof_path',
      'storage path',
    ];
    return blocked.any(normalized.contains);
  }

  static String _safeLabel(String value, {required String fallback}) {
    final text = value.trim();
    if (text.isEmpty || containsTechnicalToken(text)) return fallback;
    return text;
  }
}
