import type { AdminSection } from '../types';

const technicalLabels: Record<string, string> = {
  users_total: 'Người dùng',
  onboarding_completed: 'Hoàn tất khởi tạo hồ sơ',
  packages_active: 'Gói thành viên đang hoạt động',
  payments_pending: 'Thanh toán chờ duyệt',
  payments_succeeded: 'Thanh toán hoàn tất',
  revenue_succeeded: 'Doanh thu đã duyệt',
  sales_active: 'Cộng tác viên đang hoạt động',
  familyplus_active: 'FamilyPlus đang hoạt động',
  commission_available: 'Điểm cộng tác viên khả dụng',
  admin_alerts: 'Việc cần Admin xử lý',
  membership_summary: 'Tổng hợp gói thành viên',
  sale_points_summary: 'Tổng hợp điểm cộng tác viên',
  admin_audit_summary: 'Tổng hợp lịch sử thao tác',
};

const statusLabels: Array<[string, string]> = [
  ['awaiting_transfer', 'Chờ chuyển khoản'],
  ['pending_review', 'Chờ duyệt'],
  ['needs_follow_up', 'Cần theo dõi'],
  ['requested', 'Đã tiếp nhận'],
  ['pending', 'Đang chờ'],
  ['succeeded', 'Hoàn tất'],
  ['approved', 'Đã duyệt'],
  ['active', 'Đang hoạt động'],
  ['inactive', 'Không hoạt động'],
  ['suspended', 'Tạm dừng'],
  ['closed', 'Đã đóng'],
  ['cancelled', 'Đã hủy'],
  ['canceled', 'Đã hủy'],
  ['refunded', 'Đã hoàn tiền'],
  ['chargeback', 'Đang khiếu nại'],
  ['failed', 'Chưa hoàn tất'],
  ['rejected', 'Đã từ chối'],
  ['paid', 'Đã chi trả'],
  ['resolved', 'Đã đối soát'],
  ['adjusted', 'Đã điều chỉnh'],
  ['dismissed', 'Đã bỏ qua'],
  ['recorded', 'Đã ghi nhận'],
  ['ready', 'Sẵn sàng'],
  ['draft', 'Bản nháp'],
  ['archived', 'Đã lưu trữ'],
  ['open', 'Đang mở'],
];

const actionLabels: Record<string, string> = {
  active: 'Mở lại',
  suspended: 'Tạm khóa',
  approve: 'Duyệt',
  reject: 'Từ chối',
  refund: 'Hoàn tiền',
  cancel: 'Hủy giao dịch',
  chargeback: 'Ghi nhận khiếu nại',
  suspend: 'Tạm dừng',
  close: 'Đóng cộng tác viên',
  mark_paid: 'Xác nhận đã chi trả',
  adjust_points: 'Điều chỉnh điểm',
  resolved: 'Đã đối soát',
  needs_follow_up: 'Cần theo dõi',
  adjusted: 'Điều chỉnh',
  dismissed: 'Bỏ qua',
  upsert: 'Lưu phiên bản',
  export: 'Tạo yêu cầu xuất',
  cancel_redemption: 'Hủy lượt dùng',
  create_account: 'Tạo tài khoản',
  grant_membership: 'Cấp gói thành viên',
  import_codes: 'Nhập mã ưu đãi',
};

const auditActions: Record<string, string> = {
  admin_update_user_status: 'Cập nhật trạng thái người dùng',
  admin_review_payment: 'Xử lý thanh toán',
  admin_refund_or_cancel_payment: 'Hoàn hoặc hủy thanh toán',
  admin_review_sale_profile: 'Xử lý hồ sơ cộng tác viên',
  admin_upsert_config_version: 'Cập nhật thiết lập',
  admin_request_report_export: 'Yêu cầu xuất báo cáo',
  admin_adjust_sale_points: 'Điều chỉnh điểm cộng tác viên',
  admin_create_reconciliation_run: 'Bắt đầu đối soát',
  admin_update_reconciliation_discrepancy_status: 'Cập nhật kết quả đối soát',
  admin_review_sale_point_conversion: 'Xử lý yêu cầu quy đổi điểm',
  admin_upsert_reward_offer: 'Cập nhật ưu đãi Điểm chăm sóc',
  admin_import_reward_codes: 'Bổ sung mã ưu đãi',
  admin_cancel_reward_redemption: 'Hủy lượt dùng ưu đãi',
};

export function metricLabel(key: string, fallback = 'Chỉ số vận hành'): string {
  return technicalLabels[key] ?? fallback;
}

export function statusLabel(value: string): string {
  const normalized = value.trim().toLowerCase();
  return statusLabels.find(([key]) => normalized === key)?.[1]
    ?? statusLabels.find(([key]) => new RegExp(`(^|[_-])${key}($|[_-])`).test(normalized))?.[1]
    ?? 'Đang cập nhật';
}

export function actionLabel(value: string): string {
  return actionLabels[value] ?? 'Thực hiện';
}

export function planLabel(value: unknown, fallback = 'Chưa xác định'): string {
  const normalized = String(value ?? '').trim().toLowerCase();
  return ({
    guest: 'Khách',
    free: 'Miễn phí',
    plus: 'Plus',
    family_plus: 'FamilyPlus',
    familyplus: 'FamilyPlus',
  } as Record<string, string>)[normalized] ?? fallback;
}

export function auditActionLabel(value: string): string {
  return auditActions[value] ?? 'Thao tác quản trị';
}

export function sectionTitle(section: AdminSection): string {
  return ({
    dashboard: 'Tổng quan vận hành',
    users: 'Người dùng',
    payments: 'Thanh toán',
    sales: 'Cộng tác viên',
    'sale-conversions': 'Chi trả cộng tác viên',
    'wellness-rewards': 'Điểm chăm sóc',
    reconciliation: 'Đối soát',
    plans: 'Gói dịch vụ',
    reports: 'Báo cáo',
    audit: 'Lịch sử thao tác',
    config: 'Thiết lập',
  } satisfies Record<AdminSection, string>)[section];
}

export function formatDate(value?: string): string {
  if (!value) return '—';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return new Intl.DateTimeFormat('vi-VN', {
    dateStyle: 'medium',
    timeStyle: 'short',
    timeZone: 'Asia/Ho_Chi_Minh',
  }).format(date);
}

export function formatMoney(cents?: number, currency = 'VND'): string {
  if (cents === undefined) return '—';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency,
    maximumFractionDigits: 0,
  }).format(cents / 100);
}

export function safeDisplay(value: unknown, fallback = '—'): string {
  const text = String(value ?? '').trim();
  return text || fallback;
}
