import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { CalendarClock, Copy, Eye, KeyRound, Pencil, Plus, RefreshCw, ShieldCheck, UserRoundPlus, UsersRound } from 'lucide-react';
import { useSearchParams } from 'react-router-dom';
import { useAdminAuth } from '../auth/AuthProvider';
import { Drawer, EmptyState, ErrorState, LoadingState, Modal, ReasonDialog, StatusBadge, Toast } from '../components/Ui';
import { formatDate, planLabel, safeDisplay } from '../lib/labels';
import { canBulkProvisionAccounts, canCreateAccount, canGrantMembership, canManageUserDetails, makeIdempotencyKey, type AdminPasswordResetResult, type AdminSession, type AdminUserDetails, type AdminWorkItem, type BulkProvisionInput, type BulkProvisionPreview, type BulkProvisionResult } from '../types';
import { bulkConfirmationText, parseBulkAccountLines, type BulkAccountLineIssue } from '../lib/bulk-accounts';

type AccountAction = { item: AdminWorkItem; action: 'active' | 'suspended' };
type UserProfileFormInput = { fullName: string; phone: string; gender: string; birthYear?: number };

export function AccountsPage() {
  const { api, session } = useAdminAuth();
  const [searchParams, setSearchParams] = useSearchParams();
  const [items, setItems] = useState<AdminWorkItem[]>([]);
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [selected, setSelected] = useState<AccountAction | null>(null);
  const [createOpen, setCreateOpen] = useState(false);
  const [bulkOpen, setBulkOpen] = useState(false);
  const [membershipUser, setMembershipUser] = useState<AdminWorkItem | null>(null);
  const [detailReasonUser, setDetailReasonUser] = useState<AdminWorkItem | null>(null);
  const [detailUser, setDetailUser] = useState<AdminWorkItem | null>(null);
  const [userDetails, setUserDetails] = useState<AdminUserDetails | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [detailError, setDetailError] = useState<string | null>(null);
  const [detailBusy, setDetailBusy] = useState(false);
  const [profilePending, setProfilePending] = useState<{ userId: string; fullName: string; phone: string; gender: string; birthYear?: number } | null>(null);
  const [passwordPending, setPasswordPending] = useState<{ userId: string; subject: string; idempotencyKey: string } | null>(null);
  const [passwordResult, setPasswordResult] = useState<AdminPasswordResetResult | null>(null);
  const [createPending, setCreatePending] = useState<{ fullName: string; email: string; password: string; phone: string; reason: string; idempotencyKey: string } | null>(null);
  const [membershipPending, setMembershipPending] = useState<{ userId: string; planCode: 'plus' | 'family_plus'; startsAt: string; endsAt: string; reason: string; idempotencyKey: string } | null>(null);
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setItems(await api.listSection('users', query));
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Chưa tải được danh sách tài khoản.');
    } finally {
      setLoading(false);
    }
  }, [api, query]);

  useEffect(() => { void load(); }, [load]);
  useEffect(() => {
    const listener = () => void load();
    window.addEventListener('admin:refresh', listener);
    return () => window.removeEventListener('admin:refresh', listener);
  }, [load]);
  useEffect(() => {
    if (searchParams.get('create') === '1' && canCreateAccount(session ?? emptySession)) {
      setCreateOpen(true);
      setSearchParams({}, { replace: true });
    }
    if (searchParams.get('upgrade') === '1' && items.length > 0 && canGrantMembership(session ?? emptySession)) {
      const first = items[0];
      if (first) setMembershipUser(first);
      setSearchParams({}, { replace: true });
    }
  }, [items, searchParams, session, setSearchParams]);

  const canWrite = Boolean(session && canCreateAccount(session));
  const canUpgrade = Boolean(session && canGrantMembership(session));
  const canBulkProvision = Boolean(session && canBulkProvisionAccounts(session));
  const canManageDetails = Boolean(session && canManageUserDetails(session));
  const activeCount = useMemo(() => items.filter((item) => {
    const normalized = item.status.toLowerCase();
    return normalized === 'active' || /(^|[_-])active($|[_-])/.test(normalized);
  }).length, [items]);

  if (!session) return null;
  return (
    <div className="page-stack">
      <section className="page-heading">
        <div><span className="eyebrow">Tài khoản & quyền truy cập</span><h1>Người dùng</h1><p>Tìm kiếm tài khoản, cập nhật trạng thái và cấp gói theo đúng quyền hạn.</p></div>
        <div className="heading-actions">
          <button className="button secondary" onClick={() => void load()} disabled={loading}><RefreshCw size={16} /> Làm mới</button>
          {canWrite && <button className="button primary" onClick={() => setCreateOpen(true)}><UserRoundPlus size={16} /> Tạo tài khoản</button>}
          {canBulkProvision && <button className="button primary" onClick={() => setBulkOpen(true)}><UsersRound size={16} /> Tạo nhanh nhiều tài khoản</button>}
        </div>
      </section>
      <section className="summary-strip"><div><span className="eyebrow">Trong kết quả hiện tại</span><strong>{items.length} tài khoản</strong></div><div><span className="eyebrow">Đang hoạt động</span><strong>{activeCount}</strong></div><div><span className="eyebrow">Quyền cấp gói</span><strong>{canUpgrade ? 'Super Admin' : 'Chỉ xem'}</strong></div></section>
      <div className="filter-bar"><div className="search-field"><KeyRound size={17} /><input value={query} onChange={(event) => setQuery(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') void load(); }} placeholder="Tìm theo tên, email hoặc mã tài khoản…" aria-label="Tìm kiếm tài khoản" /></div><button className="button secondary" onClick={() => void load()}>Tìm kiếm</button></div>
      {toast && <Toast message={toast} onClose={() => setToast(null)} />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {loading && items.length === 0 ? <LoadingState /> : items.length === 0 ? <EmptyState title={query ? 'Không tìm thấy tài khoản' : 'Chưa có tài khoản'} message="Thử một từ khóa khác hoặc tải lại dữ liệu." /> : <AccountTable items={items} canUpgrade={canUpgrade} canWrite={canWrite} canManageDetails={canManageDetails} onStatus={setSelected} onMembership={setMembershipUser} onDetails={setDetailReasonUser} />}
      {selected && <ReasonDialog action={selected.action} subject={selected.item.title} onCancel={() => setSelected(null)} onConfirm={(reason) => void updateStatus(selected, reason)} busy={busy} />}
      {detailReasonUser && <ReasonDialog action="view_health" subject={detailReasonUser.title} onCancel={() => setDetailReasonUser(null)} onConfirm={(reason) => void openDetails(detailReasonUser, reason)} busy={detailLoading} />}
      {createOpen && <CreateAccountModal busy={busy} onClose={() => setCreateOpen(false)} onSubmit={(input) => { setCreateOpen(false); setCreatePending({ ...input, idempotencyKey: makeIdempotencyKey('create-account', input.email) }); }} />}
      {bulkOpen && <BulkProvisionModal api={api} onClose={() => setBulkOpen(false)} onComplete={async (result) => { setBulkOpen(false); setToast(`Đã xử lý ${result.processedCount} tài khoản: ${result.createdCount} tạo mới, ${result.grantedCount} cấp gói, ${result.skippedCount} giữ nguyên.`); await load(); }} />}
      {membershipUser && <GrantMembershipModal user={membershipUser} busy={busy} onClose={() => setMembershipUser(null)} onSubmit={(input) => { setMembershipUser(null); setMembershipPending({ ...input, idempotencyKey: makeIdempotencyKey('grant-membership', input.userId) }); }} />}
      {createPending && <ReasonDialog action="create_account" subject={createPending.email} initialReason={createPending.reason} onCancel={() => setCreatePending(null)} onConfirm={(reason) => void createAccount({ ...createPending, reason })} busy={busy} />}
      {membershipPending && <ReasonDialog action="grant_membership" subject={membershipPending.userId} initialReason={membershipPending.reason} onCancel={() => setMembershipPending(null)} onConfirm={(reason) => void grantMembership({ ...membershipPending, reason })} busy={busy} />}
      {detailUser && <UserDetailsDrawer details={userDetails} loading={detailLoading} error={detailError} busy={detailBusy} passwordResult={passwordResult} onClose={closeDetails} onEdit={(input) => setProfilePending({ ...input, userId: detailUser.id })} onReset={() => setPasswordPending({ userId: detailUser.id, subject: detailUser.title, idempotencyKey: makeIdempotencyKey('reset-user-password', detailUser.id) })} />}
      {profilePending && <ReasonDialog action="update_user_profile" subject={profilePending.userId} onCancel={() => setProfilePending(null)} onConfirm={(reason) => void updateProfile(profilePending, reason)} busy={detailBusy} />}
      {passwordPending && <ReasonDialog action="reset_user_password" subject={passwordPending.subject} onCancel={() => setPasswordPending(null)} onConfirm={(reason) => void resetPassword(passwordPending, reason)} busy={detailBusy} />}
    </div>
  );

  async function updateStatus(action: AccountAction, reason: string) {
    if (busyRef.current) return;
    busyRef.current = true; setBusy(true); setError(null);
    try {
      const result = await api.runMutation({ section: 'users', action: action.action, targetId: action.item.id, reason, idempotencyKey: makeIdempotencyKey('user-status', action.item.id) });
      setSelected(null); setToast(result.message || 'Đã cập nhật trạng thái tài khoản.'); await load();
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Chưa cập nhật được trạng thái tài khoản.');
    } finally { busyRef.current = false; setBusy(false); }
  }

  async function createAccount(input: { fullName: string; email: string; password: string; phone: string; reason: string; idempotencyKey: string }) {
    if (busyRef.current) return;
    busyRef.current = true; setBusy(true); setError(null);
    try {
      const result = await api.createAccount(input);
      setCreatePending(null); setToast(result.message || 'Đã tạo tài khoản.'); await load();
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Chưa tạo được tài khoản.');
    } finally { busyRef.current = false; setBusy(false); }
  }

  async function grantMembership(input: { userId: string; planCode: 'plus' | 'family_plus'; startsAt: string; endsAt: string; reason: string; idempotencyKey: string }) {
    if (busyRef.current) return;
    busyRef.current = true; setBusy(true); setError(null);
    try {
      const result = await api.grantMembership(input);
      setMembershipPending(null); setToast(result.message || 'Đã cập nhật gói thành viên.'); await load();
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Chưa cập nhật được gói thành viên.');
    } finally { busyRef.current = false; setBusy(false); }
  }

  async function openDetails(item: AdminWorkItem, reason: string) {
    setDetailReasonUser(null);
    setDetailUser(item);
    setUserDetails(null);
    setDetailError(null);
    setPasswordResult(null);
    setDetailLoading(true);
    try {
      setUserDetails(await api.getUserDetails(item.id, reason));
    } catch (nextError) {
      setDetailError(nextError instanceof Error ? nextError.message : 'Chưa tải được thông tin chi tiết.');
    } finally {
      setDetailLoading(false);
    }
  }

  function closeDetails() {
    setDetailUser(null);
    setUserDetails(null);
    setDetailError(null);
    setPasswordResult(null);
    setProfilePending(null);
    setPasswordPending(null);
  }

  async function updateProfile(input: { userId: string; fullName: string; phone: string; gender: string; birthYear?: number }, reason: string) {
    if (detailBusy) return;
    setDetailBusy(true);
    setDetailError(null);
    try {
      await api.updateUserProfile({ ...input, reason, idempotencyKey: makeIdempotencyKey('update-user-profile', input.userId) });
      setUserDetails((current) => current ? {
        ...current,
        user: {
          ...current.user,
          fullName: input.fullName.trim() || undefined,
          phone: input.phone.trim() || undefined,
          gender: input.gender.trim() || undefined,
          birthYear: input.birthYear,
        },
      } : current);
      setProfilePending(null);
      setToast('Đã cập nhật thông tin người dùng.');
      await load();
    } catch (nextError) {
      setDetailError(nextError instanceof Error ? nextError.message : 'Chưa cập nhật được thông tin người dùng.');
    } finally {
      setDetailBusy(false);
    }
  }

  async function resetPassword(input: { userId: string; subject: string; idempotencyKey: string }, reason: string) {
    if (detailBusy) return;
    setDetailBusy(true);
    setDetailError(null);
    try {
      const result = await api.resetUserPassword(input.userId, reason, input.idempotencyKey);
      if (!result.success) {
        setDetailError(result.message || 'Chưa đổi được mật khẩu người dùng.');
        return;
      }
      setPasswordPending(null);
      setPasswordResult(result);
      setToast(result.message || 'Đã đổi mật khẩu người dùng.');
    } catch (nextError) {
      setDetailError(nextError instanceof Error ? nextError.message : 'Chưa đổi được mật khẩu người dùng.');
    } finally {
      setDetailBusy(false);
    }
  }
}

function AccountTable({ items, canWrite, canUpgrade, canManageDetails, onStatus, onMembership, onDetails }: { items: AdminWorkItem[]; canWrite: boolean; canUpgrade: boolean; canManageDetails: boolean; onStatus: (value: AccountAction) => void; onMembership: (item: AdminWorkItem) => void; onDetails: (item: AdminWorkItem) => void }) {
  return <div className="table-card"><div className="table-scroll"><table><thead><tr><th>Tài khoản</th><th>Trạng thái</th><th>Gói hiện tại</th><th>Hoạt động gần nhất</th><th className="action-column">Thao tác</th></tr></thead><tbody>{items.map((item) => {
    const normalized = item.status.toLowerCase();
    const has = (token: string) => normalized === token || new RegExp(`(^|[_-])${token}($|[_-])`).test(normalized);
    const nextStatus: AccountAction['action'] | null = has('active') ? 'suspended' : has('suspended') ? 'active' : null;
    return <tr key={item.id}><td><div className="item-title">{safeDisplay(item.title)}</div><div className="item-subtitle">{safeDisplay(item.subtitle || item.id)}</div></td><td><StatusBadge value={item.status} /></td><td>{planLabel(item.metadata.plan_code ?? item.metadata.plan_name)}</td><td className="nowrap">{formatDate(item.createdAt)}</td><td className="action-cell"><div className="action-list">{canManageDetails && <button className="text-action" onClick={() => onDetails(item)}><Eye size={13} /> Chi tiết</button>}{canWrite && nextStatus && <button className={`text-action ${nextStatus === 'suspended' ? 'danger-text' : ''}`} onClick={() => onStatus({ item, action: nextStatus })}>{nextStatus === 'suspended' ? 'Tạm khóa' : 'Mở lại'}</button>}{canUpgrade && <button className="text-action" onClick={() => onMembership(item)}>Cấp gói</button>}{!canManageDetails && !canWrite && !canUpgrade && <span className="muted">Chỉ xem</span>}</div></td></tr>;
  })}</tbody></table></div></div>;
}

function UserDetailsDrawer({ details, loading, error, busy, passwordResult, onClose, onEdit, onReset }: { details: AdminUserDetails | null; loading: boolean; error: string | null; busy: boolean; passwordResult: AdminPasswordResetResult | null; onClose: () => void; onEdit: (input: UserProfileFormInput) => void; onReset: () => void }) {
  const [editing, setEditing] = useState(false);
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [gender, setGender] = useState('');
  const [birthYear, setBirthYear] = useState('');
  const [formError, setFormError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!details) return;
    setFullName(details.user.fullName ?? '');
    setPhone(details.user.phone ?? '');
    setGender(details.user.gender ?? '');
    setBirthYear(details.user.birthYear ? String(details.user.birthYear) : '');
    setEditing(false);
    setFormError(null);
    setCopied(false);
  }, [details]);

  function submitEdit(event: FormEvent) {
    event.preventDefault();
    const name = fullName.trim();
    const yearText = birthYear.trim();
    const year = yearText ? Number(yearText) : undefined;
    if (name.length < 2) {
      setFormError('Họ và tên cần có ít nhất 2 ký tự.');
      return;
    }
    if (yearText && (!Number.isInteger(year) || year === undefined || year < 1900 || year > new Date().getFullYear())) {
      setFormError('Năm sinh chưa hợp lệ.');
      return;
    }
    setFormError(null);
    setEditing(false);
    onEdit({ fullName: name, phone, gender, birthYear: year });
  }

  async function copyPassword() {
    if (!passwordResult?.temporaryPassword || !navigator.clipboard) return;
    await navigator.clipboard.writeText(passwordResult.temporaryPassword);
    setCopied(true);
  }

  const title = details?.user.fullName || details?.user.email || 'Thông tin người dùng';
  return <Drawer title={title} onClose={onClose}>
    <div className="drawer-body">
      {loading && <LoadingState label="Đang tải thông tin người dùng…" />}
      {error && <div className="drawer-error" role="alert">{error}</div>}
      {details && <>
        <section className="drawer-section">
          <div className="selected-account"><span className="avatar small">{(title[0] ?? 'U').toUpperCase()}</span><span><strong>{safeDisplay(details.user.fullName, 'Chưa cập nhật họ tên')}</strong><small>{safeDisplay(details.user.email, details.user.id)}</small></span></div>
          <div className="drawer-actions">
            <button className="button secondary" onClick={() => { setEditing((value) => !value); setFormError(null); }} disabled={busy}><Pencil size={15} /> {editing ? 'Hủy sửa' : 'Sửa thông tin'}</button>
            <button className="button primary" onClick={onReset} disabled={busy}><KeyRound size={15} /> Đổi mật khẩu</button>
          </div>
          {passwordResult && <div className="password-result" role="status">
            {passwordResult.temporaryPassword ? <><code>{passwordResult.temporaryPassword}</code><button onClick={() => void copyPassword()}>{copied ? 'Đã sao chép' : 'Sao chép'}</button></> : <span>{passwordResult.message}</span>}
          </div>}
        </section>

        <section className="drawer-section">
          <div className="drawer-section-heading"><h3>Thông tin cơ bản</h3><StatusBadge value={details.user.adminStatus ?? 'active'} /></div>
          {editing ? <form onSubmit={submitEdit}>
            {formError && <div className="inline-alert danger">{formError}</div>}
            <div className="form-grid two"><label className="field-label">Họ và tên<input className="input" value={fullName} onChange={(event) => setFullName(event.target.value)} /></label><label className="field-label">Số điện thoại<input className="input" value={phone} onChange={(event) => setPhone(event.target.value)} /></label><label className="field-label">Giới tính<input className="input" value={gender} onChange={(event) => setGender(event.target.value)} /></label><label className="field-label">Năm sinh<input className="input" inputMode="numeric" value={birthYear} onChange={(event) => setBirthYear(event.target.value)} /></label></div>
            <p className="form-note">Email và ảnh đại diện chỉ xem, không thay đổi trong thao tác này.</p>
            <div className="modal-actions"><button type="submit" className="button primary" disabled={busy}>Lưu thông tin</button></div>
          </form> : <DetailGrid record={{ email: details.user.email, full_name: details.user.fullName, phone: details.user.phone, gender: details.user.gender, birth_year: details.user.birthYear, created_at: details.user.createdAt, updated_at: details.user.updatedAt }} />}
        </section>

        <section className="drawer-section">
          <div className="drawer-section-heading"><h3>Gói hiện tại</h3><StatusBadge value={details.membership.status} /></div>
          <DetailGrid record={{ plan_code: planLabel(details.membership.planCode), source: details.membership.source, starts_at: details.membership.startsAt, ends_at: details.membership.endsAt }} />
        </section>

        <section className="drawer-section">
          <h3>Tình hình sức khỏe · Bản thân</h3>
          {details.health.subject && <DetailGrid record={details.health.subject} />}
          <DetailBlock title="Hồ sơ sức khỏe" record={details.health.profile} />
          <DetailBlock title="Lối sống" record={details.health.lifestyle} />
          <DetailCollection title="Mục tiêu" records={details.health.goals} />
          <DetailCollection title="Tình trạng sức khỏe" records={details.health.conditions} />
          <DetailCollection title="Dị ứng" records={details.health.allergies} />
          <DetailCollection title="Điều trị" records={details.health.treatments} />
          <DetailCollection title="Khảo sát" records={details.health.surveyAnswers} />
        </section>
      </>}
    </div>
  </Drawer>;
}

