import { useState, type ReactNode } from 'react';
import { AlertTriangle, CheckCircle2, LoaderCircle, X } from 'lucide-react';
import { actionLabel, statusLabel } from '../lib/labels';

export function LoadingState({ label = 'Đang tải dữ liệu…' }: { label?: string }) {
  return (
    <div className="state-card" role="status">
      <LoaderCircle className="spin" size={22} aria-hidden="true" />
      <span>{label}</span>
    </div>
  );
}

export function EmptyState({ title, message, action }: { title: string; message: string; action?: ReactNode }) {
  return (
    <div className="state-card empty-state">
      <div className="state-icon soft-blue" aria-hidden="true">∅</div>
      <div>
        <strong>{title}</strong>
        <p>{message}</p>
        {action}
      </div>
    </div>
  );
}

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div className="state-card error-state" role="alert">
      <AlertTriangle size={22} aria-hidden="true" />
      <div>
        <strong>Chưa tải được dữ liệu</strong>
        <p>{message}</p>
        {onRetry && <button className="button secondary" onClick={onRetry}>Thử lại</button>}
      </div>
    </div>
  );
}

export function StatusBadge({ value }: { value: string }) {
  const normalized = value.toLowerCase();
  const has = (token: string) => normalized === token || new RegExp(`(^|[_-])${token}($|[_-])`).test(normalized);
  const tone = has('fail') || has('reject') || has('closed') || has('cancel') || has('inactive')
    ? 'danger'
    : has('pending') || has('open') || has('follow') || has('awaiting')
      ? 'warning'
      : has('active') || has('success') || has('approved') || has('paid') || has('resolved') || has('ready')
        ? 'success'
        : 'neutral';
  return <span className={`status-badge ${tone}`}>{statusLabel(value)}</span>;
}

export function Modal({ title, children, onClose }: { title: string; children: ReactNode; onClose: () => void }) {
  return (
    <div className="modal-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
      <section className="modal" role="dialog" aria-modal="true" aria-labelledby="modal-title">
        <div className="modal-header">
          <h2 id="modal-title">{title}</h2>
          <button className="icon-button" aria-label="Đóng" onClick={onClose}><X size={20} /></button>
        </div>
        {children}
      </section>
    </div>
  );
}

export function Drawer({ title, children, onClose }: { title: string; children: ReactNode; onClose: () => void }) {
  return (
    <div className="drawer-backdrop" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget) onClose(); }}>
      <aside className="drawer" role="dialog" aria-modal="true" aria-labelledby="drawer-title">
        <div className="drawer-header">
          <h2 id="drawer-title">{title}</h2>
          <button className="icon-button" aria-label="Đóng" onClick={onClose}><X size={20} /></button>
        </div>
        {children}
      </aside>
    </div>
  );
}

export function ReasonDialog({
  action,
  subject,
  initialReason = '',
  busy = false,
  requireTransferVerification = false,
  requireExternalConfirmation = false,
  onCancel,
  onConfirm,
}: {
  action: string;
  subject: string;
  initialReason?: string;
  busy?: boolean;
  requireTransferVerification?: boolean;
  requireExternalConfirmation?: boolean;
  onCancel: () => void;
  onConfirm: (reason: string, flags: { transferVerified: boolean; externalConfirmed: boolean }) => void;
}) {
  const [reason, setReason] = useState(initialReason);
  const [transferVerified, setTransferVerified] = useState(false);
  const [externalConfirmed, setExternalConfirmed] = useState(false);
  const canSubmit = reason.trim().length > 0 && (!requireTransferVerification || transferVerified) && (!requireExternalConfirmation || externalConfirmed);
  return (
    <Modal title={`Xác nhận: ${actionLabel(action)}`} onClose={onCancel}>
      <div className="modal-body">
        <p className="modal-intro">Bạn đang xử lý <strong>{subject}</strong>. Thao tác sẽ được ghi nhận để kiểm tra sau.</p>
        <label className="field-label" htmlFor="admin-reason">Lý do bắt buộc</label>
        <textarea id="admin-reason" className="textarea" value={reason} onChange={(event) => setReason(event.target.value)} placeholder="Nhập lý do ngắn gọn…" rows={4} autoFocus />
        {requireTransferVerification && (
          <label className="check-row"><input type="checkbox" checked={transferVerified} onChange={(event) => setTransferVerified(event.target.checked)} /> Tôi đã đối chiếu đúng giao dịch chuyển khoản.</label>
        )}
        {requireExternalConfirmation && (
          <label className="check-row"><input type="checkbox" checked={externalConfirmed} onChange={(event) => setExternalConfirmed(event.target.checked)} /> Tôi đã xử lý thu hồi ưu đãi bên ngoài.</label>
        )}
      </div>
      <div className="modal-actions">
        <button className="button secondary" onClick={onCancel}>Hủy</button>
        <button className="button primary" disabled={!canSubmit || busy} onClick={() => onConfirm(reason.trim(), { transferVerified, externalConfirmed })}><CheckCircle2 size={17} /> {busy ? 'Đang xử lý…' : 'Xác nhận'}</button>
      </div>
    </Modal>
  );
}

export function Toast({ message, error, onClose }: { message: string; error?: boolean; onClose: () => void }) {
  return (
    <div className={`toast ${error ? 'toast-error' : ''}`} role="status">
      {error ? <AlertTriangle size={18} /> : <CheckCircle2 size={18} />}
      <span>{message}</span>
      <button className="toast-close" aria-label="Đóng thông báo" onClick={onClose}><X size={16} /></button>
    </div>
  );
}
