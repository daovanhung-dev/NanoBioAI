import { FormEvent, useState } from 'react';
import { ArrowRight, LockKeyhole, ShieldCheck } from 'lucide-react';
import { Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAdminAuth } from '../auth/AuthProvider';
import { ErrorState } from '../components/Ui';

export function LoginPage() {
  const { status, session, message, signIn, changePassword, signOut, refresh } = useAdminAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [busy, setBusy] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  if (session && status === 'signed_in') return <Navigate to="/admin/dashboard" replace />;

  async function submit(event: FormEvent) {
    event.preventDefault();
    setFormError(null);
    if (status === 'password_change_required') {
      if (newPassword.length < 8) {
        setFormError('Mật khẩu mới cần ít nhất 8 ký tự.');
        return;
      }
      if (newPassword !== confirmPassword) {
        setFormError('Mật khẩu nhập lại chưa khớp.');
        return;
      }
      setBusy(true);
      try {
        await changePassword(newPassword);
        navigate('/admin/dashboard', { replace: true });
      } catch (error) {
        setFormError(error instanceof Error ? error.message : 'Chưa thể cập nhật mật khẩu.');
      } finally {
        setBusy(false);
      }
      return;
    }

    if (!identifier.trim() || password.length < 1) {
      setFormError('Vui lòng nhập tên đăng nhập, email hoặc số điện thoại cùng mật khẩu.');
      return;
    }
    setBusy(true);
    try {
      const canContinue = await signIn(identifier, password);
      if (!canContinue) {
        setPassword('');
        return;
      }
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
          <h2>{status === 'password_change_required' ? 'Đặt mật khẩu mới' : 'Chào mừng trở lại'}</h2>
          <p className="login-subtitle">
            {status === 'password_change_required'
              ? 'Hãy đổi mật khẩu tạm để tiếp tục vào khu quản trị.'
              : 'Đăng nhập bằng tài khoản đã được cấp quyền quản trị.'}
          </p>
          {(formError || (configurationError ? message : null)) && <div className="inline-alert danger" role="alert">{formError || message}</div>}
          {status === 'password_change_required' ? <>
            <label className="field-label" htmlFor="admin-new-password">Mật khẩu mới</label>
            <input id="admin-new-password" className="input" type="password" autoComplete="new-password" value={newPassword} onChange={(event) => setNewPassword(event.target.value)} placeholder="Ít nhất 8 ký tự" />
            <label className="field-label" htmlFor="admin-confirm-password">Nhập lại mật khẩu mới</label>
            <input id="admin-confirm-password" className="input" type="password" autoComplete="new-password" value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} placeholder="Nhập lại mật khẩu mới" />
            <button className="button primary wide" disabled={busy}>{busy ? 'Đang cập nhật…' : 'Lưu mật khẩu mới'}</button>
            <button className="button secondary wide" type="button" disabled={busy} onClick={() => void signOut()}>Đăng xuất</button>
          </> : <>
            <label className="field-label" htmlFor="admin-identifier">Tên đăng nhập, email hoặc số điện thoại</label>
            <input id="admin-identifier" className="input" type="text" autoComplete="username" value={identifier} onChange={(event) => setIdentifier(event.target.value)} placeholder="admin, admin@nanobio.vn hoặc 0912 345 678" />
            <label className="field-label" htmlFor="admin-password">Mật khẩu</label>
            <input id="admin-password" className="input" type="password" autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} placeholder="Nhập mật khẩu" />
            <button className="button primary wide" disabled={busy || status === 'loading'}>{busy ? 'Đang kiểm tra…' : <>Đăng nhập <ArrowRight size={17} /></>}</button>
          </>}
          {status === 'forbidden' && <p className="login-hint">Tài khoản đăng nhập được nhưng chưa có vai trò quản trị đang hoạt động.</p>}
          {status === 'error' && !configurationError && message && !formError && <ErrorState message={message} onRetry={() => void refresh()} />}
          <small className="login-footer">NanoBio · Vận hành có trách nhiệm</small>
        </form>
      </div>
    </div>
  );
}