const detailLabels: Record<string, string> = {
  email: 'Email', full_name: 'Họ và tên', phone: 'Số điện thoại', gender: 'Giới tính', birth_year: 'Năm sinh',
  created_at: 'Ngày tạo', updated_at: 'Cập nhật gần nhất', display_name: 'Tên hiển thị', relationship: 'Mối quan hệ',
  occupation: 'Nghề nghiệp', height_cm: 'Chiều cao (cm)', weight_kg: 'Cân nặng (kg)', bmi: 'BMI', blood_pressure: 'Huyết áp', blood_sugar: 'Đường huyết',
  skip_breakfast: 'Bỏ bữa sáng', eat_late: 'Ăn muộn', eat_sweet: 'Ăn ngọt', eat_oily: 'Ăn nhiều dầu mỡ', low_vegetable: 'Ít rau', low_water: 'Uống ít nước',
  fast_food: 'Đồ ăn nhanh', alcohol: 'Rượu bia', coffee_high: 'Nhiều cà phê', sleep_quality: 'Chất lượng giấc ngủ', activity_level: 'Mức độ vận động', water_per_day: 'Nước mỗi ngày',
  goal_code: 'Mã mục tiêu', goal_name: 'Mục tiêu', is_active: 'Đang áp dụng', condition_code: 'Mã tình trạng', condition_name: 'Tình trạng', severity_level: 'Mức độ',
  allergy_name: 'Tên dị ứng', note: 'Ghi chú', treatment_name: 'Tên điều trị', medication_name: 'Tên thuốc', question_code: 'Câu hỏi', answer_value: 'Câu trả lời',
  plan_code: 'Gói', source: 'Nguồn cấp', starts_at: 'Bắt đầu', ends_at: 'Hết hạn',
};

