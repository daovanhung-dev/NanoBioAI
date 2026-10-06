import { useCallback, useEffect, useState, type FormEvent } from 'react';
import { ChevronLeft, ChevronRight, Pencil, RefreshCw, Search } from 'lucide-react';
import { useAdminAuth } from '../auth/AuthProvider';
import { EmptyState, ErrorState, LoadingState, Modal, StatusBadge, Toast } from '../components/Ui';
import { formatDate, statusLabel } from '../lib/labels';
import { makeKey } from '../lib/admin-api';
import {
  canManageEarlyAccess,
  EARLY_ACCESS_LEAD_STATUSES,
  type EarlyAccessLead,
  type EarlyAccessLeadStatus,
} from '../types';

const PAGE_SIZE = 25;

const genderLabels: Record<string, string> = {
  male: 'Nam',
  female: 'Nữ',
  other: 'Khác',
  prefer_not_to_say: 'Không muốn trả lời',
};

type StatusEdit = {
  lead: EarlyAccessLead;
  status: EarlyAccessLeadStatus;
};

export function EventInfoPage() {
  const { api, session } = useAdminAuth();
  const [draftQuery, setDraftQuery] = useState('');
  const [query, setQuery] = useState('');
  const [page, setPage] = useState(0);
  const [rows, setRows] = useState<EarlyAccessLead[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [toast, setToast] = useState<string | null>(null);
  const [edit, setEdit] = useState<StatusEdit | null>(null);
  const [reason, setReason] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const result = await api.fetchEarlyAccessLeads(query, page, PAGE_SIZE);
      setRows(result.rows);
      setTotal(result.total);
      if (page > 0 && result.total > 0 && page * PAGE_SIZE >= result.total) {
        setPage(Math.max(0, Math.ceil(result.total / PAGE_SIZE) - 1));
      }
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Chưa tải được thông tin sự kiện.');
    } finally {
      setLoading(false);
    }
  }, [api, page, query]);

  useEffect(() => { void load(); }, [load]);
  useEffect(() => {
    const listener = () => void load();
    window.addEventListener('admin:refresh', listener);
    return () => window.removeEventListener('admin:refresh', listener);
  }, [load]);

  if (!session) return null;
  const canUpdate = canManageEarlyAccess(session);
  const pageCount = Math.max(1, Math.ceil(total / PAGE_SIZE));

  function search(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPage(0);
    setQuery(draftQuery.trim());
  }

  async function confirmStatusUpdate() {
    if (!edit || !reason.trim() || busy) return;
    setBusy(true);
    try {
      await api.updateEarlyAccessLeadStatus({
        leadId: edit.lead.id,
        status: edit.status,
        reason: reason.trim(),
        idempotencyKey: makeKey('early-access-status', edit.lead.id),
      });
      setEdit(null);
      setReason('');
      setToast('Đã cập nhật trạng thái hồ sơ.');
      await load();
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Chưa cập nhật được trạng thái hồ sơ.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="page-stack">
      <section className="page-heading">
        <div>
          <span className="eyebrow">NanoBio Early Access</span>
          <h1>Thông tin sự kiện</h1>
          <p>Xem thông tin khách hàng đã đăng ký trên website và theo dõi hồ sơ hỗ trợ.</p>
        </div>
        <div className="heading-actions">
          <button className="button secondary" onClick={() => void load()} disabled={loading}>
            <RefreshCw size={16} /> Làm mới
          </button>
        </div>
      </section>

      <section className="summary-strip event-info-summary">
        <div><span className="eyebrow">Tổng hồ sơ</span><strong>{total.toLocaleString('vi-VN')}</strong></div>
        <div><span className="eyebrow">Quyền xem</span><strong>Admin được phân quyền</strong></div>
        <div><span className="eyebrow">Lưu trữ</span><strong>12 tháng, trừ hồ sơ còn mở</strong></div>
      </section>

      <form className="filter-bar" onSubmit={search}>
        <div className="search-field">
          <Search size={17} aria-hidden="true" />
          <input
            value={draftQuery}
            onChange={(event) => setDraftQuery(event.target.value)}
            placeholder="Tìm theo số điện thoại, họ tên hoặc địa chỉ…"
            aria-label="Tìm kiếm thông tin khách hàng"
          />
        </div>
        <button className="button secondary" type="submit">Tìm kiếm</button>
      </form>

      {toast && <Toast message={toast} onClose={() => setToast(null)} />}
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {loading && rows.length === 0 ? <LoadingState label="Đang tải thông tin sự kiện…" /> : null}
      {!loading && !error && rows.length === 0 ? (
        <EmptyState
          title={query ? 'Không tìm thấy hồ sơ' : 'Chưa có khách hàng đăng ký'}
          message={query ? 'Thử từ khóa khác hoặc xóa bộ lọc tìm kiếm.' : 'Thông tin đăng ký mới từ website sẽ hiển thị tại đây.'}
        />
      ) : null}
      {rows.length > 0 && (
        <section className="table-card event-info-table" aria-label="Danh sách khách hàng NanoBio Early Access">
          <div className="table-scroll">
            <table>
              <thead>
                <tr>
                  <th>Số điện thoại</th>
                  <th>Họ tên</th>
                  <th>Tuổi</th>
                  <th>Giới tính</th>
                  <th>Địa chỉ</th>
                  <th>Ngày đăng ký</th>
                  <th>Trạng thái</th>
                  {canUpdate && <th>Thao tác</th>}
                </tr>
              </thead>
              <tbody>
                {rows.map((lead) => (
                  <tr key={lead.id}>
                    <td className="nowrap"><strong className="item-title">{lead.phoneDisplay ?? lead.phoneE164}</strong></td>
                    <td>{lead.fullName ?? '—'}</td>
                    <td>{lead.age ?? '—'}</td>
                    <td>{lead.gender ? genderLabels[lead.gender] ?? '—' : '—'}</td>
                    <td className="event-info-address">{lead.address ?? '—'}</td>
                    <td className="nowrap">{formatDate(lead.createdAt)}</td>
                    <td><StatusBadge value={lead.status} /></td>
                    {canUpdate && (
                      <td>
                        <button
                          className="text-action"
                          onClick={() => { setEdit({ lead, status: lead.status }); setReason(''); setError(null); }}
                          aria-label={`Cập nhật trạng thái cho ${lead.phoneDisplay ?? lead.phoneE164}`}
                        >
                          <Pencil size={14} /> Cập nhật
                        </button>
                      </td>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <div className="event-info-pagination">
            <span>{total === 0 ? 0 : page * PAGE_SIZE + 1}–{Math.min((page + 1) * PAGE_SIZE, total)} / {total.toLocaleString('vi-VN')}</span>
            <div>
              <button className="button secondary" onClick={() => setPage((current) => Math.max(0, current - 1))} disabled={page === 0 || loading} aria-label="Trang trước">
                <ChevronLeft size={16} /> Trước
              </button>
              <span>Trang {page + 1} / {pageCount}</span>
              <button className="button secondary" onClick={() => setPage((current) => Math.min(pageCount - 1, current + 1))} disabled={page >= pageCount - 1 || loading} aria-label="Trang sau">
                Sau <ChevronRight size={16} />
              </button>
            </div>
          </div>
        </section>
      )}

      {edit && (
        <Modal title="Cập nhật trạng thái hồ sơ" onClose={() => { if (!busy) setEdit(null); }}>
          <div className="modal-body">
            <p className="modal-intro">Hồ sơ của <strong>{edit.lead.fullName ?? edit.lead.phoneDisplay ?? edit.lead.phoneE164}</strong>. Thao tác sẽ được ghi nhận để kiểm tra sau.</p>
            <label className="field-label" htmlFor="early-access-status">Trạng thái</label>
            <select
              id="early-access-status"
              className="input"
              value={edit.status}
              onChange={(event) => setEdit({ ...edit, status: event.target.value as EarlyAccessLeadStatus })}
            >
              {EARLY_ACCESS_LEAD_STATUSES.map((status) => (
                <option key={status} value={status}>{statusLabel(status)}</option>
              ))}
            </select>
            <label className="field-label" htmlFor="early-access-reason">Lý do bắt buộc</label>
            <textarea
              id="early-access-reason"
              className="textarea"
              value={reason}
              maxLength={300}
              onChange={(event) => setReason(event.target.value)}
              placeholder="Nhập ghi chú xử lý ngắn gọn…"
              rows={4}
            />
          </div>
          <div className="modal-actions">
            <button className="button secondary" onClick={() => setEdit(null)} disabled={busy}>Hủy</button>
            <button className="button primary" onClick={() => void confirmStatusUpdate()} disabled={!reason.trim() || busy}>
              {busy ? 'Đang lưu…' : 'Lưu trạng thái'}
            </button>
          </div>
        </Modal>
      )}
    </div>
  );
}
