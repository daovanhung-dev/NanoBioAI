import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { AdminApi, AdminApiError } from '../lib/admin-api';
import type { BackendAuthSession } from '../lib/backend-client';
import type { AdminSession } from '../types';

type AuthStatus = 'loading' | 'signed_out' | 'signed_in' | 'password_change_required' | 'forbidden' | 'error';

type AuthContextValue = {
  api: AdminApi;
  status: AuthStatus;
  session: AdminSession | null;
  userEmail: string | null;
  message: string | null;
  signIn: (identifier: string, password: string) => Promise<boolean>;
  changePassword: (newPassword: string) => Promise<void>;
  signOut: () => Promise<void>;
  refresh: () => Promise<void>;
};

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const api = useMemo(() => new AdminApi(), []);
  const [status, setStatus] = useState<AuthStatus>('loading');
  const [session, setSession] = useState<AdminSession | null>(null);
  const [userEmail, setUserEmail] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const loadFromSession = useCallback(async (authSession: BackendAuthSession | null, signOutNonAdmin = true, throwOnError = false): Promise<AdminSession | null> => {
    if (!authSession) {
      setSession(null);
      setUserEmail(null);
      setStatus('signed_out');
      return null;
    }

    setUserEmail(authSession.user.email);
    if (authSession.mustChangePassword) {
      setSession(null);
      setStatus('password_change_required');
      setMessage(null);
      return null;
    }

    try {
      const adminSession = await api.fetchAdminSession();
      if (!adminSession.active || adminSession.roles.length === 0) {
        if (signOutNonAdmin) await api.signOut().catch(() => undefined);
        setSession(null);
        setStatus('forbidden');
        setMessage('Tài khoản này chưa có quyền quản trị đang hoạt động.');
        return null;
      }
      setSession(adminSession);
      setStatus('signed_in');
      setMessage(null);
      return adminSession;
    } catch (error) {
      if (error instanceof AdminApiError && error.businessCode === 'PASSWORD_CHANGE_REQUIRED') {
        setSession(null);
        setStatus('password_change_required');
        setMessage(null);
        return null;
      }
      setSession(null);
      setStatus('error');
      setMessage(error instanceof Error ? error.message : 'Chưa thể kiểm tra quyền quản trị.');
      if (throwOnError) throw error;
      return null;
    }
  }, [api]);

  const refresh = useCallback(async () => {
    setStatus('loading');
    try {
      const current = await api.getCurrentSession();
      await loadFromSession(current);
    } catch (error) {
      setStatus('error');
      setMessage(error instanceof Error ? error.message : 'Chưa thể kết nối khu quản trị.');
    }
  }, [api, loadFromSession]);

  useEffect(() => {
    void refresh();
    let subscription: { unsubscribe: () => void } | undefined;
    try {
      subscription = api.watchAuth((authSession) => {
        void loadFromSession(authSession, false);
      });
    } catch (error) {
      setStatus('error');
      setMessage(error instanceof Error ? error.message : 'Chưa thể khởi động khu quản trị.');
    }
    return () => subscription?.unsubscribe();
  }, [api, loadFromSession, refresh]);

  const signIn = useCallback(async (identifier: string, password: string) => {
    setStatus('loading');
    setMessage(null);
    try {
      const authSession = await api.signIn(identifier, password);
      const next = await loadFromSession(authSession, true, true);
      if (authSession.mustChangePassword) return false;
      if (!next) {
        throw new AdminApiError('Tài khoản này chưa có quyền quản trị đang hoạt động.');
      }
      return true;
    } catch (error) {
      const safeMessage = error instanceof Error ? error.message : 'Chưa thể đăng nhập lúc này.';
      if (safeMessage.includes('chưa có quyền quản trị')) {
        setStatus('forbidden');
      } else {
        setStatus('error');
      }
      setMessage(safeMessage);
      throw error;
    }
  }, [api, loadFromSession]);

  const changePassword = useCallback(async (newPassword: string) => {
    setMessage(null);
    try {
      const authSession = await api.changePassword(newPassword);
      const next = await loadFromSession(authSession, true, true);
      if (authSession.mustChangePassword || !next) {
        throw new AdminApiError('Tài khoản chưa thể tiếp tục vào khu quản trị.');
      }
    } catch (error) {
      const safeMessage = error instanceof Error ? error.message : 'Chưa thể cập nhật mật khẩu.';
      setStatus('password_change_required');
      setMessage(safeMessage);
      throw error;
    }
  }, [api, loadFromSession]);

  const signOut = useCallback(async () => {
    await api.signOut();
    setSession(null);
    setUserEmail(null);
    setStatus('signed_out');
    setMessage(null);
  }, [api]);

  return (
    <AuthContext.Provider value={{ api, status, session, userEmail, message, signIn, changePassword, signOut, refresh }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAdminAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAdminAuth must be used inside AuthProvider');
  return context;
}