function DetailBlock({ title, record }: { title: string; record?: Record<string, unknown> }) {
  if (!record || Object.keys(record).length === 0) return <div className="detail-card"><strong>{title}</strong><p className="muted">Chưa có dữ liệu.</p></div>;
  return <div className="detail-card"><strong>{title}</strong><DetailGrid record={record} /></div>;
}

function DetailCollection({ title, records }: { title: string; records: Array<Record<string, unknown>> }) {
  return <div className="detail-card"><strong>{title}</strong>{records.length === 0 ? <p className="muted">Chưa có dữ liệu.</p> : <div className="detail-list">{records.map((record, index) => <DetailGrid key={`${title}-${index}`} record={record} />)}</div>}</div>;
}

function DetailGrid({ record }: { record: Record<string, unknown> }) {
  const entries = Object.entries(record).filter(([key, value]) => !['id', 'user_id', 'subject_id', 'owner_user_id', 'created_at', 'updated_at'].includes(key) && value !== null && value !== undefined && value !== '');
  if (entries.length === 0) return <p className="muted">Chưa có dữ liệu.</p>;
  return <div className="detail-grid">{entries.map(([key, value]) => <div className="detail-item" key={key}><small>{detailLabels[key] ?? 'Thông tin'}</small><span>{formatDetailValue(key, value)}</span></div>)}</div>;
}

