import { Navigate, Outlet, Route, Routes, useLocation } from 'react-router-dom';
import { useAdminAuth } from './auth/AuthProvider';
import { AdminShell } from './components/AdminShell';
import { ErrorState, LoadingState } from './components/Ui';
import { AccountsPage } from './pages/AccountsPage';
import { DashboardPage } from './pages/DashboardPage';
import { LoginPage } from './pages/LoginPage';
import { SectionPage } from './pages/SectionPage';
import { WellnessRewardsPage } from './pages/WellnessRewardsPage';

export function App() {
  return (
    <Routes>
      <Route path="/admin/login" element={<LoginPage />} />
      <Route path="/admin" element={<RequireAdmin />}>
        <Route element={<ShellRoute />}>
          <Route index element={<Navigate to="dashboard" replace />} />
          <Route path="dashboard" element={<DashboardPage />} />
          <Route path="users" element={<AccountsPage />} />
          <Route path="accounts" element={<Navigate to="../users" replace />} />
          <Route path="accounts/create" element={<Navigate to="../users?create=1" replace />} />
          <Route path="accounts/upgrade" element={<Navigate to="../users?upgrade=1" replace />} />
          <Route path="memberships/review" element={<SectionPage section="payments" />} />
          <Route path="payments" element={<SectionPage section="payments" />} />
          <Route path="sales" element={<SectionPage section="sales" />} />
          <Route path="sales/review" element={<SectionPage section="sales" />} />
          <Route path="sale-conversions" element={<SectionPage section="sale-conversions" />} />
          <Route path="sales/payouts" element={<SectionPage section="sale-conversions" />} />
          <Route path="wellness-rewards" element={<WellnessRewardsPage />} />
          <Route path="reconciliation" element={<SectionPage section="reconciliation" />} />
          <Route path="plans" element={<SectionPage section="plans" />} />
          <Route path="reports" element={<SectionPage section="reports" />} />
          <Route path="audit" element={<SectionPage section="audit" />} />
          <Route path="config" element={<SectionPage section="config" />} />
          <Route path="*" element={<Navigate to="dashboard" replace />} />
        </Route>
      </Route>
      <Route path="*" element={<Navigate to="/admin/dashboard" replace />} />
    </Routes>
  );
}

function RequireAdmin() {
  const { status, session, message, refresh } = useAdminAuth();
  const location = useLocation();
  if (status === 'loading') return <LoadingState label="Đang khôi phục phiên quản trị…" />;
  if (status === 'signed_out' || !session) {
    if (status === 'forbidden') return <AccessDenied message={message ?? 'Tài khoản chưa có quyền quản trị.'} />;
    if (status === 'error') return <ErrorState message={message ?? 'Chưa thể kiểm tra phiên quản trị.'} onRetry={() => void refresh()} />;
    return <Navigate to="/admin/login" replace state={{ from: `${location.pathname}${location.search}` }} />;
  }
  return <Outlet />;
}

function ShellRoute() {
  return <AdminShell><Outlet /></AdminShell>;
}

function AccessDenied({ message }: { message: string }) {
  return <div className="standalone-state"><div className="state-icon soft-red">!</div><h1>Không có quyền truy cập</h1><p>{message}</p><a className="button secondary" href="#/admin/login">Đến trang đăng nhập</a></div>;
}
