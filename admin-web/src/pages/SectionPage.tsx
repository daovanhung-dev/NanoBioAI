import { useCallback, useEffect, useRef, useState, type ChangeEvent } from 'react';
import { Download, FilePlus2, Filter, RefreshCw, Save, Wrench } from 'lucide-react';
import { useAdminAuth } from '../auth/AuthProvider';
import { EmptyState, ErrorState, LoadingState, ReasonDialog, StatusBadge, Toast } from '../components/Ui';
import { actionLabel, auditActionLabel, formatDate, formatMoney, safeDisplay, sectionTitle } from '../lib/labels';
import { canAdjustPoints, makeIdempotencyKey, type AdminMutation, type AdminSection, type AdminWorkItem } from '../types';

export function SectionPage({ section }: { section: Exclude<AdminSection, 'dashboard' | 'wellness-rewards'> }) {
  const { api, session } = useAdminAuth();
  const [items, setItems] = useState<AdminWorkItem[]>([]);
  const [reportExports, setReportExports] = useState<AdminWorkItem[]>([]);
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [selected, setSelected] = useState<{ item: AdminWorkItem; action: string; file?: File; idempotencyKey: string } | null>(null);
  const [adjustment, setAdjustment] = useState<{ item: AdminWorkItem; idempotencyKey: string } | null>(null);
  const [configEditor, setConfigEditor] = useState(false);
  const [mutationBusy, setMutationBusy] = useState(false);
  const mutationBusyRef = useRef(false);
  const proofInput = useRef<HTMLInputElement>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const [nextItems, nextExports] = await Promise.all([
        api.listSection(section, query),
        section === 'reports' ? api.listReportExports(query) : Promise.resolve([]),
      ]);
      setItems(nextItems);
      setReportExports(nextExports);
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Chưa tải được dữ liệu.');
    } finally {
      setLoading(false);
    }
  }, [api, query, section]);

  useEffect(() => { void load(); }, [load]);
  useEffect(() => {
    const listener = () => void load();
    window.addEventListener('admin:refresh', listener);
    return () => window.removeEventListener('admin:refresh', listener);
  }, [load]);

  if (!session) return null;
  const isReadOnly = section === 'audit';
  const showConfig = section === 'plans' || section === 'config';

  async function confirmAction(reason: string, flags: { transferVerified: boolean; externalConfirmed: boolean }) {
    if (!selected || mutationBusyRef.current) return;
    const { item, action, file } = selected;
    mutationBusyRef.current = true; setMutationBusy(true);
    try {
      let paymentProofPath: string | undefined;
      if (action === 'mark_paid') {
        if (!file) throw new Error('Bạn cần chọn ảnh xác nhận chi trả.');
        paymentProofPath = await api.uploadPayoutProof(item.id, file);
      }
      const mutation: AdminMutation = {
        section,
        action,
        targetId: item.id,
        reason,
        idempotencyKey: selected.idempotencyKey,
        payload: { transferVerified: flags.transferVerified, paymentProofPath },
      };
      const result = await api.runMutation(mutation);
      setSelected(null);
      setToast(result.message || 'Đã cập nhật.');
      await load();
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Thao tác chưa hoàn tất.');
    } finally { mutationBusyRef.current = false; setMutationBusy(false); }
  }

  async function confirmAdjustment(reason: string, points: number) {
    if (!adjustment || !Number.isFinite(points) || points === 0) return;
    try {
      const result = await api.runMutation({ section: 'sale-conversions', action: 'adjust_points', targetId: String(adjustment.item.metadata.sale_user_id ?? adjustment.item.id), reason, idempotencyKey: adjustment.idempotencyKey, payload: { pointDeltaCents: points } });
      setAdjustment(null);
      setToast(result.message || 'Đã ghi điều chỉnh điểm.');
      await load();
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Thao tác chưa hoàn tất.');
    }
  }

  function requestAction(item: AdminWorkItem, action: string) {
    if (action === 'mark_paid') {
      if (proofInput.current) {
        proofInput.current.dataset.itemId = item.id;
        proofInput.current.click();
      }
      return;
    }
    setSelected({ item, action, idempotencyKey: makeIdempotencyKey(action, item.id) });
  }

  function handleProof(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0];
    const itemId = proofInput.current?.dataset.itemId;
    const item = items.find((candidate) => candidate.id === itemId);
    if (file && item) setSelected({ item, action: 'mark_paid', file, idempotencyKey: makeIdempotencyKey('mark-paid', item.id) });
    event.target.value = '';
  }

  return (
    <div className="page-stack">
      <input ref={proofInput} type="file" accept="image/jpeg,image/png" hidden onChange={handleProof} />
      <section className="page-heading">
        <div><span className="eyebrow">Khu vực có quyền hạn riêng</span><h1>{sectionTitle(section)}</h1><p>{sectionDescription(section)}</p></div>
        <div className="heading-actions"><button className="button secondary" onClick={() => void load()} disabled={loading}><RefreshCw size={16} /> Làm mới</button>{showConfig && <button className="button primary" onClick={() => setConfigEditor(true)}><FilePlus2 size={16} /> Tạo phiên bản</button>}{section === 'reconciliation' && <button className="button primary" onClick={() => setSelected({ item: { id: 'payments', title: 'Đối soát thanh toán', subtitle: '', status: 'open', section, metadata: {} }, action: 'create_run', idempotencyKey: makeIdempotencyKey('create-reconciliation', 'payments') })}><Wrench size={16} /> Bắt đầu đối soát</button>}</div>
      </section>
      <div className="filter-bar"><div className="search-field"><Filter size={17} /><input value={query} onChange={(event) => setQuery(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') void load(); }} placeholder={section === 'audit' ? 'Tìm hành động, đối tượng hoặc lý do…' : 'Tìm theo tên, email hoặc mã…'} aria-label="Tìm kiếm" /></div><button className="button secondary" onClick={() => void load()}>Tìm kiếm</button></div>
      {toast && <Toast message={toast} onClose={() => setToast(null)} />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {showConfig && configEditor && <ConfigEditor section={section} onClose={() => setConfigEditor(false)} onDone={(message) => { setConfigEditor(false); setToast(message); void load(); }} />}
      {loading && items.length === 0 ? <LoadingState /> : items.length === 0 ? <EmptyState title={query ? 'Không tìm thấy kết quả' : 'Chưa có việc cần xử lý'} message={query ? 'Hãy thử từ khóa ngắn hơn hoặc xóa nội dung tìm kiếm.' : 'Các mục mới sẽ xuất hiện tại đây khi có dữ liệu.'} /> : <ItemTable section={section} items={items} readOnly={isReadOnly} onAction={requestAction} onAdjust={(item) => setAdjustment({ item, idempotencyKey: makeIdempotencyKey('adjust-points', item.id) })} allowAdjust={section === 'sale-conversions' && canAdjustPoints(session)} />}
      {section === 'reports' && <ReportExports items={reportExports} />}
      {selected && <ReasonDialog action={selected.action} subject={selected.item.title} requireTransferVerification={section === 'payments' && selected.action === 'approve'} onCancel={() => setSelected(null)} onConfirm={(reason, flags) => void confirmAction(reason, flags)} busy={mutationBusy} />}
      {adjustment && <AdjustmentDialog item={adjustment.item} onCancel={() => setAdjustment(null)} onConfirm={(reason, points) => void confirmAdjustment(reason, points)} />}
    </div>
  );
}

function ItemTable({ section, items, readOnly, allowAdjust, onAction, onAdjust }: { section: AdminSection; items: AdminWorkItem[]; readOnly: boolean; allowAdjust: boolean; onAction: (item: AdminWorkItem, action: string) => void; onAdjust: (item: AdminWorkItem) => void }) {
  return <div className="table-card"><div className="table-scroll"><table><thead><tr><th>Thông tin</th><th>Trạng thái</th><th>Thời gian</th><th className="action-column">Thao tác</th></tr></thead><tbody>{items.map((item) => <tr key={item.id}><td><div className="item-title">{section === 'audit' ? auditActionLabel(item.title) : item.title}</div><div className="item-subtitle">{section === 'audit' ? item.subtitle : detailSubtitle(item, section)}</div></td><td><StatusBadge value={item.status} /></td><td className="nowrap">{formatDate(item.createdAt)}</td><td className="action-cell">{readOnly ? <span className="muted">Chỉ xem</span> : <ActionList section={section} item={item} allowAdjust={allowAdjust} onAction={onAction} onAdjust={onAdjust} />}</td></tr>)}</tbody></table></div></div>;
}

function ActionList({ section, item, allowAdjust, onAction, onAdjust }: { section: AdminSection; item: AdminWorkItem; allowAdjust: boolean; onAction: (item: AdminWorkItem, action: string) => void; onAdjust: (item: AdminWorkItem) => void }) {
  const actions = availableActions(section, item.status, allowAdjust);
  if (actions.length === 0) return <span className="muted">Không có thao tác</span>;
  return <div className="action-list">{actions.map((action) => <button key={action} className={`text-action ${['reject', 'cancel', 'close', 'refund', 'chargeback'].includes(action) ? 'danger-text' : ''}`} onClick={() => action === 'adjust_points' ? onAdjust(item) : onAction(item, action)}>{actionLabel(action)}</button>)}</div>;
}

function availableActions(section: AdminSection, status: string, allowAdjust: boolean): string[] {
  const normalized = status.toLowerCase();
  const has = (token: string) => normalized === token || new RegExp(`(^|[_-])${token}($|[_-])`).test(normalized);
  if (section === 'users') return has('active') ? ['suspended'] : has('suspended') ? ['active'] : [];
  if (section === 'payments') {
    if (has('pending')) return ['approve', 'reject'];
    if (has('succeeded')) return ['refund', 'cancel'];
    return [];
  }
  if (section === 'sales') return has('pending') || has('requested') ? ['approve', 'reject'] : has('active') ? ['suspend', 'close'] : has('suspended') ? ['approve', 'close'] : [];
  if (section === 'sale-conversions') {
    const actions = has('approved') ? ['mark_paid'] : has('pending') || has('requested') ? ['approve', 'reject'] : [];
    return allowAdjust ? [...actions, 'adjust_points'] : actions;
  }
  if (section === 'reconciliation') return has('open') || has('follow') ? ['resolved', 'needs_follow_up', 'adjusted', 'dismissed'] : [];
  if (section === 'reports') return has('available') ? ['export'] : [];
  return [];
}

function detailSubtitle(item: AdminWorkItem, section: AdminSection): string {
  const reconciliation = item.paymentReconciliation;
  if (section === 'payments' && reconciliation) return `${safeDisplay(reconciliation.payerFullName)} · ${formatMoney(reconciliation.amountCents, reconciliation.currency ?? 'VND')} · ${safeDisplay(reconciliation.transferReference)}`;
  if (section === 'sale-conversions') return `${safeDisplay(item.metadata.bank_name)} · ${maskAccount(item.metadata.bank_account_number)} · ${formatMoney(number(item.metadata.money_amount_cents), String(item.metadata.currency ?? 'VND'))}`;
  if (section === 'audit') return item.subtitle;
  return item.subtitle || item.id;
}

function ReportExports({ items }: { items: AdminWorkItem[] }) {
  return <section className="panel report-history"><div className="panel-heading"><div><span className="eyebrow">Theo dõi yêu cầu</span><h2>Lịch sử xuất báo cáo</h2></div><Download size={19} className="panel-icon" /></div>{items.length === 0 ? <p className="muted">Chưa có yêu cầu xuất báo cáo.</p> : <div className="mini-list">{items.map((item) => <div className="mini-row" key={item.id}><span><strong>{item.title}</strong><small>{item.subtitle}</small></span><span><StatusBadge value={item.status} /><small>{formatDate(item.createdAt)}</small></span></div>)}</div>}</section>;
}

function ConfigEditor({ section, onClose, onDone }: { section: 'plans' | 'config'; onClose: () => void; onDone: (message: string) => void }) {
  const { api } = useAdminAuth();
  const [key, setKey] = useState(section === 'plans' ? 'plan_' : '');
  const [value, setValue] = useState('{\n  \n}');
  const [reason, setReason] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [review, setReview] = useState<{ key: string; value: Record<string, unknown>; reason: string; idempotencyKey: string } | null>(null);
  async function save() {
    if (!key.trim() || !reason.trim()) { setError('Cần nhập khóa thiết lập và lý do.'); return; }
    let parsed: unknown;
    try { parsed = JSON.parse(value); } catch { setError('Nội dung thiết lập chưa đúng định dạng.'); return; }
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) { setError('Giá trị thiết lập cần là một object JSON.'); return; }
    if (/(secret|password|token|api[_-]?key|service[_-]?role|database[_-]?url|gemini)/i.test(JSON.stringify(parsed))) { setError('Không thể đưa thông tin bí mật vào thiết lập vận hành.'); return; }
    setReview({ key: key.trim(), value: parsed as Record<string, unknown>, reason: reason.trim(), idempotencyKey: makeIdempotencyKey('config-upsert', key.trim()) });
  }
  async function confirmSave(confirmedReason: string) {
    if (!review || busy) return;
    setBusy(true); setError(null);
    try {
      const result = await api.runMutation({ section, action: 'upsert', targetId: review.key, reason: confirmedReason, idempotencyKey: review.idempotencyKey, payload: { configValue: review.value } });
      setReview(null);
      onDone(result.message || 'Đã lưu phiên bản.');
    } catch (nextError) { setError(nextError instanceof Error ? nextError.message : 'Chưa lưu được thiết lập.'); } finally { setBusy(false); }
  }
  return <><div className="panel inline-editor"><div className="panel-heading"><div><span className="eyebrow">Phiên bản mới</span><h2>{section === 'plans' ? 'Cập nhật gói dịch vụ' : 'Cập nhật thiết lập'}</h2></div><button className="icon-button" onClick={onClose} aria-label="Đóng">×</button></div>{error && <div className="inline-alert danger">{error}</div>}<label className="field-label">Khóa thiết lập<input className="input" value={key} onChange={(event) => setKey(event.target.value)} placeholder="Ví dụ: plan_plus" /></label><label className="field-label">Giá trị JSON<textarea className="textarea code-input" rows={7} value={value} onChange={(event) => setValue(event.target.value)} /></label><label className="field-label">Lý do<input className="input" value={reason} onChange={(event) => setReason(event.target.value)} placeholder="Nhập lý do cập nhật" /></label><div className="modal-actions"><button className="button secondary" onClick={onClose}>Hủy</button><button className="button primary" disabled={busy} onClick={() => void save()}><Save size={16} /> Xem lại</button></div></div>{review && <ReasonDialog action="upsert" subject={review.key} initialReason={review.reason} onCancel={() => setReview(null)} onConfirm={(confirmedReason) => void confirmSave(confirmedReason)} busy={busy} />}</>;
}

function AdjustmentDialog({ item, onCancel, onConfirm }: { item: AdminWorkItem; onCancel: () => void; onConfirm: (reason: string, points: number) => void }) {
  const [reason, setReason] = useState('');
  const [points, setPoints] = useState('');
  return <div className="modal-backdrop"><section className="modal" role="dialog" aria-modal="true"><div className="modal-header"><h2>Điều chỉnh điểm</h2><button className="icon-button" onClick={onCancel} aria-label="Đóng">×</button></div><div className="modal-body"><p className="modal-intro">Thao tác này tạo một điều chỉnh mới và không ghi đè lịch sử điểm.</p><label className="field-label">Số điểm (+/-)<input className="input" type="number" value={points} onChange={(event) => setPoints(event.target.value)} placeholder="Ví dụ: 500000" /></label><label className="field-label">Lý do<input className="input" value={reason} onChange={(event) => setReason(event.target.value)} placeholder="Nhập lý do bắt buộc" /></label></div><div className="modal-actions"><button className="button secondary" onClick={onCancel}>Hủy</button><button className="button primary" disabled={!reason.trim() || !Number(points)} onClick={() => onConfirm(reason.trim(), Number(points))}>Xác nhận</button></div></section></div>;
}

function sectionDescription(section: AdminSection): string {
  return ({
    users: 'Tìm kiếm và quản lý trạng thái tài khoản người dùng.',
    payments: 'Đối chiếu giao dịch trước khi duyệt hoặc từ chối.',
    sales: 'Xử lý hồ sơ và trạng thái hoạt động của cộng tác viên.',
    'sale-conversions': 'Kiểm tra yêu cầu quy đổi và xác nhận việc chi trả.',
    reconciliation: 'Theo dõi sai lệch và ghi nhận kết quả đối soát.',
    plans: 'Quản lý các gói dịch vụ đang áp dụng.',
    reports: 'Tạo và theo dõi yêu cầu xuất báo cáo.',
    audit: 'Xem lại các thao tác quan trọng đã được ghi nhận.',
    config: 'Cập nhật thiết lập vận hành theo phạm vi được cấp.',
    dashboard: '',
    'wellness-rewards': '',
  } satisfies Record<AdminSection, string>)[section];
}

function maskAccount(value: unknown): string {
  const text = String(value ?? '');
  if (text.length < 5) return text ? '••••' : '—';
  return `${'•'.repeat(Math.max(0, text.length - 4))}${text.slice(-4)}`;
}

function number(value: unknown): number | undefined {
  const result = Number(value);
  return Number.isFinite(result) ? result : undefined;
}