function formatDetailValue(key: string, value: unknown): string {
  if (typeof value === 'boolean') return value ? 'Có' : 'Không';
  if (typeof value === 'object') return safeDisplay(JSON.stringify(value));
  if (key.endsWith('_at') && typeof value === 'string') return formatDate(value);
  return safeDisplay(value);
}

function CreateAccountModal({ busy, onClose, onSubmit }: { busy: boolean; onClose: () => void; onSubmit: (input: { fullName: string; email: string; password: string; phone: string; reason: string }) => void }) {
  const [fullName, setFullName] = useState(''); const [email, setEmail] = useState(''); const [password, setPassword] = useState(''); const [phone, setPhone] = useState(''); const [reason, setReason] = useState(''); const [error, setError] = useState<string | null>(null);
  function submit(event: FormEvent) { event.preventDefault(); if (fullName.trim().length < 2 || !email.trim() || password.length < 8 || !reason.trim()) { setError('Nhập đủ họ tên, email, mật khẩu từ 8 ký tự và lý do.'); return; } onSubmit({ fullName, email, password, phone, reason }); }
  return <Modal title="Tạo tài khoản" onClose={onClose}><form onSubmit={submit}><div className="modal-body">{error && <div className="inline-alert danger">{error}</div>}<label className="field-label">Họ và tên<input className="input" value={fullName} onChange={(event) => setFullName(event.target.value)} autoFocus /></label><label className="field-label">Email<input className="input" type="email" value={email} onChange={(event) => setEmail(event.target.value)} /></label><label className="field-label">Mật khẩu tạm thời<input className="input" type="password" value={password} onChange={(event) => setPassword(event.target.value)} /></label><label className="field-label">Số điện thoại <span className="muted">(không bắt buộc)</span><input className="input" value={phone} onChange={(event) => setPhone(event.target.value)} /></label><label className="field-label">Lý do bắt buộc<textarea className="textarea" rows={3} value={reason} onChange={(event) => setReason(event.target.value)} /></label><p className="form-note">Mật khẩu chỉ gửi qua Edge Function bảo mật và không được hiển thị lại sau khi tạo.</p></div><div className="modal-actions"><button type="button" className="button secondary" onClick={onClose}>Hủy</button><button className="button primary" disabled={busy}><Plus size={16} /> {busy ? 'Đang tạo…' : 'Tạo tài khoản'}</button></div></form></Modal>;
}

