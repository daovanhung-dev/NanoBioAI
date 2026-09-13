import { FormEvent, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { Gift, Import, Plus, RefreshCw, ShieldAlert, Tag } from 'lucide-react';
import { useAdminAuth } from '../auth/AuthProvider';
import { EmptyState, ErrorState, LoadingState, Modal, ReasonDialog, StatusBadge, Toast } from '../components/Ui';
import { formatDate, safeDisplay } from '../lib/labels';
import { hasPermission, makeIdempotencyKey, PERMISSIONS, type AdminSession, type AdminWorkItem, type RewardOfferInput } from '../types';

type PendingAction =
  | { kind: 'offer'; input: Omit<RewardOfferInput, 'reason' | 'idempotencyKey'>; reason: string; idempotencyKey: string }
  | { kind: 'import'; offerId: string; codes: string[]; expiresAt: string; reason: string; idempotencyKey: string }
  | { kind: 'cancel'; redemptionId: string; subject: string; idempotencyKey: string };

export function WellnessRewardsPage() {
  const { api, session } = useAdminAuth();
  const [items, setItems] = useState<AdminWorkItem[]>([]);
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [offerOpen, setOfferOpen] = useState(false);
  const [editingOffer, setEditingOffer] = useState<AdminWorkItem | null>(null);
  const [importOpen, setImportOpen] = useState(false);
  const [pending, setPending] = useState<PendingAction | null>(null);
  const [busy, setBusy] = useState(false);
  const busyRef = useRef(false);

  const canWrite = hasPermission(session ?? emptySession, PERMISSIONS.wellnessRewardsWrite);
  const load = useCallback(async () => {
    setLoading(true); setError(null);
    try { setItems(await api.listSection('wellness-rewards', query)); }
    catch (nextError) { setError(nextError instanceof Error ? nextError.message : 'Chưa tải được dữ liệu ưu đãi.'); }
    finally { setLoading(false); }
  }, [api, query]);

  useEffect(() => { void load(); }, [load]);
  useEffect(() => {
    const listener = () => void load();
    window.addEventListener('admin:refresh', listener);
    return () => window.removeEventListener('admin:refresh', listener);
  }, [load]);

  const offers = useMemo(() => items.filter((item) => !item.metadata.redemption_id && !item.metadata.redemptionId), [items]);
  if (!session) return null;
  return (
    <div className="page-stack">
      <section className="page-heading">
        <div><span className="eyebrow">Ưu đãi & mã sử dụng</span><h1>Điểm chăm sóc</h1><p>Quản lý ưu đãi, kho mã và các lượt sử dụng theo chính sách vận hành.</p></div>
        <div className="heading-actions"><button className="button secondary" onClick={() => void load()} disabled={loading}><RefreshCw size={16} /> Làm mới</button>{canWrite && <><button className="button secondary" onClick={() => setImportOpen(true)}><Import size={16} /> Nhập mã</button><button className="button primary" onClick={() => setOfferOpen(true)}><Plus size={16} /> Tạo ưu đãi</button></>}</div>
      </section>
      {!canWrite && <div className="inline-alert info"><ShieldAlert size={17} /> Vai trò hiện tại chỉ được xem. Thay đổi ưu đãi cần quyền Content Admin hoặc Super Admin.</div>}
      <div className="filter-bar"><div className="search-field"><Tag size={17} /><input value={query} onChange={(event) => setQuery(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') void load(); }} placeholder="Tìm theo tên ưu đãi, nhà cung cấp hoặc trạng thái…" aria-label="Tìm kiếm ưu đãi" /></div><button className="button secondary" onClick={() => void load()}>Tìm kiếm</button></div>
      {toast && <Toast message={toast} onClose={() => setToast(null)} />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {loading && items.length === 0 ? <LoadingState /> : items.length === 0 ? <EmptyState title="Chưa có ưu đãi" message="Các ưu đãi và lượt sử dụng sẽ xuất hiện khi backend trả về dữ liệu." /> : <RewardsTable items={items} canWrite={canWrite} onEdit={(item) => { setEditingOffer(item); setOfferOpen(true); }} onCancel={(redemptionId, subject) => setPending({ kind: 'cancel', redemptionId, subject, idempotencyKey: makeIdempotencyKey('reward-cancel', redemptionId) })} />}
      {offerOpen && <OfferModal existing={editingOffer} onClose={() => { setOfferOpen(false); setEditingOffer(null); }} onSubmit={(input) => { setOfferOpen(false); setEditingOffer(null); const { reason, ...offerInput } = input; setPending({ kind: 'offer', input: offerInput, reason, idempotencyKey: makeIdempotencyKey('reward-offer', offerInput.offerId ?? offerInput.title) }); }} />}
      {importOpen && <ImportCodesModal offers={offers} onClose={() => setImportOpen(false)} onSubmit={(input) => { setImportOpen(false); setPending({ kind: 'import', ...input, idempotencyKey: makeIdempotencyKey('reward-import', input.offerId) }); }} />}
      {pending && <ReasonDialog action={pending.kind === 'offer' ? 'upsert' : pending.kind === 'import' ? 'import_codes' : 'cancel_redemption'} subject={pending.kind === 'cancel' ? pending.subject : pending.kind === 'offer' ? pending.input.title : `${pending.codes.length} mã ưu đãi`} initialReason={pending.kind === 'cancel' ? '' : pending.reason} requireExternalConfirmation={pending.kind === 'cancel'} onCancel={() => setPending(null)} onConfirm={(reason) => void executePending(reason)} busy={busy} />}
    </div>
  );

  async function executePending(reason: string) {
    if (!pending || busyRef.current) return;
    busyRef.current = true; setBusy(true); setError(null);
    try {
      let result;
      if (pending.kind === 'offer') result = await api.upsertRewardOffer({ ...pending.input, reason, idempotencyKey: pending.idempotencyKey });
      else if (pending.kind === 'import') result = await api.importRewardCodes(pending.offerId, pending.codes, pending.expiresAt, reason, pending.idempotencyKey);
      else result = await api.cancelRewardRedemption(pending.redemptionId, reason, pending.idempotencyKey);
      setPending(null); setToast(result.message || 'Đã cập nhật.'); await load();
    } catch (nextError) { setError(nextError instanceof Error ? nextError.message : 'Thao tác chưa hoàn tất.'); }
    finally { busyRef.current = false; setBusy(false); }
  }
}

function RewardsTable({ items, canWrite, onEdit, onCancel }: { items: AdminWorkItem[]; canWrite: boolean; onEdit: (item: AdminWorkItem) => void; onCancel: (redemptionId: string, subject: string) => void }) {
  return <div className="table-card"><div className="table-scroll"><table><thead><tr><th>Ưu đãi / lượt sử dụng</th><th>Nhà cung cấp</th><th>Trạng thái</th><th>Thời gian</th><th className="action-column">Thao tác</th></tr></thead><tbody>{items.map((item) => {
    const redemptionId = String(item.metadata.redemption_id ?? item.metadata.redemptionId ?? '');
    return <tr key={item.id}><td><div className="item-title">{safeDisplay(item.title)}</div><div className="item-subtitle">{safeDisplay(item.subtitle || item.metadata.offer_title, item.id)}</div></td><td>{safeDisplay(item.metadata.provider_name ?? item.metadata.provider)}</td><td><StatusBadge value={item.status} /></td><td className="nowrap">{formatDate(item.createdAt)}</td><td className="action-cell">{canWrite && redemptionId && !['cancelled', 'canceled', 'revoked'].includes(item.status.toLowerCase()) ? <button className="text-action danger-text" onClick={() => onCancel(redemptionId, item.title)}>Hủy lượt dùng</button> : canWrite && !redemptionId ? <button className="text-action" onClick={() => onEdit(item)}>Chỉnh sửa</button> : <span className="muted">{redemptionId ? 'Không có thao tác' : 'Chỉ xem'}</span>}</td></tr>;
  })}</tbody></table></div></div>;
}

function OfferModal({ existing, onClose, onSubmit }: { existing: AdminWorkItem | null; onClose: () => void; onSubmit: (input: Omit<RewardOfferInput, 'reason' | 'idempotencyKey'> & { reason: string }) => void }) {
  const [title, setTitle] = useState(existing?.title ?? ''); const [description, setDescription] = useState(String(existing?.metadata.description ?? '')); const [providerName, setProviderName] = useState(String(existing?.metadata.provider_name ?? '')); const [costPoints, setCostPoints] = useState(String(existing?.metadata.cost_points ?? '')); const [eligible, setEligible] = useState((existing?.metadata.eligible_plan_codes as string[] | undefined)?.join(', ') || 'plus, family_plus'); const [availableFrom, setAvailableFrom] = useState(toLocalInput(existing?.metadata.available_from)); const [availableUntil, setAvailableUntil] = useState(toLocalInput(existing?.metadata.available_until)); const [expires, setExpires] = useState(toLocalInput(existing?.metadata.voucher_expires_at)); const [isActive, setIsActive] = useState(existing?.status.toLowerCase() === 'active' || !existing); const [reason, setReason] = useState(''); const [error, setError] = useState<string | null>(null);
  function submit(event: FormEvent) { event.preventDefault(); const cost = Number(costPoints); const from = toIso(availableFrom); const until = toIso(availableUntil); if (!title.trim() || !description.trim() || !providerName.trim() || !Number.isInteger(cost) || cost <= 0 || !reason.trim() || (from && until && new Date(until) <= new Date(from))) { setError('Nhập đủ thông tin, điểm là số nguyên dương và khoảng thời gian hợp lệ.'); return; } onSubmit({ title, description, providerName, costPoints: cost, eligiblePlanCodes: eligible.split(',').map((value) => value.trim()).filter(Boolean), availableFrom: from || undefined, availableUntil: until || undefined, voucherExpiresAt: toIso(expires) || undefined, isActive, reason }); }
  return <Modal title={existing ? 'Cập nhật ưu đãi Điểm chăm sóc' : 'Tạo ưu đãi Điểm chăm sóc'} onClose={onClose}><form onSubmit={submit}><div className="modal-body">{error && <div className="inline-alert danger">{error}</div>}<label className="field-label">Tên ưu đãi<input className="input" value={title} onChange={(event) => setTitle(event.target.value)} autoFocus /></label><label className="field-label">Mô tả<textarea className="textarea" rows={3} value={description} onChange={(event) => setDescription(event.target.value)} /></label><div className="form-grid two"><label className="field-label">Nhà cung cấp<input className="input" value={providerName} onChange={(event) => setProviderName(event.target.value)} /></label><label className="field-label">Chi phí điểm<input className="input" type="number" min="1" step="1" value={costPoints} onChange={(event) => setCostPoints(event.target.value)} /></label></div><label className="field-label">Gói được dùng <span className="muted">(phân tách bằng dấu phẩy)</span><input className="input" value={eligible} onChange={(event) => setEligible(event.target.value)} /></label><div className="form-grid two"><label className="field-label">Bắt đầu hiển thị<input className="input" type="datetime-local" value={availableFrom} onChange={(event) => setAvailableFrom(event.target.value)} /></label><label className="field-label">Kết thúc hiển thị<input className="input" type="datetime-local" value={availableUntil} onChange={(event) => setAvailableUntil(event.target.value)} /></label></div><label className="field-label">Mã hết hạn lúc <input className="input" type="datetime-local" value={expires} onChange={(event) => setExpires(event.target.value)} /></label><label className="check-row"><input type="checkbox" checked={isActive} onChange={(event) => setIsActive(event.target.checked)} /> Cho phép hiển thị và sử dụng</label><label className="field-label">Lý do bắt buộc<textarea className="textarea" rows={2} value={reason} onChange={(event) => setReason(event.target.value)} /></label><p className="form-note">Bạn sẽ xem lại và xác nhận lần cuối trước khi gửi thay đổi.</p></div><div className="modal-actions"><button type="button" className="button secondary" onClick={onClose}>Hủy</button><button className="button primary"><Gift size={16} /> Xem lại</button></div></form></Modal>;
}

function ImportCodesModal({ offers, onClose, onSubmit }: { offers: AdminWorkItem[]; onClose: () => void; onSubmit: (input: { offerId: string; codes: string[]; expiresAt: string; reason: string }) => void }) {
  const [offerId, setOfferId] = useState(offers[0]?.id ?? ''); const [codes, setCodes] = useState(''); const [expires, setExpires] = useState(''); const [reason, setReason] = useState(''); const [error, setError] = useState<string | null>(null);
  function submit(event: FormEvent) { event.preventDefault(); const values = codes.split(/\r?\n|,/).map((value) => value.trim()).filter(Boolean); if (!offerId || values.length === 0 || !toIso(expires) || !reason.trim()) { setError('Chọn ưu đãi, nhập mã, thời hạn và lý do.'); return; } onSubmit({ offerId, codes: values, expiresAt: toIso(expires), reason }); }
  return <Modal title="Nhập mã ưu đãi" onClose={onClose}><form onSubmit={submit}><div className="modal-body">{error && <div className="inline-alert danger">{error}</div>}{offers.length === 0 ? <EmptyState title="Chưa có ưu đãi để nhập mã" message="Tạo ưu đãi trước rồi quay lại nhập mã." /> : <><label className="field-label">Ưu đãi<select className="input" value={offerId} onChange={(event) => setOfferId(event.target.value)}>{offers.map((offer) => <option key={offer.id} value={offer.id}>{offer.title}</option>)}</select></label><label className="field-label">Danh sách mã <span className="muted">(mỗi dòng một mã)</span><textarea className="textarea code-input" rows={7} value={codes} onChange={(event) => setCodes(event.target.value)} /></label><label className="field-label">Mã hết hạn lúc<input className="input" type="datetime-local" value={expires} onChange={(event) => setExpires(event.target.value)} /></label><label className="field-label">Lý do bắt buộc<textarea className="textarea" rows={2} value={reason} onChange={(event) => setReason(event.target.value)} /></label><p className="form-note">Mã chỉ được thêm mới; không có thao tác sửa hoặc xóa file sau khi tải lên backend.</p></>}</div><div className="modal-actions"><button type="button" className="button secondary" onClick={onClose}>Hủy</button><button className="button primary" disabled={offers.length === 0}><Import size={16} /> Xem lại</button></div></form></Modal>;
}

function toIso(value: string): string {
  if (!value) return '';
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? '' : date.toISOString();
}

function toLocalInput(value: unknown): string {
  if (!value) return '';
  const date = new Date(String(value));
  if (Number.isNaN(date.getTime())) return '';
  const pad = (number: number) => String(number).padStart(2, '0');
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

const emptySession: AdminSession = { userId: '', roles: [], permissions: [], active: false, canUseUserApp: false };
