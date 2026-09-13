import { useCallback, useEffect, useMemo, useState } from 'react';
import { ArrowUpRight, BellRing, CalendarDays, CircleDollarSign, RefreshCw, UsersRound } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAdminAuth } from '../auth/AuthProvider';
import { EmptyState, ErrorState, LoadingState, StatusBadge } from '../components/Ui';
import { formatMoney, metricLabel, formatDate } from '../lib/labels';
import type { DashboardMetric } from '../types';

export function DashboardPage() {
  const { api, session } = useAdminAuth();
  const navigate = useNavigate();
  const [metrics, setMetrics] = useState<DashboardMetric[]>([]);
  const [pending, setPending] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [range, setRange] = useState('30');
  const [updatedAt, setUpdatedAt] = useState<string>();

  const load = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const to = new Date();
      const from = new Date(to.getTime() - Number(range) * 24 * 60 * 60 * 1000);
      const [nextMetrics, nextPending] = await Promise.all([
        api.fetchDashboard(from, to),
        api.fetchPaymentReviewAlert().catch(() => 0),
      ]);
      setMetrics(nextMetrics);
      setPending(nextPending);
      setUpdatedAt(new Date().toISOString());
    } catch (nextError) {
      setError(nextError instanceof Error ? nextError.message : 'Chưa tải được tổng quan.');
    } finally {
      setLoading(false);
    }
  }, [api, range]);

  useEffect(() => { void load(); }, [load]);
  useEffect(() => {
    const listener = () => void load();
    window.addEventListener('admin:refresh', listener);
    return () => window.removeEventListener('admin:refresh', listener);
  }, [load]);

  const metricMap = useMemo(() => new Map(metrics.map((metric) => [metric.key, metric])), [metrics]);
  if (!session) return null;
  return (
    <div className="page-stack">
      <section className="page-heading">
        <div><span className="eyebrow">Theo dõi trong {range} ngày</span><h1>Tổng quan vận hành</h1><p>Nhìn nhanh các chỉ số và việc cần xử lý tiếp theo.</p></div>
        <div className="heading-actions"><label className="select-wrap"><CalendarDays size={16} /><select value={range} onChange={(event) => setRange(event.target.value)} aria-label="Khoảng thời gian"><option value="7">7 ngày</option><option value="30">30 ngày</option><option value="90">90 ngày</option></select></label><button className="button secondary" onClick={() => void load()} disabled={loading}><RefreshCw size={16} /> Làm mới</button></div>
      </section>
      {error && <ErrorState message={error} onRetry={() => void load()} />}
      {loading && metrics.length === 0 ? <LoadingState /> : metrics.length === 0 ? <EmptyState title="Chưa có số liệu" message="Tổng quan sẽ hiển thị khi dịch vụ trả về dữ liệu vận hành." /> : (
        <>
          <section className="metric-grid" aria-label="Chỉ số vận hành">
            {metrics.map((metric) => <MetricCard key={metric.key} metric={metric} onOpen={() => metric.targetSection && navigate(`/admin/${metric.targetSection}`)} />)}
          </section>
          <section className="dashboard-grid">
            <div className="panel priority-panel">
              <div className="panel-heading"><div><span className="eyebrow">Ưu tiên hôm nay</span><h2>Việc cần xử lý</h2></div><BellRing size={20} className="panel-icon" /></div>
              <button className="priority-row" onClick={() => navigate('/admin/payments')}><span className="priority-icon amber"><CircleDollarSign size={18} /></span><span><strong>{pending} giao dịch chờ duyệt</strong><small>Đối chiếu trước khi quyết định</small></span><ArrowUpRight size={17} /></button>
              <button className="priority-row" onClick={() => navigate('/admin/users')}><span className="priority-icon blue"><UsersRound size={18} /></span><span><strong>{metricMap.get('users_total')?.value ?? 0} người dùng trong hệ thống</strong><small>Mở danh sách người dùng</small></span><ArrowUpRight size={17} /></button>
            </div>
            <div className="panel snapshot-panel"><div className="panel-heading"><div><span className="eyebrow">Trạng thái dữ liệu</span><h2>Snapshot gần nhất</h2></div><StatusBadge value="ready" /></div><div className="snapshot-value">{formatDate(updatedAt)}</div><p>Doanh thu đã duyệt trong khoảng chọn: <strong>{formatMoney(metricMap.get('revenue_succeeded')?.value)}</strong></p><p className="muted">Số liệu được lấy từ quyền vận hành hiện tại của bạn.</p></div>
          </section>
        </>
      )}
    </div>
  );
}

function MetricCard({ metric, onOpen }: { metric: DashboardMetric; onOpen: () => void }) {
  return <button className="metric-card" onClick={onOpen}><span className="metric-top"><span className="metric-label">{metricLabel(metric.key, metric.label)}</span><ArrowUpRight size={16} /></span><strong>{metric.key === 'revenue_succeeded' || metric.key === 'commission_available' ? formatMoney(metric.value) : new Intl.NumberFormat('vi-VN').format(metric.value)}</strong><span className="metric-bottom"><StatusBadge value={metric.status} /> <small>Trong kỳ đã chọn</small></span></button>;
}