function GrantMembershipModal({ user, busy, onClose, onSubmit }: { user: AdminWorkItem; busy: boolean; onClose: () => void; onSubmit: (input: { userId: string; planCode: 'plus' | 'family_plus'; startsAt: string; endsAt: string; reason: string }) => void }) {
  const [planCode, setPlanCode] = useState<'plus' | 'family_plus'>('plus'); const [months, setMonths] = useState('1'); const [reason, setReason] = useState(''); const [error, setError] = useState<string | null>(null);
  function submit(event: FormEvent) { event.preventDefault(); if (!reason.trim()) { setError('Cần nhập lý do cấp gói.'); return; } const starts = new Date(); const ends = new Date(starts); ends.setMonth(ends.getMonth() + Number(months)); onSubmit({ userId: user.id, planCode, startsAt: starts.toISOString(), endsAt: ends.toISOString(), reason }); }
  return <Modal title="Cấp gói thành viên" onClose={onClose}><form onSubmit={submit}><div className="modal-body">{error && <div className="inline-alert danger">{error}</div>}<div className="selected-account"><span className="avatar small">{(user.title[0] ?? 'U').toUpperCase()}</span><span><strong>{safeDisplay(user.title)}</strong><small>{safeDisplay(user.subtitle || user.id)}</small></span></div><label className="field-label">Gói dịch vụ<select className="input" value={planCode} onChange={(event) => setPlanCode(event.target.value as 'plus' | 'family_plus')}><option value="plus">Plus</option><option value="family_plus">FamilyPlus</option></select></label><label className="field-label">Thời hạn<select className="input" value={months} onChange={(event) => setMonths(event.target.value)}><option value="1">1 tháng</option><option value="3">3 tháng</option><option value="6">6 tháng</option><option value="12">12 tháng</option></select></label><label className="field-label">Lý do bắt buộc<textarea className="textarea" rows={3} value={reason} onChange={(event) => setReason(event.target.value)} /></label><p className="form-note"><CalendarClock size={15} /> Gói đang hoạt động trước đó sẽ được backend xử lý theo chính sách hiện hành.</p></div><div className="modal-actions"><button type="button" className="button secondary" onClick={onClose}>Hủy</button><button className="button primary" disabled={busy}><CalendarClock size={16} /> {busy ? 'Đang cập nhật…' : 'Xác nhận cấp gói'}</button></div></form></Modal>;
}

