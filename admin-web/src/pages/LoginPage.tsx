import { FormEvent, useState } from 'react';
import { ArrowRight, LockKeyhole, ShieldCheck } from 'lucide-react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAdminAuth } from '../auth/AuthProvider';
import { ErrorState } from '../components/Ui';

export function LoginPage() {
  const { status, session, message, signIn, refresh } = useAdminAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  if (session && status === 'signed_in') return <Navigate to="/admin/dashboard" replace />;

  async function submit(event: FormEvent) {
    event.preventDefault();
    setFormError(null);
    if (!email.trim() || password.length < 1) {
      setFormError('Vui lòng nhập email và mật khẩu.');
      return;
    }
    setBusy(true);
    try {
      await signIn(email, password);
      const destination = typeof location.state?.from === 'string' ? location.state.from : '/admin/dashboard';
      navigate(destination, { replace: true });
    } catch (error) {
      setFormError(error instanceof Error ? error.message : 'Chưa thể đăng nhập lúc này.');
    } finally {
      setBusy(false);
    }
  }

  const configurationError = status === 'error' && message?.includes('cấu hình');
  return (
    <div className="login-page">
      <div className="login-visual">
        <div className="login-orb orb-one" /><div className="login-orb orb-two" />
        <div className="login-brand"><div className="brand-mark large"><ShieldCheck size={30} /></div><span>NanoBio Admin</span></div>
        <div className="login-hero"><span className="eyebrow light">Bảng điều khiển vận hành</span><h1>Giữ hệ thống khỏe mạnh, từng quyết định một.</h1><p>Không gian dành cho đội ngũ NanoBio theo dõi dữ liệu và xử lý công việc với quyền hạn rõ ràng.</p></div>
        <div className="login-trust"><LockKeyhole size={17} /> Mọi thao tác quan trọng đều được kiểm tra và ghi nhận.</div>
      </div>
      <div className="login-card-wrap">
        <form className="login-card" onSubmit={submit}>
          <div className="mobile-login-logo"><ShieldCheck size={24} /></div>
          <span className="eyebrow">Khu vực nội bộ</span>
          <h2>Chào mừng trở lại</h2>
          <p className="login-subtitle">Đăng nhập bằng tài khoản đã được cấp quyền quản trị.</p>
          {(formError || (configurationError ? message : null)) && <div className="inline-alert danger" role="alert">{formError || message}</div>}
          <label className="field-label" htmlFor="admin-email">Email</label>
          <input id="admin-email" className="input" type="email" autoComplete="username" value={email} onChange={(event) => setEmail(event.target.value)} placeholder="admin@nanobio.vn" />
          <label className="field-label" htmlFor="admin-password">Mật khẩu</label>
          <input id="admin-password" className="input" type="password" autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Nhập mật khẩu" />
          <button className="button primary wide" disabled={busy || status === 'loading'}>{busy ? 'Đang kiểm tra…' : <>Đăng nhập <ArrowRight size={17} /></>}</button>
          {status === 'forbidden' && <p className="login-hint">Tài khoản đăng nhập được nhưng chưa có vai trò quản trị đang hoạt động.</p>}
          {status === 'error' && !configurationError && message && !formError && <ErrorState message={message} onRetry={() => void refresh()} />}
          <small className="login-footer">NanoBio · Vận hành có trách nhiệm</small>
        </form>
      </div>
    </div>
  );
}
