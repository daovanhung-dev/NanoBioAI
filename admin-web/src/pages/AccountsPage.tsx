import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { CalendarClock, KeyRound, Plus, RefreshCw, UserRoundPlus } from 'lucide-react';
import { useSearchParams } from 'react-router-dom';
import { useAdminAuth } from '../auth/AuthProvider';
import { EmptyState, ErrorState, LoadingState, Modal, ReasonDialog, StatusBadge, Toast } from '../components/Ui';
import { formatDate, planLabel, safeDisplay } from '../lib/labels';
import { canCreateAccount, canGrantMembership, makeIdempotencyKey, type AdminSession, type AdminWorkItem } from '../types';

type AccountAction = { item: AdminWorkItem; action: 'active' | 'suspended' };

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
  const [membershipUser, setMembershipUser] = useState<AdminWorkItem | null>(null);
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
        </div>
      </section>
      <section className="summary-strip"><div><span className="eyebrow">Trong kết quả hiện tại</span><strong>{items.length} tài khoản</strong></div><div><span className="eyebrow">Đang hoạt động</span><strong>{activeCount}</strong></div><div><span className="eyebrow">Quyền cấp gói</span><strong>{canUpgrade ? 'Super Admin' : 'Chỉ xem'}</strong></div></section>
      <div className="filter-bar"><div className="search-field"><KeyRound size={17} /><input value={query} onChange={(event) => setQuery(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') void load(); }} placeholder="Tìm theo tên, email hoặc mã tài khoản…" aria-label="Tìm kiếm tài khoản" /></div><button className="button secondary" onClick={() => void load()}>Tìm kiếm</button></div>
      {toast && <Toast message={toast} onClose={() => setToast(null)} />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {loading && items.length === 0 ? <LoadingState /> : items.length === 0 ? <EmptyState title={query ? 'Không tìm thấy tài khoản' : 'Chưa có tài khoản'} message="Thử một từ khóa khác hoặc tải lại dữ liệu." /> : <AccountTable items={items} canUpgrade={canUpgrade} canWrite={canWrite} onStatus={setSelected} onMembership={setMembershipUser} />}
      {selected && <ReasonDialog action={selected.action} subject={selected.item.title} onCancel={() => setSelected(null)} onConfirm={(reason) => void updateStatus(selected, reason)} busy={busy} />}
      {createOpen && <CreateAccountModal busy={busy} onClose={() => setCreateOpen(false)} onSubmit={(input) => { setCreateOpen(false); setCreatePending({ ...input, idempotencyKey: makeIdempotencyKey('create-account', input.email) }); }} />}
      {membershipUser && <GrantMembershipModal user={membershipUser} busy={busy} onClose={() => setMembershipUser(null)} onSubmit={(input) => { setMembershipUser(null); setMembershipPending({ ...input, idempotencyKey: makeIdempotencyKey('grant-membership', input.userId) }); }} />}
      {createPending && <ReasonDialog action="create_account" subject={createPending.email} initialReason={createPending.reason} onCancel={() => setCreatePending(null)} onConfirm={(reason) => void createAccount({ ...createPending, reason })} busy={busy} />}
      {membershipPending && <ReasonDialog action="grant_membership" subject={membershipPending.userId} initialReason={membershipPending.reason} onCancel={() => setMembershipPending(null)} onConfirm={(reason) => void grantMembership({ ...membershipPending, reason })} busy={busy} />}
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
}

function AccountTable({ items, canWrite, canUpgrade, onStatus, onMembership }: { items: AdminWorkItem[]; canWrite: boolean; canUpgrade: boolean; onStatus: (value: AccountAction) => void; onMembership: (item: AdminWorkItem) => void }) {
  return <div className="table-card"><div className="table-scroll"><table><thead><tr><th>Tài khoản</th><th>Trạng thái</th><th>Gói hiện tại</th><th>Hoạt động gần nhất</th><th className="action-column">Thao tác</th></tr></thead><tbody>{items.map((item) => {
    const normalized = item.status.toLowerCase();
    const has = (token: string) => normalized === token || new RegExp(`(^|[_-])${token}($|[_-])`).test(normalized);
    const nextStatus: AccountAction['action'] | null = has('active') ? 'suspended' : has('suspended') ? 'active' : null;
    return <tr key={item.id}><td><div className="item-title">{safeDisplay(item.title)}</div><div className="item-subtitle">{safeDisplay(item.subtitle || item.id)}</div></td><td><StatusBadge value={item.status} /></td><td>{planLabel(item.metadata.plan_code ?? item.metadata.plan_name)}</td><td className="nowrap">{formatDate(item.createdAt)}</td><td className="action-cell"><div className="action-list">{canWrite && nextStatus && <button className={`text-action ${nextStatus === 'suspended' ? 'danger-text' : ''}`} onClick={() => onStatus({ item, action: nextStatus })}>{nextStatus === 'suspended' ? 'Tạm khóa' : 'Mở lại'}</button>}{canUpgrade && <button className="text-action" onClick={() => onMembership(item)}>Cấp gói</button>}{!canWrite && !canUpgrade && <span className="muted">Chỉ xem</span>}</div></td></tr>;
  })}</tbody></table></div></div>;
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

const emptySession: AdminSession = { userId: '', roles: [], permissions: [], active: false, canUseUserApp: false };