function BulkProvisionModal({ api, onClose, onComplete }: { api: import('../lib/admin-api').AdminApi; onClose: () => void; onComplete: (result: BulkProvisionResult) => Promise<void> }) {
  const [lines, setLines] = useState('');
  const [password, setPassword] = useState('');
  const [planCode, setPlanCode] = useState<'plus' | 'family_plus'>('plus');
  const [durationMonths, setDurationMonths] = useState<'1' | '3' | '6' | '12'>('1');
  const [reason, setReason] = useState('');
  const [confirmation, setConfirmation] = useState('');
  const [preview, setPreview] = useState<BulkProvisionPreview | null>(null);
  const [accounts, setAccounts] = useState<BulkProvisionInput['accounts']>([]);
  const [idempotencyKey, setIdempotencyKey] = useState('');
  const [issues, setIssues] = useState<BulkAccountLineIssue[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  function close() {
    setPassword('');
    setLines('');
    setConfirmation('');
    onClose();
  }

  async function previewAccounts(event: FormEvent) {
    event.preventDefault();
    const parsed = parseBulkAccountLines(lines);
    setIssues(parsed.issues);
    setError(null);
    if (parsed.issues.length > 0 || password.length < 8 || !reason.trim()) {
      if (password.length < 8) setError('Mật khẩu tạm thời cần ít nhất 8 ký tự.');
      else if (!reason.trim()) setError('Cần nhập lý do cho batch.');
      return;
    }

    const nextKey = idempotencyKey || makeIdempotencyKey('bulk-provision-accounts', 'accounts');
    setBusy(true);
    try {
      const nextAccounts = parsed.accounts;
      const nextPreview = await api.previewBulkProvision({
        accounts: nextAccounts,
        planCode,
        durationMonths: Number(durationMonths) as 1 | 3 | 6 | 12,
        reason: reason.trim(),
        idempotencyKey: nextKey,
      });
      setAccounts(nextAccounts);
      setIdempotencyKey(nextKey);
      setPreview(nextPreview);
      setConfirmation('');
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Chưa tạo được bản xem trước.');
    } finally {
      setBusy(false);
    }
  }

  async function execute() {
    if (!preview || !accounts.length || confirmation !== bulkConfirmationText(accounts.length)) return;
    setBusy(true);
    setError(null);
    try {
      const result = await api.executeBulkProvision({
        accounts,
        password,
        planCode,
        durationMonths: Number(durationMonths) as 1 | 3 | 6 | 12,
        reason: reason.trim(),
        idempotencyKey,
      }, preview.fingerprint);
      if (!result.success) {
        setError(result.message || 'Batch đã dừng giữa chừng. Hãy giữ nguyên mã thao tác để xử lý tiếp.');
        return;
      }
      setPassword('');
      await onComplete(result);
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Batch chưa hoàn tất. Hãy giữ nguyên mã thao tác để thử lại.');
    } finally {
      setBusy(false);
    }
  }

  function resetPreview() {
    setPreview(null);
    setConfirmation('');
    setError(null);
  }

  const newCount = preview?.rows.filter((row) => row.status === 'new').length ?? 0;
  const existingCount = preview?.rows.filter((row) => row.status === 'existing').length ?? 0;
  const preservedCount = preview?.rows.filter((row) => row.status === 'paid_preserved').length ?? 0;
  const expectedConfirmation = bulkConfirmationText(accounts.length);

  return <Modal title="Tạo nhanh nhiều tài khoản" onClose={close}>
    {!preview ? <form onSubmit={previewAccounts}>
      <div className="modal-body">
        {error && <div className="inline-alert danger">{error}</div>}
        {issues.length > 0 && <div className="inline-alert danger"><span>{issues.map((issue) => `${issue.index > 0 ? `Dòng ${issue.index}: ` : ''}${issue.message}`).join(' ')}</span></div>}
        <p className="modal-intro">Nhập mỗi dòng theo dạng <strong>email@gmail.com | Họ và tên</strong>. Chỉ Super Admin được dùng chức năng này, tối đa 100 tài khoản.</p>
        <label className="field-label">Danh sách tài khoản<textarea className="textarea code-input" rows={8} value={lines} onChange={(event) => { setLines(event.target.value); setIssues([]); setError(null); }} placeholder="nguoi.dung@gmail.com | Nguyễn Văn A" autoFocus /></label>
        <label className="field-label">Mật khẩu tạm thời chung<input className="input" type="password" value={password} onChange={(event) => setPassword(event.target.value)} autoComplete="new-password" /></label>
        <div className="form-grid two">
          <label className="field-label">Gói dịch vụ<select className="input" value={planCode} onChange={(event) => setPlanCode(event.target.value as 'plus' | 'family_plus')}><option value="plus">Plus</option><option value="family_plus">FamilyPlus</option></select></label>
          <label className="field-label">Thời hạn<select className="input" value={durationMonths} onChange={(event) => setDurationMonths(event.target.value as '1' | '3' | '6' | '12')}><option value="1">1 tháng</option><option value="3">3 tháng</option><option value="6">6 tháng</option><option value="12">12 tháng</option></select></label>
        </div>
        <label className="field-label">Lý do bắt buộc<textarea className="textarea" rows={3} value={reason} onChange={(event) => setReason(event.target.value)} placeholder="Ví dụ: Cấp gói theo danh sách được phê duyệt." /></label>
        <p className="form-note"><ShieldCheck size={15} /> Mật khẩu chỉ dùng cho tài khoản mới, không được ghi vào audit hoặc hiển thị lại. Tài khoản mới sẽ phải đổi mật khẩu ở lần đăng nhập đầu.</p>
      </div>
      <div className="modal-actions"><button type="button" className="button secondary" onClick={close}>Hủy</button><button className="button primary" disabled={busy}><UsersRound size={16} /> {busy ? 'Đang kiểm tra…' : 'Xem trước'}</button></div>
    </form> : <>
      <div className="modal-body">
        {error && <div className="inline-alert danger">{error}</div>}
        <p className="modal-intro">Bản xem trước đã xác định <strong>{preview.candidateCount} tài khoản</strong>. Gói <strong>{planLabel(planCode)}</strong>, thời hạn <strong>{durationMonths} tháng</strong>.</p>
        <div className="summary-strip"><div><span className="eyebrow">Tạo mới</span><strong>{newCount}</strong></div><div><span className="eyebrow">Đã có tài khoản</span><strong>{existingCount}</strong></div><div><span className="eyebrow">Giữ gói hiện tại</span><strong>{preservedCount}</strong></div></div>
        <div className="bulk-preview-list">{preview.rows.map((row) => <div className="bulk-preview-row" key={row.index}><span className="avatar small">{row.index}</span><span><strong>{accounts[row.index - 1]?.email ?? `Dòng ${row.index}`}</strong><small>{accounts[row.index - 1]?.fullName ?? ''}</small></span><span className="status-badge neutral">{row.status === 'new' ? 'Tạo mới' : row.status === 'existing' ? 'Cấp gói' : `Giữ ${planLabel(row.currentPlan)}`}</span></div>)}</div>
        <div className="inline-alert info">Tài khoản đã có Plus/FamilyPlus còn hạn sẽ không bị ghi đè. Nếu thao tác dừng giữa chừng, hãy dùng lại đúng mã thao tác hiện tại, không tạo batch mới.</div>
        <label className="field-label">Nhập để xác nhận: <strong>{expectedConfirmation}</strong><input className="input code-input" value={confirmation} onChange={(event) => setConfirmation(event.target.value)} autoFocus /></label>
      </div>
      <div className="modal-actions"><button type="button" className="button secondary" onClick={resetPreview}>Quay lại</button><button type="button" className="button primary" disabled={busy || confirmation !== expectedConfirmation} onClick={() => void execute()}><ShieldCheck size={16} /> {busy ? 'Đang xử lý…' : 'Tạo và cấp gói'}</button></div>
    </>}
  </Modal>;
}

const emptySession: AdminSession = { userId: '', roles: [], permissions: [], active: false, canUseUserApp: false };
